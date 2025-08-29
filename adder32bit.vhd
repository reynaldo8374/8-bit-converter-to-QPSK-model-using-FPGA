-- Deskripsi: Blok untuk menjumlahkan dua bilangan signed sebesar 32 bit

-- Library
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- Define entity
entity adder32bit is
        port(
                x       : in signed(31 downto 0); -- operan bertanda
                y       : in signed(31 downto 0); -- operan bertanda
                result  : out signed(31 downto 0) -- output hasil penjumlahan
        ); 
end adder32bit;

-- Define architecture
architecture rtl of adder32bit is 
begin
        result <= x + y; -- Operasi penjumlahan
end rtl;