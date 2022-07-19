-- Projet de fin d'études : RISC-V
-- ECE Paris / SECAPEM
-- Program Counter VHDL

-- LIBRARIES
LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;

-- ENTITY
ENTITY ProgramCounter IS
	PORT (
		-- INPUTS
		PChold		  : IN    STD_LOGIC;
		PCclock       : IN    STD_LOGIC;
		PCreset       : IN    STD_LOGIC;
		PCoffset      : IN    STD_LOGIC_VECTOR(31 DOWNTO 0);
		PCoffsetsign  : IN    STD_LOGIC;
		PCjal         : IN    STD_LOGIC;
		PCjalr        : IN    STD_LOGIC;
		PCbranch      : IN    STD_LOGIC;
		PCfunct3      : IN    STD_LOGIC_VECTOR(2 DOWNTO 0);
		PCauipc       : IN    STD_LOGIC;
		PCalueq       : IN    STD_LOGIC;
		PCaluinf      : IN    STD_LOGIC;
		PCalusup      : IN    STD_LOGIC;
		PCaluinfU     : IN    STD_LOGIC;
		PCalusupU     : IN    STD_LOGIC;
		PClock :in std_logic;
		PCLoad : IN STD_LOGIC;
		-- OUTPUTS
		--PCnext : INOUT STD_LOGIC_VECTOR(31 DOWNTO 0);
		PCnext : out STD_LOGIC_VECTOR(31 DOWNTO 0);
		PC 	 : out STD_LOGIC_VECTOR(31 DOWNTO 0)
	);
END ENTITY;

-- ARCHITECTURE
ARCHITECTURE archi OF ProgramCounter IS

	SIGNAL SigBranchCond : STD_LOGIC;
	SIGNAL SigMux1Sel : STD_LOGIC;
	SIGNAL SigMux2Sel : STD_LOGIC;
	--SIGNAL SigMux3Sel : STD_LOGIC;
	SIGNAL SigMux1Out : STD_LOGIC_VECTOR(31 DOWNTO 0);
	SIGNAL SigMux2Out : STD_LOGIC_VECTOR(31 DOWNTO 0);
	--SIGNAL SigMux3Out : STD_LOGIC_VECTOR(31 DOWNTO 0);
	SIGNAL SigOffSum : STD_LOGIC_VECTOR(31 DOWNTO 0);
	SIGNAL SigOffSub : STD_LOGIC_VECTOR(31 DOWNTO 0);

--	SIGNAL MuxPCfetch, PC : std_LOGIC_VECTOR(31 downto 0);
	SIGNAL SigPC, SigPCnext, MuxPC : std_LOGIC_VECTOR(31 downto 0);


BEGIN
		
	-----------------------------------------------------------------
	-------------------------- PC REG -------------------------------
	-----------------------------------------------------------------
	MuxPC <= SigPC when PChold='1' else
				SIGPCnext;
--	PC 	<= x"FFFFFFFC" when PCreset='1' else
--				MuxPC when rising_edge(PCclock);
	-----------------------------------------------------------------
	
	
	-----------------------------------------------------------------
	-------------------------- COMBINATORY --------------------------
	-----------------------------------------------------------------
	
	-- branch cond
	SigBranchCond <= PCalueq WHEN PCfunct3 = "000" ELSE
							NOT PCalueq WHEN PCfunct3 = "001" ELSE
							'0' WHEN PCfunct3 = "010" ELSE
							'0' WHEN PCfunct3 = "011" ELSE
							PCaluinf WHEN PCfunct3 = "100" ELSE
							PCalusup OR PCalueq WHEN PCfunct3 = "101" ELSE
							PCaluinfU WHEN PCfunct3 = "110" ELSE
							PCalusupU OR PCalueq WHEN PCfunct3 = "111" ELSE
							'0';

	-- mux 1
	SigMux1Sel <= (SigBranchCond AND PCbranch) OR PCjal OR PCjalr; --mux3
	
   SigMux1Out <= x"00000004" WHEN SigMux1Sel = '0'ELSE 
				     PCoffset ; -- set lsb to 0
					  
	SigOffSum <= --STD_LOGIC_VECTOR(unsigned(SigPC) + unsigned(SigMux1Out)) when SigMux1Sel='0' else
					 STD_LOGIC_VECTOR(unsigned(SigPC) + unsigned(SigMux1Out));
					 
	SigOffSub <= STD_LOGIC_VECTOR(unsigned(SigPC) - unsigned(SigMux1Out)) when SigMux1Sel='0' else
					 STD_LOGIC_VECTOR(unsigned(SIGPCnext) - unsigned(SigMux1Out));
	
	SigMux2Sel <= SigMux1Sel AND PCoffsetsign;
	
	SigMux2Out <= (PCoffset AND x"fffffffe") WHEN PCjalr = '1' ELSE
					  SigOffSum WHEN (SigMux2Sel = '0' AND PCjalr = '0') OR PCjal = '1' OR PCbranch = '1' ELSE
				     SigOffSub;
					  
	SIGPCnext <= SigMux2Out when PChold='0' else
					 SigPC;
					
	PC <= SigPC;
	
	SigPC 	<= (others => '0') when PCreset='1' else
				   MuxPC when rising_edge(PCclock);
	
	PCnext    <= SIGPCnext;
	
	-- END
END archi;
-- END FILE