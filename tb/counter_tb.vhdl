library ieee;
use ieee.std_logic_1164.all;

entity counter_tb is
end entity counter_tb;

architecture sim of counter_tb is
    -- Clock period
    constant CLK_PERIOD : time := 10 ns;
    
    -- Signals to connect to counter
    signal clk    : std_logic := '0';
    signal reset  : std_logic := '0';
    signal enable : std_logic := '0';
    signal count  : std_logic_vector(7 downto 0);
    
    -- Control simulation
    signal sim_done : boolean := false;
    
begin
    -- Instantiate the counter
    uut: entity work.counter
        port map (
            clk    => clk,
            reset  => reset,
            enable => enable,
            count  => count
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
    
    -- Stimulus process
    stim: process
    begin
        -- Start with reset
        reset <= '1';
        enable <= '0';
        wait for 20 ns;
        
        -- Release reset
        reset <= '0';
        wait for 20 ns;
        
        -- Enable counting
        enable <= '1';
        wait for 200 ns;
        
        -- Disable counting
        enable <= '0';
        wait for 50 ns;
        
        -- Enable again
        enable <= '1';
        wait for 100 ns;
        
        -- Reset while counting
        reset <= '1';
        wait for 20 ns;
        reset <= '0';
        
        -- Count a bit more
        wait for 100 ns;
        
        -- End simulation
        sim_done <= true;
        wait;
    end process;
    
end architecture sim;