library ieee; 
use ieee.std_logic_1164.all; 
use ieee.std_logic_unsigned.all;


-- Carry-select block: pre-computes sums for Ci=0 and Ci=1,
-- then selects the correct result via a mux based on actual Ci
entity carry_select_block is
	generic(NBIT: integer :=4);
	Port (	A:	In	std_logic_vector(NBIT-1 downto 0);
		B:	In	std_logic_vector(NBIT-1 downto 0);
		Ci:	In	std_logic;
		S:	Out	std_logic_vector(NBIT-1 downto 0));
end carry_select_block; 

architecture STRUCTURAL of carry_select_block is

  signal S0, S1 : std_logic_vector(NBIT-1 downto 0);

  component RCA 
  generic (NBIT: integer);
  Port ( A:	In	std_logic_vector(NBIT - 1 downto 0);
	 B:	In	std_logic_vector(NBIT-1 downto 0);
	 Ci:	In	std_logic;
	 S:	Out	std_logic_vector(NBIT-1 downto 0);
	 Co:	Out	std_logic);
  end component; 

  component MUX21_GENERIC
  generic(NBIT: integer);
  port( A:	In	std_logic_vector(NBIT - 1 downto 0);
	B:	In	std_logic_vector(NBIT-1 downto 0);
	SEL:	In	std_logic;
	Y:	Out	std_logic_vector(NBIT-1 downto 0)
  );
  end component;

begin

MUX21_4bit: MUX21_GENERIC
  generic map( NBIT => NBIT)
  port map ( A => S1,
	     B => S0,
	     SEL => Ci,
	     Y => S);
RCA0: RCA
  generic map (NBIT => NBIT)
  port map( A => A,
	    B => B,
	    Ci => '1',
	    S => S1,
	    Co => open);
 
RCA1: RCA 
  generic map( NBIT => NBIT)
  port map( A => A,
	    B => B,
	    Ci => '0',
	    S => S0,
	    Co => open);
end STRUCTURAL;


configuration CFG_CARRY_SELECT of carry_select_block is
	for STRUCTURAL
		for all: RCA 		
			use entity work.RCA(STRUCTURAL);
		end for;
		
		for all: MUX21_GENERIC
			use entity work.MUX21_GENERIC(BEHAVIORAL);
		end for;
	end for;
end configuration CFG_CARRY_SELECT;
