

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity PG_elem is
    port (
        a : in  std_logic;
        b : in  std_logic;
        p : out std_logic;
        g : out std_logic
    );
end PG_elem;

architecture behavioral of PG_elem is
begin
    p <= a xor b;
    g <= a and b;
end behavioral;
