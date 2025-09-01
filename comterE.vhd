-- comterD: Counter with 1-bit increment and comparator for decimal 360
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity comterE is
    port (
        clk     : in  std_logic;
        enable  : in  std_logic;
        rst     : in  std_logic;
        counter : out unsigned(8 downto 0); -- 9-bit counter output (can count up to 511)
        flag    : out std_logic             -- High when counter = 360
    );
end comterE;

architecture rtl of comterE is
    constant COMP_VAL: unsigned(8 downto 0) := to_unsigned(360, 9);
    signal count : unsigned(8 downto 0) := (others => '0');
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
                    count <= count + 1;
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