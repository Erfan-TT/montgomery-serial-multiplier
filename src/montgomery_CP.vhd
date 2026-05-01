library ieee;
use ieee.std_logic_1164.all;

entity montgomery_CP is
port(
start, clk, rst, eq : in std_logic;
done, busy, sh, rst_from_cp, en_index, ld  : out std_logic 
);

end entity;


architecture beh of montgomery_CP is 
type statetype is (IDLE, LOAD, RUN, FINISH);
signal state, statenext: statetype;

begin

seqprocess: process(clk, rst) begin
if( rst = '1') then 
state <= IDLE;
elsif( rising_edge(clk)) then
state <= statenext;
end if;
end process;


combprocess: process(eq, state, start) begin
statenext <= state;
done <= '0';
busy <='0';
sh <= '0';
rst_from_cp <= '0';
en_index <='0';
ld <= '0';

case state is 
when IDLE =>
    rst_from_cp <= '1';
    if(start = '1') then 
    statenext <= LOAD;
    else statenext <= IDLE;
    end if;

when LOAD =>
    ld <= '1';
    busy <= '1';
    statenext <= RUN;
    
when RUN =>
    sh <= '1';
    en_index <='1';
    busy <= '1';
    if( eq = '1') then
    statenext <= FINISH;
    else statenext <= RUN;
    end if;
        
when FINISH =>
    done <= '1';
    busy <= '1';
    sh <= '0';
    statenext <= IDLE;
    
end case;
end process;

end beh;