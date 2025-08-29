-- modified cordic by rey
-- Version 5.0: Added a global 'enable' signal to control pipeline operation.
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity pipelineCORDIC is
    port (
        clk    : in  std_logic;
        enable : in  std_logic; -- Pipeline runs only when this is '1'
        reset  : in  std_logic;
        angle  : in  signed(31 downto 0);
        Yout   : out signed(7 downto 0)
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
    
begin
    -- Quadrant detection is combinational, always active
    quadrant <= std_logic_vector(angle(31 downto 30));
    
    -- Process for Stage 0 (Initialization)
    process(clk)
    begin
        if rising_edge(clk) then
            if reset = '1' then
                X(0) <= (others => '0');
                Y(0) <= (others => '0');
                Z(0) <= (others => '0');
            -- Only load new data or run if enable is '1'
            elsif enable = '1' then
                case quadrant is
                    when "00" | "11" =>
                        X(0) <= "01001101111010111"; -- Using precise 1/K value: 39795
                        Y(0) <= (others => '0');
                        Z(0) <= angle;
                    when "01" =>
                        X(0) <= (others => '0');
                        Y(0) <= "01001101111010111"; -- Value: 39795
                        Z(0) <= "00" & angle(29 downto 0);
                    when "10" =>
                        X(0) <= (others => '0');
                        Y(0) <= "10110010000101001"; -- Value: -39795
                        Z(0) <= "11" & angle(29 downto 0);
                    when others => 
                        X(0) <= (others => '0');
                        Y(0) <= (others => '0');
                        Z(0) <= (others => '0');
                end case;
            end if;
            -- If enable is '0', the registers will hold their previous value.
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
                -- Only advance the pipeline if enable is '1'
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
            -- Only update the output register if enable is '1'
            elsif enable = '1' then
                Yout <= Y(15)(16 downto 9);
            end if;
        end if;
    end process;
    
end behavioral;