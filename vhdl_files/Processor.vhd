-- Projet de fin d'études : RISC-V
-- ECE Paris / SECAPEM
-- Processor entity VHDL = Alu + RegisterFile + InstructionDecoder + ProgramCounter

-- LIBRARIES
LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;

-- ENTITY
ENTITY Processor IS
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
END ENTITY;

-- ARCHITECTURE
ARCHITECTURE archi OF Processor IS

	-- COMPONENTS
	-- program counter
	COMPONENT ProgramCounter IS
		PORT (
			-- INPUTS
			PChold        : IN    STD_LOGIC;
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
			PClock        : IN    STD_LOGIC;
			PCLoad        : IN    STD_LOGIC;
			-- OUTPUTS
			PCnext : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
		   PC 	 : out STD_LOGIC_VECTOR(31 DOWNTO 0)
		);
	END COMPONENT;

	-- instruction decoder
	COMPONENT InstructionDecoder IS
		PORT (
			-- INPUTS
			-- instruction endianness must be Big Endian !
			IDinstruction : IN  STD_LOGIC_VECTOR (31 DOWNTO 0);
			-- OUTPUTS
			IDopcode      : OUT STD_LOGIC_VECTOR (6 DOWNTO 0);
			IDimmSel      : OUT STD_LOGIC;
			IDrd          : OUT STD_LOGIC_VECTOR (4 DOWNTO 0);
			IDrs1         : OUT STD_LOGIC_VECTOR (4 DOWNTO 0);
			IDrs2         : OUT STD_LOGIC_VECTOR (4 DOWNTO 0);
			IDfunct3      : OUT STD_LOGIC_VECTOR (2 DOWNTO 0);
			IDfunct7      : OUT STD_LOGIC;
			IDimm12I      : OUT STD_LOGIC_VECTOR (11 DOWNTO 0);
			IDimm12S      : OUT STD_LOGIC_VECTOR (11 DOWNTO 0);
			IDimm13B      : OUT STD_LOGIC_VECTOR (12 DOWNTO 0);
			IDimm32U      : OUT STD_LOGIC_VECTOR (31 DOWNTO 0);
			IDimm21J      : OUT STD_LOGIC_VECTOR (20 DOWNTO 0);
			IDload        : OUT STD_LOGIC;
			IDstore       : OUT STD_LOGIC;
			IDlui         : OUT STD_LOGIC;
			IDauipc       : OUT STD_LOGIC;
			IDjal         : OUT STD_LOGIC;
			IDjalr        : OUT STD_LOGIC;
			IDbranch      : OUT STD_LOGIC
		);
	END COMPONENT;

	--register file
	COMPONENT RegisterFile IS
		PORT (
			-- INPUTS
			hold    : IN  STD_LOGIC;
			RFclock : IN  STD_LOGIC;
			RFreset : IN  STD_LOGIC;
			RFin    : IN  STD_LOGIC_VECTOR(31 DOWNTO 0);
			RFrd    : IN  STD_LOGIC_VECTOR(4 DOWNTO 0);
			RFrs1   : IN  STD_LOGIC_VECTOR(4 DOWNTO 0);
			RFrs2   : IN  STD_LOGIC_VECTOR(4 DOWNTO 0);
			-- OUTPUTS
			RFout1  : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
			RFout2  : OUT STD_LOGIC_VECTOR(31 DOWNTO 0)
		);
	END COMPONENT;

	--alu
	COMPONENT Alu IS
		PORT (
			-- INPUTS
			ALUin1    : IN  STD_LOGIC_VECTOR (31 DOWNTO 0);
			ALUin2    : IN  STD_LOGIC_VECTOR (31 DOWNTO 0);
			ALUfunct7 : IN  STD_LOGIC;
			ALUfunct3 : IN  STD_LOGIC_VECTOR (2 DOWNTO 0);
			-- OUTPUTS
			ALUout    : OUT STD_LOGIC_VECTOR (31 DOWNTO 0);
			ALUsup    : OUT STD_LOGIC;
			ALUeq     : OUT STD_LOGIC;
			ALUinf    : OUT STD_LOGIC;
			ALUinfU   : OUT STD_LOGIC;
			ALUsupU   : OUT STD_LOGIC
		);
	END COMPONENT;

	-- SIGNALS
	-- program counter
	SIGNAL SIGoffsetPC1           : STD_LOGIC_VECTOR (31 DOWNTO 0);
	SIGNAL SIGoffsetPC2           : STD_LOGIC_VECTOR (31 DOWNTO 0);
	SIGNAL SIGoffsetPC3           : STD_LOGIC_VECTOR (31 DOWNTO 0);
	SIGNAL SIGoffsetPC            : STD_LOGIC_VECTOR (31 DOWNTO 0);
	SIGNAL SIGoffsetsignPC        : STD_LOGIC;
	SIGNAL SIGprogcounter         : STD_LOGIC_VECTOR (31 DOWNTO 0);
	SIGNAL SIGprogcounterfetch    : STD_LOGIC_VECTOR (31 DOWNTO 0);
	-- instruction decoder
	SIGNAL SIGopcode              : STD_LOGIC_VECTOR (6 DOWNTO 0);
	SIGNAL SIGimmSel              : STD_LOGIC;
	SIGNAL SIGrdID, MuxrdID       : STD_LOGIC_VECTOR (4 DOWNTO 0);
	SIGNAL SIGrdRF                : STD_LOGIC_VECTOR (4 DOWNTO 0);
	SIGNAL SIGrs1                 : STD_LOGIC_VECTOR (4 DOWNTO 0);
	SIGNAL SIGrs2                 : STD_LOGIC_VECTOR (4 DOWNTO 0);
	SIGNAL SIGfunct3              : STD_LOGIC_VECTOR (2 DOWNTO 0);
	SIGNAL Muxfunct3Load          : STD_LOGIC_VECTOR (2 DOWNTO 0);

	SIGNAL SIGfunct7              : STD_LOGIC;
	SIGNAL SIGimm12I              : STD_LOGIC_VECTOR (11 DOWNTO 0);
	SIGNAL SIGimm12S              : STD_LOGIC_VECTOR (11 DOWNTO 0);
	SIGNAL SIGimm13B              : STD_LOGIC_VECTOR (12 DOWNTO 0);
	SIGNAL SIGimm32U              : STD_LOGIC_VECTOR (31 DOWNTO 0);
	SIGNAL SIGimm21J              : STD_LOGIC_VECTOR (20 DOWNTO 0);
	SIGNAL SIGload, Muxload       : STD_LOGIC;
	SIGNAL SIGstore               : STD_LOGIC;
	SIGNAL SIGlui                 : STD_LOGIC;
	SIGNAL SIGauipc               : STD_LOGIC;
	SIGNAL SIGjal                 : STD_LOGIC;
	SIGNAL SIGjalr                : STD_LOGIC;
	SIGNAL SIGbranch              : STD_LOGIC;
	-- register file
	SIGNAL SIGinputRF             : STD_LOGIC_VECTOR (31 DOWNTO 0);
	SIGNAL SIGoutput1RF           : STD_LOGIC_VECTOR (31 DOWNTO 0);
	SIGNAL SIGoutput2RF           : STD_LOGIC_VECTOR (31 DOWNTO 0);
	-- alu
	SIGNAL SIGinput1ALU           : STD_LOGIC_VECTOR (31 DOWNTO 0);
	SIGNAL SIGinput2ALU           : STD_LOGIC_VECTOR (31 DOWNTO 0);
	SIGNAL SIGoutputALU           : STD_LOGIC_VECTOR (31 DOWNTO 0);
	SIGNAL SIGfunct3ALU           : STD_LOGIC_VECTOR (2 DOWNTO 0);
	SIGNAL SIGfunct7ALU           : STD_LOGIC;
	SIGNAL SIGeqALU               : STD_LOGIC;
	SIGNAL SIGinfALU              : STD_LOGIC;
	SIGNAL SIGsupALU              : STD_LOGIC;
	SIGNAL SIGinfUALU             : STD_LOGIC;
	SIGNAL SIGsupUALU             : STD_LOGIC;

	--SIG delay for synchronous memory
	SIGNAL Muxinstruction         : STD_LOGIC_VECTOR(31 DOWNTO 0);
	SIGNAL MuxNOPtest, RegNOPtest : STD_LOGIC;
	SIGNAL RegaddrLoad            : STD_LOGIC_VECTOR(4 DOWNTO 0);
	SIGNAL WriteReg               : STD_LOGIC; --enable to write data load in register
	SIGNAL funct3Load, function3  : STD_LOGIC_VECTOR(2 DOWNTO 0);
	SIGNAL DMout                  : STD_LOGIC_VECTOR(31 DOWNTO 0);
	SIGNAL Regreset               : STD_LOGIC;
	SIGNAL SigLock                : STD_LOGIC;

	SIGNAL PCprec                 : STD_LOGIC_VECTOR (31 DOWNTO 0); -- send the last value of PC when instruction are JAL, JALR, LOAD or BRANCH
	SIGNAL PC                     : STD_LOGIC_VECTOR (31 DOWNTO 0);

