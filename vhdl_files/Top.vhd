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
		TOPclock    : IN  STD_LOGIC; --must go through pll
		TOPreset    : IN  STD_LOGIC; --SW0
		-- DEMO OUTPUTS
		TOPdisplay1 : OUT STD_LOGIC_VECTOR(31 DOWNTO 0); --0x80000004
		TOPdisplay2 : OUT STD_LOGIC_VECTOR(31 DOWNTO 0); --0x80000008
		TOPleds     : OUT STD_LOGIC_VECTOR(31 DOWNTO 0); --0x8000000c
		TestLed     : OUT STD_LOGIC
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
	SIGNAL SIGoutputDMorREG : STD_LOGIC_VECTOR (31 DOWNTO 0);
	SIGNAL SIGcounter : STD_LOGIC_VECTOR (31 DOWNTO 0); --0x80000000
	SIGNAL SIGPLLclock : STD_LOGIC;
	SIGNAL SIGPLLclockinverted : STD_LOGIC;
	SIGNAL SIGclock : STD_LOGIC; --either from pll or simulation
	--SIGNAL SIGclockInverted : STD_LOGIC; --either from pll or simulation
	SIGNAL SIGsimulOn : STD_LOGIC; --either from pll or simulation
	
	
	
	SIGNAL REGLed, SIGLed, csLed, CSRAM, dataLed, muxLoadDelay : STD_LOGIC; -- TEST LED Output
	SIGNAL SRAMq_b, ledstate : std_logic_vector(31 downto 0);
	SIGNAL PCTEST : STD_LOGIC_VECTOR (11 DOWNTO 0);
	

BEGIN
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

	SIGsimulOn <= '0';
	SIGclock <= TOPclock WHEN SIGsimulOn = '1' ELSE
		SIGPLLclock;
	--SIGclockInverted <= NOT TOPclock ;--WHEN SIGsimulOn = '1' ELSE
		--SIGPLLclockinverted;
	SIGoutputDMorREG <= SIGcounter WHEN SIGaddrDM = x"80000000" ELSE
		SIGoutputDM;

---------------------------------------------
	csLed <= SIGaddrDM(31);
	
	dataLed <= SIGinputDM(0);

	muxLoadDelay <= '0' when TOPreset='1' else
						 SIGaddrDM(31) when rising_edge(SIGclock);
						 
	SIGLed <= dataLed WHEN SIGaddrDM(31) = '1' AND SIGstore='1' ELSE
				 REGLed;
				 
	ledstate <= x"0000000" & "000" & REGLed;
				 
	SIGoutputDM<= ledstate when muxLoadDelay='1' else
							  SRAMq_b;
						
						
	REGLed <= '0' WHEN TOPreset = '1' ELSE
				 SIGLed WHEN rising_edge(SIGclock);

	TestLed <= REGLed;
	
	CSRAM <= '1'; --NOT csLed;
---------------------------------------------
	-- INSTANCES
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
	
	PCTEST <= SIGprogcounter(13 DOWNTO 2);
	
	Memory : RAM_2PORT
	PORT MAP(
		address_a => PCTEST, --: IN STD_LOGIC_VECTOR (11 DOWNTO 0); --  Add instruction
		--address_a => SIGprogcounter(10 DOWNTO 0), --: IN STD_LOGIC_VECTOR (11 DOWNTO 0); --  Add instruction
		address_b => SIGaddrDM(11 DOWNTO 0), --: IN STD_LOGIC_VECTOR (11 DOWNTO 0); --  Add memory
		clock     => SIGclock, --: IN STD_LOGIC  := '1';
		data_a => (OTHERS => '0'), --: IN STD_LOGIC_VECTOR (31 DOWNTO 0); -- Instruction
		data_b    => SIGinputDM, --: IN STD_LOGIC_VECTOR (31 DOWNTO 0);	-- Data
		enable	 => CSRAM,
		wren_a    => '0', --: IN STD_LOGIC  := '0';					-- Write Instruction Select
		wren_b    => SIGstore, --: IN STD_LOGIC  := '0';					-- Write Data Select
		q_a       => SIGinstruction, --: OUT STD_LOGIC_VECTOR (31 DOWNTO 0);-- DataOut Instruction
		q_b       => SRAMq_b --: OUT STD_LOGIC_VECTOR (31 DOWNTO 0) -- DataOut Data
	);
	--    instIM  : InstructionMemory
	--    port map(
	--        IMclock          => SIGclock,
	--        IMprogcounter    => SIGprogcounter,
	--        IMout            => SIGinstruction
	--    );
	--
	--    instDM  : DataMemory
	--    port map(
	--        DMclock          => SIGclock,
	--        --DMclock          => SIGclockInverted,
	--        DMstore          => SIGstore,
	--        DMload           => SIGload,
	--        DMaddr           => SIGaddrDM,--complex
	--        DMin             => SIGinputDM,--complex
	--        DMfunct3         => SIGfunct3,
	--        DMout            => SIGoutputDM--complex
--	);

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
		DISPinput    => SIGoutputDM,
		DISPWrite    => SIGstore,
		--OUTPUTS
		DISPleds     => TOPleds,
		DISPdisplay1 => TOPdisplay1,
		DISPdisplay2 => TOPdisplay2
	);

	instPLL : clock1M
	PORT MAP(
		areset => TOPreset,
		inclk0 => TOPclock,
		c0     => SIGPLLclock
		--locked     => SIGPLLclockinverted
	);
	-- END
END archi;
-- END FILE