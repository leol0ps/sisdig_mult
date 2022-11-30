----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 29.11.2022 18:21:50
-- Design Name: 
-- Module Name: bin2ascii - arch
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
use ieee.numeric_std.all;
-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity bin2ascii is
   port (
   bin_code: in std_logic_vector(7 downto 0);
   ascii_H: out std_logic_vector(7 downto 0);
   ascii_L: out std_logic_vector(7 downto 0)
);
end bin2ascii;
architecture arch of bin2ascii is
alias high: std_logic_vector(3 downto 0) is bin_code(7 downto 4);
alias low: std_logic_vector(3 downto 0) is bin_code(3 downto 0);
begin
    with high select 
        ascii_H <=
            "00110000" when "0000",  -- 0
            "00110001" when "0001",  -- 1
            "00110010" when "0010",  -- 2
            "00110011" when "0011",  -- 3
            "00110100" when "0100",  -- 4
            "00110101" when "0101",  -- 5
            "00110110" when "0110",  -- 6
            "00110111" when "0111",  -- 7
            "00111000" when "1000",  -- 8
            "00111001" when "1001",  -- 9
    
            "01000001" when "1010",  -- A
            "01000010" when "1011",  -- B
            "01000011" when "1100",  -- C
            "01000100" when "1101",  -- D
            "01000101" when "1110",  -- E
            "01000110" when others;  -- F 
     with low select
        ascii_L <=
            "00110000" when "0000",  -- 0
            "00110001" when "0001",  -- 1
            "00110010" when "0010",  -- 2
            "00110011" when "0011",  -- 3
            "00110100" when "0100",  -- 4
            "00110101" when "0101",  -- 5
            "00110110" when "0110",  -- 6
            "00110111" when "0111",  -- 7
            "00111000" when "1000",  -- 8
            "00111001" when "1001",  -- 9
    
            "01000001" when "1010",  -- A
            "01000010" when "1011",  -- B
            "01000011" when "1100",  -- C
            "01000100" when "1101",  -- D
            "01000101" when "1110",  -- E
            "01000110" when others;  -- F                        
end arch;
