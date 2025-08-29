-- comterA: 2-bit counter + comparator with enable and reset, with counter output
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity comterA is
    port (
        clk     : in  std_logic;
        enable  : in  std_logic;            -- Enable signal
        rst     : in  std_logic;            -- Reset signal
        counter : out unsigned(1 downto 0); -- 2-bit counter output
        flag    : out std_logic             -- High when counter = "11"
    );
end comterA;

architecture rtl of comterA is
    signal count : unsigned(1 downto 0) := (others => '0');
begin
    process(clk, rst)
    begin
        if rst = '1' then
            count <= (others => '0');
        elsif rising_edge(clk) then
            if enable = '1' then
                count <= count + 1;
            end if;
        end if;
    end process;

    counter <= count;
    flag <= '1' when count = "11" else '0';
end rtl;