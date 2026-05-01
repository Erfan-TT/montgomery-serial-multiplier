library IEEE;
use IEEE.STD_LOGIC_1164.ALL;


entity montgomery_multiplier is
generic( WIDTH: integer:= 32);
Port (
    clk, rst, start: in std_logic;
    A, B, N :        in std_logic_vector(WIDTH-1 downto 0);
    result :         out std_logic_vector(WIDTH-1 downto 0);
    busy, done:      out std_logic
  );
end montgomery_multiplier;

architecture Behavioral of montgomery_multiplier is
-- control signals : 
signal en_index, SH, rst_from_cp, LD, ld_result : std_logic;

-- status signal : 
signal eq: std_logic ; -- whenever the index reaches to width

component montgomery_CP is
port(
start, clk, rst, eq : in std_logic;
done, busy, sh, rst_from_cp, en_index, ld  : out std_logic 
);
end component;

component montgomery_DP is
generic( WIDTH: integer:= 32);
port(
A, B, N: in std_logic_vector( WIDTH-1 downto 0);
clk, rst, rst_from_cp, sh, en_index, LD : in std_logic ;
eq: out std_logic ;
result: out std_logic_vector( WIDTH-1 downto 0)
);
end component;


begin
CP: montgomery_CP 
port map( start => start, clk => clk, rst => rst, eq => eq, done => done, busy => busy, sh => sh, ld => ld, rst_from_cp => rst_from_cp, en_index => en_index);


DP: montgomery_DP
generic map(WIDTH => WIDTH)
port map( A => A, B => B, N => N,
clk => clk, rst => rst, rst_from_cp => rst_from_cp , sh => sh, en_index =>en_index, LD => LD,
eq=>eq,
result =>result);


end Behavioral;
