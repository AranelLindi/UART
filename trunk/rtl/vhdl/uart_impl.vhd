----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 12.08.2021 21:41:36
-- Design Name: 
-- Module Name: uart_impl - Behavioral
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
-- Description: 
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------
LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

ENTITY uart_impl IS
    PORT (
        -- System clock.
        clk : IN STD_LOGIC;

        -- Receiver.
        rx : IN STD_LOGIC;

        -- Transmitter.
        tx : OUT STD_LOGIC
    );
END uart_impl;

ARCHITECTURE Behavioral OF uart_impl IS
    -- Byte which was received and shall be send.
    SIGNAL s_byte : STD_LOGIC_VECTOR(7 DOWNTO 0);

    -- Valid byte was received and transmitter should start.
    SIGNAL s_dv : STD_LOGIC;

    -- High if transmitter is active.
    SIGNAL s_tx_act : STD_LOGIC;

    -- High if transmitter is done.
    SIGNAL s_tx_done : STD_LOGIC;
    COMPONENT uart_rx IS
        GENERIC (
            uart_clk_cycles_per_bit : INTEGER
        );
        PORT (
            clk : IN STD_LOGIC;
            uart_rx_serial : IN STD_LOGIC;
            uart_rx_dv : OUT STD_LOGIC;
            uart_rx_data : OUT STD_LOGIC_VECTOR(7 DOWNTO 0)
        );
    END COMPONENT;

    COMPONENT uart_tx IS
        GENERIC (
            uart_clk_cycles_per_bit : INTEGER
        );
        PORT (
            clk : IN STD_LOGIC;
            uart_tx_dv : IN STD_LOGIC;
            uart_tx_byte : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
            uart_tx_active : OUT STD_LOGIC;
            uart_tx_serial : OUT STD_LOGIC;
            uart_tx_done : OUT STD_LOGIC
        );
    END COMPONENT;
BEGIN
    -- Receiver module.
    rec : uart_rx GENERIC MAP(uart_clk_cycles_per_bit => 87)
    PORT MAP(
        clk => clk,
        uart_rx_serial => rx,
        uart_rx_dv => s_dv,
        uart_rx_data => s_byte
    );

    -- Transmitter module.
    trans : uart_tx GENERIC MAP(uart_clk_cycles_per_bit => 87)
    PORT MAP(
        clk => clk,
        uart_tx_dv => s_dv,
        uart_tx_byte => s_byte,
        uart_tx_active => s_tx_act,
        uart_tx_serial => tx,
        uart_tx_done => s_tx_done
    );
END Behavioral;