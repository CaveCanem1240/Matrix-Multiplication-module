library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use IEEE.STD_LOGIC_TEXTIO.ALL;
use STD.TEXTIO.ALL;

-- Use the libraries you need

library work;
use work.util_package.ALL;

entity test_systolic is
	Generic(
        MAT_A_ROWS : POSITIVE := MAT_A_ROWS_VALUE;
        MAT_LENGTH : POSITIVE := MAT_LENGTH_VALUE;
        MAT_B_COLS : POSITIVE := MAT_B_COLS_VALUE;
        ARRAY_SIZE : POSITIVE := ARRAY_SIZE_VALUE;
        INPUT_WIDTH : POSITIVE := INPUT_WIDTH_VALUE;
        RAND_SEED_A : POSITIVE := RAND_SEED_A_VALUE;
        RAND_SEED_B : POSITIVE := RAND_SEED_B_VALUE;
        SAMPLE_NUM : POSITIVE := SAMPLE_NUM_VALUE;
        VALID_KIND : POSITIVE := get_valid_kind(ARRAY_SIZE, MAT_LENGTH);
        OUTPUT_WIDTH : POSITIVE := INPUT_WIDTH*2 + clog2(MAT_LENGTH));
--  Port ( );
end test_systolic;

architecture Behavioral of test_systolic is
    component systolic is
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
            input_done : out STD_LOGIC := '0');
    end component;

    signal clk_sig: STD_LOGIC := '0';
    signal rst_sig: STD_LOGIC := '1';
    
    type InputLineType is array(natural range <>) of STD_LOGIC_VECTOR(INPUT_WIDTH-1 downto 0);
    type InputMatrixAType is array(0 to MAT_A_ROWS-1) of InputLineType(0 to MAT_LENGTH-1);
    type InputMatrixBType is array(0 to MAT_LENGTH-1) of InputLineType(0 to MAT_B_COLS-1);

    signal matrix_A: InputMatrixAType := (others => (others => (others => '0')));
    signal matrix_B: InputMatrixBType := (others => (others => (others => '0')));

    type OutputLineType is array(natural range <>) of STD_LOGIC_VECTOR(OUTPUT_WIDTH-1 downto 0);
    type OutputMatrixType is array(0 to MAT_A_ROWS-1) of OutputLineType(0 to MAT_B_COLS-1);
    type OutputMatrixListType is array(0 to VALID_KIND-1) of OutputMatrixType;

    signal matrix_D: OutputMatrixType := (others => (others => (others => '0')));
    signal reference_D: OutputMatrixListType := (others => (others => (others => (others => '0'))));

    signal read_address_A_sig: STD_LOGIC_VECTOR (clog2(MAT_A_ROWS * MAT_LENGTH)-1 downto 0) := (others => '0');
    signal read_address_B_sig: STD_LOGIC_VECTOR (clog2(MAT_LENGTH * MAT_B_COLS)-1 downto 0) := (others => '0');
    
    signal input_A_sig: STD_LOGIC_VECTOR(INPUT_WIDTH * ARRAY_SIZE-1 downto 0) := (others => '0');
    signal input_B_sig: STD_LOGIC_VECTOR(INPUT_WIDTH * ARRAY_SIZE-1 downto 0) := (others => '0');
    
    signal matrix_in_done_sig: STD_LOGIC := '0';
    signal matrix_out_done_sig: STD_LOGIC := '0';

