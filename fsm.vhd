library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity fsm is
    port(
        clk         : in  std_logic;
        reset_btn   : in  std_logic;  -- active low
        start_btn   : in  std_logic;  -- active low
        o_RX_DV     : in  std_logic;

        flag_A      : in  std_logic;
        flag_B      : in  std_logic;
        flag_co     : in  std_logic;
        flag_E      : in  std_logic;
        flag_D      : in  std_logic;

        o_TX_Done   : in  std_logic;
        o_TX_Active : in  std_logic;

        res_A       : out std_logic;
        en_A        : out std_logic;
        res_B       : out std_logic;
        en_B        : out std_logic;
        res_co      : out std_logic;
        en_co       : out std_logic;
        res_E       : out std_logic;
        en_E        : out std_logic;
        res_D       : out std_logic;
        en_D        : out std_logic;
        res_re      : out std_logic;
        en_re       : out std_logic;
        i_TX_DV     : out std_logic
    );
end fsm;

architecture behavioral of fsm is
    type state_type is (IDLE, WAIT_RX_DV, PROCESSING, PROC_B, READ_REG, DONE);
    signal state : state_type;

    -- registered outputs
    signal res_A_reg, en_A_reg : std_logic := '0';
    signal res_B_reg, en_B_reg : std_logic := '0';
    signal res_co_reg, en_co_reg : std_logic := '0';
    signal res_E_reg, en_E_reg : std_logic := '0';
    signal res_D_reg, en_D_reg : std_logic := '0';
    signal res_re_reg, en_re_reg : std_logic := '0';
    signal i_TX_DV_reg : std_logic := '0';

    -- helpers
    signal start_latched : std_logic := '0';
    signal tx_waiting    : std_logic := '0';
begin
    -- drive ports
    res_A   <= res_A_reg;   en_A   <= en_A_reg;
    res_B   <= res_B_reg;   en_B   <= en_B_reg;
    res_co  <= res_co_reg;  en_co  <= en_co_reg;
    res_E   <= res_E_reg;   en_E   <= en_E_reg;
    res_D   <= res_D_reg;   en_D   <= en_D_reg;
    res_re  <= res_re_reg;  en_re  <= en_re_reg;
    i_TX_DV <= i_TX_DV_reg;

    -- single synchronous process FSM
    process(clk)
        variable ns : state_type;
    begin
        if rising_edge(clk) then
            if reset_btn = '0' then
                -- reset state/regs
                state <= IDLE;
                start_latched <= '0';
                tx_waiting <= '0';

                res_A_reg <= '1'; en_A_reg <= '0';
                res_B_reg <= '1'; en_B_reg <= '0';
                res_co_reg <= '1'; en_co_reg <= '0';
                res_E_reg <= '1'; en_E_reg <= '0';
                res_D_reg <= '1'; en_D_reg <= '0';
                res_re_reg <= '1'; en_re_reg <= '0';
                i_TX_DV_reg <= '0';
            else
                -- defaults each cycle
                res_A_reg <= '0'; en_A_reg <= '0';
                res_B_reg <= '0'; en_B_reg <= '0';
                res_co_reg <= '0'; en_co_reg <= '0';
                res_E_reg <= '0'; en_E_reg <= '0';
                res_D_reg <= '0'; en_D_reg <= '0';
                res_re_reg <= '0'; en_re_reg <= '0';
                i_TX_DV_reg <= '0';

                ns := state;

                if state = IDLE then
                    if start_btn = '0' then start_latched <= '1';
                    else                    start_latched <= '0';
                    end if;
                end if;

                case state is
                    when IDLE =>
                        res_A_reg <= '1'; res_B_reg <= '1'; res_co_reg <= '1';
                        res_D_reg <= '1'; res_E_reg <= '1'; res_re_reg <= '1';
                        if start_latched = '1' then ns := WAIT_RX_DV; end if;

                    when WAIT_RX_DV =>
                        res_A_reg <= '1'; res_B_reg <= '1'; res_co_reg <= '1';
                        res_D_reg <= '1'; res_E_reg <= '1'; res_re_reg <= '1';
                        if o_RX_DV = '1' then ns := PROCESSING; end if;

                    when PROCESSING =>
                        en_B_reg  <= '1';
                        en_co_reg <= '1';
                        if (flag_co = '1') and (flag_D = '0') then
                            en_D_reg  <= '1';
                            en_re_reg <= '1';
                        end if;

                        if flag_D = '1' then
                            ns := READ_REG;
                        -- Saat flag_B=1, pindah ke state PROC_B
                        elsif flag_B = '1' then
                            res_B_reg <= '1';  -- Pulse reset_b
                            en_A_reg  <= '1';  -- Pulse en_A juga!
                            ns := PROCESSING;
                        end if;

                    when READ_REG =>
                        if (tx_waiting = '0') and (o_TX_Active = '0') and (flag_E = '0') then
                            i_TX_DV_reg <= '1';
                            tx_waiting  <= '1';
                        end if;
                        if (tx_waiting = '1') and (o_TX_Done = '1') then
                            en_E_reg   <= '1';
                            tx_waiting <= '0';
                        end if;
                        if (flag_E = '1') and (tx_waiting = '0') and (o_TX_Active = '0') then
                            ns := DONE;
                        end if;

                    when DONE =>
                        res_A_reg <= '1'; res_B_reg <= '1'; res_co_reg <= '1';
                        res_D_reg <= '1'; res_E_reg <= '1'; res_re_reg <= '1';
                        ns := DONE;

                    when others =>
                        ns := IDLE;
                end case;

                state <= ns;
            end if;
        end if;
    end process;
end behavioral;