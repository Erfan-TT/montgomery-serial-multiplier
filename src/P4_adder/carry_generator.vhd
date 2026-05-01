----------------------------------------------------------------------------------
-- Sparse tree like carry generator 
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.math_real.ALL;
use IEEE.numeric_std.ALL;

entity CARRY_GENERATOR is

        generic (
            NBIT :          integer := 32;
            NBIT_PER_BLOCK: integer := 4);

        port (
            A :      in    std_logic_vector(NBIT-1 downto 0);
            B :      in    std_logic_vector(NBIT-1 downto 0);
            Cin :    in    std_logic;
            Co :     out    std_logic_vector((NBIT/NBIT_PER_BLOCK)-1 downto 0));
end CARRY_GENERATOR;

architecture Structural of carry_generator is

    constant LOG2_N_OVER_4 : integer := integer(ceil(log2(real(NBIT/NBIT_PER_BLOCK)))); 
    constant MAX_LAYERS : integer := 2 + LOG2_N_OVER_4;
    
    type signal_matrix is array (0 to MAX_LAYERS) of std_logic_vector(NBIT-1 downto 0);
    signal P, G: signal_matrix;
    signal p0, g0: std_logic;
    component G_block is
    port (
        Gik    : in  std_logic;  -- Generate upper
        Pik    : in  std_logic;  -- Propagate upper
        Gk1j   : in  std_logic;  -- Generate lower
        Gij    : out std_logic   -- Generate output
    );
    end component;

    component PG_block is
    port (
        Gik    : in  std_logic;  -- Generate upper
        Pik    : in  std_logic;  -- Propagate upper
        Gk1j   : in  std_logic;  -- Generate lower
        Pk1j   : in  std_logic;  -- Propagate lower
        Gij    : out std_logic;  -- Generate output
        Pij    : out std_logic   -- Propagate output
    );
    end  component;

    component PG_elem is
    port (
        a : in  std_logic;
        b : in  std_logic;
        p : out std_logic;
        g : out std_logic
    );
    end component;
      
begin

    --------------------------------------------------------------------------------------
    --Layer 0: PG-network
    --------------------------------------------------------------------------------------
    layer0_gen: for i in 0 to NBIT-1 generate
        include_cin: if i = 0 generate
            PG0_elem_inst: PG_elem 
                port map(
                    a => a(i),
                    b => b(i),
                    p => p0,
                    g => g0);
            
            G_cin_inst: G_block
                port map(
                    Gik => g0,
                    Pik => p0,
                    Gk1j => Cin,
                    Gij => G(0)(i));
            P(0)(i) <= '0';
        end generate;
        
        PG_network: if i > 0 generate 
            PG_elem_inst: PG_elem
                port map(a => a(i), 
                         b => b(i), 
                         p => P(0)(i), 
                         g => G(0)(i));
            end generate;
    end generate;
    --------------------------------------------------------------------------------------
    --Layer 1 and 2: binary tree structure
    --------------------------------------------------------------------------------------                                                                                                                
    binary_layers: for L in 1 to 2 generate 
        constant DISTANCE   : integer := 2**(L-1);
        constant MOD_VAL    : integer := 2**L;
        constant TARGET_I   : integer := MOD_VAL - 1;
    begin
        layer_generate: for i in 0 to NBIT-1 generate
            passive_nodes: if (i mod MOD_VAL /= TARGET_I) generate
                P(L)(i) <= P(L-1)(i);
                G(L)(i) <= G(L-1)(i);
            end generate;     
            
            active_nodes: if (i mod MOD_VAL = TARGET_I) generate
                -- G block @ the right most active node
                G_blk: if (i = TARGET_I) generate
                    G_inst: G_block
                        port map(   Gik  => G(L-1)(i),
                                    Pik  => P(L-1)(i),
                                    Gk1j => G(L-1)(i- DISTANCE),
                                    Gij  => G(L)(i)
                            );
                    P(L)(i) <= '0';
                end generate;
                -- PG blocks
                PG_blk: if(i > TARGET_I) generate   
                    PG_inst: PG_block
                        port map(
                                Gik  => G(L-1)(i),
                                Pik  => P(L-1)(i),
                                Gk1j => G(L-1)(i - DISTANCE),
                                Pk1j => P(L-1)(i - DISTANCE),
                                Gij  => G(L)(i),
                                Pij  => P(L)(i)                        
                        );
                end generate;                        
            end generate;   
        end generate;          
    end generate;
    
    --------------------------------------------------------------------------------------
    --Layer 3 and onward: sparse tree structure
    --------------------------------------------------------------------------------------                                                                                                                
    tree_layers: for s in 1 to LOG2_N_OVER_4 generate
        constant L : integer := s + 2; -- since 0 1 and 2 are already considered        
        constant D : integer := 2**(s - 1); -- exponentially increasing skip distance 
    begin
        layer_s_gen: for i in 0 to NBIT-1 generate
            constant is_4multiple : boolean := (i mod 4 = 3);
        begin
            passive_nodes: if not is_4multiple generate
                P(L)(i) <= P(L-1)(i);
                G(L)(i) <= G(L-1)(i);
            end generate;

            active_nodes: if is_4multiple generate
                constant GRP : integer := (i + 1) / 4; -- identifies group number for i
                -- for first layer of sparse tree even cardinality groups are active
                -- for layers >1 groups are not active for the fist skip distance, and the 
                -- active nodes are clustered together clusters have gaps = cluster size = skip distance
                constant cluster_num : integer := (GRP - D - 1)/D;
                constant is_active_GRP : boolean := ((s = 1) and (GRP mod 2 = 0)) or ((s > 1) and (GRP > D) and (cluster_num mod 2 = 0));
            begin
                passive_grps: if not is_active_GRP generate
                    P(L)(i) <= P(L-1)(i);
                    G(L)(i) <= G(L-1)(i);
                end generate;

                active_grps: if is_active_GRP generate
                    constant lower_input_grp : integer := ((GRP - 1) / D) * D; -- k_right => lower_input_grp
                    constant lower_input_node : integer := (4 * lower_input_grp) - 1;  -- i_right => lower_input_node 
                    constant is_g_blk : boolean := (lower_input_grp = D);

                begin
                    g_blk: if is_g_blk generate
                        G_inst: G_block
                            port map (
                                Gik  => G(L-1)(i),
                                Pik  => P(L-1)(i),
                                Gk1j => G(L-1)(lower_input_node),
                                Gij  => G(L)(i)
                            );
                        P(L)(i) <= '0';
                    end generate;

                    pg_blk: if not is_g_blk generate
                        PG_inst: PG_block
                            port map (
                                Gik  => G(L-1)(i),
                                Pik  => P(L-1)(i),
                                Gk1j => G(L-1)(lower_input_node),
                                Pk1j => P(L-1)(lower_input_node),
                                Gij  => G(L)(i),
                                Pij  => P(L)(i)
                            );
                    end generate;
                end generate;
            end generate;
        end generate;
    end generate;

    ----------------------------------------------------------------------------------------------
    -- Carry generate assignment
    ----------------------------------------------------------------------------------------------
    carry_out_gen: for i in 0 to (NBIT/NBIT_PER_BLOCK)-1 generate
      Co(i) <= G(MAX_LAYERS)((i+1)*NBIT_PER_BLOCK - 1);
    end generate;  
      
end architecture Structural;
