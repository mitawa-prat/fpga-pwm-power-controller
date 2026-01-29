library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity power_controller_fsm is
    port (
        clk              : in  std_logic;
        reset            : in  std_logic;
        
        -- Control inputs
        start_cmd        : in  std_logic;  -- User command to start
        stop_cmd         : in  std_logic;  -- User command to stop
        fault_ack        : in  std_logic;  -- Acknowledge fault to allow restart
        
        -- Status inputs
        interlock_active : in  std_logic;  -- From interlock system
        
        -- Outputs
        pwm_enable       : out std_logic;  -- Enable PWM generator
        state_idle       : out std_logic;  -- State indicators
        state_startup    : out std_logic;
        state_running    : out std_logic;
        state_fault      : out std_logic;
        state_shutdown   : out std_logic
    );
end entity power_controller_fsm;

architecture rtl of power_controller_fsm is
    -- State type definition
    type state_type is (IDLE, STARTUP, RUNNING, FAULT, SHUTDOWN);
    signal current_state : state_type;
    signal next_state    : state_type;
    
    -- Startup delay counter (simulates pre-charge time)
    signal startup_counter : unsigned(7 downto 0);
    constant STARTUP_DELAY : unsigned(7 downto 0) := to_unsigned(50, 8);  -- 50 clock cycles
    
    -- Shutdown delay counter
    signal shutdown_counter : unsigned(7 downto 0);
    constant SHUTDOWN_DELAY : unsigned(7 downto 0) := to_unsigned(30, 8);  -- 30 clock cycles
    
begin
    -- State register (sequential logic)
    process(clk, reset)
    begin
        if reset = '1' then
            current_state <= IDLE;
        elsif rising_edge(clk) then
            current_state <= next_state;
        end if;
    end process;
    
    -- Next state logic (combinational)
    process(current_state, start_cmd, stop_cmd, fault_ack, interlock_active, 
            startup_counter, shutdown_counter)
    begin
        -- Default: stay in current state
        next_state <= current_state;
        
        case current_state is
            when IDLE =>
                if start_cmd = '1' and interlock_active = '0' then
                    next_state <= STARTUP;
                end if;
            
            when STARTUP =>
                -- Check for faults during startup
                if interlock_active = '1' then
                    next_state <= FAULT;
                -- Wait for startup delay to complete
                elsif startup_counter >= STARTUP_DELAY then
                    next_state <= RUNNING;
                end if;
            
            when RUNNING =>
                -- Priority 1: Fault detection
                if interlock_active = '1' then
                    next_state <= FAULT;
                -- Priority 2: Stop command
                elsif stop_cmd = '1' then
                    next_state <= SHUTDOWN;
                end if;
            
            when FAULT =>
                -- Must acknowledge fault AND fault must be cleared to restart
                if fault_ack = '1' and interlock_active = '0' then
                    next_state <= IDLE;
                end if;
            
            when SHUTDOWN =>
                -- Wait for shutdown delay, then return to idle
                if shutdown_counter >= SHUTDOWN_DELAY then
                    next_state <= IDLE;
                end if;
        end case;
    end process;
    
    -- Output logic and counters (sequential)
    process(clk, reset)
    begin
        if reset = '1' then
            pwm_enable       <= '0';
            startup_counter  <= (others => '0');
            shutdown_counter <= (others => '0');
            
        elsif rising_edge(clk) then
            -- Default outputs
            pwm_enable <= '0';
            
            case current_state is
                when IDLE =>
                    startup_counter  <= (others => '0');
                    shutdown_counter <= (others => '0');
                
                when STARTUP =>
                    -- Increment startup counter
                    if startup_counter < STARTUP_DELAY then
                        startup_counter <= startup_counter + 1;
                    end if;
                    -- PWM disabled during startup
                    pwm_enable <= '0';
                
                when RUNNING =>
                    -- Enable PWM in running state
                    pwm_enable <= '1';
                    startup_counter  <= (others => '0');
                    shutdown_counter <= (others => '0');
                
                when FAULT =>
                    -- Immediately disable PWM
                    pwm_enable <= '0';
                    startup_counter  <= (others => '0');
                    shutdown_counter <= (others => '0');
                
                when SHUTDOWN =>
                    -- Increment shutdown counter
                    if shutdown_counter < SHUTDOWN_DELAY then
                        shutdown_counter <= shutdown_counter + 1;
                    end if;
                    -- PWM disabled during shutdown
                    pwm_enable <= '0';
            end case;
        end if;
    end process;
    
    -- State indicator outputs (for monitoring/debugging)
    state_idle     <= '1' when current_state = IDLE     else '0';
    state_startup  <= '1' when current_state = STARTUP  else '0';
    state_running  <= '1' when current_state = RUNNING  else '0';
    state_fault    <= '1' when current_state = FAULT    else '0';
    state_shutdown <= '1' when current_state = SHUTDOWN else '0';
    
end architecture rtl;