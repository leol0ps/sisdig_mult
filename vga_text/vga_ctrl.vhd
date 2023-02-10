-- Listing 13.10
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
entity vga_ctrl is
   port(
      clk, reset: in std_logic;
      hsync, vsync: out std_logic;
      rgb: out   std_logic_vector (11 downto 0)--modificado
   );
end vga_ctrl;

architecture arch of vga_ctrl is
   type state_type is (newgame, play, newball, over);
   signal video_on, pixel_tick: std_logic;
   signal pixel_x, pixel_y: std_logic_vector (9 downto 0);
   signal graph_on, gra_still, hit, miss: std_logic;
   signal text_on: std_logic_vector(3 downto 0);
   signal graph_rgb, text_rgb: std_logic_vector(11 downto 0);--modificado
   signal rgb_reg, rgb_next: std_logic_vector(11 downto 0);--modificado
   signal state_reg, state_next: state_type;
   signal dig0, dig1: std_logic_vector(3 downto 0);
   signal d_inc, d_clr: std_logic;
   signal timer_tick, timer_start, timer_up: std_logic;
   signal ball_reg, ball_next: unsigned(1 downto 0);
   signal ball: std_logic_vector(1 downto 0);
begin
   -- instantiate video synchonization unit
   vga_sync_unit: entity work.vga_sync
      port map(clk=>clk, reset=>reset,
               hsync=>hsync, vsync=>vsync,
               pixel_x=>pixel_x, pixel_y=>pixel_y,
               video_on=>video_on, p_tick=>pixel_tick);
   -- instantiate text module
   ball <= std_logic_vector(ball_reg);  --type conversion
   text_unit: entity work.vga_mult_result
      port map(clk=>clk, reset=>reset,
               pixel_x=>pixel_x, pixel_y=>pixel_y,
               a_bcd0=>dig0, a_bcd1=>dig1,b_bcd0 =>dig0,b_bcd1 => dig1,p_bcd3 => dig0,p_bcd2 => dig1,p_bcd1 => dig0,p_bcd0 => dig1, ball=>ball,
               text_on=>text_on, text_rgb=>text_rgb);

   -- instantiate 2 sec timer
   timer_tick <=  -- 60 Hz tick
      '1' when pixel_x="0000000000" and
               pixel_y="0000000000" else
      '0';
   -- registers
   process (clk,reset)
   begin
      if reset='1' then
         state_reg <= newgame;
         ball_reg <= (others=>'0');
         rgb_reg <= (others=>'0');
      elsif (clk'event and clk='1') then
         state_reg <= state_next;
         ball_reg <= ball_next;
         if (pixel_tick='1') then
           rgb_reg <= rgb_next;
         end if;
      end if;
   end process;
   -- fsmd next-state logic
   -- rgb multiplexing circuit
   process(state_reg,video_on,graph_on,graph_rgb,
           text_on,text_rgb)
   begin
      if video_on='0' then
		--modificado
         rgb_next <= "000000000000"; -- blank the edge/retrace
      else
         -- display score, rule or game over
         if (text_on(3)='1') or
            (state_reg=newgame and text_on(1)='1') or -- rule
            (state_reg=over and text_on(0)='1') then
            rgb_next <= text_rgb;
         else
			--modificado
           rgb_next <= "000000001111"; -- yellow background
         end if;
      end if;
   end process;
   rgb <= rgb_reg;
end arch;