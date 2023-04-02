library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

-- Use the libraries you need

library work;
use work.util_package.ALL;

entity systolic is
    Generic ( 
        MAT_A_ROWS : POSITIVE := 4;
        MAT_LENGTH : POSITIVE := 4;
        MAT_B_COLS : POSITIVE := 4;
        ARRAY_SIZE : POSITIVE := 4;
        INPUT_WIDTH : POSITIVE := 8;
        VALID_KIND : POSITIVE := get_valid_kind(ARRAY_SIZE, MAT_LENGTH);
        OUTPUT_WIDTH : POSITIVE := INPUT_WIDTH*2 + clog2(MAT_LENGTH));
    Port ( 
        clk : in STD_LOGIC;
        rst : in STD_LOGIC;
        read_address_A : out STD_LOGIC_VECTOR (clog2(MAT_A_ROWS * MAT_LENGTH)-1 downto 0) := (others => '0');
        read_address_B : out STD_LOGIC_VECTOR (clog2(MAT_LENGTH * MAT_B_COLS)-1 downto 0) := (others => '0');
        A : in STD_LOGIC_VECTOR (INPUT_WIDTH * ARRAY_SIZE-1 downto 0);
        B : in STD_LOGIC_VECTOR (INPUT_WIDTH * ARRAY_SIZE-1 downto 0);
        D : out STD_LOGIC_VECTOR (OUTPUT_WIDTH * (ARRAY_SIZE**2)-1 downto 0) := (others => '0');
        valid_D : out STD_LOGIC_VECTOR (clog2(VALID_KIND+1) * (ARRAY_SIZE**2)-1 downto 0) := (others => '0');
        --valid_D : out STD_LOGIC_VECTOR (clog2(SAMPLE_NUM+1) * (ARRAY_SIZE**2)-1 downto 0) := (others => '0');
        input_done : out STD_LOGIC := '0');
end systolic;

architecture Behavioral of systolic is

    component counter
        Generic ( 
            WIDTH : POSITIVE := 32;
            HEIGHT : POSITIVE := 32);
        Port ( 
            clk : in STD_LOGIC;
            rst : in STD_LOGIC;
            enable_row_count : in STD_LOGIC;
            pixel_cntr : out STD_LOGIC_VECTOR (clog2(WIDTH)-1 downto 0) := (others => '0');
            slice_cntr : out STD_LOGIC_VECTOR (clog2(HEIGHT)-1 downto 0) := (others => '0'));
    end component;

    component pipe is
        Generic(
            DATA_WIDTH : POSITIVE := 8;
            LENGTH : POSITIVE := 10);  
        Port ( 
            clk : in STD_LOGIC;
            rst : in STD_LOGIC;
            D : in STD_LOGIC_VECTOR (DATA_WIDTH-1 downto 0);
            Q : out STD_LOGIC_VECTOR (DATA_WIDTH-1 downto 0) := (others => '0'));
    end component;

    component pe
        Generic ( 
            MAT_LENGTH : POSITIVE := 32;
            INPUT_WIDTH : POSITIVE := 8;
            OUTPUT_WIDTH : POSITIVE := INPUT_WIDTH*2 + clog2(MAT_LENGTH));
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
    end component;
    
-- Add your own code here
    type pe_signal_2d is array (ARRAY_SIZE downto 0) of std_logic_vector(INPUT_WIDTH-1 downto 0);
    type pe_signal_3d is array (ARRAY_SIZE downto 0) of pe_signal_2d;
    signal pe_vector_a,pe_vector_b : pe_signal_3d;
    type sum_signal_2d is array (ARRAY_SIZE downto 0) of std_logic_vector(OUTPUT_WIDTH-1 downto 0);
    type sum_signal_3d is array (ARRAY_SIZE downto 0) of sum_signal_2d;
    signal sum_vector : STD_LOGIC_VECTOR (OUTPUT_WIDTH * (ARRAY_SIZE**2)-1 downto 0) := (others => '0');
    type array_signal is array (ARRAY_SIZE-1 downto 0) of std_logic_vector(ARRAY_SIZE-1 downto 0);
    signal init_vector,valid_vector : array_signal:=(others => (others => '0'));
