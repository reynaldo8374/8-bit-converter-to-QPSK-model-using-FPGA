library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity comterD is
    port (
        clk     : in  std_logic;
        enable  : in  std_logic;
        rst     : in  std_logic;
        counter : out unsigned(8 downto 0); -- 9-bit counter output (can count up to 511)
        flag    : out std_logic             -- High when counter = 360
    );
end comterD;

architecture rtl of comterD is
    constant COMP_VAL: unsigned(8 downto 0) := to_unsigned(359, 9);
    signal count : unsigned(8 downto 0) := (others => '0');
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
    flag <= '1' when count = COMP_VAL else '0';
end rtl;