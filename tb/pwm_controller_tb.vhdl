library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity pwm_controller_tb is
end entity pwm_controller_tb;

architecture sim of pwm_controller_tb is
    constant CLK_PERIOD   : time := 10 ns;
    constant PWM_WIDTH    : integer := 8;
    constant SENSOR_WIDTH : integer := 12;
    
    signal clk                : std_logic := '0';
    signal reset              : std_logic := '0';
    signal enable             : std_logic := '0';
    signal duty_cycle         : std_logic_vector(PWM_WIDTH-1 downto 0);
    signal current_value      : std_logic_vector(SENSOR_WIDTH-1 downto 0);
    signal voltage_value      : std_logic_vector(SENSOR_WIDTH-1 downto 0);
    signal temperature_value  : std_logic_vector(SENSOR_WIDTH-1 downto 0);
    signal current_threshold  : std_logic_vector(SENSOR_WIDTH-1 downto 0);
    signal voltage_threshold  : std_logic_vector(SENSOR_WIDTH-1 downto 0);
    signal temp_threshold     : std_logic_vector(SENSOR_WIDTH-1 downto 0);
    signal hysteresis         : std_logic_vector(SENSOR_WIDTH-1 downto 0);
    signal pwm_out            : std_logic;
    signal interlock_active   : std_logic;
    signal fault_current      : std_logic;
    signal fault_voltage      : std_logic;
    signal fault_temperature  : std_logic;
    
    signal sim_done : boolean := false;
    
begin
    -- Instantiate complete PWM controller
    uut: entity work.pwm_controller
        generic map (
            PWM_WIDTH    => PWM_WIDTH,
            SENSOR_WIDTH => SENSOR_WIDTH
        )
        port map (
            clk               => clk,
            reset             => reset,
            enable            => enable,
            duty_cycle        => duty_cycle,
            current_value     => current_value,
            voltage_value     => voltage_value,
            temperature_value => temperature_value,
            current_threshold => current_threshold,
            voltage_threshold => voltage_threshold,
            temp_threshold    => temp_threshold,
            hysteresis        => hysteresis,
            pwm_out           => pwm_out,
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
        enable <= '0';
        duty_cycle        <= std_logic_vector(to_unsigned(128, PWM_WIDTH)); -- 50% duty
        current_value     <= std_logic_vector(to_unsigned(2000, SENSOR_WIDTH));
        voltage_value     <= std_logic_vector(to_unsigned(2500, SENSOR_WIDTH));
        temperature_value <= std_logic_vector(to_unsigned(2000, SENSOR_WIDTH));
        
        -- Set safety thresholds
        current_threshold <= std_logic_vector(to_unsigned(3000, SENSOR_WIDTH));
        voltage_threshold <= std_logic_vector(to_unsigned(3500, SENSOR_WIDTH));
        temp_threshold    <= std_logic_vector(to_unsigned(2800, SENSOR_WIDTH));
        hysteresis        <= std_logic_vector(to_unsigned(200, SENSOR_WIDTH));
        
        wait for 50 ns;
        reset <= '0';
        wait for 50 ns;
        
        -- Test 1: Normal PWM operation (no faults)
        report "Test 1: Normal PWM operation";
        enable <= '1';
        wait for 3000 ns;  -- Let PWM run for multiple cycles
        
        -- Test 2: Overcurrent fault while PWM is running
        report "Test 2: Overcurrent fault - PWM should stop immediately";
        current_value <= std_logic_vector(to_unsigned(3200, SENSOR_WIDTH));
        wait for 2000 ns;  -- PWM should be disabled
        
        -- Test 3: Clear the fault
        report "Test 3: Clear fault - PWM should resume";
        current_value <= std_logic_vector(to_unsigned(2700, SENSOR_WIDTH));
        wait for 2000 ns;  -- PWM should resume
        
        -- Test 4: Change duty cycle during operation
        report "Test 4: Change duty cycle to 25%";
        duty_cycle <= std_logic_vector(to_unsigned(64, PWM_WIDTH)); -- 25%
        wait for 2000 ns;
        
        -- Test 5: Overvoltage fault
        report "Test 5: Overvoltage fault";
        voltage_value <= std_logic_vector(to_unsigned(3700, SENSOR_WIDTH));
        wait for 1500 ns;
        
        -- Test 6: Multiple simultaneous faults
        report "Test 6: Multiple simultaneous faults";
        current_value     <= std_logic_vector(to_unsigned(3300, SENSOR_WIDTH));
        temperature_value <= std_logic_vector(to_unsigned(2900, SENSOR_WIDTH));
        wait for 1500 ns;
        
        -- Test 7: Clear all faults
        report "Test 7: Clear all faults - resume operation";
        current_value     <= std_logic_vector(to_unsigned(2000, SENSOR_WIDTH));
        voltage_value     <= std_logic_vector(to_unsigned(2500, SENSOR_WIDTH));
        temperature_value <= std_logic_vector(to_unsigned(2000, SENSOR_WIDTH));
        wait for 2000 ns;
        
        -- Test 8: Change to 75% duty cycle
        report "Test 8: Change to 75% duty cycle";
        duty_cycle <= std_logic_vector(to_unsigned(192, PWM_WIDTH)); -- 75%
        wait for 2000 ns;
        
        -- Test 9: Disable PWM manually
        report "Test 9: Disable PWM manually";
        enable <= '0';
        wait for 1000 ns;
        
        -- Test 10: Re-enable
        report "Test 10: Re-enable PWM";
        enable <= '1';
        wait for 2000 ns;
        
        -- End simulation
        report "Simulation complete";
        sim_done <= true;
        wait;
    end process;
    
end architecture sim;