-- filepath: c:\Users\Reynaldo\Documents\8-bit-converter-to-QPSK-model-using-FPGA\high_rtl.vhd
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity high_rtl is
    port(
        clk           : in  std_logic;
        reset_btn     : in  std_logic;
        start_btn     : in  std_logic;
        i_RX_Serial   : in  std_logic;
        o_TX_Serial   : out std_logic
    );
end high_rtl;

architecture structural of high_rtl is

    -- UART RX/TX
    signal rx_dv         : std_logic;
    signal rx_byte       : std_logic_vector(7 downto 0);
    signal tx_active     : std_logic;
    signal tx_done       : std_logic;
    signal tx_dv         : std_logic;
    signal tx_data       : std_logic_vector(7 downto 0);

    -- FSM control signals
    signal res_A, en_A, res_B, en_B, res_co, en_co : std_logic;
    signal res_E, en_E, res_D, en_D, res_re, en_re : std_logic;

    -- comterA (selector for mux4to1_2bit)
    signal comterA_counter : unsigned(1 downto 0);
    signal flag_A          : std_logic;

    -- mux4to1_2bit
    signal mux2bit_out     : std_logic_vector(1 downto 0);

    -- mux4to1_qpsk
    signal muxqpsk_out     : signed(31 downto 0);

    -- comterB (angle increment)
    signal comterB_counter : unsigned(31 downto 0);
    signal flag_B          : std_logic;

    -- adder32bit
    signal angle           : signed(31 downto 0);

    -- pipelineCORDIC
    signal cordic_yout     : signed(7 downto 0);
    signal flag_co         : std_logic;

    -- comterD (register write address)
    signal comterD_counter : unsigned(8 downto 0);
    signal flag_D          : std_logic;

    -- comterE (register read address)
    signal comterE_counter : unsigned(31 downto 0);
    signal flag_E          : std_logic;

    -- register file
    signal regfile_data_out : signed(7 downto 0);

begin

    -- UART RX
    uart_rx_inst: entity work.UART_RX
        generic map (g_CLKS_PER_BIT => 115) -- Set as needed
        port map (
            i_Clk       => clk,
            i_RX_Serial => i_RX_Serial,
            o_RX_DV     => rx_dv,
            o_RX_Byte   => rx_byte
        );

    -- UART TX
    uart_tx_inst: entity work.UART_TX
        generic map (g_CLKS_PER_BIT => 115) -- Set as needed
        port map (
            i_Clk       => clk,
            i_TX_DV     => tx_dv,
            i_TX_Byte   => tx_data,
            o_TX_Active => tx_active,
            o_TX_Serial => o_TX_Serial,
            o_TX_Done   => tx_done
        );

    -- FSM
    fsm_inst: entity work.fsm
        port map (
            clk         => clk,
            reset_btn   => reset_btn,
            start_btn   => start_btn,
            o_RX_DV     => rx_dv,
            flag_A      => flag_A,
            flag_B      => flag_B,
            flag_co     => flag_co,
            flag_E      => flag_E,
            flag_D      => flag_D,
            o_TX_Done   => tx_done,
            o_TX_Active => tx_active,
            res_A       => res_A,
            en_A        => en_A,
            res_B       => res_B,
            en_B        => en_B,
            res_co      => res_co,
            en_co       => en_co,
            res_E       => res_E,
            en_E        => en_E,
            res_D       => res_D,
            en_D        => en_D,
            res_re      => res_re,
            en_re       => en_re,
            i_TX_DV     => tx_dv
        );

    -- comterA: 2-bit counter for mux selector
    comterA_inst: entity work.comterA
        port map (
            clk     => clk,
            enable  => en_A,
            rst     => res_A,
            counter => comterA_counter,
            flag    => flag_A
        );

    -- mux4to1_2bit: selects 2 bits from RX data
    mux2bit_inst: entity work.mux4to1_2bit
        port map (
            in_data  => rx_byte,
            Sel      => std_logic_vector(comterA_counter),
            out_data => mux2bit_out
        );

    -- mux4to1_qpsk: selects QPSK phase based on 2-bit selector
    muxqpsk_inst: entity work.mux4to1_qpsk
        port map (
            Sel  => mux2bit_out,
            Data => muxqpsk_out
        );

    -- comterB: angle incrementer
    comterB_inst: entity work.comterB
        port map (
            clk     => clk,
            enable  => en_B,
            rst     => res_B,
            counter => comterB_counter,
            flag    => flag_B
        );

    -- adder32bit: sum phase from mux and comterB
    adder32bit_inst: entity work.adder32bit
        port map (
            x      => muxqpsk_out,
            y      => signed(comterB_counter),
            result => angle
        );

    -- pipelineCORDIC: calculates sine value
    cordic_inst: entity work.pipelineCORDIC
        port map (
            clk     => clk,
            enable  => en_co,
            reset   => res_co,
            angle   => angle,
            Yout    => cordic_yout,
            flag_co => flag_co
        );

    -- comterD: register write address
    comterD_inst: entity work.comterD
        port map (
            clk     => clk,
            enable  => en_D,
            rst     => res_D,
            counter => comterD_counter,
            flag    => flag_D
        );

    -- comterE: register read address (adjust width if needed)
    comterE_inst: entity work.comterE
        port map (
            clk     => clk,
            enable  => en_E,
            rst     => res_E,
            counter => comterE_counter,
            flag    => flag_E
        );

    -- register_file_360x8: stores CORDIC output
    regfile_inst: entity work.register_file_360x8
        port map (
            clk          => clk,
            rst          => res_re,
            write_enable => en_re,
            write_addr   => std_logic_vector(comterD_counter),
            data_in      => cordic_yout,
            read_addr    => std_logic_vector(comterE_counter(8 downto 0)), -- Only 9 bits used
            data_out     => regfile_data_out
        );

    -- TX data selection (from register file)
    tx_data <= std_logic_vector(regfile_data_out);

end structural;