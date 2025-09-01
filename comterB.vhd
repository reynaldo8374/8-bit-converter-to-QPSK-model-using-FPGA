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
        flag    : out std_logic              -- High when counter = 11111111111111111111111100000000
    );
end comterB;

architecture rtl of comterB is
    constant ADD_VAL  : unsigned(31 downto 0) := "00000010110110000010110110000010"; -- 4 deg step
    constant COMP_VAL : unsigned(31 downto 0) := "11111111111111111111111100000000"; -- 360 deg
    signal count : unsigned(31 downto 0) := (others => '0');
    signal enabled_last : std_logic := '0';
begin
    process(clk, rst)
    begin
        if rst = '1' then
            count <= (others => '0');
            enabled_last <= '0';
        elsif rising_edge(clk) then
            if enable = '1' then
                if enabled_last = '1' then
                    count <= count + ADD_VAL;
                end if;
                enabled_last <= '1';
            else
                enabled_last <= '0';
            end if;
        end if;
    end process;

    counter <= count;
    flag <= '1' when count = COMP_VAL else '0';
end rtl;