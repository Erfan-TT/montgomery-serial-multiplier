library IEEE;
use IEEE.std_logic_1164.all;

entity PG_block is
    port(
        Gik    : in  std_logic;  -- Generate upper
        Pik    : in  std_logic;  -- Propagate upper
        Gk1j   : in  std_logic;  -- Generate lower
        Pk1j   : in  std_logic;  -- Propagate lower
        Gij    : out std_logic;  -- Generate output
        Pij    : out std_logic   -- Propagate output
    );

end PG_block;

architecture behavioral of PG_block is
begin

    Gij <= Gik or (Pik and Gk1j);
    Pij <= Pik and Pk1j;

end behavioral;
