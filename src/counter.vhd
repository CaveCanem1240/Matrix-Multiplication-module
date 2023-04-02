library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

-- Use the libraries you need

library work;
use work.util_package.ALL;

entity counter is
    Generic ( 
            WIDTH : POSITIVE := 32;
            HEIGHT : POSITIVE := 32);
    Port ( 
            clk : in STD_LOGIC;
            rst : in STD_LOGIC;
            enable_row_count : in STD_LOGIC;
            pixel_cntr : out STD_LOGIC_VECTOR (clog2(WIDTH)-1 downto 0) := (others => '0');
            slice_cntr : out STD_LOGIC_VECTOR (clog2(HEIGHT)-1 downto 0) := (others => '0'));
end counter;

architecture Behavioral of counter is
-- Add your own code here
begin
-- Add your own code here
end Behavioral;
