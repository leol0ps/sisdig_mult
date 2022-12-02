----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 21.11.2022 15:06:49
-- Design Name: 
-- Module Name: fsm_top - Behavioral
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

entity mult_8b_top is
   port(
    clk : in std_logic;
    reset: in std_logic;
    led: out std_logic_vector(8 downto 0);
    ps2d, ps2c: in std_logic;
    tx: out std_logic
   );
end mult_8b_top;

architecture Behavioral of mult_8b_top is
signal led_reg,led_next: std_logic_vector(8 downto 0);
signal start: std_logic;
signal ready: std_logic;
signal x_reg, y_reg, x_next, y_next: std_logic_vector(7 downto 0);
signal z_reg: std_logic_vector(15 downto 0);
signal reset_mult, start_mult, done_tick_mult: std_logic;
signal wr_uart: std_logic;
signal w_data: std_logic_vector(7 downto 0);
signal mult_done_tick: std_logic;
signal uart_full: std_logic;
CONSTANT DVSR : std_logic_vector (10 downto 0):= std_logic_vector(to_unsigned(324,11));
constant SP: std_logic_vector(7 downto 0):="00100000";-- space in ASCII
constant CHAR_X     : std_logic_vector(7 downto 0):="01011000";-- X
constant CHAR_Y     : std_logic_vector(7 downto 0):="01011001";-- Y
constant CHAR_STAR  : std_logic_vector(7 downto 0):="00101010";-- *
constant CHAR_EQ    : std_logic_vector(7 downto 0):="00111101";-- =
constant CR : std_logic_vector(7 downto 0) := "00001101"; -- '\n'
type state_type is (idle,wait_mult,done,send_x_equal,send_y_equal,send_x_h,send_x_l,send_y_h,send_y_l,print_uart);
signal state_reg,state_next: state_type;
signal k_normal,k_press,k_done_tick,valid_reg,valid_next: std_logic;
signal k_key: std_logic_vector(7 downto 0);
signal convertkb_bin: std_logic_vector(3 downto 0);
signal convert_error: std_logic;
signal ascii,ascii_print: std_logic_vector(7 downto 0);
signal first_entry_reg,first_entry_next: std_logic;
signal x_ascii_h,x_ascii_l,y_ascii_h,y_ascii_l,z1_ascii_h,z1_ascii_l,z2_ascii_h,z2_ascii_l,ascii_z_baixo: std_logic_vector(7 downto 0);
type t_array is array (18 downto 0) of std_logic_vector(7 downto 0);
signal print_array: t_array;
signal counter_reg,counter_next: unsigned(4 downto 0);
alias z_baixo : std_logic_vector(7 downto 0) is z_reg(7 downto 0);
signal hex_in : std_logic_vector(3 downto 0);
begin
   print_array(18) <= CHAR_X; -- insere "x" no array 
   print_array(17) <= CHAR_EQ; -- insere "=" no array
   --16 e 15 sao de x_reg
   print_array(14) <= SP; -- insere ' ' no array
   print_array(13) <= CHAR_Y; -- insere 'y' no array
   print_array(12) <= CHAR_EQ; -- insere "=" no array
   --11 e 10 sao de y_reg
   print_array(9) <= SP; 
   print_array(8) <= CHAR_X; -- insere "x" no array 
   print_array(7) <= CHAR_STAR;-- insere '*' no array 
   print_array(6) <= CHAR_Y; -- insere 'y' no array
   print_array(5) <= CHAR_EQ; -- insere '=' no array
   -- 4 ate 1 sao de z_Reg
   print_array(0) <= CR; -- insere nova linha
    

    mult_radix: entity work.novomult(radix4)
        port map(
            clk => clk,
            reset => reset,
            start => start_mult,
            x_in => x_reg,
            y_in => y_reg,
            z_out => z_reg,
            done_tick => done_tick_mult
        );
    uart_unit: entity work.uart(str_arch)
        port map(
            clk => clk,
            reset => reset,
            rd_uart => '0',
            wr_uart => wr_uart,
            w_data => w_data,
            tx_full => uart_full,
            dvsr => DVSR,
            tx => tx,
            rx => '1',
            r_data => open,
            rx_empty => open
        );
    keyboard_unit: entity work.kb_code(arch)
        port map(
            clk => clk,
            reset => reset,
            ps2c => ps2c,
            ps2d => ps2d,           
            k_done_tick => k_done_tick,
            k_press => k_press,
            k_normal => k_normal,
            k_key => k_key,
            rd_key_code => '1'
        );
