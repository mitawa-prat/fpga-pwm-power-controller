library ieee;
use ieee.std_logic_1164.all;

entity power_controller_fsm_tb is
end entity power_controller_fsm_tb;

architecture sim of power_controller_fsm_tb is
    constant CLK_PERIOD : time := 10 ns;
    
    signal clk              : std_logic := '0';
    signal reset            : std_logic := '0';
    signal start_cmd        : std_logic := '0';
    signal stop_cmd         : std_logic := '0';
    signal fault_ack        : std_logic := '0';
    signal interlock_active : std_logic := '0';
    signal pwm_enable       : std_logic;
    signal state_idle       : std_logic;
    signal state_startup    : std_logic;
    signal state_running    : std_logic;
    signal state_fault      : std_logic;
    signal state_shutdown   : std_logic;
    
    signal sim_done : boolean := false;
    
begin
    -- Instantiate FSM
    uut: entity work.power_controller_fsm
        port map (
            clk              => clk,
            reset            => reset,
            start_cmd        => start_cmd,
            stop_cmd         => stop_cmd,
            fault_ack        => fault_ack,
            interlock_active => interlock_active,
            pwm_enable       => pwm_enable,
            state_idle       => state_idle,
            state_startup    => state_startup,
            state_running    => state_running,
            state_fault      => state_fault,
            state_shutdown   => state_shutdown
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
        wait for 50 ns;
        reset <= '0';
        wait for 50 ns;
        
        -- Test 1: Normal startup sequence
        report "Test 1: Normal startup sequence";
        start_cmd <= '1';
        wait for 20 ns;
        start_cmd <= '0';
        wait for 600 ns;  -- Wait through startup delay
        
        -- Test 2: Normal operation
        report "Test 2: Running normally";
        wait for 500 ns;
        
        -- Test 3: Normal shutdown
        report "Test 3: Normal shutdown";
        stop_cmd <= '1';
        wait for 20 ns;
        stop_cmd <= '0';
        wait for 400 ns;  -- Wait through shutdown delay
        
        -- Test 4: Start again
        report "Test 4: Restart after shutdown";
        start_cmd <= '1';
        wait for 20 ns;
        start_cmd <= '0';
        wait for 600 ns;
        
        -- Test 5: Fault during operation
        report "Test 5: Fault occurs during running";
        interlock_active <= '1';
        wait for 300 ns;
        
        -- Test 6: Try to restart without acknowledging (should stay in fault)
        report "Test 6: Try restart without ack (should fail)";
        start_cmd <= '1';
        wait for 20 ns;
        start_cmd <= '0';
        wait for 200 ns;
        
        -- Test 7: Clear fault but don't acknowledge
        report "Test 7: Clear fault, still need ack";
        interlock_active <= '0';
        wait for 200 ns;
        
        -- Test 8: Acknowledge fault (should return to idle)
        report "Test 8: Acknowledge fault";
        fault_ack <= '1';
        wait for 20 ns;
        fault_ack <= '0';
        wait for 100 ns;
        
        -- Test 9: Restart after fault cleared
        report "Test 9: Restart after fault cleared";
        start_cmd <= '1';
        wait for 20 ns;
        start_cmd <= '0';
        wait for 600 ns;
        
        -- Test 10: Fault during startup
        report "Test 10: Fault during startup";
        stop_cmd <= '1';
        wait for 20 ns;
        stop_cmd <= '0';
        wait for 400 ns;
        
        start_cmd <= '1';
        wait for 20 ns;
        start_cmd <= '0';
        wait for 200 ns;  -- Partway through startup
        
        interlock_active <= '1';  -- Fault!
        wait for 300 ns;
        
        -- Clear and acknowledge
        interlock_active <= '0';
        wait for 50 ns;
        fault_ack <= '1';
        wait for 20 ns;
        fault_ack <= '0';
        wait for 100 ns;
        
        -- End simulation
        report "Simulation complete";
        sim_done <= true;
        wait;
    end process;
    
end architecture sim;