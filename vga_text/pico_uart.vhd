--Listing 16.4
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
entity pico_uart is
   port(
      clk, reset: in std_logic;
      sw: in std_logic_vector(7 downto 0);
      btn: in std_logic_vector(1 downto 0);
      rx: in std_logic;
      tx: out  std_logic;
      hsync, vsync: out std_logic;
      rgb: out   std_logic_vector (11 downto 0)--modificado
   );
end pico_uart;

architecture arch of pico_uart is
   -- KCPSM6/ROM signals
 signal address : std_logic_vector(11 downto 0);
 signal instruction : std_logic_vector(17 downto 0);
 signal bram_enable : std_logic;
 signal in_port : std_logic_vector(7 downto 0);
 signal out_port : std_logic_vector(7 downto 0);
 Signal port_id : std_logic_vector(7 downto 0);
 Signal write_strobe : std_logic;
 Signal k_write_strobe : std_logic;
 Signal read_strobe : std_logic;
 Signal interrupt : std_logic;
 Signal interrupt_ack : std_logic;
 Signal kcpsm6_sleep : std_logic;
 Signal kcpsm6_reset : std_logic;
   -- I/O port signals
   -- output enable
   signal en_d: std_logic_vector(6 downto 0);
   -- four-digit seven-segment led display
   signal ds3_reg, ds2_reg: std_logic_vector(7 downto 0);
   signal result_lsb_reg, result_msb_reg: std_logic_vector(7 downto 0);
   signal in3, in2: std_logic_vector(7 downto 0);
   signal in1, in0: std_logic_vector(7 downto 0);
   -- two push buttons
   signal btnc_flag_reg, btnc_flag_next: std_logic;
   signal btns_flag_reg, btns_flag_next: std_logic;
   signal set_btnc_flag, set_btns_flag: std_logic;
   signal clr_btn_flag: std_logic;
   -- uart
   signal w_data: std_logic_vector(7 downto 0);
   signal rd_uart, rx_not_empty, rx_empty: std_logic;
   signal wr_uart, tx_full: std_logic;
   signal rx_char: std_logic_vector(7 downto 0);
   -- multiplier
   signal m_src0_reg, m_src1_reg, a_end_reg,b_end_reg: std_logic_vector(7 downto 0);
   signal prod: std_logic_vector(15 downto 0);
   --DVSR = M-1, M=100_000_000/19200*16=325
   constant DVSR: std_logic_vector (10 downto 0):=std_logic_vector(to_unsigned(324,11));
begin
   in3(7) <= ds3_reg(7);
in3(6) <= ds3_reg(0);
in3(5) <= ds3_reg(1);
in3(4) <= ds3_reg(2);
in3(3) <= ds3_reg(3);
in3(2) <= ds3_reg(4);
in3(1) <= ds3_reg(5);
in3(0) <= ds3_reg(6);

in2(7) <= ds2_reg(7);
in2(6) <= ds2_reg(0);
in2(5) <= ds2_reg(1);
in2(4) <= ds2_reg(2);
in2(3) <= ds2_reg(3);
in2(2) <= ds2_reg(4);
in2(1) <= ds2_reg(5);
in2(0) <= ds2_reg(6);

in1(7) <= ds1_reg(7);
in1(6) <= ds1_reg(0);
in1(5) <= ds1_reg(1);
in1(4) <= ds1_reg(2);
in1(3) <= ds1_reg(3);
in1(2) <= ds1_reg(4);
in1(1) <= ds1_reg(5);
in1(0) <= ds1_reg(6);

in0(7) <= ds0_reg(7);
in0(6) <= ds0_reg(0);
in0(5) <= ds0_reg(1);
in0(4) <= ds0_reg(2);
in0(3) <= ds0_reg(3);
in0(2) <= ds0_reg(4);
in0(1) <= ds0_reg(5);
in0(0) <= ds0_reg(6);

