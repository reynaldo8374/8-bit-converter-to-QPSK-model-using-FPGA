-- filepath: c:\Users\Reynaldo\Documents\8-bit-converter-to-QPSK-model-using-FPGA\fsm.vhd
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity fsm is
    port(
        clk             : in  std_logic;
        reset_btn       : in  std_logic;
        start_btn       : in  std_logic;
        o_RX_DV         : in  std_logic;
        flag_A          : in  std_logic;
        flag_B          : in  std_logic;
        flag_co         : in  std_logic;
        flag_E          : in  std_logic;
        flag_D          : in  std_logic;
        o_TX_Done       : in  std_logic;
        o_TX_Active     : in  std_logic;
        -- Outputs
        res_A           : out std_logic;
        en_A            : out std_logic;
        res_B           : out std_logic;
        en_B            : out std_logic;
        res_co          : out std_logic;
        en_co           : out std_logic;
        res_E           : out std_logic;
        en_E            : out std_logic;
        res_D           : out std_logic;
        en_D            : out std_logic;
        res_re          : out std_logic;
        en_re           : out std_logic;
        i_TX_DV         : out std_logic
    );
end fsm;

architecture behavioral of fsm is
    type state_type is (IDLE, WAIT_START, PREP, PROCESSING, WAIT_CORDIC, WRITE_REG, READ_REG, TX, WAIT_TX_DONE, DONE);
    signal current_state, next_state : state_type;

    -- Output registers
    signal res_A_reg, en_A_reg, res_B_reg, en_B_reg : std_logic := '0';
    signal res_co_reg, en_co_reg : std_logic := '0';
    signal res_E_reg, en_E_reg : std_logic := '0';
    signal res_D_reg, en_D_reg : std_logic := '0';
    signal res_re_reg, en_re_reg : std_logic := '0';
    signal i_TX_DV_reg : std_logic := '0';

begin

    -- Output assignments
    res_A   <= res_A_reg;
    en_A    <= en_A_reg;
    res_B   <= res_B_reg;
    en_B    <= en_B_reg;
    res_co  <= res_co_reg;
    en_co   <= en_co_reg;
    res_E   <= res_E_reg;
    en_E    <= en_E_reg;
    res_D   <= res_D_reg;
    en_D    <= en_D_reg;
    res_re  <= res_re_reg;
    en_re   <= en_re_reg;
    i_TX_DV <= i_TX_DV_reg;

    -- State register
    process(clk, reset_btn)
    begin
        if reset_btn = '0' then -- tombol reset ditekan (active low)
            current_state <= IDLE;
        elsif rising_edge(clk) then
            current_state <= next_state;
        end if;
    end process;

    -- Next state and output logic
    process(current_state, o_RX_DV, start_btn, flag_A, flag_B, flag_co, flag_E, flag_D, o_TX_Done, o_TX_Active)
    begin
        -- Default outputs
        res_A_reg   <= '0'; en_A_reg   <= '0';
        res_B_reg   <= '0'; en_B_reg   <= '0';
        res_co_reg  <= '0'; en_co_reg  <= '0';
        res_E_reg   <= '0'; en_E_reg   <= '0';
        res_D_reg   <= '0'; en_D_reg   <= '0';
        res_re_reg  <= '0'; en_re_reg  <= '0';
        i_TX_DV_reg <= '0';
        next_state  <= current_state;

        case current_state is
            when IDLE =>
                -- Wait for RX data
                if o_RX_DV = '1' then
                    next_state <= WAIT_START;
                end if;

            when WAIT_START =>
                -- Wait for user to press start
                if start_btn = '0' then -- tombol start ditekan (active low)
                    -- Reset/enable all modules as needed
                    res_A_reg <= '1'; res_B_reg <= '1'; res_co_reg <= '1';
                    res_E_reg <= '1'; res_D_reg <= '1'; res_re_reg <= '1';
                    next_state <= PREP;
                end if;

            when PREP =>
                -- Release reset, enable modules
                res_A_reg <= '0'; en_A_reg <= '1';
                res_B_reg <= '0'; en_B_reg <= '1';
                res_co_reg <= '0'; en_co_reg <= '1';
                res_E_reg <= '0'; en_E_reg <= '1';
                res_D_reg <= '0'; en_D_reg <= '1';
                res_re_reg <= '0'; en_re_reg <= '1';
                next_state <= PROCESSING;

            when PROCESSING =>
                -- Wait for CORDIC pipeline to produce first valid output
                if flag_co = '1' then
                    next_state <= WRITE_REG;
                end if;

            when WRITE_REG =>
                -- Enable register write when flag_D is high
                en_re_reg <= '1';
                if flag_D = '1' then
                    -- Assume one write per process, then go to read
                    next_state <= READ_REG;
                end if;

            when READ_REG =>
                -- Enable register read when flag_E is high
                en_re_reg <= '1';
                if flag_E = '1' then
                    next_state <= TX;
                end if;

            when TX =>
                -- Trigger UART TX
                i_TX_DV_reg <= '1';
                next_state <= WAIT_TX_DONE;

            when WAIT_TX_DONE =>
                -- Wait for TX to finish
                if o_TX_Done = '1' then
                    next_state <= DONE;
                end if;

            when DONE =>
                -- Go back to idle, ready for next RX + start
                next_state <= IDLE;

            when others =>
                next_state <= IDLE;
        end case;
    end process;

end behavioral;