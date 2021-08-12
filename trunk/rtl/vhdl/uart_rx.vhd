----------------------------------------------------------------------------------
-- Company: University of Wuerzburg, Germany
-- Engineer: Stefan Lindoerfer
-- 
-- Create Date: 29.07.2021 10:50
-- Design Name: Receiver for Uart
-- Module Name: uart_rx
-- Project Name: Bachelor Thesis: Implementation of a SpaceWire Router Switch on a FPGA
-- Target Devices: 
-- Tool Versions: based on code from: https://www.nandland.com/vhdl/modules/module-uart-serial-port-rs232.html
-- Description: This file contains the Uart Receiver. It is able to receive 8 bits of serial data,
-- one start bit, one stop bit and no parity bit. When receive is complete uart_rx_dv will be driven
-- 'High' for one clock cycle.
-- Dependencies: none
-- 
-- Revision:
-- Revision 0.1 - Code implementation, formatting, commenting; not yet tested or simulated!
----------------------------------------------------------------------------------

LIBRARY IEEE;
USE IEEE.std_logic_1164.ALL;

ENTITY uart_rx IS
    GENERIC (
        -- frequency clk / frequency Uart
        -- Example: 10 MHz Clock, 115200 baud rate Uart
        -- 10000000 / 115200 = 87
        uart_clk_cycles_per_bit : INTEGER
    );
    PORT (
        -- System clock.
        clk : IN STD_LOGIC;

        -- Incoming data bits.
        uart_rx_serial : IN STD_LOGIC;

        -- 'High' if rx_data containts a valid received byte.
        -- 'Low' when less than 8 bits or nothing was received.
        uart_rx_dv : OUT STD_LOGIC; -- for what?

        -- Received data byte.
        uart_rx_data : OUT STD_LOGIC_VECTOR(7 DOWNTO 0)
    );
END uart_rx;

ARCHITECTURE uart_rx_arch OF uart_rx IS
    -- Finite machine states.
    TYPE state_type IS (S_Idle, S_Rx_Start_Bit, S_Rx_Data_Bits, S_Rx_Stop_Bit, S_Cleanup);

    -- Current state.
    SIGNAL state : state_type := S_Idle;

    -- Data sampling shift register.
    SIGNAL s_rx_data : STD_LOGIC_VECTOR(1 DOWNTO 0) := (OTHERS => '0');

    -- Internal counters.
    SIGNAL s_clk_count : INTEGER RANGE 0 TO (uart_clk_cycles_per_bit - 1) := 0;
    SIGNAL s_bit_index : INTEGER RANGE 0 TO 7 := 0; -- 8 bits total

    -- Initialize outputs with standard values.
    SIGNAL s_rx_byte : STD_LOGIC_VECTOR(7 DOWNTO 0) := (OTHERS => '0');
    SIGNAL s_rx_dv : STD_LOGIC := '0';

BEGIN
    -- Drive other outputs.
    uart_rx_dv <= s_rx_dv;
    uart_rx_data <= s_rx_byte;

    -- Samples incoming data bits into shift register to avoid metastability issues.
    Data_Sampling : PROCESS (clk)
    BEGIN
        IF rising_edge(clk) THEN
            s_rx_data(0) <= uart_rx_serial;
            s_rx_data(1) <= s_rx_data(0);
        END IF;
    END PROCESS;

    -- Finite state machine of receiver.
    FiniteStateMachine : PROCESS (clk)
    BEGIN
        IF rising_edge(clk) THEN
            CASE state IS
                WHEN S_Idle =>
                    s_rx_dv <= '0';
                    s_clk_count <= 0;
                    s_bit_index <= 0;

                    IF (s_rx_data(1) <= '0') THEN -- Start bit detected.
                        state <= S_Rx_Start_Bit;
                    ELSE
                        state <= S_Idle;
                    END IF;

                -- Check middle of start bit to make sure its still low.
                WHEN S_Rx_Start_Bit =>
                    IF s_clk_count = ((uart_clk_cycles_per_bit - 1) / 2) THEN
                        IF (s_rx_data(1) = '0') THEN
                            s_clk_count <= 0; -- reset counter since we found the middle.
                            state <= s_Rx_Data_Bits;
                        ELSE
                            state <= S_Idle;
                        END IF;
                    ELSE
                        s_clk_count <= (s_clk_count + 1);
                        state <= S_Rx_Start_Bit;
                    END IF;

                -- Wait (uart_clk_cycles_per_bit - 1) clock cycles to sample serial data.
                WHEN S_Rx_Data_Bits =>
                    IF (s_clk_count < (uart_clk_cycles_per_bit - 1)) THEN
                        s_clk_count <= (s_clk_count + 1);
                        state <= s_Rx_Data_Bits;
                    ELSE
                        s_clk_count <= 0;
                        s_rx_byte(s_bit_index) <= s_rx_data(1);

                        -- Check if we have send out all bits.
                        IF (s_bit_index < 7) THEN
                            s_bit_index <= (s_bit_index + 1);
                            state <= S_Rx_Start_Bit;
                        ELSE
                            s_bit_index <= 0;
                            state <= S_Rx_Stop_Bit;
                        END IF;
                    END IF;

                -- Receive Stop bit. Stop bit = 1
                WHEN S_Rx_Stop_Bit =>
                    -- Wait (uart_clk_cycles_per_bit - 1) clock cycles for Stop bit to finish.
                    IF (s_clk_count < (uart_clk_cycles_per_bit - 1)) THEN
                        s_clk_count <= (s_clk_count + 1);
                        state <= S_Rx_Stop_Bit;
                    ELSE
                        s_rx_dv <= '1';
                        s_clk_count <= 0;
                        state <= S_Cleanup;
                    END IF;

                -- Stay here for one clock cycle.
                WHEN S_Cleanup =>
                    state <= S_Idle;
                    s_rx_dv <= '0';
            END CASE;
        END IF;
    END PROCESS;
END uart_rx_arch;