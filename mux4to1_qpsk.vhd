library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity mux4to1_qpsk is
    port (
        Sel  : in  std_logic_vector(1 downto 0);   -- Selector
        Data : out signed(31 downto 0)             -- Output data (QPSK phase)
    );
end mux4to1_qpsk;

architecture rtl of mux4to1_qpsk is
begin
    process (Sel)
    begin
        case Sel is
            when "00" =>
                Data <= "00100000000000000000000000000000"; -- 45 deg
            when "01" =>
                Data <= "01100000000000000000000000000000"; -- 135 deg
            when "10" =>
                Data <= "10100000000000000000000000000000"; -- 225 deg
            when others =>
                Data <= "11100000000000000000000000000000"; -- 315 deg
        end case;
    end process;
end rtl;