library ieee; 
use ieee.std_logic_1164.all; 
use ieee.std_logic_unsigned.all;

-- Sum generator: array of NBLOCKS carry-select blocks producing the final sum
entity SUM_GENERATOR is
	generic (
		NBIT_PER_BLOCK: integer := 4;
		NBLOCKS:	integer := 8);
	port (
		A:	in	std_logic_vector(NBIT_PER_BLOCK*NBLOCKS-1 downto 0);
		B:	in	std_logic_vector(NBIT_PER_BLOCK*NBLOCKS-1 downto 0);
		Ci:	in	std_logic_vector(NBLOCKS-1 downto 0);
		S:	out	std_logic_vector(NBIT_PER_BLOCK*NBLOCKS-1 downto 0));
end SUM_GENERATOR;

architecture STRUCTURAL of SUM_GENERATOR is
  
  constant NBIT : integer := NBIT_PER_BLOCK * NBLOCKS;

  component carry_select_block 
  generic (NBIT: integer);
  Port ( A:	In	std_logic_vector(NBIT - 1 downto 0);
	 B:	In	std_logic_vector(NBIT-1 downto 0);
	 Ci:	In	std_logic;
	 S:	Out	std_logic_vector(NBIT-1 downto 0));
  end component; 
  
begin

  SUM_GEN: for i in 0 to NBLOCKS - 1 generate
	carry_select_int: carry_select_block
		generic map(NBIT => NBIT_PER_BLOCK)
		port map(
			A => A((i+1)*NBIT_PER_BLOCK - 1 downto i*NBIT_PER_BLOCK),
			B => B((i+1)*NBIT_PER_BLOCK - 1 downto i*NBIT_PER_BLOCK),
			Ci => Ci(i),
			S => S((i+1)*NBIT_PER_BLOCK - 1 downto i*NBIT_PER_BLOCK));
  end generate SUM_GEN;
end STRUCTURAL;
