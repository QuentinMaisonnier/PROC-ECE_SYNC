-- Projet de fin d'études : RISC-V
-- ECE Paris / SECAPEM
-- Top entity VHDL = Processor + DataMemory + InstructionMemory

-- LIBRARIES
LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;
USE work.simulPkg.ALL;

-- ENTITY
ENTITY Top IS
	PORT (
		-- INPUTS
		enableDebug, switchSEL, switchSEL2 : IN STD_LOGIC; -- input for debuger
		TOPclock    			  : IN  STD_LOGIC; --must go through pll
		reset    				  : IN  STD_LOGIC; --SW0
		-- OUTPUTS
		TOPdisplay1 			  : OUT STD_LOGIC_VECTOR(31 DOWNTO 0); --0x80000004
		TOPdisplay2 			  : OUT STD_LOGIC_VECTOR(31 DOWNTO 0); --0x80000008
		TOPleds     			  : OUT STD_LOGIC_VECTOR(31 DOWNTO 0) --0x8000000c

	);
END ENTITY;

-- ARCHITECTURE
ARCHITECTURE archi OF Top IS

	-- COMPONENTS
	-- processor
	COMPONENT Processor IS
		PORT (
			-- INPUTS
			PROCclock       : IN  STD_LOGIC;
			PROCreset       : IN  STD_LOGIC;
			PROCinstruction : IN  STD_LOGIC_VECTOR(31 DOWNTO 0);
			PROCoutputDM    : IN  STD_LOGIC_VECTOR(31 DOWNTO 0);
			-- OUTPUTS
			PROCprogcounter : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
			PROCstore       : OUT STD_LOGIC;
			PROCload        : OUT STD_LOGIC;
			PROCfunct3      : OUT STD_LOGIC_VECTOR(2 DOWNTO 0);
			PROCaddrDM      : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
			PROCinputDM     : OUT STD_LOGIC_VECTOR(31 DOWNTO 0)
		);
	END COMPONENT;

	-- instruction memory
	COMPONENT InstructionMemory IS
		PORT (
			-- INPUTS
			IMclock       : IN  STD_LOGIC;
			IMprogcounter : IN  STD_LOGIC_VECTOR(31 DOWNTO 0);
			-- OUTPUTS
			IMout         : OUT STD_LOGIC_VECTOR(31 DOWNTO 0)
		);
	END COMPONENT;

	--data memory
	COMPONENT DataMemory IS
		PORT (
			-- INPUTS
			DMclock  : IN  STD_LOGIC;
			DMstore  : IN  STD_LOGIC;
			DMload   : IN  STD_LOGIC;
			DMaddr   : IN  STD_LOGIC_VECTOR(31 DOWNTO 0);
			DMin     : IN  STD_LOGIC_VECTOR(31 DOWNTO 0);
			DMfunct3 : IN  STD_LOGIC_VECTOR(2 DOWNTO 0);
			-- OUTPUTS
			DMout    : OUT STD_LOGIC_VECTOR(31 DOWNTO 0)
		);
	END COMPONENT;

	COMPONENT Counter IS
		PORT (
			-- INPUTS
			CPTclock   : IN  STD_LOGIC;
			CPTreset   : IN  STD_LOGIC;
			CPTwrite   : IN  STD_LOGIC;
			CPTaddr    : IN  STD_LOGIC_VECTOR(31 DOWNTO 0);
			CPTinput   : IN  STD_LOGIC_VECTOR(31 DOWNTO 0);

			-- OUTPUTS
			CPTcounter : OUT STD_LOGIC_VECTOR(31 DOWNTO 0)
		);
	END COMPONENT;

	COMPONENT Displays IS
		PORT (
			--INPUTS
			DISPclock    : IN  STD_LOGIC;
			DISPreset    : IN  STD_LOGIC;
			DISPaddr     : IN  STD_LOGIC_VECTOR(31 DOWNTO 0);
			DISPinput    : IN  STD_LOGIC_VECTOR(31 DOWNTO 0);
			DISPwrite    : IN  STD_LOGIC;

			--OUTPUTS
			DISPleds     : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
			DISPdisplay1 : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
			DISPdisplay2 : OUT STD_LOGIC_VECTOR(31 DOWNTO 0)
		);
	END COMPONENT;

	
	COMPONENT clock1M IS
		PORT
		(
			areset		: IN STD_LOGIC  := '0';
			inclk0		: IN STD_LOGIC  := '0';
			c0		: OUT STD_LOGIC ;
			locked		: OUT STD_LOGIC 
		);
	END COMPONENT;
	
	COMPONENT RAM_2PORT IS
		PORT (
			address_a		: IN STD_LOGIC_VECTOR (11 DOWNTO 0);
			address_b		: IN STD_LOGIC_VECTOR (11 DOWNTO 0);
			clock		: IN STD_LOGIC  := '1';
			data_a		: IN STD_LOGIC_VECTOR (31 DOWNTO 0);
			data_b		: IN STD_LOGIC_VECTOR (31 DOWNTO 0);
			enable		: IN STD_LOGIC  := '1';
			wren_a		: IN STD_LOGIC  := '0';
			wren_b		: IN STD_LOGIC  := '0';
			q_a		: OUT STD_LOGIC_VECTOR (31 DOWNTO 0);
			q_b		: OUT STD_LOGIC_VECTOR (31 DOWNTO 0)
		);
	END COMPONENT;
	
	
	COMPONENT DEBUGER IS
		PORT (
			-- INPUTS
			--TOPclock    : IN STD_LOGIC; --must go through pll
			enable 		: IN STD_LOGIC;
			SwitchSel	: IN STD_LOGIC;
			SwitchSel2	: IN STD_LOGIC;
			--reset    	: IN STD_LOGIC; --SW0
			PCregister  : IN STD_LOGIC_VECTOR(15 downto 0);
			Instruction : IN STD_LOGIC_VECTOR(31 downto 0);
			--OUTPUTS
			TOPdisplay2 : OUT STD_LOGIC_VECTOR(31 DOWNTO 0); --0x80000004
			TOPdisplay1 : OUT STD_LOGIC_VECTOR(31 DOWNTO 0); --0x80000004
			TOPleds     : OUT STD_LOGIC_VECTOR(31 DOWNTO 0) --0x8000000c
		);
	END COMPONENT;
	

	-- SIGNALS
	-- instruction memory
	SIGNAL SIGprogcounter : STD_LOGIC_VECTOR (31 DOWNTO 0);
	SIGNAL SIGinstruction : STD_LOGIC_VECTOR (31 DOWNTO 0);
	-- data memory
	SIGNAL SIGfunct3 : STD_LOGIC_VECTOR (2 DOWNTO 0);
	SIGNAL SIGload : STD_LOGIC;
	SIGNAL SIGstore : STD_LOGIC;
	SIGNAL SIGaddrDM : STD_LOGIC_VECTOR (31 DOWNTO 0);
	SIGNAL SIGinputDM : STD_LOGIC_VECTOR (31 DOWNTO 0);
	SIGNAL SIGoutputDM : STD_LOGIC_VECTOR (31 DOWNTO 0);
	--SIGNAL SIGoutputDMorREG : STD_LOGIC_VECTOR (31 DOWNTO 0);
	SIGNAL SIGcounter : STD_LOGIC_VECTOR (31 DOWNTO 0); --0x80000000
	SIGNAL SIGPLLclock : STD_LOGIC;
	SIGNAL SIGPLLclockinverted : STD_LOGIC;
	SIGNAL SIGclock : STD_LOGIC; --either from pll or simulation
	--SIGNAL SIGclockInverted : STD_LOGIC; --either from pll or simulation
	SIGNAL SIGsimulOn : STD_LOGIC; --either from pll or simulation
	SIGNAL TOPreset : STD_LOGIC;
	SIGNAL PLLlock : STD_LOGIC;
	
	--SIGNAL debuger
	
	SIGNAL debugDisplay1, debugDisplay2, debugLed : STD_LOGIC_VECTOR(31 downto 0);
	SIGNAL procDisplay1, procDisplay2, procLed : STD_LOGIC_VECTOR(31 downto 0);
	SIGNAL csDM : STD_LOGIC;
	
	

