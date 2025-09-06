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
        flag    : out std_logic              
    );
end comterB;

architecture rtl of comterB is
    constant ADD_VAL  : unsigned(31 downto 0) := "00000010110110000010110110000010"; -- 4 deg step
    constant COMP_VAL : unsigned(31 downto 0) := "11111111111111111111111110110100"; -- 360 deg
    signal count      : unsigned(31 downto 0) := (others => '0');
begin
    -- Proses sinkron dengan reset asinkron
    process(clk, rst)
    begin
        if rst = '1' then
            count <= (others => '0');
        elsif rising_edge(clk) then
            if enable = '1' then
                -- Jika clock sebelumnya reset aktif, langsung lompat ke ADD_VAL
                if rst = '1' then
                    count <= ADD_VAL;
                else
                    count <= count + ADD_VAL;
                end if;
            end if;
        end if;
    end process;

    counter <= count;
    flag <= '1' when count = COMP_VAL else '0';
end rtl;