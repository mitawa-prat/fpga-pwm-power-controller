# PWM Power Controller with Safety Interlocks

[![Build Status](https://img.shields.io/badge/build-passing-brightgreen.svg)]()
[![VHDL](https://img.shields.io/badge/VHDL-IEEE%201993-blue.svg)]()
[![License](https://img.shields.io/badge/license-Educational-orange.svg)]()

A production-grade FPGA-based PWM controller designed for high-reliability power converter applications, featuring comprehensive safety interlocks and state machine control.

## 🎯 Project Overview

This project implements a complete digital control system for power converters, specifically designed for applications requiring:
- **Precise PWM generation** for power control
- **Fast fault detection** and response (<100ns)
- **Multi-sensor safety monitoring**
- **Controlled startup/shutdown sequences**
- **Industrial-grade reliability**

**Target Application:** Magnet power supply control for particle accelerators (inspired by CERN's converter control requirements)

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

---

## ✨ Key Features

### Core Functionality
- ✅ **8-bit PWM Generator** - Configurable duty cycle (0-100%) with 256-step resolution
- ✅ **Triple Safety Interlocks** - Current, voltage, and temperature monitoring
- ✅ **Hysteresis-based Fault Detection** - Prevents oscillation in fault conditions
- ✅ **State Machine Control** - IDLE → STARTUP → RUNNING → FAULT/SHUTDOWN states
- ✅ **Fast Response Time** - Fault detection and PWM disable within 1 clock cycle (10ns @ 100MHz)

### Safety Features
- 🛡️ **Hardware Interlocks** - Three independent sensor monitoring channels
- 🛡️ **Fail-Safe Design** - PWM cannot be active during fault conditions
- 🛡️ **Fault Acknowledgment** - Requires operator intervention to clear fault states
- 🛡️ **Triple-Redundant Safety Logic** - Multiple layers ensure PWM is disabled during faults

---

## 📁 Project Structure
```
X:\FPGA_PROJ\
├── rtl/                          # VHDL design files
│   ├── pwm_generator.vhdl        # PWM generation core
│   ├── interlock.vhdl            # Safety interlock system
│   ├── power_controller_fsm.vhdl # State machine controller
│   ├── pwm_controller.vhdl       # PWM + interlock integration
│   └── complete_power_controller.vhdl  # Top-level system
├── tb/                           # Testbenches
│   ├── pwm_generator_tb.vhdl
│   ├── interlock_tb.vhdl
│   ├── power_controller_fsm_tb.vhdl
│   ├── pwm_controller_tb.vhdl
│   └── complete_power_controller_tb.vhdl
├── sim/                          # Simulation outputs (.vcd files)
├── docs/                         # Documentation
│   ├── ARCHITECTURE.md           # Detailed design documentation
│   └── TEST_RESULTS.md           # Test results and verification
├── scripts/                      # Build automation
│   ├── build_all.bat             # Build and test everything
│   ├── run_single_test.bat       # Run individual tests
│   ├── generate_report.bat       # Generate test reports
│   └── clean.bat                 # Clean build artifacts
└── README.md                     # This file
```

---

## 🚀 Getting Started

### Prerequisites

- **GHDL** - VHDL simulator ([Download](https://github.com/ghdl/ghdl/releases))
- **GTKWave** - Waveform viewer ([Download](https://sourceforge.net/projects/gtkwave/))
- **Xilinx Vivado** (optional) - For synthesis and FPGA implementation

### Quick Start

#### 1. Clone/Download the Project
```bash
git clone <[repo-url](https://github.com/mitawa-prat/fpga-pwm-power-controller.git)>
cd FPGA_PROJ
```

#### 2. Build and Test Everything
```bash
scripts\build_all.bat
```

This will:
- Compile all VHDL files
- Run all testbenches
- Generate waveforms in `sim/`
- Create test report in `docs/TEST_RESULTS.md`

#### 3. View Waveforms
```bash
gtkwave sim\complete_system.vcd
```

---

## 🧪 Running Individual Tests

### Complete System Test
```bash
scripts\run_single_test.bat complete_power_controller
```

### PWM Generator Test
```bash
scripts\run_single_test.bat pwm_generator
```

### Safety Interlock Test
```bash
scripts\run_single_test.bat interlock
```

### State Machine Test
```bash
scripts\run_single_test.bat power_controller_fsm
```

---

## 📊 Design Specifications

### PWM Generator
| Parameter | Value |
|-----------|-------|
| Resolution | 8-bit (256 steps) |
| Duty Cycle Range | 0-100% |
| Update Rate | Every PWM period |
| Control | Synchronous enable/disable |

### Safety Interlock System
| Parameter | Value |
|-----------|-------|
| Sensor Inputs | 12-bit ADC (0-4095) |
| Monitored Parameters | Current, Voltage, Temperature |
| Response Time | 1 clock cycle |
| Hysteresis | Configurable (prevents chattering) |
| Fault Flags | Individual per sensor |

### State Machine
| State | Description | PWM Status |
|-------|-------------|------------|
| IDLE | System off, awaiting start | Disabled |
| STARTUP | Initialization (50 cycles) | Disabled |
| RUNNING | Normal operation | Enabled |
| FAULT | Safety interlock triggered | Disabled |
| SHUTDOWN | Controlled power-down (30 cycles) | Disabled |

### Timing (@ 100MHz Clock)
| Parameter | Value |
|-----------|-------|
| Clock Period | 10ns |
| Fault Detection Latency | <10ns (1 cycle) |
| PWM Disable Latency | <10ns (combinational) |
| State Transition Time | 10ns (1 cycle) |

---

## ✅ Verification & Testing

### Test Coverage
- ✅ Normal startup and operation
- ✅ Duty cycle adjustment during operation
- ✅ Emergency fault response
- ✅ Multiple simultaneous faults
- ✅ Fault recovery and restart
- ✅ Controlled shutdown
- ✅ Hysteresis behavior
- ✅ State machine edge cases

### Safety Properties Verified
1. **Fast Response** - Faults detected within 1 clock cycle
2. **Fail-Safe** - PWM never active during fault
3. **No Glitches** - Hysteresis prevents oscillation
4. **Valid States** - Only legal state transitions occur
5. **Reset Behavior** - All faults clear on reset

See [TEST_RESULTS.md](docs/TEST_RESULTS.md) for detailed test results.

---

## 🎯 Target Hardware

**Primary Target:** Xilinx Kintex-7 FPGA
- Part: XC7K70T (or similar)
- Resources: ~100 LUTs, ~50 FFs
- Block RAM: None required
- DSP Slices: None required

**Estimated Resource Usage:** <1% of XC7K70T

**Portability:** Design uses standard VHDL and can be ported to other FPGA families with minimal changes.

---

## 📚 Documentation

- **[ARCHITECTURE.md](docs/ARCHITECTURE.md)** - Detailed system architecture and design decisions
- **[TEST_RESULTS.md](docs/TEST_RESULTS.md)** - Comprehensive test results and verification
- **Inline Comments** - All VHDL files are well-commented

---

## 🛠️ Future Enhancements

Potential improvements and extensions:

- [ ] **Formal Verification** - PSL/SVA assertions to mathematically prove safety properties
- [ ] **Digital PI Controller** - Closed-loop current regulation
- [ ] **Communication Interface** - SPI/I2C for external configuration
- [ ] **Watchdog Timer** - Detect and recover from FSM lockup
- [ ] **Telemetry** - Status and fault logging
- [ ] **Multi-Channel** - Support multiple independent PWM channels
- [ ] **BIST** - Built-in self-test on startup

---

## 🎓 Learning Outcomes

This project demonstrates:

✅ **Safety-Critical Design** - Multiple layers of protection for high-reliability systems  
✅ **Real-Time Response** - Sub-100ns fault detection and response  
✅ **Modular Architecture** - Reusable, well-structured components  
✅ **Synchronous Design** - Proper clocked processes and timing  
✅ **State Machine Design** - FSM for system control  
✅ **Hardware Interlocks** - Fast protection circuits  
✅ **Professional Documentation** - Industry-standard documentation practices  
✅ **Test-Driven Development** - Comprehensive testbench suite  

---

## 🏢 Real-World Application

This design is directly applicable to:
- **Particle Accelerator Magnet Power Supplies** (CERN, Fermilab, etc.)
- **Industrial Motor Drives**
- **Solar/Battery Inverters**
- **DC-DC Power Converters**
- **LED Lighting Controllers**
- **Any safety-critical power electronics application**

---

## 📖 Design Rationale

The design philosophy prioritizes **correctness and safety over performance**, making it suitable for applications where failures could result in:
- Equipment damage (expensive magnets, power supplies)
- Safety hazards (electrical fires, component explosions)
- Experimental data loss (accelerator downtime)

### Key Design Decisions

**Why 8-bit PWM?**
- Sufficient resolution for most applications (0.4% step size)
- Simple, fast implementation
- Low resource usage

**Why Hysteresis?**
- Prevents fault chattering near thresholds
- Improves system stability
- Standard practice in industrial control

**Why State Machine?**
- Enforces safe startup/shutdown sequences
- Prevents invalid operations
- Clear system status indication

**Why Triple-Redundant Safety?**
- Defense in depth
- Catches bugs in any single layer
- Demonstrates safety-critical design thinking

---

## 👤 Author

**Saini**

- 🎓 Created as a demonstration of FPGA design and safety-critical systems
- 💼 Portfolio project for accelerator electronics/power converter control positions
- 🔗 LinkedIn: [saini](https://www.linkedin.com/in/sainiprateek/)
- 📧 Email: [mitawa](prateek7up@gmail.com)

---

## 📄 License

This project is available for educational and portfolio purposes.

**Note:** This is a demonstration project. For production use in safety-critical applications, additional verification, validation, and certification would be required according to relevant safety standards (IEC 61508, ISO 26262, etc.).

---

## 🙏 Acknowledgments

- Design inspired by CERN's accelerator power converter requirements
- Safety interlock patterns based on industrial power electronics best practices
- State machine design follows IEC 61508 functional safety guidelines

---

## 📞 Contact & Feedback

Questions, suggestions, or found a bug? Feel free to:
- Open an issue on GitHub
- Contact me via [email](prateek7up@gmail.com) / [linkedin](https://www.linkedin.com/in/sainiprateek/)
- Submit a pull request

---


**⭐ If you find this project useful, please consider starring the repository!**