BEGIN
	TOPreset <= '1' when reset='1' else
					reset when rising_edge(SIGclock);
	-- BEGIN
	-- ALL
	-- TEST BENCH ONLY ---
	PKG_instruction <= SIGinstruction;
	PKG_store <= SIGstore;
	PKG_load <= SIGload;
	PKG_funct3 <= SIGfunct3;
	PKG_addrDM <= SIGaddrDM;
	PKG_inputDM <= SIGinputDM;
	PKG_outputDM <= SIGoutputDM;
	PKG_progcounter <= SIGprogcounter;
	PKG_counter <= SIGcounter;
	-----------------------

	SIGsimulOn <= '1';
	SIGclock <= TOPclock WHEN SIGsimulOn = '1' ELSE
		SIGPLLclock;
	--SIGclockInverted <= NOT TOPclock ;--WHEN SIGsimulOn = '1' ELSE
		--SIGPLLclockinverted;
--	SIGoutputDMorREG <= SIGcounter WHEN SIGaddrDM = x"80000000" ELSE
--		SIGoutputDM;

---------------------------------------------
	csDM <= '0' when SIGaddrDM(31)='1' else
			  '1';
			  
	TOPdisplay1 <= procDisplay1 when enableDebug='0' else
						debugDisplay1;
						
	TOPdisplay2 <= procDisplay2 when enableDebug='0' else
						debugDisplay2;
						
	TOPLeds <= procLed when enableDebug='0' else
				  --debugLed;
				  procLed;

