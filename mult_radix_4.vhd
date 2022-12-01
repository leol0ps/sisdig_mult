
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

entity novomult is
    generic (N: integer := 8);
   port(
    clk, reset: in std_logic;
    start: in std_logic;
    x_in, y_in: in std_logic_vector(N-1 downto 0);
    ready: out std_logic;
    done_tick: out std_logic;
    z_out: out std_logic_vector(2*N-1 downto 0)
);
end novomult;

architecture radix4 of novomult is
    type state_type is (idle, running, done);
    signal state_reg, state_next: state_type;
    signal z_reg, z_next: unsigned(N*2-1 downto 0);
    signal x_reg, x_next: unsigned(N downto 0);
    signal y_reg, y_next: unsigned(N*2-1 downto 0);
    signal n_reg, n_next: unsigned(N/2-1 downto 0);
    signal sum: unsigned(N*2-1 downto 0);
    signal triplet : unsigned(2 downto 0);
   
    begin
        triplet <= x_reg(2 downto 0);
        process(clk,reset)
            begin
                if reset = '1' then
                    state_reg <= idle;
                    x_reg <=(others=>'0');
                    y_reg <=(others =>'0');
                    z_reg <=(others =>'0');
                    n_reg <= (others =>'0');
                elsif (clk'event and clk = '1') then
                     state_reg <= state_next;
                     x_reg <= x_next;
                     y_reg <= y_next;
                     z_reg <= z_next;
                     n_reg <= n_next;
                end if;    
        end process;
        process(start,n_reg,x_reg,y_reg,z_reg,state_reg,sum,x_in,y_in,n_next)
            begin
                z_next <= z_reg;
                n_next <= n_reg;
                x_next <= x_reg;
                y_next <= y_reg;
                ready <= '0';
                done_tick<='0';
                state_next <= state_reg;
                case state_reg is 
                when idle =>
                    ready <='1';
                    if start = '1' then 
                        state_next <= running;
                        x_next <= unsigned(x_in&'0');
                        y_next <= to_unsigned(0,N)& unsigned(y_in); 
                        n_next <= to_unsigned(N/2+1,N/2); 
                        z_next <= (others=>'0'); 
                    end if;
                when running => 
                    n_next <= n_reg -1; 
                    y_next <= y_reg(N*2-3 downto 0)&"00";
                    x_next <= "00"&x_reg(N downto 2);
                    z_next <= sum;
                    if n_next = 0 then 
                        state_next <= done;
                    end if;
                when done =>
                        done_tick <= '1';
                        state_next <= idle;
                end case;
        end process;
        process(z_reg,y_reg,z_next,triplet)
            begin 
                case triplet is
                 when "001" =>
                    sum <= z_reg + y_reg;
                 when "010" =>
                    sum <= z_reg + y_reg;
                 when "011" =>
                    sum <= z_reg + (y_reg(N*2-2 downto 0)&'0');
                 when "100" =>
                    sum <= z_reg - (y_reg(N*2-2 downto 0)&'0');
                 when "101" =>
                    sum <= z_reg -  y_reg;
                 when "110" =>  
                    sum <= z_reg - y_reg;
                 when others =>
                    sum <= z_reg;
                 end case;            
        end process;
         z_out <= std_logic_vector(z_reg);
end radix4;
