-- Projet de fin d'études : RISC-V
-- ECE Paris / SECAPEM
-- Top entity VHDL = Processor + DataMemory + InstructionMemory

-- LIBRARIES
LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;
USE work.simulPkg.ALL;
USE work.SDRAM_package.ALL;

-- ENTITY
ENTITY Top IS
	PORT (
		-- INPUTS
		enableDebug, switchSEL, switchSEL2   : IN    STD_LOGIC; -- input for debuger
		TOPclock                             : IN    STD_LOGIC; --must go through pll
		buttonClock                          : IN    STD_LOGIC;
		reset                                : IN    STD_LOGIC;                                    --SW0

		-- OUTPUTS
		TOPdisplay1                          : OUT   STD_LOGIC_VECTOR(31 DOWNTO 0);                --0x80000004
		TOPdisplay2                          : OUT   STD_LOGIC_VECTOR(31 DOWNTO 0);                --0x80000008
		TOPleds                              : OUT   STD_LOGIC_VECTOR(31 DOWNTO 0);                --0x8000000c

		SDRAM_ADDR                           : OUT   STD_LOGIC_VECTOR (12 DOWNTO 0);               -- Address
		SDRAM_DQ                             : INOUT STD_LOGIC_VECTOR ((DATA_WIDTH - 1) DOWNTO 0); -- data input / output
		SDRAM_BA                             : OUT   STD_LOGIC_VECTOR (1 DOWNTO 0);                -- BA0 / BA1 ?
		SDRAM_DQM                            : OUT   STD_LOGIC_VECTOR ((DQM_WIDTH - 1) DOWNTO 0);  -- LDQM ? UDQM ?
		SDRAM_RAS_N, SDRAM_CAS_N, SDRAM_WE_N : OUT   STD_LOGIC;                                    -- RAS + CAS + WE = CMD
		SDRAM_CKE, SDRAM_CS_N                : OUT   STD_LOGIC;                                    -- CKE (clock rising edge) | CS ?
		SDRAM_CLK                            : OUT   STD_LOGIC

	);
END ENTITY;

