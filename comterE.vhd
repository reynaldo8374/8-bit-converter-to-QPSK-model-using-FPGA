-- comterE: Example counter + comparator (template, adjust as needed)
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity comterE is
    port (
        clk     : in  std_logic;
        enable  : in  std_logic;
        rst     : in  std_logic;
        counter : out unsigned(31 downto 0); -- Adjust width if needed
        flag    : out std_logic
    );
end comterE;

architecture rtl of comterE is
    constant ADD_VAL  : unsigned(31 downto 0) := (others => '1'); -- Example increment, adjust as needed
    constant COMP_VAL : unsigned(31 downto 0) := (others => '1'); -- Example compare value, adjust as needed
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