--     ascii_unit: entity work.key2ascii(arch) 
--            port map(
--                key_code => k_key,
--                ascii_code => ascii
--            );
     convert_unit: entity work.convert_kb_to_bin(arch)
        port map(
            key_code => k_key,
            bin => convertkb_bin,
            is_hexa_number => convert_error
        );
      bin_to_ascii_x: entity work.bin2ascii(arch)
        port map(
            bin_code => x_reg,
            ascii_h => x_ascii_h,
            ascii_l => x_ascii_l
        );
      bin_to_ascii_y: entity work.bin2ascii(arch)
          port map(
              bin_code => y_reg,
              ascii_h => y_ascii_h,
              ascii_l => y_ascii_l
          );
      bin_to_ascii_z1: entity work.bin2ascii(arch)
            port map(
                bin_code => z_reg(15 downto 8),
                ascii_h => z1_ascii_h,
                ascii_l => z1_ascii_l
            );
      bin_to_ascii_z2: entity work.bin2ascii(arch)
                  port map(
                      bin_code => z_baixo,
                      ascii_h => z2_ascii_h,
                      ascii_l => z2_ascii_l
                  );
    process(clk,reset)
        begin
            if reset = '1' then 
                state_reg <= idle;
                x_reg <= "00000000";
                y_reg <= "00000000";
                first_entry_reg <= '0';
				valid_reg <= '0';
            elsif(clk'event and clk='1') then
                state_reg <= state_next;
                x_reg <= x_next;
                y_reg <= y_next;
                first_entry_reg <= first_entry_next;
                counter_reg <= counter_next;
                led_reg <= led_next;
				valid_reg <= valid_next;
            end if;
    end process;
    process(state_reg,ascii,k_done_tick,x_reg,y_reg,state_next,led_reg,counter_reg,k_key,k_normal,convert_error,convertkb_bin,
    done_tick_mult,first_entry_reg,y_ascii_h,x_ascii_l,y_ascii_l,x_ascii_h,z1_ascii_h,z1_ascii_l,z2_ascii_h,z2_ascii_l,ascii_print,valid_reg)
        begin 
         led_next <= led_reg;
         counter_next <= counter_reg;
         wr_uart <= '0';            
         w_data <= SP;            
         state_next <= state_reg;
         first_entry_next <= first_entry_reg;
		 valid_next <= valid_reg;
         case state_reg is 
            when idle =>
                led_next <= '0'&z_reg(7 downto 0);
                if (k_done_tick = '1' and k_normal = '1' and k_press = '1')  then 

                    if k_key = "00100010" then -- teclou x
                        state_next <= send_x_equal;
                    elsif k_key = "00110101" then -- teclou y
                        state_next <= send_y_equal;
                    elsif k_key =  "00011011" then -- teclou start
                        start_mult <= '1';
                        state_next <= wait_mult; -- espera pelo done_tick do multiplicador
					elsif k_key =  "01000100" then -- teclou output
						if(valid_reg = '0') then
							start_mult <= '1';
							state_next <= wait_mult; -- espera pelo done_tick do multiplicador
						else
						    counter_next <= "10011"; -- inicia contador com 19
							state_next <= print_uart; 
						end if;
                    end if;
                end if;
            when send_x_equal =>
                led_next <= '0'&k_key;
                if (k_done_tick = '1' and k_normal = '1' and k_press = '1')  then 
                    if k_key = "01010101" then
                        state_next <= send_x_h;
                        first_entry_next <= '1';
                    end if;
                end if;
            when send_y_equal =>
                led_next <= '0'&k_key;
                if (k_done_tick = '1' and k_normal = '1' and k_press = '1')  then 
                    if k_key = "01010101" then
                        state_next <= send_y_h; 
                        first_entry_next <= '1';
                    end if;
                end if;    
            when send_x_h =>
                if(k_done_tick = '1' and k_normal = '1' and k_press ='1') then
                        if(convert_error = '0') then
                            x_next(7 downto 4) <=  convertkb_bin;
                            state_next <= send_x_l;
                         end if;
					end if;
			when send_x_l =>
				led_next <= '0'&k_key;
				if(k_done_tick = '1' and k_normal = '1' and k_press = '1') then
                        if(convert_error = '0') then 
                            x_next(3 downto 0) <= convertkb_bin;
                            state_next <= idle;
							valid_next <= '0';
                        end if;
                    end if;
            when send_y_h =>
				led_next <= '0'&k_key;
                 if(k_done_tick = '1' and k_normal = '1' and k_press = '1') then
                        if(convert_error = '0') then
                            y_next(7 downto 4) <=  convertkb_bin;
                            state_next <= send_y_l;
                         end if;
                    end if;
			when send_y_l =>
				led_next <= '0'&k_key;
				if(k_done_tick = '1' and k_normal = '1' and k_press ='1') then
                        if(convert_error = '0') then
                            y_next(3 downto 0) <= convertkb_bin;
                            state_next <= idle;
							valid_next <= '0';
                        end if;
                    end if;
            when   wait_mult =>
                  led_next <= "000000001";
                  if  done_tick_mult = '1' then  -- espera o done_tick do mult
                       print_array(16) <= x_ascii_h;
                       print_array(15) <= x_ascii_l;
                       print_array(11) <= y_ascii_h;
                       print_array(10) <= y_ascii_l;
                       print_array(4) <= z1_ascii_h;
                       print_array(3) <= z1_ascii_l;
                       print_array(2) <= z2_ascii_h;
                       print_array(1) <= z2_ascii_l;
                       counter_next <= "10011"; -- inicia contador com 19
                       state_next <= print_uart; 
					   valid_next <= '1';
                  end if;
            when print_uart =>
                led_next <= "000000010";
                
                if uart_full = '1' then
                
                elsif counter_reg /= "00000" then
                    counter_next<= counter_reg-1;
                    w_data<= print_array(to_integer(counter_reg) - 1);
                    wr_uart <= '1';
                else
                    state_next <= done;
                end if;
            when done =>
                state_next <= idle;
            end case;
    end process;
    led <=  valid_reg & led_reg(7 downto  0);
end Behavioral;