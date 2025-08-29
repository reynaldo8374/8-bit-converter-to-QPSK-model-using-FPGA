-- filepath: c:\Users\Reynaldo\Documents\8-bit-converter-to-QPSK-model-using-FPGA\register_file_360x8.vhd
-- Register File 360x8: Synchronous write, asynchronous read, with reset and address protection

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity register_file_360x8 is
    port (
        clk          : in  std_logic;
        rst          : in  std_logic;
        write_enable : in  std_logic;
        write_addr   : in  std_logic_vector(8 downto 0);
        data_in      : in  signed(7 downto 0);
        read_addr    : in  std_logic_vector(8 downto 0);
        data_out     : out signed(7 downto 0)
    );
end entity register_file_360x8;

architecture rtl of register_file_360x8 is
    type memory_t is array (0 to 359) of signed(7 downto 0);
    signal memory_reg : memory_t := (others => (others => '0'));
begin

    -- Synchronous write with reset and address protection
    write_process : process(clk)
    begin
        if rising_edge(clk) then
            if rst = '1' then
                memory_reg <= (others => (others => '0'));
            elsif write_enable = '1' then
                if to_integer(unsigned(write_addr)) >= 0 and to_integer(unsigned(write_addr)) <= 359 then
                    memory_reg(to_integer(unsigned(write_addr))) <= data_in;
                end if;
            end if;
        end if;
    end process write_process;

    -- Asynchronous read with address protection
    process(all)
    begin
        if to_integer(unsigned(read_addr)) >= 0 and to_integer(unsigned(read_addr)) <= 359 then
            data_out <= memory_reg(to_integer(unsigned(read_addr)));
        else
            data_out <= (others => '0');
        end if;
    end process;

end architecture rtl;