begin
    
    pe_array_x:
    for i in 0 to ARRAY_SIZE-1 GENERATE
        pe_array_y:
        for j in 0 to ARRAY_SIZE-1 GENERATE
        begin
            pe_unit:
            pe generic map(MAT_LENGTH=>MAT_LENGTH,INPUT_WIDTH=>INPUT_WIDTH,OUTPUT_WIDTH=>OUTPUT_WIDTH)
               port map(clk=>clk, rst=>rst, init=>init_vector(i)(j),in_a=>pe_vector_a(i)(j),in_b=>pe_vector_b(i)(j),out_sum=>D(OUTPUT_WIDTH * (i*ARRAY_SIZE+j+1)-1 downto OUTPUT_WIDTH * (i*ARRAY_SIZE+j)),valid_sum=>valid_vector(i)(j),out_a=>pe_vector_a(i)(j+1),out_b=>pe_vector_b(i+1)(j));
        end GENERATE;
    end GENERATE;
    pe00:
    pe_vector_a(0)(0)<=A(INPUT_WIDTH-1 downto 0);
    pe_vector_b(0)(0)<=B(INPUT_WIDTH-1 downto 0);
    pe_pipe:
    for i in 1 to ARRAY_SIZE-1 GENERATE
    begin
        pipe_a_unit:
        pipe generic map(DATA_WIDTH =>INPUT_WIDTH, LENGTH => i)
             port map(clk=>clk, rst=>rst,D=>A(INPUT_WIDTH*(i+1)-1 downto INPUT_WIDTH*i),Q=>pe_vector_a(i)(0));
        pipe_b_unit:
        pipe generic map(DATA_WIDTH =>INPUT_WIDTH, LENGTH => i)
             port map(clk=>clk, rst=>rst,D=>B(INPUT_WIDTH*(i+1)-1 downto INPUT_WIDTH*i),Q=>pe_vector_b(0)(i));
    end GENERATE;
    
    address:
    process(clk,rst)
    variable address_digt : integer:=clog2(MAT_A_ROWS * MAT_LENGTH);
    variable ind : integer:=0;
    variable next_init_vector : array_signal:=(others => (others => '0'));
    begin
    
        if rst = '1' then
            read_address_A <= (others => '0');
            read_address_B <= (others => '0');
            ind := 0;
            input_done <= '0';
        elsif rising_edge(clk) then
            input_done <= '0';
            read_address_A <= STD_LOGIC_VECTOR(TO_UNSIGNED(MAT_LENGTH -ind-1,address_digt));
            read_address_B <= STD_LOGIC_VECTOR(TO_UNSIGNED((MAT_LENGTH -ind-1)*MAT_LENGTH,address_digt));
            for i in ARRAY_SIZE-1 downto 0 loop
                for j in ARRAY_SIZE-1 downto 0 loop
                    if init_vector(i)(j) = '1' then
                        next_init_vector(i)(j) := '0';
                        if i+1 <= ARRAY_SIZE-1 then
                            next_init_vector(i+1)(j) := '1';
                        end if;
                        if j+1 <= ARRAY_SIZE-1 then
                            next_init_vector(i)(j+1) := '1';
                        end if;
                    end if;
                end loop;
            end loop;
            if ind = 0 then
                next_init_vector(0)(0) := '1';
            else
                next_init_vector(0)(0) := '0';
            end if;
            init_vector <= next_init_vector;
            ind := ind + 1;
            if ind = MAT_LENGTH then
                ind := 0;
                input_done <= '1';
            end if;
        end if;
    end process;
    
    process(valid_vector,rst)
    variable valid_D_size : integer := clog2(VALID_KIND+1);
    type valid_D_signal_2d is array (ARRAY_SIZE downto 0) of integer;
    type valid_D_signal_3d is array (ARRAY_SIZE downto 0) of valid_D_signal_2d;
    variable valid_D_array : valid_D_signal_3d:=(others => (others => 0));
    variable final_D : STD_LOGIC_VECTOR (OUTPUT_WIDTH * (ARRAY_SIZE**2)-1 downto 0) := (others => '0');
    begin
        if rst = '1' then
            valid_D_array :=(others => (others => 0));
        else
            for i in ARRAY_SIZE-1 downto 0 loop
                for j in ARRAY_SIZE-1 downto 0 loop
                    if valid_vector(i)(j) = '0' then
                        valid_D((j+i*ARRAY_SIZE+1)*valid_D_size-1 downto (j+i*ARRAY_SIZE)*valid_D_size) <= STD_LOGIC_VECTOR(TO_UNSIGNED(0,valid_D_size));
                    elsif valid_vector(i)(j) = '1' then
                        valid_D_array(i)(j) := valid_D_array(i)(j) +1;
                        if valid_D_array(i)(j) = VALID_KIND+1 then
                            valid_D_array(i)(j) := 1;
                        end if;
                        valid_D((j+i*ARRAY_SIZE+1)*valid_D_size-1 downto (j+i*ARRAY_SIZE)*valid_D_size) <= STD_LOGIC_VECTOR(TO_UNSIGNED(valid_D_array(i)(j),valid_D_size));
                    end if;
                   
                end loop;
            end loop;
        end if;
    end process;
-- Add your own code here
end Behavioral;
