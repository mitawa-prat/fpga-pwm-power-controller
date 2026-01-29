library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity pwm_controller is
    generic (
        PWM_WIDTH    : integer := 8;   -- PWM resolution
        SENSOR_WIDTH : integer := 12   -- ADC resolution
    );
    port (
        clk                : in  std_logic;
        reset              : in  std_logic;
        
        -- PWM control
        enable             : in  std_logic;
        duty_cycle         : in  std_logic_vector(PWM_WIDTH-1 downto 0);
        
        -- Sensor inputs
        current_value      : in  std_logic_vector(SENSOR_WIDTH-1 downto 0);
        voltage_value      : in  std_logic_vector(SENSOR_WIDTH-1 downto 0);
        temperature_value  : in  std_logic_vector(SENSOR_WIDTH-1 downto 0);
        
        -- Safety thresholds
        current_threshold  : in  std_logic_vector(SENSOR_WIDTH-1 downto 0);
        voltage_threshold  : in  std_logic_vector(SENSOR_WIDTH-1 downto 0);
        temp_threshold     : in  std_logic_vector(SENSOR_WIDTH-1 downto 0);
        hysteresis         : in  std_logic_vector(SENSOR_WIDTH-1 downto 0);
        
        -- Outputs
        pwm_out            : out std_logic;
        interlock_active   : out std_logic;
        fault_current      : out std_logic;
        fault_voltage      : out std_logic;
        fault_temperature  : out std_logic
    );
end entity pwm_controller;

architecture rtl of pwm_controller is
    -- Internal signals
    signal pwm_raw            : std_logic;  -- PWM before interlock
    signal interlock_active_i : std_logic;  -- Interlock status
    signal pwm_enable_safe    : std_logic;  -- Enable with safety check
    
begin
    -- Instantiate PWM generator
    pwm_gen: entity work.pwm_generator
        generic map (
            COUNTER_WIDTH => PWM_WIDTH
        )
        port map (
            clk        => clk,
            reset      => reset,
            enable     => pwm_enable_safe,  -- Use safe enable signal
            duty_cycle => duty_cycle,
            pwm_out    => pwm_raw
        );
    
    -- Instantiate interlock system
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
    
    -- Safety logic: PWM only enabled if no interlock AND user enables
    pwm_enable_safe <= enable and (not interlock_active_i);
    
    -- Final output with safety gate
    -- CRITICAL: This ensures PWM is ALWAYS disabled during fault
    pwm_out <= pwm_raw and (not interlock_active_i);
    
    -- Pass through interlock status
    interlock_active <= interlock_active_i;
    
end architecture rtl;