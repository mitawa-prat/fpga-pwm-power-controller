library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity pwm_generator_tb is
end entity pwm_generator_tb;

architecture sim of pwm_generator_tb is
    constant CLK_PERIOD : time := 10 ns;
    constant COUNTER_WIDTH : integer := 8;
    
    signal clk        : std_logic := '0';
    signal reset      : std_logic := '0';
    signal enable     : std_logic := '0';
    signal duty_cycle : std_logic_vector(COUNTER_WIDTH-1 downto 0);
    signal pwm_out    : std_logic;
    
    signal sim_done : boolean := false;
    
begin
    -- Instantiate PWM generator
    uut: entity work.pwm_generator
        generic map (
            COUNTER_WIDTH => COUNTER_WIDTH
        )
        port map (
            clk        => clk,
            reset      => reset,
            enable     => enable,
            duty_cycle => duty_cycle,
            pwm_out    => pwm_out
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
        -- Reset
        reset <= '1';
        enable <= '0';
        duty_cycle <= (others => '0');
        wait for 50 ns;
        
        reset <= '0';
        wait for 20 ns;
        
        -- Test 1: 25% duty cycle
        duty_cycle <= std_logic_vector(to_unsigned(64, COUNTER_WIDTH)); -- 64/256 = 25%
        enable <= '1';
        wait for 3000 ns;  -- Wait for multiple PWM periods
        
        -- Test 2: 50% duty cycle
        duty_cycle <= std_logic_vector(to_unsigned(128, COUNTER_WIDTH)); -- 128/256 = 50%
        wait for 3000 ns;
        
        -- Test 3: 75% duty cycle
        duty_cycle <= std_logic_vector(to_unsigned(192, COUNTER_WIDTH)); -- 192/256 = 75%
        wait for 3000 ns;
        
        -- Test 4: 10% duty cycle
        duty_cycle <= std_logic_vector(to_unsigned(26, COUNTER_WIDTH)); -- 26/256 ≈ 10%
        wait for 3000 ns;
        
        -- Test 5: Disable PWM
        enable <= '0';
        wait for 500 ns;
        
        -- Test 6: Re-enable
        enable <= '1';
        wait for 2000 ns;
        
        -- End simulation
        sim_done <= true;
        wait;
    end process;
    
end architecture sim;