---------------------------------------------
	-- INSTANCES
	
	debug : debUGER
	PORT MAP(
		--TOPclock =>
		enable => enableDebug,
		SwitchSel => switchSEL,
		SwitchSel2 => switchSEL2,
		--reset => 
		PCregister => SIGprogcounter(15 DOWNTO 0),
		Instruction => SIGinstruction,
		--OUTPUTS
		TOPdisplay2 => debugDisplay2,
		TOPdisplay1 => debugDisplay1,
		TOPleds => debugLed
		);
		
	instPROC : Processor
	PORT MAP(
		PROCclock       => SIGclock,
		PROCreset       => TOPreset,
		PROCinstruction => SIGinstruction,
		PROCoutputDM    => SIGoutputDM,
		-- OUTPUTS
		PROCprogcounter => SIGprogcounter,
		PROCstore       => SIGstore,
		PROCload        => SIGload,
		PROCfunct3      => SIGfunct3,
		PROCaddrDM      => SIGaddrDM,
		PROCinputDM     => SIGinputDM
	);
	
	Memory : RAM_2PORT
	PORT MAP(
		address_a => SIGprogcounter(13 DOWNTO 2), --  Addr instruction (divided by 4 because we use 32 bits memory)
		address_b => SIGaddrDM(13 DOWNTO 2),   	--  Addr memory (divided by 4 because we use 32 bits memory)
		clock     => SIGclock,
		data_a => (OTHERS => '0'),						-- Instruction in
		data_b    => SIGinputDM,						-- Data in
		enable	 => csDM,
		wren_a    => '0',									-- Write Instruction Select
		wren_b    => SIGstore,							-- Write Data Select
		q_a       => SIGinstruction,					-- DataOut Instruction
		q_b       => SIGoutputDM 						-- DataOut Data
	);


	instCPT : Counter
	PORT MAP(
		CPTclock   => SIGclock,
		CPTreset   => TOPreset,
		CPTwrite   => SIGstore,
		CPTaddr    => SIGaddrDM,
		CPTinput   => SIGoutputDM,
		CPTcounter => SIGcounter
	);

	instDISP : Displays
	PORT MAP(
		--INPUTS
		DISPclock    => SIGclock,
		DISPreset    => TOPreset,
		DISPaddr     => SIGaddrDM,
		DISPinput    => SIGinputDM,
		DISPWrite    => SIGstore,
		--OUTPUTS
		DISPleds     => procLed,
		DISPdisplay1 => procDisplay1,
		DISPdisplay2 => procDisplay2
	);

	instPLL : clock1M
	PORT MAP(
		areset => '0',
		inclk0 => TOPclock,
		c0     => SIGPLLclock,
		locked     => PLLlock
	);
	-- END
END archi;
-- END FILE