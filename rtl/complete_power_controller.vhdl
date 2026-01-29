library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity complete_power_controller is
    generic (
        PWM_WIDTH    : integer := 8;
        SENSOR_WIDTH : integer := 12
    );
    port (
        clk                : in  std_logic;
        reset              : in  std_logic;
        
        -- User commands
        start_cmd          : in  std_logic;
        stop_cmd           : in  std_logic;
        fault_ack          : in  std_logic;
        
        -- PWM configuration
        duty_cycle         : in  std_logic_vector(PWM_WIDTH-1 downto 0);
        
        -- Sensor inputs
        current_value      : in  std_logic_vector(SENSOR_WIDTH-1 downto 0);
        voltage_value      : in  std_logic_vector(SENSOR_WIDTH-1 downto 0);
        temperature_value  : in  std_logic_vector(SENSOR_WIDTH-1 downto 0);
        
        -- Safety configuration
        current_threshold  : in  std_logic_vector(SENSOR_WIDTH-1 downto 0);
        voltage_threshold  : in  std_logic_vector(SENSOR_WIDTH-1 downto 0);
        temp_threshold     : in  std_logic_vector(SENSOR_WIDTH-1 downto 0);
        hysteresis         : in  std_logic_vector(SENSOR_WIDTH-1 downto 0);
        
        -- Outputs
        pwm_out            : out std_logic;
        
        -- Status outputs
        state_idle         : out std_logic;
        state_startup      : out std_logic;
        state_running      : out std_logic;
        state_fault        : out std_logic;
        state_shutdown     : out std_logic;
        
        interlock_active   : out std_logic;
        fault_current      : out std_logic;
        fault_voltage      : out std_logic;
        fault_temperature  : out std_logic
    );
end entity complete_power_controller;

architecture rtl of complete_power_controller is
    -- Internal signals
    signal pwm_enable_fsm    : std_logic;  -- Enable from FSM
    signal pwm_enable_final  : std_logic;  -- Final enable (FSM AND not interlock)
    signal interlock_active_i : std_logic;
    signal pwm_raw           : std_logic;
    
begin
    -- Instantiate State Machine
    fsm: entity work.power_controller_fsm
        port map (
            clk              => clk,
            reset            => reset,
            start_cmd        => start_cmd,
            stop_cmd         => stop_cmd,
            fault_ack        => fault_ack,
            interlock_active => interlock_active_i,
            pwm_enable       => pwm_enable_fsm,
            state_idle       => state_idle,
            state_startup    => state_startup,
            state_running    => state_running,
            state_fault      => state_fault,
            state_shutdown   => state_shutdown
        );
    
    -- Instantiate Safety Interlock System
    interlock_sys: entity work.interlock
        generic map (
            SENSOR_WIDTH => SENSOR_WIDTH
        )
        port map (
            clk               => clk,
            reset             => reset,
            current_value     => current_value,
            voltage_value     => voltage_value,
            temperature_value => temperature_value,
            current_threshold => current_threshold,
            voltage_threshold => voltage_threshold,
            temp_threshold    => temp_threshold,
            hysteresis        => hysteresis,
            interlock_active  => interlock_active_i,
            fault_current     => fault_current,
            fault_voltage     => fault_voltage,
            fault_temperature => fault_temperature
        );
    
    -- Instantiate PWM Generator
    pwm_gen: entity work.pwm_generator
        generic map (
            COUNTER_WIDTH => PWM_WIDTH
        )
        port map (
            clk        => clk,
            reset      => reset,
            enable     => pwm_enable_final,
            duty_cycle => duty_cycle,
            pwm_out    => pwm_raw
        );
    
    -- Triple-redundant safety logic:
    -- 1. FSM must enable (state = RUNNING)
    -- 2. No interlock active
    -- 3. Final gate on output
    pwm_enable_final <= pwm_enable_fsm and (not interlock_active_i);
    pwm_out <= pwm_raw and (not interlock_active_i);
    
    -- Pass through interlock status
    interlock_active <= interlock_active_i;
    
end architecture rtl;