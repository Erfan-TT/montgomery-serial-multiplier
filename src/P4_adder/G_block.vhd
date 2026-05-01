library IEEE;
use IEEE.std_logic_1164.all;


entity G_block is

    port (
        Gik    : in  std_logic;  -- Generate upper
        Pik    : in  std_logic;  -- Propagate upper
        Gk1j   : in  std_logic;  -- Generate lower
        Gij    : out std_logic   -- Generate output
    );

end G_block;

architecture behavioral of G_block is
begin
    Gij <= Gik or (Pik and Gk1j);
end behavioral;
