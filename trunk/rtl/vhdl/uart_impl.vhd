----------------------------------------------------------------------------------
-- Company: University of Wuerzburg, Germany
-- Engineer: Stefan Lindoerfer
-- 
-- Create Date: 02.09.2021 21:00:00
-- Design Name: 
-- Module Name: uart_impl
-- Project Name: Part of Bachelor Thesis: Implementation of a SpaceWire Router on a FPGA.
-- Target Devices: Digilent Basys3
-- Tool Versions: 
-- Description: Sends all through usb-uart received bytes back unchanged.
-- 
-- Dependencies: uart_rx, uart_tx, Basys3.xdc (Constraints)
-- 
-- Revision: 1.0 - Hardware implementation worked as expected.
----------------------------------------------------------------------------------
LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;

ENTITY uart_impl IS
    PORT (
        -- System clock.
        clk : IN STD_LOGIC;

        -- Receiver serial (rx).
        rxstream : IN STD_LOGIC;

        -- Transmitter serial (tx).
        txstream : OUT STD_LOGIC
    );
END uart_impl;

ARCHITECTURE uart_impl_arch OF uart_impl IS
    -- FSM states.
    TYPE implstates IS (S_Idle, S_Send, S_End);
    SIGNAL state : implstates := S_Idle;

    -- Byte which was received and shall be send.
    SIGNAL s_rxdata : STD_LOGIC_VECTOR(7 DOWNTO 0) := (OTHERS => '0');

    -- High if receiver has a new byte.
    SIGNAL s_rxvalid : STD_LOGIC := '0';

    -- High tells transmitter to send byte in s_txdata.
    SIGNAL s_txwrite : STD_LOGIC := '0';

    -- Byte which should be transmitted next.
    SIGNAL s_txdata : STD_LOGIC_VECTOR(7 DOWNTO 0) := (OTHERS => '0');

    -- High if transmitter is active.
    SIGNAL s_txactive : STD_LOGIC := '0';

    -- High if transmitter is done.
    SIGNAL s_txdone : STD_LOGIC := '0';

    -- Uart receiver.
    COMPONENT uart_rx IS
        GENERIC (
            clk_cycles_per_bit : INTEGER
        );
        PORT (
            clk : IN STD_LOGIC; -- System clock.
            rxstream : IN STD_LOGIC; -- Receiver serial (rx)
            rxvalid : OUT STD_LOGIC; -- High if receiver contains valid data
            rxdata : OUT STD_LOGIC_VECTOR(7 DOWNTO 0) -- Received data byte
        );
    END COMPONENT;

    -- Uart transmitter.
    COMPONENT uart_tx IS
        GENERIC (
            clk_cycles_per_bit : INTEGER
        );
        PORT (
            clk : IN STD_LOGIC; -- System clock.
            txwrite : IN STD_LOGIC; -- High if transmitter should start work
            txdata : IN STD_LOGIC_VECTOR(7 DOWNTO 0); -- Data byte to transmit
            txactive : OUT STD_LOGIC; -- Shows if transmitter is active
            txstream : OUT STD_LOGIC; -- Transmitter serial (tx)
            txdone : OUT STD_LOGIC -- High if transmitters work is done
        );
    END COMPONENT;
BEGIN
    -- Receiver module.
    rec : uart_rx GENERIC MAP(clk_cycles_per_bit => 87)
    PORT MAP(
        clk => clk,
        rxstream => rxstream,
        rxvalid => s_rxvalid,
        rxdata => s_rxdata
    );

    -- Transmitter module.
    trans : uart_tx GENERIC MAP(clk_cycles_per_bit => 87)
    PORT MAP(
        clk => clk,
        txwrite => s_txwrite,
        txdata => s_txdata,
        txactive => s_txactive,
        txstream => txstream,
        txdone => s_txdone
    );

    -- Synchronous process.
    fsm : PROCESS (clk)
    BEGIN
        IF rising_edge(clk) THEN
            CASE state IS
                WHEN S_Idle =>
                    -- Watch if receiver has got new byte to send...
                    IF s_rxvalid = '1' THEN
                        -- .. write it into output stream.
                        s_txdata <= s_rxdata;

                        -- Ready for transmitting.
                        state <= S_Send;

                    END IF;

                WHEN S_Send =>
                    -- Check if transmitter is still active...
                    IF s_txactive = '0' THEN
                        -- ... if not, send byte in s_txdata.
                        s_txwrite <= '1';

                        -- Cleanup/Reset state.
                        state <= S_End;

                    END IF;

                WHEN S_End =>
                    -- Withdraw transmitting signal.
                    s_txwrite <= '0';

                    -- Wait in Idle state for next reveived byte.
                    state <= S_Idle;

                WHEN OTHERS => state <= S_Idle;
            END CASE;
        END IF;
    END PROCESS;
END uart_impl_arch;