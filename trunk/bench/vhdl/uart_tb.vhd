----------------------------------------------------------------------
-- File Downloaded from http://www.nandland.com
----------------------------------------------------------------------
LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;

ENTITY uart_tb IS
END uart_tb;

ARCHITECTURE behave OF uart_tb IS

    COMPONENT uart_tx IS
        GENERIC (
            uart_clk_cycles_per_bit : INTEGER -- Needs to be set correctly! (See instructions in uart_rx.vhd / uart_tx.vhd)
        );
        PORT (
            clk : IN STD_LOGIC;
            uart_tx_dv : IN STD_LOGIC;
            uart_tx_byte : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
            uart_tx_active : OUT STD_LOGIC;
            uart_tx_serial : OUT STD_LOGIC;
            uart_tx_done : OUT STD_LOGIC
        );
    END COMPONENT uart_tx;

    COMPONENT uart_rx IS
        GENERIC (
            uart_clk_cycles_per_bit : INTEGER -- Needs to be set correctly! (See instructions in uart_rx.vhd / uart_tx.vhd)
        );
        PORT (
            clk : IN STD_LOGIC;
            uart_rx_serial : IN STD_LOGIC;
            uart_rx_dv : OUT STD_LOGIC;
            uart_rx_data : OUT STD_LOGIC_VECTOR(7 DOWNTO 0)
        );
    END COMPONENT uart_rx;
    -- Test Bench uses a 10 MHz Clock
    -- Want to interface to 115200 baud UART
    -- 10000000 / 115200 = 87 Clocks Per Bit.
    CONSTANT c_CLKS_PER_BIT : INTEGER := 87;

    CONSTANT c_BIT_PERIOD : TIME := 8680 ns;

    SIGNAL r_CLOCK : STD_LOGIC := '0';
    SIGNAL r_TX_DV : STD_LOGIC := '0';
    SIGNAL r_TX_BYTE : STD_LOGIC_VECTOR(7 DOWNTO 0) := (OTHERS => '0');
    SIGNAL w_TX_SERIAL : STD_LOGIC;
    SIGNAL w_TX_DONE : STD_LOGIC;
    SIGNAL w_RX_DV : STD_LOGIC;
    SIGNAL w_RX_BYTE : STD_LOGIC_VECTOR(7 DOWNTO 0);
    SIGNAL r_RX_SERIAL : STD_LOGIC := '1';
    -- Low-level byte-write
    PROCEDURE UART_WRITE_BYTE (
        i_data_in : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
        SIGNAL o_serial : OUT STD_LOGIC) IS
    BEGIN

        -- Send Start Bit
        o_serial <= '0';
        WAIT FOR c_BIT_PERIOD;

        -- Send Data Byte
        FOR ii IN 0 TO 7 LOOP
            o_serial <= i_data_in(ii);
            WAIT FOR c_BIT_PERIOD;
        END LOOP; -- ii

        -- Send Stop Bit
        o_serial <= '1';
        WAIT FOR c_BIT_PERIOD;
    END UART_WRITE_BYTE;
BEGIN

    -- Instantiate UART transmitter
    UART_TX_INST : uart_tx
    GENERIC MAP(
        uart_clk_cycles_per_bit => c_CLKS_PER_BIT
    )
    PORT MAP(
        clk => r_CLOCK,
        uart_tx_dv => r_TX_DV,
        uart_tx_byte => r_TX_BYTE,
        uart_tx_active => OPEN,
        uart_tx_serial => w_TX_SERIAL,
        uart_tx_done => w_TX_DONE
    );

    -- Instantiate UART Receiver
    UART_RX_INST : uart_rx
    GENERIC MAP(
        uart_clk_cycles_per_bit => c_CLKS_PER_BIT
    )
    PORT MAP(
        clk => r_CLOCK,
        uart_rx_serial => r_RX_SERIAL,
        uart_rx_dv => w_RX_DV,
        uart_rx_data => w_RX_BYTE
    );

    r_CLOCK <= NOT r_CLOCK AFTER 50 ns;

    PROCESS IS
    BEGIN
        -- Tell the UART to send a command.
        WAIT UNTIL rising_edge(r_CLOCK);
        WAIT UNTIL rising_edge(r_CLOCK);
        r_TX_DV <= '1';
        r_TX_BYTE <= X"AB";
        WAIT UNTIL rising_edge(r_CLOCK);
        r_TX_DV <= '0';
        WAIT UNTIL w_TX_DONE = '1';
        -- Send a command to the UART
        WAIT UNTIL rising_edge(r_CLOCK);
        UART_WRITE_BYTE(X"3F", r_RX_SERIAL);
        WAIT UNTIL rising_edge(r_CLOCK);

        -- Check that the correct command was received
        IF w_RX_BYTE = X"3F" THEN
            REPORT "Test Passed - Correct Byte Received" SEVERITY note;
        ELSE
            REPORT "Test Failed - Incorrect Byte Received" SEVERITY note;
        END IF;

        ASSERT false REPORT "Tests Complete" SEVERITY failure;
    END PROCESS;
END behave;