BEGIN
	-- BEGIN

	-- ALL
	-- program counter
	PROCprogcounter <= SIGprogcounterfetch;

	SIGoffsetsignPC <= SIGimm21J(20);

	SIGoffsetPC1    <= SIGimm32U WHEN SIGauipc = '1' ELSE
							 SIGoutputALU WHEN SIGjalr = '1' ELSE
							 (OTHERS => '0');

	SIGoffsetPC2(20 DOWNTO 0)  <= SIGimm21J;
	
	SIGoffsetPC2(31 DOWNTO 21) <= (OTHERS => '1') WHEN SIGoffsetsignPC = '1' ELSE (OTHERS => '0');
	
	SIGoffsetPC3(12 DOWNTO 0)  <= SIGimm13B;
	
	SIGoffsetPC3(31 DOWNTO 13) <= (OTHERS => '1') WHEN SIGoffsetsignPC = '1' ELSE (OTHERS => '0');
	
	SIGoffsetPC                <= SIGoffsetPC1 WHEN SIGauipc = '1' OR SIGjalr = '1' ELSE
											SIGoffsetPC2 WHEN SIGjal = '1' ELSE
											SIGoffsetPC3 WHEN SIGbranch = '1' ELSE (OTHERS => '0');
	-- register file

	RegaddrLoad <= (OTHERS => '0') WHEN PROCreset = '1' ELSE
		            MuxrdID WHEN rising_edge(PROCclock);
						
	MuxrdID <= SIGrdID WHEN Hold = '0' ELSE
		        RegaddrLoad;

	WriteReg <= '0' WHEN PROCreset = '1' ELSE --- on decale juste sigload de 1 cycle
		         Muxload WHEN rising_edge(PROCclock);

	Muxload <= SIGload WHEN Hold = '0' ELSE
				  WriteReg;

	SIGrdRF <= RegaddrLoad WHEN SIGstore = '0' AND WriteReg = '1' ELSE
				  SIGrdID WHEN (SIGbranch = '0' AND SIGstore = '0') ELSE
				  (OTHERS => '0');

	SIGinputRF <= DMout WHEN WriteReg = '1' ELSE --- avant il y a avait sigload (au cas ou ca pmarche plus)
					  STD_LOGIC_VECTOR(unsigned(SIGprogcounter) + 4) WHEN (SIGjal = '1' OR SIGjalr = '1') ELSE
					  SIGimm32U WHEN SIGlui = '1' ELSE
					  STD_LOGIC_VECTOR(unsigned(SIGimm32U) + unsigned(SIGprogcounter)) WHEN SIGauipc = '1' ELSE
					  SIGoutputALU WHEN SIGstore = '0' ELSE
					  (OTHERS => '0');
	-- alu
	SIGfunct7ALU <= '0' WHEN ((SIGfunct3ALU = "000" OR
						 SIGfunct3ALU = "010" OR
						 SIGfunct3ALU = "011" OR
						 SIGfunct3ALU = "100" OR
						 SIGfunct3ALU = "110" OR
						 SIGfunct3ALU = "111") AND
						 (SIGimmSel = '1' OR
						 SIGload = '1' OR
						 SIGstore = '1' OR
						 SIGjalr = '1')) ELSE
						 SIGfunct7;
		
	SIGfunct3ALU <= "000" WHEN (SIGstore = '1' OR SIGload = '1') ELSE
						 SIGfunct3;
						 
	SIGinput1ALU <= SIGoutput1RF;

	SIGinput2ALU(11 DOWNTO 0) <= SIGimm12S(11 DOWNTO 0) WHEN SIGstore = '1' ELSE
										  SIGimm12I(11 DOWNTO 0) WHEN (SIGload = '1' OR SIGimmSel = '1' OR SIGjalr = '1') ELSE
										  SIGoutput2RF(11 DOWNTO 0);

	SIGinput2ALU(31 DOWNTO 12) <= (OTHERS => '0') WHEN (SIGimmSel = '1' OR SIGload = '1' OR SIGstore = '1' OR SIGjalr = '1') AND SIGimm12I(11) = '0' ELSE
											(OTHERS => '1') WHEN (SIGimmSel = '1' OR SIGload = '1' OR SIGstore = '1' OR SIGjalr = '1') AND SIGimm12I(11) = '1' ELSE
											SIGoutput2RF(31 DOWNTO 12);

	-- data memory
	PROCaddrDM  <= SIGoutputALU;
	PROCinputDM <= SIGoutput2RF;
	PROCstore   <= SIGstore;
	

	funct3Load  <= (OTHERS => '0') WHEN procreset = '1' ELSE
						Muxfunct3Load WHEN rising_edge(proCclock);
						
	Muxfunct3Load <= SIGfunct3 WHEN Hold = '0' ELSE
						  funct3Load;

	function3 <= funct3Load WHEN writeReg = '1' ELSE
					 SIGfunct3;

	PROCfunct3 <= function3;

	PROCload <= SIGload;
	-----------NOP----------------------- 
	Muxinstruction <= x"00000013" WHEN PROCreset = '1'  ELSE
							PROCinstruction;
							
				
	SigLock <= '1' WHEN SIGoutputALU(31) = '1' ELSE
				  '0';
	------------------------------------

	DMout <= PROCoutputDM;

	--	DMout <= std_logic_vector(resize(signed(PROCoutputDM(7 downto 0)), DMout'length)) when WriteReg='1' and function3 = "000" else
	--				std_logic_vector(resize(signed(PROCoutputDM(15 downto 0)), DMout'length)) when WriteReg='1' and function3 = "001" else
	--				PROCoutputDM(31 downto 0) when WriteReg='1' and function3 = "010" else
	--				std_logic_vector(resize(unsigned(PROCoutputDM(7 downto 0)), DMout'length)) when  WriteReg='1' and function3 = "100" else
	--				std_logic_vector(resize(unsigned(PROCoutputDM(15 downto 0)), DMout'length)) when  WriteReg='1' and function3 = "101" else
	--				(others=>'0');
	-- INSTANCES
	
	instPC : ProgramCounter
	PORT MAP(
		PChold        => Hold,
		PCclock       => PROCclock,
		PCreset       => PROCreset,
		PCoffset      => SIGoffsetPC,     --complex
		PCoffsetsign  => SIGoffsetsignPC, --complex
		PCjal         => SIGjal,
		PCjalr        => SIGjalr,
		PCbranch      => SIGbranch,
		PCfunct3      => SIGfunct3,
		PCauipc       => SIGauipc,
		PCalueq       => SIGeqALU,
		PCaluinf      => SIGinfALU,
		PCalusup      => SIGsupALU,
		PCaluinfU     => SIGinfUALU,
		PCalusupU     => SIGsupUALU,
		PCLoad        => Sigload,
		PClock        => SigLock,
		PCnext		  => SIGprogcounterfetch,
		PC 			  => SIGprogcounter
	);

	instID : InstructionDecoder
	PORT MAP(
		IDinstruction => Muxinstruction, -- ICI
--		IDinstruction    => PROCinstruction, -- ICI
		IDopcode      => SIGopcode,
		IDimmSel      => SIGimmSel,
		IDrd          => SIGrdID,
		IDrs1         => SIGrs1,
		IDrs2         => SIGrs2,
		IDfunct3      => SIGfunct3,
		IDfunct7      => SIGfunct7,
		IDimm12I      => SIGimm12I,
		IDimm12S      => SIGimm12S,
		IDimm13B      => SIGimm13B,
		IDimm32U      => SIGimm32U,
		IDimm21J      => SIGimm21J,
		IDload        => SIGload,
		IDstore       => SIGstore,
		IDlui         => SIGlui,
		IDauipc       => SIGauipc,
		IDjal         => SIGjal,
		IDjalr        => SIGjalr,
		IDbranch      => SIGbranch
	);

	instRF : RegisterFile
	PORT MAP(
		Hold    => Hold,
		RFclock => PROCclock,
		RFreset => PROCreset,
		RFin    => SIGinputRF, --complex
		RFrd    => SIGrdRF,
		RFrs1   => SIGrs1,
		RFrs2   => SIGrs2,
		RFout1  => SIGoutput1RF, --complex
		RFout2  => SIGoutput2RF--complex
	);

	instALU : Alu
	PORT MAP(
		ALUin1    => SIGinput1ALU, --complex
		ALUin2    => SIGinput2ALU, --complex
		ALUfunct7 => SIGfunct7ALU, --chiant
		ALUfunct3 => SIGfunct3ALU,
		ALUout    => SIGoutputALU, --complex
		ALUeq     => SIGeqALU,
		ALUinf    => SIGinfALU,
		ALUsup    => SIGsupALU,
		ALUinfU   => SIGinfUALU,
		ALUsupU   => SIGsupUALU
	);

	-- END
END archi;
-- END FILE