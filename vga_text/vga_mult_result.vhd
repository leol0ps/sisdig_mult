-- Listing 13.6
library ieee;
use ieee.std_logic_1164.ALL;
use ieee.numeric_std.ALL;
entity vga_mult_result is
   port(
      clk, reset: in std_logic;
      pixel_x, pixel_y: in std_logic_vector(9 downto 0);
      a_bcd1,a_bcd0,b_bcd1,b_bcd0, p_bcd3,p_bcd2,p_bcd1,p_bcd0: in std_logic_vector(3 downto 0);
      ball: in std_logic_vector(1 downto 0);
      text_on: out std_logic_vector(3 downto 0);
      text_rgb: out std_logic_vector(11 downto 0)--modificado
   );
end vga_mult_result;

architecture arch of vga_mult_result is
   signal pix_x, pix_y: unsigned(9 downto 0);
   signal new_x,new_x2: unsigned (4 downto 0);
   signal rom_addr: std_logic_vector(10 downto 0);
   signal char_addr, char_addr_s, char_addr_l, char_addr_r, char_addr_p,
          char_addr_o: std_logic_vector(6 downto 0);
   signal row_addr, row_addr_s, row_addr_l,row_addr_r, row_addr_p,
          row_addr_o: std_logic_vector(3 downto 0);
   signal bit_addr, bit_addr_s, bit_addr_l,bit_addr_r,bit_addr_p,
          bit_addr_o: std_logic_vector(2 downto 0);
   signal font_word: std_logic_vector(7 downto 0);
   signal font_bit: std_logic;
   signal score_on, logo_on, rule_on, over_on,produto_on: std_logic;
   signal rule_rom_addr: unsigned(5 downto 0);
   type rule_rom_type is array (0 to 63) of
       std_logic_vector (6 downto 0);
begin
   pix_x <= unsigned(pixel_x);
   pix_y <= unsigned(pixel_y);
   -- instantiate font rom
   font_unit: entity work.font_rom
      port map(clk=>clk, addr=>rom_addr, data=>font_word);

 
   new_x <= pix_x(8 downto 4) - 7;
   score_on <=
--      '1' when pix_y(9 downto 5)=7 and
--               pix_x(9 downto 4)>7 and pix_x(9 downto 4)<32  else
--      '0';
         '1' when pix_y(9 downto 5)=7 and
               pix_x(9 downto 4)>6 and pix_x(9 downto 4)<28  else
         '0';
   row_addr_s <= std_logic_vector(pix_y(4 downto 1));
   bit_addr_s <= std_logic_vector(pix_x(3 downto 1));
   with new_x select
     char_addr_s <=
 	"1100001" when "00000", -- a
     "0111101" when "00001",-- =
     "011" & a_bcd1 when "00011", -- dig a 10
     "011" & a_bcd0 when "00100", -- dig a 1
     "0000000" when "00101", --
     "1100010" when "00110", -- b
     "0111101" when "00111",-- =
     "011" & b_bcd1 when "01000", -- dig b 10
     "011" & b_bcd0 when "01001", -- dig b 1
       "0000000" when "01010", --
       "1110000" when "01011", -- p
       "0111101" when "01100",-- = ATÉ AQUI NA ORDEM
       "1100001" when "01101", -- a
       "0101010" when "01110", -- *
       "1100010" when "01111", -- b
         "0111101" when "10000",-- =
         "011" & p_bcd3 when "10001", -- dig p 1000
         "011" & p_bcd2 when "10010", -- dig p 100
         "011" & p_bcd1 when "10011", -- dig p 10
         "011" & p_bcd0 when "10100", -- dig p 1
         "0000000" when others;
   process(score_on,logo_on,rule_on,pix_x,pix_y,font_bit,
           char_addr_s,char_addr_l,char_addr_r,char_addr_p,
           row_addr_s,row_addr_l,row_addr_r,row_addr_p,
           bit_addr_s,bit_addr_l,bit_addr_r,bit_addr_p)
   begin
		--modificado
      text_rgb <= "000000001111";  -- background, yellow
      if score_on='1' then
         char_addr <= char_addr_s;
         row_addr <= row_addr_s;
         bit_addr <= bit_addr_s;
         if font_bit='1' then
            text_rgb <= "111111111111";
         end if;
      end if;
   end process;
   logo_on <='0';
   rule_on <= '0';
   over_on <= '0';
   text_on <= score_on & logo_on & rule_on & over_on ;
   ---------------------------------------------
   -- font rom interface
   ---------------------------------------------
   rom_addr <= char_addr & row_addr;
   font_bit <= font_word(to_integer(unsigned(not bit_addr)));
end arch;