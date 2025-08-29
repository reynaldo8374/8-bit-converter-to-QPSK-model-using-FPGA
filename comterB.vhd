-- comterB: 32-bit counter with custom adder and comparator
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity comterB is
    port (
        clk     : in  std_logic;
        enable  : in  std_logic;
        rst     : in  std_logic;
        counter : out unsigned(31 downto 0); -- 32-bit counter output
        flag    : out std_logic              -- High when counter = 0xFFFFFFC0
    );
end comterB;

architecture rtl of comterB is
    constant ADD_VAL : unsigned(31 downto 0) := x"02D82D82"; -- 00000010110110000010110110000010
    constant COMP_VAL: unsigned(31 downto 0) := x"FFFFFFC0"; -- 11111111111111111111111100000000
    signal count : unsigned(31 downto 0) := (others => '0');
begin
    process(clk, rst)
    begin
        if rst = '1' then
            count <= (others => '0');
        elsif rising_edge(clk) then
            if enable = '1' then
                count <= count + ADD_VAL;
            end if;
        end if;
    end process;

    counter <= count;
    flag <= '1' when count = COMP_VAL else '0';
end rtl;