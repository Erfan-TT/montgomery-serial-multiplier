library IEEE;
use IEEE.std_logic_1164.all;
use WORK.constants.all;

entity MUX21_GENERIC is
	Generic (NBIT: integer:= numBit;
		 DELAY_MUX: Time:= TP_MUX);
        Port (	A:	In	std_logic_vector(NBIT-1 downto 0) ;
		B:	In	std_logic_vector(NBIT-1 downto 0);
		SEL:	In	std_logic;
		Y:	Out	std_logic_vector(NBIT-1 downto 0));
end MUX21_GENERIC;



architecture BEHAVIORAL of MUX21_GENERIC is

begin
	process(A, B, SEL) begin
		for i in 0 to (NBIT - 1) loop
			Y(i) <=  (A(i) and SEL) or (B(i) and not(SEL)) after DELAY_MUX;
		end loop;
	end process;
end BEHAVIORAL;


architecture STRUCTURAL of MUX21_GENERIC is

        component MUX21 is
	Port (	A:	In	std_logic;
		B:	In	std_logic;
		S:	In	std_logic;
		Y:	Out	std_logic);
        end component;

	   
 begin

   gen_muxs: for i in 0 to (NBIT - 1) generate
     mux21_inst: MUX21
      port map (
        A => A(i),
        B => B(i),
        S => SEL,
        Y => Y(i)
      );
   end generate gen_muxs;


end STRUCTURAL;


configuration CFG_MUX21_GEN_BEHAVIORAL of MUX21_GENERIC is
	for BEHAVIORAL
	end for;
end CFG_MUX21_GEN_BEHAVIORAL;


configuration CFG_MUX21_GEN_STRUCTURAL of MUX21_GENERIC is
	for STRUCTURAL
		for all : MUX21
			use configuration WORK.CFG_MUX21_STRUCTURAL;
		end for;
	end for;
end CFG_MUX21_GEN_STRUCTURAL;
