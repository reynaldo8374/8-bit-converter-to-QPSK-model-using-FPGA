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
    type state_type is (IDLE, WAIT_RX_DV, PROC_START_A, PROC_WAIT_FLAGS, PROC_RESET_B, READ_REG, DONE);
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
    en_A    <= '1' when (current_state = PROC_WAIT_FLAGS and flag_B = '1') else '0';
    res_B   <= '1' when (current_state = PROC_WAIT_FLAGS and flag_B = '1') else res_B_reg;
    en_B    <= '0' when (current_state = PROC_WAIT_FLAGS and flag_A = '1' and flag_B = '1') else
               '1' when ((current_state = PROC_START_A) or 
                        (current_state = PROC_WAIT_FLAGS)) else '0';
    res_co  <= res_co_reg;
    en_co   <= en_co_reg;
    res_E   <= res_E_reg;
    en_E    <= '1' when (current_state = READ_REG and flag_E = '0' and 
                        o_TX_Active = '0') else '0';
    res_D   <= res_D_reg;
    en_D    <= '1' when (flag_co = '1' and flag_D = '0' and 
                        (current_state = PROC_WAIT_FLAGS or current_state = PROC_RESET_B)) else '0';
    res_re  <= res_re_reg;
    en_re   <= '1' when (flag_co = '1' and flag_D = '0' and 
                        (current_state = PROC_WAIT_FLAGS or current_state = PROC_RESET_B)) else '0';
    i_TX_DV <= '1' when (current_state = READ_REG and flag_E = '0' and 
                        o_TX_Active = '0') else '0';

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

    -- Next state logic (combinational only)
    process(current_state, o_RX_DV, start_btn_latched, flag_co, flag_B, flag_D, flag_E, o_TX_Done)
    begin
        case current_state is
            when IDLE =>
                if start_btn_latched = '1' then
                    next_state <= WAIT_RX_DV;
                else
                    next_state <= IDLE;
                end if;

            when WAIT_RX_DV => 
                if o_RX_DV = '1' then
                    next_state <= PROC_START_A;
                else
                    next_state <= WAIT_RX_DV;
                end if; 
            
            when PROC_START_A =>
                next_state <= PROC_WAIT_FLAGS;
                
            when PROC_WAIT_FLAGS =>
                if flag_D = '1' then
                    next_state <= READ_REG;
                elsif flag_B = '1' then
                    next_state <= PROC_RESET_B;
                else
                    next_state <= PROC_WAIT_FLAGS;
                end if;
            
            when PROC_RESET_B =>
                next_state <= PROC_START_A;

            when READ_REG =>
                if flag_E = '1' and o_TX_Done = '1' then
                    next_state <= DONE;
                else
                    next_state <= READ_REG;
                end if;

            when DONE =>
                next_state <= DONE;

            when others =>
                next_state <= IDLE;
        end case;
    end process;

    -- Output register logic (synchronous)
    process(clk)
    begin
        if rising_edge(clk) then
            if reset_btn = '0' then
                -- Reset semua output
                res_A_reg <= '1';
                en_A_reg <= '0';
                res_B_reg <= '1';
                en_B_reg <= '0';
                res_co_reg <= '1';
                en_co_reg <= '0';
                res_E_reg <= '1';
                en_E_reg <= '0';
                res_D_reg <= '1';
                en_D_reg <= '0';
                res_re_reg <= '1';
                en_re_reg <= '0';
                i_TX_DV_reg <= '0';
            else
                -- Default: semua reset = 0, enable = 0
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
                    when IDLE =>
                        -- Reset semua module di IDLE
                        res_A_reg <= '1';
                        res_B_reg <= '1';
                        res_co_reg <= '1';
                        res_D_reg <= '1';
                        res_E_reg <= '1';
                        res_re_reg <= '1';

                    when WAIT_RX_DV =>
                        -- Tetap reset sambil tunggu RX
                        res_A_reg <= '1';
                        res_B_reg <= '1';
                        res_co_reg <= '1';
                        res_D_reg <= '1';
                        res_E_reg <= '1';
                        res_re_reg <= '1';
                    
                    when PROC_START_A =>
                        -- en_B sekarang kombinasional, hapus dari sini
                        en_co_reg <= '1';
                        
                    when PROC_WAIT_FLAGS =>
                        -- en_B sekarang kombinasional, hapus dari sini
                        
                        -- en_co sampai flag_D=1
                        if flag_D = '0' then
                            en_co_reg <= '1';
                        end if;
                    
                    when PROC_RESET_B =>
                        -- res_B dan en_B sekarang kombinasional, hapus dari sini
                        
                        -- CORDIC tetap jalan sampai flag_D=1
                        if flag_D = '0' then
                            en_co_reg <= '1';
                        end if;
                        
                        -- en_D dan en_re sekarang kombinasional, hapus dari sini

                    when READ_REG =>
                        -- en_E sekarang kombinasional, hapus dari sini
                        
                        -- TX trigger
                        if o_TX_Active = '0' then
                            i_TX_DV_reg <= '1';
                        end if;

                    when DONE =>
                        -- Semua idle, reset semua module
                        res_A_reg <= '1';
                        res_B_reg <= '1';
                        res_co_reg <= '1';
                        res_D_reg <= '1';
                        res_E_reg <= '1';
                        res_re_reg <= '1';

                    when others =>
                        res_A_reg <= '1';
                        res_B_reg <= '1';
                        res_co_reg <= '1';
                        res_D_reg <= '1';
                        res_E_reg <= '1';
                        res_re_reg <= '1';
                end case;
            end if;
        end if;
    end process;

end behavioral;