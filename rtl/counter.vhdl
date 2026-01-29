library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity counter is
    port (
        clk     : in  std_logic;
        reset   : in  std_logic;
        enable  : in  std_logic;
        count   : out std_logic_vector(7 downto 0)
    );
end entity counter;

architecture rtl of counter is
    signal count_internal : unsigned(7 downto 0);
begin
    process(clk, reset)
    begin
        if reset = '1' then
            count_internal <= (others => '0');
        elsif rising_edge(clk) then
            if enable = '1' then
                count_internal <= count_internal + 1;
            end if;
        end if;
    end process;
    
    count <= std_logic_vector(count_internal);
end architecture rtl;