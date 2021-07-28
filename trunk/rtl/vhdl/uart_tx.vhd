LIBRARY library IEEE;
USE IEEE.std_logic_1164.ALL;

ENTITY uart_tx IS
    GENERIC (
        -- siehe receiver!
        clk_cycles_per_bit : INTEGER
    );
    PORT (
        -- System clock.
        clk : IN STD_LOGIC;

        -- 
        tx_dv : IN STD_LOGIC;
        tx_byte : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
        tx_active : OUT STD_LOGIC;
        tx_serial : OUT STD_LOGIC;
        tx_done : OUT STD_LOGIC
    );
END uart_tx;

ARCHITECTURE uart_tx_arch OF uart_tx IS

    -- Machine states.
    TYPE state_type IS (S_Idle, S_Tx_Start_Bit, s_Tx_Data_Bits, S_Tx_Stop_Bit, S_Cleanup);

    -- Current state.
    SIGNAL state : state_type := S_Idle;

    SIGNAL s_clk_count : INTEGER RANGE 0 TO clk_cycles_per_bit - 1 := 0;

    SIGNAL s_bit_index : INTEGER RANGE 0 TO 7 := 0; -- 8 Bits total

    SIGNAL s_tx_data : STD_ULOGIC_VECTOR(7 DOWNTO 0) := (OTHERS => '0');

    SIGNAL s_tx_done : STD_ULOGIC := '0';
BEGIN

    PROCESS (clk)
        IF rising_edge(clk) THEN
            CASE state IS
                WHEN S_Idle =>
                    tx_active <= '0';
                    tx_serial <= '1'; -- Drive Line High for Idle
                    tx_done <= '0';
                    s_clk_count <= 0;
                    s_bit_index <= 0;

                    IF tx_dv = '1' THEN
                        s_tx_data <= tx_byte;
                        state <= S_Tx_Start_Bit;
                    ELSE
                        state <= S_Idle;
                    END IF;

                    -- Send out Start Bit. Start bit = 0
                WHEN S_Tx_Start_Bit =>
                    tx_active <= '1';
                    tx_serial <= '0';

                    -- Wait clk_cycles_per_bit-1 clock cycles for start bit to finish
                    IF s_clk_count < clk_cycles_per_bit - 1 THEN
                        s_clk_count <= s_clk_count + 1;
                        state <= S_Tx_Start_Bit;
                    ELSE
                        s_clk_count <= 0;
                        state <= s_Tx_Data_Bits;
                    END IF;

                    -- Wait clk_cycles_per_bit-1 clock cycles for data bits to finish
                WHEN s_Tx_Data_Bits =>
                    tx_serial <= s_tx_data(s_bit_index);

                    IF s_clk_count < clk_cycles_per_bit - 1 THEN
                        s_clk_count <= s_clk_count + 1;
                        state <= s_Tx_Data_Bits;
                    ELSE
                        s_clk_count <= 0;

                        -- Check if we have sent out all bits
                        IF s_bit_index < 7 THEN
                            s_bit_index <= s_bit_index + 1;
                            state <= s_Tx_Data_Bits;
                        ELSE
                            s_bit_index <= 0;
                            state <= S_Tx_Stop_Bit;
                        END IF;
                    END IF;

                    -- Send out Stop bit. Stop bit = 1
                WHEN S_Tx_Stop_Bit =>
                    tx_serial <= '1';

                    -- Wait clk_cycles_per_bit-1 clock cycles for Stop bit to finish
                    IF s_clk_count < clk_cycles_per_bit - 1 THEN
                        s_clk_count <= s_clk_count + 1;
                        state <= S_Tx_Stop_Bit;
                    ELSE
                        tx_done <= '1';
                        s_clk_count <= '0';
                        state <= S_Cleanup;
                    END IF;

                    -- Stay here for 1 clk cycle
                WHEN S_Cleanup =>
                    tx_active <= '0';
                    tx_done <= '1';
                    state <= S_Idle;

                WHEN OTHERS =>
                    state <= S_Idle;

            END CASE;
        END IF;
    END PROCESS;

    -- drive other outputs.
    tx_done <= s_tx_done;
END uart_tx_arch;