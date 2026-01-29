library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity complete_power_controller_tb is
end entity complete_power_controller_tb;

architecture sim of complete_power_controller_tb is
    constant CLK_PERIOD   : time := 10 ns;
    constant PWM_WIDTH    : integer := 8;
    constant SENSOR_WIDTH : integer := 12;
    
    signal clk                : std_logic := '0';
    signal reset              : std_logic := '0';
    signal start_cmd          : std_logic := '0';
    signal stop_cmd           : std_logic := '0';
    signal fault_ack          : std_logic := '0';
    signal duty_cycle         : std_logic_vector(PWM_WIDTH-1 downto 0);
    signal current_value      : std_logic_vector(SENSOR_WIDTH-1 downto 0);
    signal voltage_value      : std_logic_vector(SENSOR_WIDTH-1 downto 0);
    signal temperature_value  : std_logic_vector(SENSOR_WIDTH-1 downto 0);
    signal current_threshold  : std_logic_vector(SENSOR_WIDTH-1 downto 0);
    signal voltage_threshold  : std_logic_vector(SENSOR_WIDTH-1 downto 0);
    signal temp_threshold     : std_logic_vector(SENSOR_WIDTH-1 downto 0);
    signal hysteresis         : std_logic_vector(SENSOR_WIDTH-1 downto 0);
    signal pwm_out            : std_logic;
    signal state_idle         : std_logic;
    signal state_startup      : std_logic;
    signal state_running      : std_logic;
    signal state_fault        : std_logic;
    signal state_shutdown     : std_logic;
    signal interlock_active   : std_logic;
    signal fault_current      : std_logic;
    signal fault_voltage      : std_logic;
    signal fault_temperature  : std_logic;
    
    signal sim_done : boolean := false;
    
begin
    -- Instantiate complete system
    uut: entity work.complete_power_controller
        generic map (
            PWM_WIDTH    => PWM_WIDTH,
            SENSOR_WIDTH => SENSOR_WIDTH
        )
        port map (
            clk               => clk,
            reset             => reset,
            start_cmd         => start_cmd,
            stop_cmd          => stop_cmd,
            fault_ack         => fault_ack,
            duty_cycle        => duty_cycle,
            current_value     => current_value,
            voltage_value     => voltage_value,
            temperature_value => temperature_value,
            current_threshold => current_threshold,
            voltage_threshold => voltage_threshold,
            temp_threshold    => temp_threshold,
            hysteresis        => hysteresis,
            pwm_out           => pwm_out,
            state_idle        => state_idle,
            state_startup     => state_startup,
            state_running     => state_running,
            state_fault       => state_fault,
            state_shutdown    => state_shutdown,
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
        duty_cycle        <= std_logic_vector(to_unsigned(128, PWM_WIDTH));
        current_value     <= std_logic_vector(to_unsigned(2000, SENSOR_WIDTH));
        voltage_value     <= std_logic_vector(to_unsigned(2500, SENSOR_WIDTH));
        temperature_value <= std_logic_vector(to_unsigned(2000, SENSOR_WIDTH));
        
        -- Configure thresholds
        current_threshold <= std_logic_vector(to_unsigned(3000, SENSOR_WIDTH));
        voltage_threshold <= std_logic_vector(to_unsigned(3500, SENSOR_WIDTH));
        temp_threshold    <= std_logic_vector(to_unsigned(2800, SENSOR_WIDTH));
        hysteresis        <= std_logic_vector(to_unsigned(200, SENSOR_WIDTH));
        
        wait for 50 ns;
        reset <= '0';
        wait for 50 ns;
        
        -- Test 1: Normal startup
        report "Test 1: Normal startup";
        start_cmd <= '1';
        wait for 20 ns;
        start_cmd <= '0';
        wait for 800 ns;
        
        -- Test 2: Adjust duty cycle
        report "Test 2: Change duty cycle to 25%";
        duty_cycle <= std_logic_vector(to_unsigned(64, PWM_WIDTH));
        wait for 1000 ns;
        
        -- Test 3: Emergency fault
        report "Test 3: Overcurrent fault";
        current_value <= std_logic_vector(to_unsigned(3300, SENSOR_WIDTH));
        wait for 500 ns;
        
        -- Test 4: Clear and acknowledge fault
        report "Test 4: Clear fault";
        current_value <= std_logic_vector(to_unsigned(2000, SENSOR_WIDTH));
        wait for 100 ns;
        fault_ack <= '1';
        wait for 20 ns;
        fault_ack <= '0';
        wait for 100 ns;
        
        -- Test 5: Restart
        report "Test 5: Restart after fault";
        start_cmd <= '1';
        wait for 20 ns;
        start_cmd <= '0';
        wait for 800 ns;
        
        -- Test 6: Normal shutdown
        report "Test 6: Normal shutdown";
        stop_cmd <= '1';
        wait for 20 ns;
        stop_cmd <= '0';
        wait for 500 ns;
        
        -- End
        report "Simulation complete";
        sim_done <= true;
        wait;
    end process;
    
end architecture sim;