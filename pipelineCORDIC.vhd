-- modified cordic by rey
-- Version 6.0: Added 'flag_co' output to signal when Yout is valid.
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity pipelineCORDIC is
    port (
        clk     : in  std_logic;
        enable  : in  std_logic; -- Pipeline runs only when this is '1'
        reset   : in  std_logic;
        angle   : in  signed(31 downto 0);
        Yout    : out signed(7 downto 0);
        flag_co : out std_logic  -- NEW: '1' when Yout is valid
    );
end pipelineCORDIC;

architecture behavioral of pipelineCORDIC is
    -- Pre-computed atan values for CORDIC rotation
    type atan_table_array is array (0 to 14) of signed(31 downto 0);
    constant atan : atan_table_array := (
        b"00100000000000000000000000000000", -- atan(2^0)
        b"00010010111001000000010100011101", -- atan(2^-1)
        b"00001001111110110011100001011011", -- atan(2^-2)
        b"00000101000100010001000111010100", -- atan(2^-3)
        b"00000010100010110000110101000011",
        b"00000001010001011101011111100001",
        b"00000000101000101111011000011110",
        b"00000000010100010111110001010101",
        b"00000000001010001011111001010011",
        b"00000000000101000101111100101110",
        b"00000000000010100010111110011000",
        b"00000000000001010001011111001100",
        b"00000000000000101000101111100110",
        b"00000000000000010100010111110011",
        b"00000000000000001010001011111001"
    );

    signal quadrant  : std_logic_vector(1 downto 0);
    type XY is array (0 to 15) of signed(16 downto 0);   
    type type_Z is array (0 to 15) of signed(31 downto 0);
    signal X, Y      : XY := (others => (others => '0'));
    signal Z         : type_Z := (others => (others => '0'));
    
    -- NEW: Shift register to create the valid flag
    signal valid_pipeline_reg : std_logic_vector(0 to 15); --16 bit

begin
    -- Quadrant detection is combinational, always active
    quadrant <= std_logic_vector(angle(31 downto 30));
    
    -- This process creates a 16-stage shift register for the valid flag.
    -- The 'enable' signal travels through this register, perfectly in sync
    -- with the data traveling through the main CORDIC pipeline.
    valid_flag_proc : process(clk)
    begin
        if rising_edge(clk) then
            if reset = '1' then 
                valid_pipeline_reg <= (others => '0'); -- valid_pipeline_reg = (0,0,0,...,0)
            elsif enable = '1' then 
                -- Shift the flag one stage to the right
                valid_pipeline_reg(1 to 15) <= valid_pipeline_reg(0 to 14); -- 15 bit move to left
                -- A '1' enters the pipeline whenever a new calculation starts
                valid_pipeline_reg(0) <= '1'; -- add 1 at the start of the pipeline
            else -- enable = '0'
                -- If not enabled, keep shifting zeros to flush the pipeline
                valid_pipeline_reg(1 to 15) <= valid_pipeline_reg(0 to 14);
                valid_pipeline_reg(0) <= '0';
            end if;
        end if;
    end process valid_flag_proc;

    -- The output flag is the signal that has completed its journey
    flag_co <= valid_pipeline_reg(15);

    -- Process for Stage 0 (Initialization)
    process(clk)
    begin
        if rising_edge(clk) then
            if reset = '1' then
                X(0) <= (others => '0');
                Y(0) <= (others => '0');
                Z(0) <= (others => '0');
            elsif enable = '1' then
                case quadrant is
                    when "00" | "11" =>
                        -- Kecilkan dari 39795 ke 9948 (dibagi 4)
                        X(0) <= "00010011011110101"; -- 9948 ≈ 39795/4
                        Y(0) <= (others => '0');
                        Z(0) <= angle;
                    when "01" =>
                        X(0) <= (others => '0');
                        Y(0) <= "00010011011110101"; -- 9948
                        Z(0) <= "00" & angle(29 downto 0);
                    when "10" =>
                        X(0) <= (others => '0');
                        Y(0) <= "11101100100001011"; -- -9948
                        Z(0) <= "11" & angle(29 downto 0);
                    when others => 
                        X(0) <= (others => '0');
                        Y(0) <= (others => '0');
                        Z(0) <= (others => '0');
                end case;
            end if;
        end if;
    end process;
    
    -- Generate block for Pipeline Stages 1 to 15
    gen_stage: for i in 0 to 14 generate
        process(clk)
        begin
            if rising_edge(clk) then
                if reset = '1' then
                    X(i+1) <= (others => '0');
                    Y(i+1) <= (others => '0');
                    Z(i+1) <= (others => '0');
                elsif enable = '1' then
                    case Z(i)(31) is
                        when '1' => 
                            X(i+1) <= X(i) + shift_right(Y(i), i);
                            Y(i+1) <= Y(i) - shift_right(X(i), i);
                            Z(i+1) <= Z(i) + atan(i); 
                        when others =>
                            X(i+1) <= X(i) - shift_right(Y(i), i);
                            Y(i+1) <= Y(i) + shift_right(X(i), i);
                            Z(i+1) <= Z(i) - atan(i);
                    end case;
                end if;
            end if;
        end process;
    end generate gen_stage;
    
    -- Process for the final output stage
    process(clk)
    begin
        if rising_edge(clk) then
            if reset = '1' then
                Yout <= (others => '0');
            elsif enable = '1' then
                Yout <= Y(15)(16 downto 9);
            end if;
        end if;
    end process;
    
end behavioral;