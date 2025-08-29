library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity mux4to1_2bit is
    port (
        in_data  : in  std_logic_vector(7 downto 0);  -- 8-bit input
        Sel      : in  std_logic_vector(1 downto 0);  -- 2-bit selector
        out_data : out std_logic_vector(1 downto 0)   -- 2-bit output
    );
end mux4to1_2bit;

architecture rtl of mux4to1_2bit is
begin
    process (Sel, in_data)
    begin
        case Sel is
            when "00" =>
                out_data <= in_data(7 downto 6);
            when "01" =>
                out_data <= in_data(5 downto 4);
            when "10" =>
                out_data <= in_data(3 downto 2);
            when others =>
                out_data <= in_data(1 downto 0);
        end case;
    end process;
end rtl;