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
                Data <= to_signed(16#20000000#, 32); -- 45 deg
            when "01" =>
                Data <= to_signed(16#60000000#, 32); -- 135 deg
            when "10" =>
                Data <= to_signed(16#A0000000#, 32); -- 225 deg
            when others =>
                Data <= to_signed(16#E0000000#, 32); -- 315 deg
        end case;
    end process;
end rtl;