-- =====================================================
--  I/O modules
-- =====================================================

   vga_unit: entity work.vga_ctrl
		port map(clk =>clk, reset => reset, hsync => hsync, vsync => vsync, rgb => rgb, a_bcd0 => a_end_reg(3 downto 0),
		a_bcd1 => a_end_reg(7 downto 4), b_bcd0 => b_end_reg(3 downto 0),b_bcd1 => b_end_reg(7 downto 4),
		p_bcd0 => result_lsb_reg(3 downto 0), p_bcd1 => result_lsb_reg(7 downto 4), p_bcd2 => result_msb_reg(3 downto 0), result_msb_reg(7 downto 4) );
   btnc_db_unit: entity work.debounce
      port map(
         clk=>clk, reset=>reset, sw=>btn(0),
         db_level=>open, db_tick=>set_btnc_flag);
   btns_db_unit: entity work.debounce
      port map(
         clk=>clk, reset=>reset, sw=>btn(1),
         db_level=>open, db_tick=>set_btns_flag);
   -- combinational multiplier
   prod <= std_logic_vector
           (unsigned(m_src0_reg) * unsigned(m_src1_reg));
   -- =====================================================
                 --  KCPSM and ROM instantiation
                 -- =====================================================
                   processor: entity work.kcpsm6
                         generic map (     hwbuild => X"00", 
                                           interrupt_vector => X"3FF",
                                       scratch_pad_memory_size => 64)
                         port map(      address => address,
                                    instruction => instruction,
                                    bram_enable => bram_enable,
                                        port_id => port_id,
                                   write_strobe => write_strobe,
                                 k_write_strobe => k_write_strobe,
                                       out_port => out_port,
                                    read_strobe => read_strobe,
                                        in_port => in_port,
                                      interrupt => interrupt,
                                  interrupt_ack => open,
                                          sleep => kcpsm6_sleep,
                                          reset => kcpsm6_reset,
                                            clk => clk);
                    
                program_rom: entity work.mult_rom --Name to match your PSM file
                            generic map(     C_FAMILY => "7S", --Family 'S6', 'V6' or '7S'
                                            C_RAM_SIZE_KWORDS => 2,--Program size '1', '2' or '4'
                                         C_JTAG_LOADER_ENABLE => 1)--Include JTAG Loader when set to '1' 
                            port map(      address => address,      
                                       instruction => instruction,
                                            enable => bram_enable,
                                               rdl => kcpsm6_reset,
                                               clk => clk);
   -- Unused inputs on processor
   kcpsm6_reset <= '0';
   kcpsm6_sleep <= '0';
   interrupt <= '0';
   constant result_lsb_port,     00    ;
constant result_msb_port,     01    ;
constant mult_src0_port, 02    ;multiplier operand 0
constant mult_src1_port, 03    ;multiplier operand 1
constant erro_port, 04 ; flag de erro
   -- =====================================================
   --  output interface
   -- =====================================================
   --    outport port id:
   --      0x00: result_lsb_port
   --      0x01: result_msb_port
   --      0x02: m_src0
   --      0x03: m_src1
   --      0x04: erro_port
   --      0x05 a_port
   --      0x06 b_port
   -- =====================================================
   -- registers
   process (clk)
   begin
      if (clk'event and clk='1') then
         if en_d(0)='1' then result_lsb_reg <= out_port; end if;
         if en_d(1)='1' then result_msb_reg <= out_port; end if;
         if en_d(4)='1' then erro_reg <= out_port; end if;
         if en_d(2)='1' then m_src0_reg <= out_port; end if;
         if en_d(3)='1' then m_src1_reg <= out_port; end if;
         if en_d(5)='1' then a_end_reg <= out_port; end if;
         if en_d(6)='1' then b_end_reg <= out_port; end if;
      end if;
   end process;
  -- decoding circuit for enable signals
   process(port_id,write_strobe)
   begin
      en_d <= (others=>'0');
      if write_strobe='1' then
         case port_id(2 downto 0) is
            when "000" => en_d <="0000001";
            when "001" => en_d <="0000010";
            when "010" => en_d <="0000100";
            when "011" => en_d <="0001000";
            when "100" => en_d <="0010000";
            when "101" => en_d <="0100000";
            when others => en_d <="1000000";
         end case;
      end if;
   end process;
   wr_uart <= en_d(4);
   -- =====================================================
   --  input interface
   -- =====================================================
   --    input port id
   --      0x00: flag
   --      0x01: switch
   --      0x02: uart_rx_fifo
   --      0x03: prod lower byte
   --      0x04: prod upper byte
   -- =====================================================
   -- input register (for flags)
   process(clk)
   begin
      if (clk'event and clk='1') then
         btnc_flag_reg <= btnc_flag_next;
         btns_flag_reg <= btns_flag_next;
      end if;
   end process;

   btnc_flag_next <= '1' when set_btnc_flag='1' else
                     '0' when clr_btn_flag='1' else
                      btnc_flag_reg;
   btns_flag_next <= '1' when set_btns_flag='1' else
                     '0' when clr_btn_flag='1' else
                      btns_flag_reg;
   -- decoding circuit for clear signals
   clr_btn_flag <='1' when read_strobe='1' and
                           port_id(2 downto 0)="000" else
                  '0';
   rd_uart <= '1' when read_strobe='1' and
                       port_id(2 downto 0)="010" else
              '0';
   -- input multiplexing
   rx_not_empty <= not rx_empty;
   process(port_id,tx_full,rx_not_empty,
           btns_flag_reg,btnc_flag_reg,sw,rx_char,prod)
   begin
      case port_id(2 downto 0) is
         when "000" =>
            in_port <= "0000" & tx_full & rx_not_empty &
                       btns_flag_reg & btnc_flag_reg;
         when "001" =>
            in_port <= sw;
         when "010" =>
            in_port <= prod(7 downto 0);
         when "011" =>
            in_port <= prod(15 downto 8);
         when others =>
            in_port <= "00000000";
      end case;
   end process;
end arch;