----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 28.11.2022 23:37:13
-- Design Name: 
-- Module Name: convert_kb_to_bin - Behavioral
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


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.numeric_Std.all;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity convert_kb_to_bin is
   port(
   key_code: in std_logic_vector(7 downto 0);
   bin: out std_logic_vector(3 downto 0);
   is_hexa_number: out std_logic
);    
end convert_kb_to_bin;

architecture arch of convert_kb_to_bin is
signal bin_and_error: std_logic_vector(4 downto 0);
begin
    with key_code select
        bin_and_error <=
            "00000" when "01000101",
            "00001" when "00010110",
            "00010" when "00011110",
            "00011" when "00100110",
            "00100" when "00100101",
            "00101" when "00101110",
            "00110" when "00110110",
            "00111" when "00111101",
            "01000" when "00111110",
            "01001" when "01000110",
            "01010" when "00011100",
            "01011" when "00110010",
            "01100" when "00100001",
            "01101" when "00100011",
            "01110" when "00100100",
            "01111" when "00101011",
            "10000" when others;
is_hexa_number <= bin_and_error(4);
bin <= bin_and_error( 3 downto 0);
end arch;
