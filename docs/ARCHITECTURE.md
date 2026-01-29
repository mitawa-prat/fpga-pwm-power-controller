# System Architecture

## Overview

The PWM Power Controller consists of three main subsystems integrated into a single top-level module.

## Block Diagram
```
                      ┌────────────────────────────────────┐
                      │  Complete Power Controller         │
                      │                                    │
   start_cmd ────────►│  ┌──────────────────────┐          │
   stop_cmd ─────────►│  │  State Machine (FSM) │          │
   fault_ack ────────►│  │                      │          │
                      │  │  Controls system     │          │
                      │  │  operation modes     │          │
                      │  └──────────┬───────────┘          │
                      │             │ pwm_enable           │
                      │             ▼                      │
   duty_cycle ───────►│  ┌──────────────────────┐          │
                      │  │  PWM Generator       │          │
                      │  │                      │          │
                      │  │  Generates PWM       │          │
                      │  │  signal              │──────────┼──► pwm_out
                      │  └──────────┬───────────┘          │
                      │             │                      │
                      │             │ (gated by interlock) │
                      │             │                      │
   current_value ────►│  ┌──────────▼───────────┐          │
   voltage_value ────►│  │  Safety Interlocks   │          │
   temp_value ───────►│  │                      │          │
                      │  │  Monitors sensors    │          │
   thresholds ───────►│  │  and generates       │──────────┼──► interlock_active
   hysteresis ───────►│  │  fault signals       │          │     fault_current
                      │  │                      │          │     fault_voltage
                      │  └──────────────────────┘          │     fault_temperature
                      │                                    │
                      └────────────────────────────────────┘
```

## Component Descriptions

### 1. PWM Generator (`pwm_generator.vhdl`)

**Purpose:** Generates pulse-width modulated output signal for power control.

**Algorithm:**
```
counter = 0 to 255 (8-bit)
if counter < duty_cycle:
    pwm_out = HIGH
else:
    pwm_out = LOW
```

**Inputs:**
- `clk`: System clock
- `reset`: Asynchronous reset
- `enable`: Enable PWM counting
- `duty_cycle[7:0]`: Desired duty cycle (0-255)

**Outputs:**
- `pwm_out`: PWM signal

**Key Features:**
- 8-bit resolution (256 steps)
- Synchronous design
- Configurable duty cycle
- Disabled state (output LOW) when enable = '0'

### 2. Safety Interlock System (`interlock.vhdl`)

**Purpose:** Monitors multiple sensor inputs and generates fault signals when thresholds are exceeded.

**Algorithm with Hysteresis:**
```
For each sensor:
    if value >= threshold:
        fault = TRUE (trip)
    else if value < (threshold - hysteresis):
        fault = FALSE (clear)
    else:
        fault = maintain current state (hysteresis region)

interlock_active = fault_current OR fault_voltage OR fault_temperature
```

**Inputs:**
- `clk`, `reset`
- `current_value[11:0]`: Current sensor reading
- `voltage_value[11:0]`: Voltage sensor reading
- `temperature_value[11:0]`: Temperature sensor reading
- `current_threshold[11:0]`: Current trip threshold
- `voltage_threshold[11:0]`: Voltage trip threshold
- `temp_threshold[11:0]`: Temperature trip threshold
- `hysteresis[11:0]`: Hysteresis band

**Outputs:**
- `interlock_active`: Master fault signal (OR of all faults)
- `fault_current`: Current fault flag
- `fault_voltage`: Voltage fault flag
- `fault_temperature`: Temperature fault flag

**Key Features:**
- Three independent monitoring channels
- Hysteresis prevents chattering
- Individual fault flags for diagnostics
- Fast combinational output (interlock_active)

### 3. State Machine (`power_controller_fsm.vhdl`)

**Purpose:** Controls system operational modes and enforces safe state transitions.

**State Diagram:**
```
       ┌─────┐
       │IDLE │◄────────────┐
       └──┬──┘             │
          │ start_cmd      │ fault_ack
          ▼                │ (and fault clear)
       ┌────────┐          │
       │STARTUP │          │
       └───┬────┘          │
           │delay complete │
           ▼               │
       ┌────────┐          │
   ┌──►│RUNNING │          │
   │   └───┬─┬──┘          │
   │       │ │             │
   │   ────┘ └────         │
   │ stop_cmd  fault       │
   │       │    │          │
   │       ▼    ▼          │
   │  ┌────────┐ ┌─────┐   │
   │  │SHUTDOWN│ │FAULT│───┘
   │  └────┬───┘ └─────┘
   │       │
   └───────┘
```

