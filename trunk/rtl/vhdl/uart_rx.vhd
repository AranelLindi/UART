LIBRARY library IEEE;
USE IEEE.std_logic_1164.ALL;

ENTITY uart_rx IS
    GENERIC (
        -- frequency clk / frequency Uart
        -- example: 10 MHz Clock, 115200 baud Uart
        -- (10^7) / 115200 = 87
        clk_cycles_per_bit : INTEGER
    );
    PORT (
        -- System clock.
        clk : IN STD_LOGIC;

        --
        rx_serial : IN STD_LOGIC; -- for what?

        --
        rx_dv : OUT STD_LOGIC; -- for what?

        --
        rx_data : OUT STD_LOGIC_VECTOR(7 DOWNTO 0)
    );
END uart_rx;

ARCHITECTURE uart_rx_arch OF uart_rx IS

    -- Machine states.
    TYPE state_type IS (S_Idle, S_Rx_Start_Bit, s_Rx_Data_Bits, S_Rx_Stop_Bit, S_Cleanup);

    -- Current state.
    SIGNAL state : state_type := S_Idle;

    -- Data sampling shift register
    SIGNAL s_rx_data : STD_ULOGIC_VECTOR(1 DOWNTO 0);

    SIGNAL s_clk_count : INTEGER RANGE 0 TO clk_cycles_per_bit - 1 := 0; -- for what?
    SIGNAL s_bit_index : INTEGER RANGE 0 TO 7 := 0; -- 8 bits total
    SIGNAL s_rx_byte : STD_ULOGIC_VECTOR(7 DOWNTO 0) := (OTHERS => '0'); -- for what?
    SIGNAL s_rx_dv : STD_ULOGIC := '0';

BEGIN
    -- Samples incoming data bits into shift register to avoid metastability issues.
    data_sampling : PROCESS (clk)
    BEGIN
        IF rising_edge(clk) THEN
            s_rx_data(0) <= rx_serial;
            s_rx_data(1) <= s_rx_data(0);
        END IF;
    END PROCESS;

    FSM : PROCESS (clk)
    BEGIN
        IF rising_edge(clk) THEN
            CASE state IS
                WHEN S_Idle =>
                    s_rx_dv <= '0';
                    s_clk_count <= '0';
                    s_bit_index <= '0';

                    IF s_rx_data(1) <= '0' THEN -- Start bit detected.
                        state <= S_Rx_Start_Bit;
                    ELSE
                        state <= S_Idle;
                    END IF;

                    -- Check mittle of start bit to make sure its still low
                WHEN S_Rx_Start_Bit =>
                    IF s_clk_count = (clk_cycles_per_bit - 1) / 2 THEN
                        IF s_rx_data(1) = '0' THEN
                            s_clk_count <= '0'; -- reset counter since we found the middle
                            state <= s_Rx_Data_Bits;
                        ELSE
                            state <= S_Idle;
                        END IF;
                    ELSE
                        s_clk_count <= s_clk_count + 1;
                        state <= S_Rx_Start_Bit;
                    END IF;

                    -- Wait clk_cycles_per_bit-1 clock cycles to sample serial data
                WHEN s_Rx_Data_Bits =>
                    IF s_clk_count < clk_cycles_per_bit - 1 THEN
                        s_clk_count <= s_clk_count + 1;
                        state <= s_Rx_Data_Bits;
                    ELSE
                        s_clk_count <= '0';
                        s_rx_byte(s_bit_index) <= s_rx_data(1);

                        -- Check if we have send out all bits
                        IF s_bit_index < 7 THEN
                            s_bit_index <= s_bit_index + 1;
                            state <= S_Rx_Start_Bits;
                        ELSE
                            s_bit_index <= '0';
                            state <= S_Rx_Stop_Bit;
                        END IF;
                    END IF;

                    -- Receive Stop bit. Stop bit = 1
                WHEN S_Rx_Stop_Bit =>
                    -- Wait clk_cycles_per_bit-1 clock cycles for Stop bit to finish
                    IF s_clk_count < clk_cycles_per_bit THEN
                        s_clk_count <= s_clk_count + 1;
                        state <= S_Rx_Stop_Bit;
                    ELSE
                        s_rx_dv <= '1';
                        s_clk_count <= '0';
                        state <= S_Cleanup;
                    END IF;

                    -- Stay here for one clock cycle
                WHEN S_Cleanup =>
                    state <= S_Idle;
                    s_rx_dv <= '0';

                WHEN OTHERS =>
                    state <= S_Idle;

            END CASE;
        END IF;
    END PROCESS;

    -- drive other outputs.
    rx_dv <= s_rx_dv;
    rx_data <= s_rx_byte;
END uart_rx_arch;