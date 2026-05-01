-----------------------------------------------------------------------------------
-- P4 adder: top-level pentium-4-style adder combining
-- a sparse-tree carry generator with a carry-select sum generator
-----------------------------------------------------------------------------------
library IEEE;
use IEEE.std_logic_1164.all;


entity P4_ADDER is
        generic (
            NBIT : integer := 32);
        port (
            A : in std_logic_vector(NBIT-1 downto 0);
            B : in std_logic_vector(NBIT-1 downto 0);
            Cin : in std_logic;
            S : out std_logic_vector(NBIT-1 downto 0);
            Cout : out std_logic);
end P4_ADDER;

architecture STRUCTURAL of P4_ADDER is 

    --constants
    constant NBIT_PER_BLOCK : integer := 4;
    constant NBLOCKS : integer := NBIT/NBIT_PER_BLOCK;
    -- Component declaration
    component CARRY_GENERATOR is
        generic (
            NBIT           : integer;
            NBIT_PER_BLOCK : integer
        );
        port (
            A   : in  std_logic_vector(NBIT-1 downto 0);
            B   : in  std_logic_vector(NBIT-1 downto 0);
            Cin : in  std_logic;
            Co  : out std_logic_vector((NBIT/NBIT_PER_BLOCK)-1 downto 0)
        );
    end component;

    component SUM_GENERATOR is
            generic (
                    NBIT_PER_BLOCK: integer;
                    NBLOCKS:        integer);
             port (
                    A:      in      std_logic_vector(NBIT_PER_BLOCK*NBLOCKS-1 downto 0);
                    B:      in      std_logic_vector(NBIT_PER_BLOCK*NBLOCKS-1 downto 0);
		    Ci:     in      std_logic_vector(NBLOCKS-1 downto 0);
                    S:      out     std_logic_vector(NBIT_PER_BLOCK*NBLOCKS-1 downto 0));
    end component;

   -- Signal declaration
    signal carry_in : std_logic_vector (NBLOCKS-1 downto 0);
    signal carry_out: std_logic_vector(NBLOCKS-1 downto 0);
    

begin

    -- Route carry outputs from generator to sum generator inputs
    carry_in(0) <= Cin;

    carry_shift: for i in 1 to NBLOCKS-1 generate
      carry_in(i) <= carry_out(i-1);
    end generate;
    
    Cout <= carry_out(NBLOCKS-1);

                   
    carry_gen: CARRY_GENERATOR
        generic map(
            NBIT => NBIT,
            NBIT_PER_BLOCK => NBIT_PER_BLOCK
        )
        port map(
            A   => A,
            B   => B,
            Cin => Cin,
            Co  => carry_out
        );
   
    sum_gen: SUM_GENERATOR
            generic map(
                    NBIT_PER_BLOCK => NBIT_PER_BLOCK,
                    NBLOCKS   	   => NBLOCKS)
             port map(
                    A  => A,
                    B  => B,   
                    Ci => carry_in,
                    S  => S
                    );

end STRUCTURAL;