-- ARCHITECTURE
ARCHITECTURE archi OF Top IS

	-- COMPONENTS
	-- processor
	COMPONENT Processor IS
		PORT (
			-- INPUTS
			Hold            : IN  STD_LOGIC;
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
		PORT (
			areset : IN  STD_LOGIC := '0';
			inclk0 : IN  STD_LOGIC := '0';
			c0     : OUT STD_LOGIC;
			locked : OUT STD_LOGIC
		);
	END COMPONENT;

	COMPONENT RAM_2PORT IS
		PORT (
			address_a : IN  STD_LOGIC_VECTOR (11 DOWNTO 0);
			address_b : IN  STD_LOGIC_VECTOR (11 DOWNTO 0);
			clock     : IN  STD_LOGIC := '1';
			data_a    : IN  STD_LOGIC_VECTOR (31 DOWNTO 0);
			data_b    : IN  STD_LOGIC_VECTOR (31 DOWNTO 0);
			enable    : IN  STD_LOGIC := '1';
			wren_a    : IN  STD_LOGIC := '0';
			wren_b    : IN  STD_LOGIC := '0';
			q_a       : OUT STD_LOGIC_VECTOR (31 DOWNTO 0);
			q_b       : OUT STD_LOGIC_VECTOR (31 DOWNTO 0)
		);
	END COMPONENT;
	COMPONENT DEBUGER IS
		PORT (
			-- INPUTS
			enable                : IN  STD_LOGIC;
			SwitchSel, SwitchSel2 : IN  STD_LOGIC;
			--reset    	: IN STD_LOGIC; --SW0
			PCregister            : IN  STD_LOGIC_VECTOR(15 DOWNTO 0);
			Instruction           : IN  STD_LOGIC_VECTOR(31 DOWNTO 0);

			--OUTPUTS
			TOPdisplay2           : OUT STD_LOGIC_VECTOR(31 DOWNTO 0) := (OTHERS => '1'); --0x80000008
			TOPdisplay1           : OUT STD_LOGIC_VECTOR(31 DOWNTO 0) := (OTHERS => '1')  --0x80000004
		);
	END COMPONENT;

	COMPONENT SDRAM_32b IS
		PORT (
			-- SDRAM Inputs
			Clock, Reset     : IN  STD_LOGIC;
			-- Inputs (32bits)
			IN_Address       : IN  STD_LOGIC_VECTOR(25 DOWNTO 0);
			IN_Write_Select  : IN  STD_LOGIC;
			IN_Data_32       : IN  STD_LOGIC_VECTOR(31 DOWNTO 0);
			IN_Select        : IN  STD_LOGIC;
			IN_Function3     : IN  STD_LOGIC_VECTOR(1 DOWNTO 0);
			-- Outputs (16b)
			OUT_Address      : OUT STD_LOGIC_VECTOR(24 DOWNTO 0);
			OUT_Write_Select : OUT STD_LOGIC;
			OUT_Data_16      : OUT STD_LOGIC_VECTOR(15 DOWNTO 0);
			OUT_Select       : OUT STD_LOGIC;
			OUT_DQM          : OUT STD_LOGIC_VECTOR(1 DOWNTO 0);
			-- Test Outputs (32bits)
			Ready_32b        : OUT STD_LOGIC;
			Data_Ready_32b   : OUT STD_LOGIC;
			DataOut_32b      : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
			-- Test Outputs (16bits)
			Ready_16b        : IN  STD_LOGIC;
			Data_Ready_16b   : IN  STD_LOGIC;
			DataOut_16b      : IN  STD_LOGIC_VECTOR(15 DOWNTO 0)
		);
	END COMPONENT;

	COMPONENT SDRAM_controller IS
		PORT (
			clk, Reset                           : IN    STD_LOGIC;
			SDRAM_ADDR                           : OUT   STD_LOGIC_VECTOR (12 DOWNTO 0);               -- Address
			SDRAM_DQ                             : INOUT STD_LOGIC_VECTOR ((DATA_WIDTH - 1) DOWNTO 0); -- data input / output
			SDRAM_BA                             : OUT   STD_LOGIC_VECTOR (1 DOWNTO 0);                -- BA0 / BA1 ?
			SDRAM_DQM                            : OUT   STD_LOGIC_VECTOR ((DQM_WIDTH - 1) DOWNTO 0);  -- LDQM ? UDQM ?
			SDRAM_RAS_N, SDRAM_CAS_N, SDRAM_WE_N : OUT   STD_LOGIC;                                    -- RAS + CAS + WE = CMD
			SDRAM_CKE, SDRAM_CS_N                : OUT   STD_LOGIC;                                    -- CKE (clock rising edge) | CS ?
			SDRAM_CLK                            : OUT   STD_LOGIC;
			Data_OUT                             : OUT   STD_LOGIC_VECTOR ((DATA_WIDTH - 1) DOWNTO 0);
			Data_IN                              : IN    STD_LOGIC_VECTOR ((DATA_WIDTH - 1) DOWNTO 0);
			DQM                                  : IN    STD_LOGIC_VECTOR ((DQM_WIDTH - 1) DOWNTO 0);
			Address_IN                           : IN    STD_LOGIC_VECTOR (24 DOWNTO 0);
			Write_IN                             : IN    STD_LOGIC;
			Select_IN                            : IN    STD_LOGIC;
			Ready                                : OUT   STD_LOGIC;
			Data_Ready                           : OUT   STD_LOGIC
		);
	END COMPONENT;
	COMPONENT miniCache IS
		PORT (
			-- INPUTS
			clock             : IN  STD_LOGIC;
			reset             : IN  STD_LOGIC;
			bootfinish			: out std_logic;

			------------------------ TO PROC -----------------------
			PROCinstruction   : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
			PROCoutputDM      : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
			PROChold          : OUT STD_LOGIC;
			----------------------- FROM PROC ----------------------
			PROCprogcounter   : IN  STD_LOGIC_VECTOR(31 DOWNTO 0);
			PROCstore         : IN  STD_LOGIC;
			PROCload          : IN  STD_LOGIC;
			PROCfunct3        : IN  STD_LOGIC_VECTOR(2 DOWNTO 0);
			PROCaddrDM        : IN  STD_LOGIC_VECTOR(31 DOWNTO 0);
			PROCinputDM       : IN  STD_LOGIC_VECTOR(31 DOWNTO 0);

			-------------------- TO SDRAM 32 ----------------------
			funct3            : OUT STD_LOGIC_VECTOR(2 DOWNTO 0);
			writeSelect, csDM : OUT STD_LOGIC;
			AddressDM, inputDM  : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
			-------------------- FROM SDRAM 32 --------------------
			Ready_32b         : IN  STD_LOGIC;
			Data_Ready_32b    : IN  STD_LOGIC;
			DataOut_32b       : IN  STD_LOGIC_VECTOR(31 DOWNTO 0)
		);
	END COMPONENT;
	
	-- SIGNALS
	--SIGNAL SIGoutputDMorREG : STD_LOGIC_VECTOR (31 DOWNTO 0);
	SIGNAL SIGcounter                                    : STD_LOGIC_VECTOR (31 DOWNTO 0); --0x80000000
	SIGNAL SIGPLLclock                                   : STD_LOGIC;
	SIGNAL SIGPLLclockinverted                           : STD_LOGIC;
	SIGNAL SIGclock                                      : STD_LOGIC; --either from pll or simulation
	--SIGNAL SIGclockInverted : STD_LOGIC; --either from pll or simulation
	SIGNAL SIGsimulOn                                    : STD_LOGIC; --either from pll or simulation
	SIGNAL TOPreset                                      : STD_LOGIC;
	SIGNAL PLLlock                                       : STD_LOGIC;

	--SIGNAL debuger

	SIGNAL debugDisplay1, debugDisplay2			           : STD_LOGIC_VECTOR(31 DOWNTO 0);
	SIGNAL procDisplay1, procDisplay2, procLed           : STD_LOGIC_VECTOR(31 DOWNTO 0);

	-- Outputs to SDRAM controlle(16b)
	SIGNAL SIGOUT_Address                                : STD_LOGIC_VECTOR(24 DOWNTO 0);
	SIGNAL SIGOUT_Write_Select                           : STD_LOGIC;
	SIGNAL SIGOUT_Data_16                                : STD_LOGIC_VECTOR(15 DOWNTO 0);
	SIGNAL SIGOUT_Select                                 : STD_LOGIC;
	SIGNAL SIGOUT_DQM                                    : STD_LOGIC_VECTOR(1 DOWNTO 0);
	-- Outputs of SDRAM controller (16bits)
	SIGNAL SIGReady_16b                                  : STD_LOGIC;
	SIGNAL SIGData_Ready_16b                             : STD_LOGIC;
	SIGNAL SIGDataOut_16b                                : STD_LOGIC_VECTOR(15 DOWNTO 0);
	
	
	--------SIGNALS minichache
	SIGNAL SIGPROCinstruction 			: STD_LOGIC_VECTOR(31 DOWNTO 0);
	SIGNAL SIGPROCoutputDM 	  			: STD_LOGIC_VECTOR(31 DOWNTO 0);
	SIGNAL SIGPROChold 		 			: STD_LOGIC;
	SIGNAL SIGPROCprogcounter 			: STD_LOGIC_VECTOR(31 DOWNTO 0);
	SIGNAL SIGPROCstore, SIGPROCload : STD_LOGIC;
	SIGNAL SIGPROCfunct3 				: STD_LOGIC_VECTOR(2 DOWNTO 0);
	SIGNAL SIGPROCaddrDM 			   : STD_LOGIC_VECTOR(31 DOWNTO 0);
	SIGNAL SIGPROCinputDM 				: STD_LOGIC_VECTOR(31 DOWNTO 0);
	SIGNAL SIGfunct3 						: STD_LOGIC_VECTOR(2 DOWNTO 0);
	SIGNAL SIGcsDM, SIGwriteSelect   : STD_LOGIC;
	SIGNAL SIGinputDM, SIGAddressDM  : STD_LOGIC_VECTOR(31 DOWNTO 0);
	SIGNAL SIGReady_32b, SIGData_Ready_32b : STD_LOGIC;
	SIGNAL SIGDataOut_32b 				: STD_LOGIC_VECTOR(31 DOWNTO 0);
	
	SIGNAL SIGbootfinish	 				: std_logic;
BEGIN

	TOPreset <= '1' WHEN reset = '1' ELSE
				   reset WHEN rising_edge(SIGclock);
	-- BEGIN
	-- ALL
	-- TEST BENCH ONLY ---

	PKG_instruction   <= SIGPROCinstruction;
	PKG_store         <= SIGPROCstore;
	PKG_load          <= SIGPROCload;
	PKG_funct3        <= SIGPROCfunct3;
	PKG_addrDM        <= SIGPROCaddrDM;
	PKG_inputDM       <= SIGPROCinputDM;
	PKG_progcounter   <= SIGPROCprogcounter;
	PKG_counter       <= SIGcounter;
	SIGsimulOn			<= PKG_simulON;
	-----------------------

	SIGclock          <= TOPclock WHEN SIGsimulOn = '1' ELSE
	buttonClock WHEN enableDebug = '1' AND SIGbootfinish='1'  ELSE
	SIGPLLclock;



	TOPdisplay1 <= procDisplay1 WHEN enableDebug = '0' ELSE
		            debugDisplay1;

	TOPdisplay2 <= procDisplay2 WHEN enableDebug = '0' ELSE
		            debugDisplay2;

	TOPLeds <= procLed WHEN enableDebug = '0' ELSE
				  procLed;
		
	-- INSTANCES

	debug : debUGER
	PORT MAP(
		--TOPclock =>
		enable      => enableDebug,
		SwitchSel   => switchSEL,
		SwitchSel2  => switchSEL2,
		--reset => 
		PCregister  => SIGPROCprogcounter(15 DOWNTO 0),
		Instruction => SIGPROCinstruction,
		--OUTPUTS
		TOPdisplay2 => debugDisplay2,
		TOPdisplay1 => debugDisplay1
	);

	instPROC : Processor
	PORT MAP(
		Hold            => SIGPROChold,
		PROCclock       => SIGclock,
		PROCreset       => TOPreset,
		PROCinstruction => SIGPROCinstruction,
		PROCoutputDM    => SIGPROCoutputDM,
		-- OUTPUTS
		PROCprogcounter => SIGPROCprogcounter,
		PROCstore       => SIGPROCstore,
		PROCload        => SIGPROCload,
		PROCfunct3      => SIGPROCfunct3,
		PROCaddrDM      => SIGPROCaddrDM,
		PROCinputDM     => SIGPROCinputDM
	);

	instCPT : Counter
	PORT MAP(
		CPTclock   => SIGclock,
		CPTreset   => TOPreset,
		CPTwrite   => SIGPROCstore,
		CPTaddr    => SIGPROCaddrDM,
		CPTinput   => SIGPROCoutputDM,
		CPTcounter => SIGcounter
	);

	instDISP : Displays
	PORT MAP(
		--INPUTS
		DISPclock    => SIGclock,
		DISPreset    => TOPreset,
		DISPaddr     => SIGPROCaddrDM,
		DISPinput    => SIGPROCinputDM,
		DISPWrite    => SIGPROCstore,
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
		locked => PLLlock
	);

	SDRAMconverter : SDRAM_32b
	PORT MAP(
		-- SDRAM Inputs
		Clock            => SIGclock,
		Reset            => TOPreset,
		-- Inputs (32bits)
		IN_Address       => SIGAddressDM(25 DOWNTO 0),
		IN_Write_Select  => SIGwriteSelect,
		IN_Data_32       => SIGinputDM,
		IN_Select        => SIGcsDM,
		IN_Function3     => SIGfunct3(1 DOWNTO 0),
		-- Outputs (16b)
		OUT_Address      => SIGOUT_Address,
		OUT_Write_Select => SIGOUT_Write_Select,
		OUT_Data_16      => SIGOUT_Data_16,
		OUT_Select       => SIGOUT_Select,
		OUT_DQM          => SIGOUT_DQM,
		-- Outputs (32bits)
		Ready_32b        => SIGReady_32b,
		Data_Ready_32b   => SIGData_Ready_32b,
		DataOut_32b      => SIGDataOut_32b, -- For TestBench Simulation
		--		DataOut_32b			=> SIGoutputDM,
		-- Outputs (16bits)
		Ready_16b        => SIGReady_16b,
		Data_Ready_16b   => SIGData_Ready_16b,
		DataOut_16b      => SIGDataOut_16b
	);

	SDRAMcontroller : SDRAM_controller
	PORT MAP(
		clk         => SIGclock,
		Reset       => TOPreset,
		SDRAM_ADDR  => SDRAM_ADDR,
		SDRAM_DQ    => SDRAM_DQ,
		SDRAM_BA    => SDRAM_BA,
		SDRAM_DQM   => SDRAM_DQM,
		SDRAM_RAS_N => SDRAM_RAS_N,
		SDRAM_CAS_N => SDRAM_CAS_N,
		SDRAM_WE_N  => SDRAM_WE_N,
		SDRAM_CKE   => SDRAM_CKE,
		SDRAM_CS_N  => SDRAM_CS_N,
		SDRAM_CLK   => SDRAM_CLK,
		Data_OUT    => SIGDataOut_16b,
		Data_IN     => SIGOUT_Data_16,
		DQM         => SIGOUT_DQM,
		Address_IN  => SIGOUT_Address,
		Write_IN    => SIGOUT_Write_Select,
		Select_IN   => SIGOUT_Select,
		Ready       => SIGReady_16b,
		Data_Ready  => SIGData_Ready_16b
	);
	
	minicacheInst : minicache
	PORT MAP(
		-- SDRAM Inputs
		clock            => SIGclock,
		reset            => TOPreset,
		bootfinish		  => SIGbootfinish,
		------------------------ TO PROC -----------------------
		PROCinstruction  => SIGPROCinstruction,
		PROCoutputDM     => SIGPROCoutputDM,
		PROChold         => SIGPROChold,
		----------------------- FROM PROC ----------------------
		PROCprogcounter  => SIGPROCprogcounter,
		PROCstore        => SIGPROCstore,
		PROCload         => SIGPROCload,
		PROCfunct3       => SIGPROCfunct3,
		PROCaddrDM       => SIGPROCaddrDM,
		PROCinputDM      => SIGPROCinputDM,

		-------------------- TO SDRAM 32 ----------------------
		funct3           => SIGfunct3,
		writeSelect      => SIGwriteSelect,
		csDM             => SIGcsDM,
		AddressDM        => SIGAddressDM,
		inputDM          => SIGinputDM,
		-------------------- FROM SDRAM 32 --------------------
		Ready_32b        => SIGReady_32b,
		Data_Ready_32b   => SIGData_Ready_32b,
		DataOut_32b      => SIGDataOut_32b
	);
	-- END
END archi;
-- END FILE