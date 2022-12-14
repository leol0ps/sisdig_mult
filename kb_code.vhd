-- Listing 8.3 modificado
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity kb_code is
   generic(W_SIZE: integer:=2);  -- 2^W_SIZE words in FIFO
   port (
      clk, reset: in  std_logic;
      ps2d, ps2c: in  std_logic;
       
      --rx_enable : in std_logic;
      rd_key_code: in std_logic;
      
      k_key         : out std_logic_vector(7 downto 0);
      k_press       : out std_logic;
      k_normal      : out std_logic;  -- (1: normal, 0: extendida)
      k_done_tick   : out std_logic
      
      --kb_buf_empty  : out std_logic
   );
end kb_code;

architecture arch of kb_code is
   constant BRK: std_logic_vector(7 downto 0):="11110000"; -- F0
   constant EXT: std_logic_vector(7 downto 0):="11100000"; --E0

    type statetype is (idle, extended, released, done);
    signal state_reg, state_next: statetype;
    signal scan_out, w_data: std_logic_vector(7 downto 0);
    signal scan_done_tick: std_logic;
   
    signal key_code     : std_logic_vector(7 downto 0);
    signal dout         : std_logic_vector(7 downto 0);
    signal rx_done_tick : std_logic;

begin
   --=======================================================
   -- instantiation
   --=======================================================
   ps2rx_unit: entity work.ps2rx(arch)
      port map( clk=>clk,
                reset=>reset,
                rx_en=>'1',
                ps2d=>ps2d,
                ps2c=>ps2c,
                rx_done_tick=>scan_done_tick,
                dout=>scan_out
      );

   --fifo_key_unit: entity work.fifo(reg_file_arch)
   --   generic map(DATA_WIDTH=>8, ADDR_WIDTH=>W_SIZE)
   --   port map(clk=>clk, reset=>reset, rd=>rd_key_code,
   --            wr=>k_done_tick, w_data=>scan_out,
   --            empty=>kb_buf_empty, full=>open,
   --            r_data=>key_code);

   --=======================================================
   -- FSM to get the scan code after F0 received
   --=======================================================
   process (clk, reset)
   begin
      if reset='1' then
         state_reg <= idle;
      elsif (clk'event and clk='1') then
         state_reg <= state_next;
      end if;
   end process;

   process(rx_done_tick, scan_done_tick, scan_out)
   begin
      k_done_tick <='0';
      state_next <= state_reg;
      case state_reg is
      
      -- Estado IDLE
         when idle => 
            if rx_done_tick = '1' then
               if dout = EXT then --E0
                  k_normal <= '0';
                  state_next <= extended;
               else
                  k_normal <= '1';
               end if;

               if dout = BRK then --F0
                  k_press <= '0';
                  state_next <= released;
               else 
                  k_press <= '1';
                  k_key <= dout;
                  state_next <= done;
               end if;
            else
               state_next <= idle;
            end if;
      -- Fim do estado IDLE

      -- Estado EXTENDED
         when extended =>
            if rx_done_tick = '1' then
               if dout = BRK then
                  k_press <= '0';
                  state_next <= released;
               else
                  k_press <= '1';
                  k_key <= dout;
                  state_next <= done;
               end if;
            else
               state_next <= extended;
            end if;
      -- Fim do estado EXTENDED

      -- Estado RELEASED
         when released =>
            if rx_done_tick = '1' then
               k_key <= dout;
               state_next <= done;
            else 
               state_next <= released;
            end if;
      -- Fim do Estado RELEASED
         when done =>
            k_done_tick <= '1';
            state_next <= idle;

      end case;
   end process;
end arch;