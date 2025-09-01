library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity fsm is
    port(
        clk         : in  std_logic;
        reset_btn   : in  std_logic;
        start_btn   : in  std_logic;
        o_RX_DV     : in  std_logic;
        flag_A      : in  std_logic;
        flag_B      : in  std_logic;
        flag_co     : in  std_logic;
        flag_E      : in  std_logic;
        flag_D      : in  std_logic;
        o_TX_Done   : in  std_logic; -- Transmission done signal
        o_TX_Active : in  std_logic; -- Transmission active signal, active means transmission in progress
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
    type state_type is (IDLE, WAIT_RX_DV, PROCESSING, WRITE_REG, READ_REG, TX, WAIT_TX_DONE, DONE);
    signal current_state, next_state : state_type;
    
    -- Button latch signal
    signal start_btn_latched : std_logic := '0';

    -- Internal register signals for outputs
    signal res_A_reg   : std_logic := '0';
    signal en_A_reg    : std_logic := '0';
    signal res_B_reg   : std_logic := '0';
    signal en_B_reg    : std_logic := '0';
    signal res_co_reg  : std_logic := '0';
    signal en_co_reg   : std_logic := '0';
    signal res_E_reg   : std_logic := '0';
    signal en_E_reg    : std_logic := '0';
    signal res_D_reg   : std_logic := '0';
    signal en_D_reg    : std_logic := '0';
    signal res_re_reg  : std_logic := '0';
    signal en_re_reg   : std_logic := '0';
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

    -- checked
    process(clk)
    begin
        if rising_edge(clk) then
            if reset_btn = '0' then  -- reset button is pressed
                start_btn_latched <= '0'; -- start button latch reset
            elsif current_state = IDLE then
                if start_btn = '0' then  -- start button pressed
                    start_btn_latched <= '1'; -- latch the start button
                else
                    start_btn_latched <= '0'; -- clear latch if not pressed
                end if;
            elsif current_state = DONE then -- clear latch in DONE state  
                start_btn_latched <= '0'; -- clear latch
            end if;
        end if;
    end process;

    -- State register with synchronous reset
    process(clk)
    begin
        if rising_edge(clk) then
            if reset_btn = '0' then  -- reset button pressed
                current_state <= IDLE; -- Go to IDLE state
            else -- reset not pressed
                current_state <= next_state; -- Transition to next state
            end if;
        end if;
    end process;

    -- Next state and output logic
    process(current_state, o_RX_DV, start_btn_latched, flag_co, flag_B, flag_D, flag_E, o_TX_Done, o_TX_Active)
    begin
        -- Default output values 
        res_A_reg <= '0';
        en_A_reg <= '0';
        res_B_reg <= '0';
        en_B_reg <= '0';
        res_co_reg <= '0';
        en_co_reg <= '0';
        res_E_reg <= '0';
        en_E_reg <= '0';
        res_D_reg <= '0';
        en_D_reg <= '0';
        res_re_reg <= '0';
        en_re_reg <= '0';
        i_TX_DV_reg <= '0';

        case current_state is
            -- IDLE: Wait for start button press, reset all modules
            when IDLE =>
                res_A_reg <= '1';
                res_B_reg <= '1';
                res_co_reg <= '1';
                res_D_reg <= '1';
                res_E_reg <= '1';
                if start_btn_latched = '1' then -- starting process
                    next_state <= WAIT_RX_DV; -- Move to WAIT_RX_DV state
                end if;

            when WAIT_RX_DV => 
                if o_RX_DV = '1' then
                    next_state <= PROCESSING;
                else
                    next_state <= WAIT_RX_DV;
                end if; 

            -- PROCESSING: Enable modules A, B, and CO, wait for CO flag
            when PROCESSING =>
                en_A_reg <= '1'; 
                en_B_reg <= '1';
                en_co_reg <= '1';
                if flag_co = '1' then -- first output from CORDIC is ready
                    en_D_reg <= '1'; -- Enable register write/counter
                    en_re_reg <= '1'; -- Enable register file write
                end if;
                -- Only move to WRITE_REG when all symbols/angles are done
                if flag_D = '1' then -- write to register done
                    next_state <= READ_REG;
                else
                    next_state <= PROCESSING;
                end if;

            -- READ_REG: Enable module E, wait for E flag
            when READ_REG =>
                en_E_reg <= '1';
                -- Only pulse TX trigger for one clock when transmitter is not busy
                if o_TX_Active = '0' then
                    i_TX_DV_reg <= '1';    -- Pulse TX for one clock
                else
                    i_TX_DV_reg <= '0';    -- Keep low otherwise
                end if;
                -- Move to DONE when all data sent
                if flag_E = '1' and o_TX_Done = '1' then
                    next_state <= DONE;
                else
                    next_state <= READ_REG;
                end if;

            when DONE =>
                if reset_btn = '0' then  -- reset button pressed
                    next_state <= IDLE; -- Go to IDLE state
                else
                    next_state <= DONE; -- Stay in DONE state
                end if;

            when others =>
                next_state <= IDLE;
        end case;
    end process;

end behavioral;