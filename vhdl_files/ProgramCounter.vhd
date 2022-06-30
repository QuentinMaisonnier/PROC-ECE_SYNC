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
		PCprogcounter : INOUT STD_LOGIC_VECTOR(31 DOWNTO 0);
		PCprec : out STD_LOGIC_VECTOR(31 DOWNTO 0)
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

	SIGNAL MuxPCprevious, RPCprevious : std_LOGIC_VECTOR(31 downto 0);

BEGIN
	-- BEGIN

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
	
--	SigMux1Out <= x"00000001" WHEN SigMux1Sel = '0'ELSE 
--					  "00" & PCoffset(31 DOWNTO 2) ; -- set lsb to 0

   SigMux1Out <= x"00000004" WHEN SigMux1Sel = '0'ELSE 
				     PCoffset ; -- set lsb to 0

	-- adder
	SigOffSum <= --STD_LOGIC_VECTOR(unsigned(PCprogcounter) + unsigned(SigMux1Out)) when PCjal = '0' AND PCjalr = '0' AND PCLoad='0' AND PCbranch='0' AND PClock='0' else
					 STD_LOGIC_VECTOR(unsigned(PCprogcounter) + unsigned(SigMux1Out)) when PCLoad='0' AND PCbranch='0' AND PClock='0' else
						STD_LOGIC_VECTOR(unsigned(RPCprevious) + unsigned(SigMux1Out));
						
	SigOffSub <= STD_LOGIC_VECTOR(unsigned(PCprogcounter) - unsigned(SigMux1Out)) when PCjal = '0' AND PCjalr = '0' AND PCLoad='0' AND PCbranch='0' AND PCLock='0' else
					 STD_LOGIC_VECTOR(unsigned(RPCprevious) - unsigned(SigMux1Out));

	-- mux 2
	SigMux2Sel <= SigMux1Sel AND PCoffsetsign;
	SigMux2Out <= PCprogcounter when PChold='1' else
					  (PCoffset AND x"fffffffe") WHEN PCjalr = '1' ELSE
					  SigOffSum WHEN (SigMux2Sel = '0' AND PCjalr = '0') OR PCjal = '1' OR PCbranch = '1' ELSE
				     SigOffSub;

	PCprogcounter <= (OTHERS => '0') WHEN PCreset = '1' ELSE
						  SigMux2Out WHEN (rising_edge(PCclock));
		
		
	-----------------------------------------------------------------
	MuxPCprevious <= RPCprevious when PChold='1' else
						  PCprogcounter when PCjal = '0' AND PCjalr = '0' AND PCload='0' AND PCbranch='0' AND PClock='0' else
						  RPCprevious;
						  
	RPCprevious <= (others=>'0') when PCreset='1' else
						MuxPCprevious when rising_edge(PCclock);		
				
	PCprec <= RPCprevious;		
	
	-- END
END archi;
-- END FILE