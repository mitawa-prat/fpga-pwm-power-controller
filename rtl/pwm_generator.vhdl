library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity pwm_generator is
    generic (
        COUNTER_WIDTH : integer := 8  -- 8 bits = 0 to 255
    );
    port (
        clk        : in  std_logic;
        reset      : in  std_logic;
        enable     : in  std_logic;
        duty_cycle : in  std_logic_vector(COUNTER_WIDTH-1 downto 0);
        pwm_out    : out std_logic
    );
end entity pwm_generator;

architecture rtl of pwm_generator is
    signal counter : unsigned(COUNTER_WIDTH-1 downto 0);
    signal duty_unsigned : unsigned(COUNTER_WIDTH-1 downto 0);
begin
    -- Convert duty_cycle input to unsigned for comparison
    duty_unsigned <= unsigned(duty_cycle);
    
    -- PWM counter process
    process(clk, reset)
    begin
        if reset = '1' then
            counter <= (others => '0');
            pwm_out <= '0';
        elsif rising_edge(clk) then
            if enable = '1' then
                -- Increment counter (wraps automatically)
                counter <= counter + 1;
                
                -- Compare and generate PWM output
                if counter < duty_unsigned then
                    pwm_out <= '1';
                else
                    pwm_out <= '0';
                end if;
            else
                -- When disabled, keep counter at 0 and output low
                counter <= (others => '0');
                pwm_out <= '0';
            end if;
        end if;
    end process;
    
end architecture rtl;