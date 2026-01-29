library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity interlock is
    generic (
        SENSOR_WIDTH : integer := 12  -- 12-bit ADC values (0-4095)
    );
    port (
        clk                : in  std_logic;
        reset              : in  std_logic;
        
        -- Sensor inputs (from ADCs measuring current, voltage, temp)
        current_value      : in  std_logic_vector(SENSOR_WIDTH-1 downto 0);
        voltage_value      : in  std_logic_vector(SENSOR_WIDTH-1 downto 0);
        temperature_value  : in  std_logic_vector(SENSOR_WIDTH-1 downto 0);
        
        -- Threshold settings
        current_threshold  : in  std_logic_vector(SENSOR_WIDTH-1 downto 0);
        voltage_threshold  : in  std_logic_vector(SENSOR_WIDTH-1 downto 0);
        temp_threshold     : in  std_logic_vector(SENSOR_WIDTH-1 downto 0);
        
        -- Hysteresis (threshold - hysteresis = clear level)
        hysteresis         : in  std_logic_vector(SENSOR_WIDTH-1 downto 0);
        
        -- Outputs
        interlock_active   : out std_logic;  -- '1' = fault detected, disable PWM
        fault_current      : out std_logic;  -- Which fault occurred
        fault_voltage      : out std_logic;
        fault_temperature  : out std_logic
    );
end entity interlock;

architecture rtl of interlock is
    -- Convert to unsigned for comparison
    signal current_u      : unsigned(SENSOR_WIDTH-1 downto 0);
    signal voltage_u      : unsigned(SENSOR_WIDTH-1 downto 0);
    signal temperature_u  : unsigned(SENSOR_WIDTH-1 downto 0);
    
    signal current_thresh_u  : unsigned(SENSOR_WIDTH-1 downto 0);
    signal voltage_thresh_u  : unsigned(SENSOR_WIDTH-1 downto 0);
    signal temp_thresh_u     : unsigned(SENSOR_WIDTH-1 downto 0);
    signal hysteresis_u      : unsigned(SENSOR_WIDTH-1 downto 0);
    
    -- Fault flags (internal)
    signal fault_current_int      : std_logic;
    signal fault_voltage_int      : std_logic;
    signal fault_temperature_int  : std_logic;
    
begin
    -- Type conversions
    current_u       <= unsigned(current_value);
    voltage_u       <= unsigned(voltage_value);
    temperature_u   <= unsigned(temperature_value);
    
    current_thresh_u  <= unsigned(current_threshold);
    voltage_thresh_u  <= unsigned(voltage_threshold);
    temp_thresh_u     <= unsigned(temp_threshold);
    hysteresis_u      <= unsigned(hysteresis);
    
    -- Main interlock logic with hysteresis
    process(clk, reset)
        variable clear_current_thresh  : unsigned(SENSOR_WIDTH-1 downto 0);
        variable clear_voltage_thresh  : unsigned(SENSOR_WIDTH-1 downto 0);
        variable clear_temp_thresh     : unsigned(SENSOR_WIDTH-1 downto 0);
    begin
        if reset = '1' then
            fault_current_int     <= '0';
            fault_voltage_int     <= '0';
            fault_temperature_int <= '0';
            
        elsif rising_edge(clk) then
            -- Calculate clear thresholds (trip - hysteresis)
            clear_current_thresh := current_thresh_u - hysteresis_u;
            clear_voltage_thresh := voltage_thresh_u - hysteresis_u;
            clear_temp_thresh    := temp_thresh_u - hysteresis_u;
            
            -- Current interlock with hysteresis
            if current_u >= current_thresh_u then
                fault_current_int <= '1';  -- Trip
            elsif current_u < clear_current_thresh then
                fault_current_int <= '0';  -- Clear
            end if;
            -- Otherwise maintain current state (hysteresis region)
            
            -- Voltage interlock with hysteresis
            if voltage_u >= voltage_thresh_u then
                fault_voltage_int <= '1';
            elsif voltage_u < clear_voltage_thresh then
                fault_voltage_int <= '0';
            end if;
            
            -- Temperature interlock with hysteresis
            if temperature_u >= temp_thresh_u then
                fault_temperature_int <= '1';
            elsif temperature_u < clear_temp_thresh then
                fault_temperature_int <= '0';
            end if;
        end if;
    end process;
    
    -- Output assignment (combinational for fastest response)
    interlock_active  <= fault_current_int or fault_voltage_int or fault_temperature_int;
    fault_current     <= fault_current_int;
    fault_voltage     <= fault_voltage_int;
    fault_temperature <= fault_temperature_int;
    
end architecture rtl;