-- Add your own code here
begin

    clock_generate: process
    begin
        wait for 5 ns;
        clk_sig <= not clk_sig;
    end process clock_generate;

    rst_generate: process
    begin
        wait for 20 ns;
        rst_sig <= '0';
        wait;
    end process;

    uut:systolic
    Generic map (
        MAT_A_ROWS => MAT_A_ROWS,
        MAT_LENGTH => MAT_LENGTH,
        MAT_B_COLS => MAT_B_COLS,
        ARRAY_SIZE => ARRAY_SIZE,
        INPUT_WIDTH => INPUT_WIDTH,
        VALID_KIND => VALID_KIND,
        OUTPUT_WIDTH => OUTPUT_WIDTH)
    Port map (
        clk => clk_sig,
        rst => rst_sig,
        read_address_A => read_address_A_sig,
        read_address_B => read_address_B_sig,
        A => input_A_sig,
        B => input_B_sig,
        D => /* Your signal here */,
        valid_D => /* Your signal here */,
        input_done => matrix_in_done_sig); -- uut

    read_input: process
        FILE file_in: text;
        variable file_status: file_open_status;
        variable buf: line;
        variable data: STD_LOGIC_VECTOR(INPUT_WIDTH-1 downto 0);
    begin
        file_open(file_status, file_in, "testcase.txt", read_mode);

        for matrix_index in 0 to SAMPLE_NUM - 1 loop
            readline(file_in, buf);
            for length in 0 to MAT_LENGTH - 1 loop
                for row in 0 to MAT_A_ROWS - 1 loop
                    read(buf, data);
                    matrix_A(row)(length) <= data;
                end loop;
                for col in 0 to MAT_B_COLS - 1 loop
                    read(buf, data);
                    matrix_B(length)(col) <= data;
                end loop;
            end loop;
            wait until falling_edge(matrix_in_done_sig);
        end loop;
        wait;
    end process read_input;

    send_input: process(matrix_A, matrix_B, read_address_A_sig, read_address_B_sig)
        variable address_A: integer range 0 to MAT_A_ROWS*MAT_LENGTH-1;
        variable address_B: integer range 0 to MAT_LENGTH*MAT_B_COLS-1;
        variable row_A: integer range 0 to MAT_A_ROWS-1;
        variable col_A: integer range 0 to MAT_LENGTH-1;
        variable row_B: integer range 0 to MAT_LENGTH-1;
        variable col_B: integer range 0 to MAT_B_COLS-1;
    begin
        address_A := to_integer(unsigned(read_address_A_sig));
        row_A := address_A / MAT_LENGTH;
        col_A := address_A mod MAT_LENGTH;

        address_B := to_integer(unsigned(read_address_B_sig));
        row_B := address_B / MAT_B_COLS;
        col_B := address_B mod MAT_B_COLS;

        for idx in 0 to ARRAY_SIZE - 1 loop
            input_A_sig(INPUT_WIDTH*(idx+1)-1 downto INPUT_WIDTH*idx) <= matrix_A(row_A + idx)(col_A);
            input_B_sig(INPUT_WIDTH*(idx+1)-1 downto INPUT_WIDTH*idx) <= matrix_B(row_B)(col_B + idx);
        end loop;
    end process send_input;

-- Add your own code here

    save_result: process
        file file_out: TEXT;
        variable file_status: file_open_status;
        variable buf: LINE;
    begin
        file_open(file_out, "output.txt", write_mode);
        for matrix_index in 0 to SAMPLE_NUM - 1 loop
            wait until rising_edge(matrix_out_done_sig);
            for row in 0 to MAT_A_ROWS - 1 loop
                for col in 0 to MAT_B_COLS - 1 loop
                    write(buf, matrix_D(row)(col));
                end loop;
            end loop;
            writeline(file_out,buf);
        end loop;
        file_close(file_out);
        
        wait;
    end process save_result;

    check_result: process
        file file_out: TEXT;
        variable file_status: file_open_status;
        variable buf: LINE;
        variable is_right: STD_LOGIC;
    begin
        file_open(file_out, "result.txt", write_mode);
        for matrix_index in 0 to SAMPLE_NUM - 1 loop
            wait until rising_edge(matrix_out_done_sig);
            for row in 0 to MAT_A_ROWS - 1 loop
                for col in 0 to MAT_B_COLS - 1 loop
                    if matrix_D(row)(col) /= reference_D(matrix_index mod VALID_KIND)(row)(col) then
                        is_right := '0';
                    else
                        is_right := '1';
                    end if;
                    write(buf, is_right);
                end loop;
            end loop;
            writeline(file_out,buf);
        end loop;
        file_close(file_out);

        wait until falling_edge(clk_sig);
        std.env.finish;
    end process check_result;

end architecture;