**States:**
- `IDLE`: System off, awaiting start command
- `STARTUP`: Initialization sequence (50 clock cycles)
- `RUNNING`: Normal operation, PWM enabled
- `FAULT`: Safety fault detected, awaiting acknowledgment
- `SHUTDOWN`: Controlled power-down (30 clock cycles)

**Transitions:**
- IDLE → STARTUP: start_cmd asserted (and no faults)
- STARTUP → RUNNING: Delay complete
- STARTUP → FAULT: Fault detected during startup
- RUNNING → FAULT: Fault detected
- RUNNING → SHUTDOWN: stop_cmd asserted
- FAULT → IDLE: fault_ack asserted AND faults cleared
- SHUTDOWN → IDLE: Delay complete

**Outputs:**
- `pwm_enable`: Enable signal for PWM generator
- `state_*`: Individual state indicators (for monitoring)

### 4. Top-Level Integration (`complete_power_controller.vhdl`)

**Purpose:** Integrates all subsystems with triple-redundant safety logic.

**Safety Architecture:**
```
FSM pwm_enable ──┐
                 AND ──► PWM Generator enable
NOT interlock ───┘

PWM raw output ──┐
                 AND ──► Final pwm_out
NOT interlock ───┘
```

**Triple-Redundant Safety:**
1. **FSM Level:** Only enables PWM in RUNNING state
2. **Enable Level:** PWM enable ANDed with NOT interlock
3. **Output Level:** Final output gated by NOT interlock

This ensures PWM cannot be active during faults even if there's a bug in any single layer.

## Timing Analysis

### Critical Paths

**1. Fault Detection to PWM Disable:**
```
Sensor Input → Comparator → OR Gate → NOT → AND Gate → PWM Output
Estimated: <5ns combinational delay
```

**2. State Transition:**
```
Clock Edge → State Register Update → Output Logic → Next Cycle
Latency: 1 clock cycle
```

**3. PWM Generation:**
```
Clock Edge → Counter Update → Compare → PWM Output
Latency: 1 clock cycle
```

### Timing Constraints

For 100 MHz operation (10ns period):
- Setup time: <8ns
- Hold time: >1ns
- Clock-to-output: <5ns
- Combinational paths: <10ns

## Resource Utilization (Estimated)

**For Xilinx Kintex-7:**
- **LUTs:** ~100
  - PWM Generator: ~30
  - Interlock System: ~40
  - State Machine: ~20
  - Integration Logic: ~10
- **Flip-Flops:** ~50
  - PWM Counter: 8
  - Interlock State: 3
  - FSM State: 3
  - Counters: 16
  - Output Registers: ~20
- **Block RAM:** 0
- **DSP Slices:** 0

**Total Resource Usage:** <1% of XC7K70T

## Safety Analysis

### Fault Detection Time

| Fault Type | Detection Latency | PWM Disable Latency |
|------------|-------------------|---------------------|
| Overcurrent | 1 clock cycle | <1 clock cycle |
| Overvoltage | 1 clock cycle | <1 clock cycle |
| Overtemperature | 1 clock cycle | <1 clock cycle |

### Failure Modes Considered

1. **Sensor Failure:** Hysteresis prevents false triggers
2. **Single Bit Error:** Multiple redundant checks
3. **Clock Glitch:** Synchronous design, registered outputs
4. **Power Glitch:** Reset clears all faults
5. **Software Bug:** Hardware interlocks independent of FSM

## Design Decisions

### Why 8-bit PWM Resolution?
- Sufficient for most power control applications (0.4% resolution)
- Fits in single FPGA register
- Fast update rate possible

### Why Hysteresis?
- Prevents oscillation near threshold
- Reduces fault chattering
- Improves system stability
- Common in industrial control systems

### Why State Machine?
- Enforces safe startup/shutdown sequences
- Prevents invalid operations
- Provides clear system status
- Matches industrial power supply control patterns

### Why Triple-Redundant Safety?
- Defense in depth
- Catches bugs in any single layer
- Meets high-reliability requirements
- Demonstrates safety-critical design thinking

## Testing Strategy

### Unit Tests
- Each module tested independently
- Corner cases verified
- Timing verified in simulation

### Integration Tests
- Complete system scenarios
- Fault injection testing
- State transition validation

### Stress Tests
- Rapid fault injection
- State machine edge cases
- Simultaneous faults
- Hysteresis boundary conditions

## Future Improvements

1. **Formal Verification:** Mathematically prove safety properties
2. **Redundant Sensors:** Compare multiple sensors for fault detection
3. **Watchdog Timer:** Detect FSM lockup
4. **CRC Checks:** Verify configuration data integrity
5. **BIST:** Built-in self-test on startup