library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.numeric_std.all;

entity montgomery_DP is
generic( WIDTH: integer:= 32);
port(
A, B, N: in std_logic_vector( WIDTH-1 downto 0);
clk, rst, rst_from_cp, sh, en_index, LD : in std_logic ;
eq: out std_logic ;
result: out std_logic_vector( WIDTH-1 downto 0)
);
end montgomery_DP;

architecture mix of montgomery_DP is
signal A_reg, B_reg, N_reg: unsigned(WIDTH-1  downto 0);
signal t_subtracted: std_logic_vector(WIDTH+2 downto 0);
signal result_temp: unsigned(WIDTH-1 downto 0);
signal t_reg, t_reg_next : unsigned(WIDTH +2  downto 0) :=(others=>'0'); -- because the worst case would be A + N + t which would need two bits more, but I add one more just in case
signal negated_N: std_logic_vector(WIDTH+2 downto 0);
signal index_counter: integer range 0 to WIDTH := 0;
signal cout: std_logic ;
--component propogate_added
    component P4_ADDER is
        generic (
            NBIT : integer := 32);
        port (
            A : in std_logic_vector(NBIT-1 downto 0);
            B : in std_logic_vector(NBIT-1 downto 0);
            Cin : in std_logic;
            S : out std_logic_vector(NBIT-1 downto 0);
            Cout : out std_logic);
    end component;
--end component;

begin
negated_N <= not std_logic_vector(resize(N_reg, t_reg'length));
p4adder: P4_ADDER generic map(NBIT => WIDTH+3) port map(A => std_logic_vector(t_reg_next ), B => negated_N, cin => '1', S => t_subtracted, Cout => cout);

seq: process( clk, rst, rst_from_cp) begin
    if( rst = '1' ) then 
            A_reg      <= (others => '0');
            B_reg      <= (others => '0');
            N_reg      <= (others => '0');
            t_reg      <= (others => '0');
            result_temp <= (others => '0');
            index_counter  <= 0;
    elsif( rising_edge(clk)) then
        if(rst_from_cp = '1') then 
            A_reg      <= (others => '0');
            B_reg      <= (others => '0');
            N_reg      <= (others => '0');
            t_reg      <= (others => '0');
            result_temp <= (others => '0');
            index_counter  <= 0;
        end if;
        
        if( ld = '1') then  
            A_reg <= UNSIGNED(A);
            B_reg <= unsigned(B);
            N_reg <= unsigned(N);
        end if;
         
        if(sh = '1') then
            t_reg <= t_reg_next;
            B_reg(WIDTH-1) <= '0';
            for index in 0 to WIDTH-2 loop
            B_reg(index) <= B_reg(index+1);
            end loop;
        end if;
        
        if( en_index = '1') then
            index_counter <= index_counter +1; 
        end if;    
     end if;
end process;


comb: process( index_counter, B_reg, A_reg, N_reg,t_reg, cout , t_subtracted)

variable temp : unsigned(WIDTH+2 downto 0); 

begin

temp := t_reg;
-- if the b_i was one we sum A with the t_reg
if( B_reg(0) = '1') then
temp := temp + resize(A_reg, temp'length);
end if;

if( temp(0) = '1') then 
temp := temp + resize(N_reg, temp'length);
end if;

t_reg_next <= shift_right(temp, 1);

-- if cout is zero it means the t was smaller than N, and we didnt need to do the subtractoin
-- if the cout is one, it means t was bigger and we needed the subtraction.
if(cout ='1') then result_temp <= resize(unsigned(t_subtracted), WIDTH); -- discarding the three added bits to the msb's 
else result_temp <= resize(t_reg_next, WIDTH);
end if;

if( index_counter >= WIDTH ) then 
eq <= '1';
else eq <= '0';
end if;
end process;

result <= std_logic_vector(result_temp);


end mix;


architecture behavioral of montgomery_DP is

signal A_reg, B_reg, N_reg: unsigned(WIDTH-1  downto 0);
signal result_temp: unsigned(WIDTH-1 downto 0);
signal t_reg, t_reg_next : unsigned(WIDTH +2  downto 0) :=(others=>'0'); -- because the worst case would be A + N + t which would need two bits more, but adding one more just in case
signal index_counter: integer range 0 to WIDTH := 0;

begin

seq: process( clk, rst, rst_from_cp) begin
    if( rst = '1' ) then 
            A_reg      <= (others => '0');
            B_reg      <= (others => '0');
            N_reg      <= (others => '0');
            t_reg      <= (others => '0');
            result_temp <= (others => '0');
            index_counter  <= 0;
    elsif( rising_edge(clk)) then
        if(rst_from_cp = '1') then 
            A_reg      <= (others => '0');
            B_reg      <= (others => '0');
            N_reg      <= (others => '0');
            t_reg      <= (others => '0');
            result_temp <= (others => '0');
            index_counter  <= 0;
        end if;
        
        if( ld = '1') then  
            A_reg <= UNSIGNED(A);
            B_reg <= unsigned(B);
            N_reg <= unsigned(N);
        end if;
         
        if(sh = '1') then
            t_reg <= t_reg_next;
            B_reg(WIDTH-1) <= '0';
            for index in 0 to WIDTH-2 loop
            B_reg(index) <= B_reg(index+1);
            end loop;
        end if;
        
        if( en_index = '1') then
            index_counter <= index_counter +1; 
        end if;    
     end if;
end process;


comb: process( index_counter, B_reg, A_reg, N_reg,t_reg)

variable temp : unsigned(WIDTH+2 downto 0); 

begin

temp := t_reg;
-- if the b_i was one we sum A with the t_reg
if( B_reg(0) = '1') then
temp := temp + resize(A_reg, temp'length);
end if;

if( temp(0) = '1') then 
temp := temp + resize(N_reg, temp'length);
end if;
temp := shift_right(temp, 1);
t_reg_next <= temp;
-- if cout is zero it means the t was smaller than N, and we didnt need to do the subtractoin
-- if the cout is one, it means t was bigger and we need the subtraction.
if(temp>= N_reg ) then result_temp <= resize((temp - resize(N_reg, temp'length)), WIDTH); 
else result_temp <= resize(temp, WIDTH);
end if;


if( index_counter >= WIDTH ) then 
eq <= '1';
else eq <= '0';
end if;

end process;
result <= std_logic_vector(result_temp);


end behavioral;
