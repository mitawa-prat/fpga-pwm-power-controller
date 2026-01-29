library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity interlock_tb is
end entity interlock_tb;

architecture sim of interlock_tb is
    constant CLK_PERIOD : time := 10 ns;
    constant SENSOR_WIDTH : integer := 12;
    
    signal clk               : std_logic := '0';
    signal reset             : std_logic := '0';
    signal current_value     : std_logic_vector(SENSOR_WIDTH-1 downto 0);
    signal voltage_value     : std_logic_vector(SENSOR_WIDTH-1 downto 0);
    signal temperature_value : std_logic_vector(SENSOR_WIDTH-1 downto 0);
    signal current_threshold : std_logic_vector(SENSOR_WIDTH-1 downto 0);
    signal voltage_threshold : std_logic_vector(SENSOR_WIDTH-1 downto 0);
    signal temp_threshold    : std_logic_vector(SENSOR_WIDTH-1 downto 0);
    signal hysteresis        : std_logic_vector(SENSOR_WIDTH-1 downto 0);
    signal interlock_active  : std_logic;
    signal fault_current     : std_logic;
    signal fault_voltage     : std_logic;
    signal fault_temperature : std_logic;
    
    signal sim_done : boolean := false;
    
begin
    -- Instantiate interlock
    uut: entity work.interlock
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
            interlock_active  => interlock_active,
            fault_current     => fault_current,
            fault_voltage     => fault_voltage,
            fault_temperature => fault_temperature
        );
    
    -- Clock generation
    clk_gen: process
    begin
        while not sim_done loop
            clk <= '0';
            wait for CLK_PERIOD/2;
            clk <= '1';
            wait for CLK_PERIOD/2;
        end loop;
        wait;
    end process;
    
    -- Stimulus
    stim: process
    begin
        -- Initialize
        reset <= '1';
        current_value     <= (others => '0');
        voltage_value     <= (others => '0');
        temperature_value <= (others => '0');
        
        -- Set thresholds
        current_threshold <= std_logic_vector(to_unsigned(3000, SENSOR_WIDTH)); -- Trip at 3000
        voltage_threshold <= std_logic_vector(to_unsigned(3500, SENSOR_WIDTH)); -- Trip at 3500
        temp_threshold    <= std_logic_vector(to_unsigned(2800, SENSOR_WIDTH)); -- Trip at 2800
        hysteresis        <= std_logic_vector(to_unsigned(200, SENSOR_WIDTH));  -- Clear 200 below trip
        
        wait for 50 ns;
        reset <= '0';
        wait for 50 ns;
        
        -- Test 1: Normal operation (all values below threshold)
        current_value     <= std_logic_vector(to_unsigned(2000, SENSOR_WIDTH));
        voltage_value     <= std_logic_vector(to_unsigned(2500, SENSOR_WIDTH));
        temperature_value <= std_logic_vector(to_unsigned(2000, SENSOR_WIDTH));
        wait for 100 ns;
        
        -- Test 2: Overcurrent trip
        current_value <= std_logic_vector(to_unsigned(3100, SENSOR_WIDTH)); -- Above 3000
        wait for 50 ns;
        
        -- Test 3: Reduce current but stay in hysteresis region
        current_value <= std_logic_vector(to_unsigned(2900, SENSOR_WIDTH)); -- Between 2800-3000
        wait for 50 ns;  -- Should still be in fault
        
        -- Test 4: Clear the fault (below clear threshold)
        current_value <= std_logic_vector(to_unsigned(2700, SENSOR_WIDTH)); -- Below 2800
        wait for 50 ns;
        
        -- Test 5: Overvoltage trip
        voltage_value <= std_logic_vector(to_unsigned(3600, SENSOR_WIDTH)); -- Above 3500
        wait for 50 ns;
        
        -- Test 6: Clear voltage
        voltage_value <= std_logic_vector(to_unsigned(3200, SENSOR_WIDTH)); -- Below 3300
        wait for 50 ns;
        
        -- Test 7: Overtemperature trip
        temperature_value <= std_logic_vector(to_unsigned(2900, SENSOR_WIDTH)); -- Above 2800
        wait for 50 ns;
        
        -- Test 8: Multiple faults simultaneously
        current_value     <= std_logic_vector(to_unsigned(3200, SENSOR_WIDTH));
        voltage_value     <= std_logic_vector(to_unsigned(3700, SENSOR_WIDTH));
        temperature_value <= std_logic_vector(to_unsigned(3000, SENSOR_WIDTH));
        wait for 100 ns;
        
        -- Test 9: Clear all faults
        current_value     <= std_logic_vector(to_unsigned(2000, SENSOR_WIDTH));
        voltage_value     <= std_logic_vector(to_unsigned(2500, SENSOR_WIDTH));
        temperature_value <= std_logic_vector(to_unsigned(2000, SENSOR_WIDTH));
        wait for 100 ns;
        
        -- End simulation
        sim_done <= true;
        wait;
    end process;
    
end architecture sim;