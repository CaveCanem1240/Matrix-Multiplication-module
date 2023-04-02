library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Use the libraries you need
entity pipe is
    Generic(
            DATA_WIDTH : POSITIVE := 8;
            LENGTH : POSITIVE := 4);  
    Port ( 
            clk : in STD_LOGIC;
            rst : in STD_LOGIC;
            D : in STD_LOGIC_VECTOR (DATA_WIDTH-1 downto 0);
            Q : out STD_LOGIC_VECTOR (DATA_WIDTH-1 downto 0) := (others => '0'));
end pipe;

architecture Behavioral of pipe is
-- Add your own code here
signal Q_out : STD_LOGIC_VECTOR (DATA_WIDTH * (LENGTH+1)-1 downto 0) := (others => '0');
component FF
    Generic(
            DATA_WIDTH : POSITIVE := 8);
    Port( 
            clk : in STD_LOGIC;
            rst : in STD_LOGIC;
            D : in STD_LOGIC_VECTOR (DATA_WIDTH-1 downto 0);
            Q : out STD_LOGIC_VECTOR (DATA_WIDTH-1 downto 0) := (others => '0'));
end component;

begin

    Q_out(DATA_WIDTH-1 downto 0) <= D;
    G: 
        for i in 1 to LENGTH GENERATE
        begin
            U: FF generic map(DATA_WIDTH=>DATA_WIDTH)
                  port map(clk=>clk, rst=>rst, D=>Q_out(DATA_WIDTH * i-1 downto DATA_WIDTH * (i-1)), Q=> Q_out(DATA_WIDTH * (i+1)-1 downto DATA_WIDTH * i));
        end GENERATE;
    Q <= Q_out(DATA_WIDTH * (LENGTH+1)-1 downto DATA_WIDTH * LENGTH);
-- Add your own code here
end Behavioral;