library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

-- Use the libraries you need

library work;
use work.util_package.ALL;

entity pe is
    Generic ( 
        MAT_LENGTH : POSITIVE := 32;
        INPUT_WIDTH : POSITIVE := 8;
        OUTPUT_WIDTH : POSITIVE := 21);
    Port ( 
        clk : in STD_LOGIC;
        rst : in STD_LOGIC;
        init : in STD_LOGIC;
        in_a : in STD_LOGIC_VECTOR (INPUT_WIDTH-1 downto 0);
        in_b : in STD_LOGIC_VECTOR (INPUT_WIDTH-1 downto 0);
        out_sum : out STD_LOGIC_VECTOR (OUTPUT_WIDTH-1 downto 0) := (others => '0');
        valid_sum : out STD_LOGIC := '0';
        out_a : out STD_LOGIC_VECTOR (INPUT_WIDTH-1 downto 0) := (others => '0');
        out_b : out STD_LOGIC_VECTOR (INPUT_WIDTH-1 downto 0) := (others => '0'));
end pe;

architecture Behavioral of pe is

-- Add your own code here

signal sum: INTEGER:=0;
signal pro: std_logic;
begin
    add:process(init,in_a,in_b,sum)
    variable temp_sum : integer:=0;
    begin
        if init = '1' then
            temp_sum := TO_INTEGER(UNSIGNED(in_a)) * TO_INTEGER(UNSIGNED(in_b));
        else
            temp_sum :=  sum + TO_INTEGER(UNSIGNED(in_a)) * TO_INTEGER(UNSIGNED(in_b));
        end if;
        out_sum <= std_logic_vector(TO_UNSIGNED(temp_sum,OUTPUT_WIDTH));
        
    end process;
    
    
    acc:process(clk,rst)
    variable clk_counter: integer:=0;
    begin
        valid_sum <= '0';
        if rst = '1' then
            clk_counter := 0;
        elsif rising_edge(clk) then
            sum <=  TO_INTEGER(UNSIGNED(out_sum));
            if init = '1' or clk_counter /= 0 then
                clk_counter := clk_counter + 1;
                if clk_counter = MAT_LENGTH-1 then
                    valid_sum <= '1';
                    clk_counter := 0;
                end if;
            end if;
        end if;
    end process;
    
    pass_int:process(rst,clk)
    begin
        if rst = '1' then
            out_a <= (others => '0');
            out_b <= (others => '0');
        elsif rising_edge(clk) then
            out_a <= in_a;
            out_b <= in_b;
        end if;
    end process;
    
-- Add your own code here
end Behavioral;
