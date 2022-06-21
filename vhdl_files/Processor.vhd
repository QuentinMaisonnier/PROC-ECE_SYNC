-- Projet de fin d'études : RISC-V
-- ECE Paris / SECAPEM
-- Processor entity VHDL = Alu + RegisterFile + InstructionDecoder + ProgramCounter

-- LIBRARIES
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- ENTITY
entity Processor is
    port (
        -- INPUTS
        PROCclock        : in std_logic;
        PROCreset        : in std_logic;
        PROCinstruction  : in std_logic_vector(31 downto 0);
        PROCoutputDM     : in std_logic_vector(31 downto 0);
        -- OUTPUTS
        PROCprogcounter  : out std_logic_vector(31 downto 0);
        PROCstore        : out std_logic;
        PROCload         : out std_logic;
        PROCfunct3       : out std_logic_vector(2 downto 0);
        PROCaddrDM       : out std_logic_vector(31 downto 0);
        PROCinputDM      : out std_logic_vector(31 downto 0)
    );
end entity;

-- ARCHITECTURE
architecture archi of Processor is

    -- COMPONENTS
    -- program counter
    component ProgramCounter is
        port (
			-- INPUTS
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
    end component;

    -- instruction decoder
    component InstructionDecoder is
        port (
            -- INPUTS
            -- instruction endianness must be Big Endian !
            IDinstruction : in std_logic_vector (31 downto 0);
            -- OUTPUTS
            IDopcode      : out std_logic_vector (6 downto 0);
            IDimmSel      : out std_logic;
            IDrd          : out std_logic_vector (4 downto 0);
            IDrs1         : out std_logic_vector (4 downto 0);
            IDrs2         : out std_logic_vector (4 downto 0);
            IDfunct3      : out std_logic_vector (2 downto 0);
            IDfunct7      : out std_logic;
            IDimm12I      : out std_logic_vector (11 downto 0);
            IDimm12S      : out std_logic_vector (11 downto 0);
            IDimm13B      : out std_logic_vector (12 downto 0);
            IDimm32U      : out std_logic_vector (31 downto 0);
            IDimm21J      : out std_logic_vector (20 downto 0);
            IDload        : out std_logic;
            IDstore       : out std_logic;
            IDlui         : out std_logic;
            IDauipc       : out std_logic;
            IDjal         : out std_logic;
            IDjalr        : out std_logic;
            IDbranch      : out std_logic
        );
    end component;

    --register file
    component RegisterFile is
        port (
            -- INPUTS
            RFclock        : in std_logic;
            RFreset        : in std_logic;
            RFin           : in std_logic_vector(31 downto 0);
            RFrd           : in std_logic_vector(4 downto 0);
            RFrs1          : in std_logic_vector(4 downto 0);
            RFrs2          : in std_logic_vector(4 downto 0);
            -- OUTPUTS
            RFout1         : out std_logic_vector(31 downto 0);
            RFout2         : out std_logic_vector(31 downto 0)
        );
    end component;

    --alu
    component Alu is
        port (
            -- INPUTS
            ALUin1         : in std_logic_vector (31 downto 0);
            ALUin2         : in std_logic_vector (31 downto 0);
            ALUfunct7      : in std_logic;
            ALUfunct3      : in std_logic_vector (2 downto 0);
            -- OUTPUTS
            ALUout         : out std_logic_vector (31 downto 0);
            ALUsup         : out std_logic;
            ALUeq          : out std_logic;
            ALUinf         : out std_logic;
            ALUinfU        : out std_logic;
            ALUsupU        : out std_logic
        );
    end component;

    -- SIGNALS
    -- program counter
    signal SIGoffsetPC1    : std_logic_vector (31 downto 0);
    signal SIGoffsetPC2    : std_logic_vector (31 downto 0);
    signal SIGoffsetPC3    : std_logic_vector (31 downto 0);
    signal SIGoffsetPC     : std_logic_vector (31 downto 0);
    signal SIGoffsetsignPC : std_logic;
    signal SIGprogcounter  : std_logic_vector (31 downto 0);
    -- instruction decoder
    signal SIGopcode       : std_logic_vector (6 downto 0);
    signal SIGimmSel       : std_logic;
    signal SIGrdID         : std_logic_vector (4 downto 0);
    signal SIGrdRF         : std_logic_vector (4 downto 0);
    signal SIGrs1          : std_logic_vector (4 downto 0);
    signal SIGrs2          : std_logic_vector (4 downto 0);
    signal SIGfunct3       : std_logic_vector (2 downto 0);
    signal SIGfunct7       : std_logic;
    signal SIGimm12I       : std_logic_vector (11 downto 0);
    signal SIGimm12S       : std_logic_vector (11 downto 0);
    signal SIGimm13B       : std_logic_vector (12 downto 0);
    signal SIGimm32U       : std_logic_vector (31 downto 0);
    signal SIGimm21J       : std_logic_vector (20 downto 0);
    signal SIGload         : std_logic;
    signal SIGstore        : std_logic;
    signal SIGlui          : std_logic;
    signal SIGauipc        : std_logic;
    signal SIGjal          : std_logic;
    signal SIGjalr         : std_logic;
    signal SIGbranch       : std_logic;
    -- register file
    signal SIGinputRF      : std_logic_vector (31 downto 0);
    signal SIGoutput1RF    : std_logic_vector (31 downto 0);
    signal SIGoutput2RF    : std_logic_vector (31 downto 0);
    -- alu
    signal SIGinput1ALU    : std_logic_vector (31 downto 0);
    signal SIGinput2ALU    : std_logic_vector (31 downto 0);
    signal SIGoutputALU    : std_logic_vector (31 downto 0);
    signal SIGfunct3ALU    : std_logic_vector (2 downto 0);
    signal SIGfunct7ALU    : std_logic;
    signal SIGeqALU        : std_logic;
    signal SIGinfALU       : std_logic;
    signal SIGsupALU       : std_logic;
    signal SIGinfUALU      : std_logic;
    signal SIGsupUALU      : std_logic;
	 
	 
	 
	 --SIG delay for synchronous memory
	 signal Muxinstruction : std_logic_vector(31 downto 0);
	 SIGNAL MuxNOPtest, RegNOPtest : STD_logic;
	 SIGNAL RegaddrLoad : std_logic_vector(4 downto 0);
	 SIGNAL WriteReg : STD_LOGIC; --enable to write data load in register
	 SIGNAL funct3Load, function3 : std_logic_vector(2 downto 0);
	 SIGNAL DMout : std_logic_vector(31 downto 0);
	 SIGNAL Regreset : std_logic;
	 signal SigLock         : std_logic;
	 
	 SIGNAL PCprec : std_logic_vector (31 downto 0); -- send the last value of PC when instruction are JAL, JALR, LOAD or BRANCH
	 SIGNAL PC : std_logic_vector (31 downto 0);

begin
    -- BEGIN
	
    -- ALL
    -- program counter
	 
	 	  
    PROCprogcounter <=  SIGprogcounter;
	 
    SIGoffsetsignPC <=  SIGimm21J(20);
	 
    SIGoffsetPC1    <=  SIGimm32U when SIGauipc = '1' else
                        SIGoutputALU when SIGjalr = '1' else
                        (others => '0');
								
    SIGoffsetPC2(20 downto 0)   <= SIGimm21J;
    SIGoffsetPC2(31 downto 21)  <= (others => '1') when SIGoffsetsignPC = '1' else (others => '0');
    SIGoffsetPC3(12 downto 0)   <= SIGimm13B;
    SIGoffsetPC3(31 downto 13)  <= (others => '1') when SIGoffsetsignPC = '1'        else (others => '0');
    SIGoffsetPC                 <= SIGoffsetPC1 when SIGauipc = '1' OR SIGjalr = '1' else
                                   SIGoffsetPC2 when SIGjal = '1'                    else
                                   SIGoffsetPC3 when SIGbranch = '1'                 else (others => '0');
    -- register file
	 
	 RegaddrLoad <= (others=>'0') when PROCreset='1' else
						 SIGrdID when rising_edge(PROCclock);
						 
	 WriteReg <= '0' when PROCreset='1' else --- on decale juste sigload de 1 cycle
					 sigload when rising_edge(PROCclock);
					 
    SIGrdRF <=  RegaddrLoad when SIGstore = '0' AND WriteReg='1' else
					 SIGrdID when (SIGbranch = '0' AND SIGstore = '0') else
                (others => '0');
					 
    SIGinputRF <= DMout when WriteReg = '1' else --- avant il y a avait sigload (au cas ou ca pmarche plus)
                std_logic_vector(unsigned(SIGprogcounter)+4) when (SIGjal = '1' OR SIGjalr = '1') else
                SIGimm32U when SIGlui = '1' else
                std_logic_vector(unsigned(SIGimm32U) + unsigned(SIGprogcounter)) when SIGauipc = '1' else
                SIGoutputALU   when SIGstore = '0' else
                (others => '0');
    -- alu
    SIGfunct7ALU    <=    '0' when ((SIGfunct3ALU = "000" OR
                                     SIGfunct3ALU = "010" OR
                                     SIGfunct3ALU = "011" OR
                                     SIGfunct3ALU = "100" OR
                                     SIGfunct3ALU = "110" OR
                                     SIGfunct3ALU = "111") AND
                                    (SIGimmSel = '1' OR
                                     SIGload = '1' OR
                                     SIGstore = '1' OR
                                     SIGjalr = '1' )) else
                                    SIGfunct7;
    SIGfunct3ALU    <=    "000" when (SIGstore = '1' OR SIGload = '1') else
                                      SIGfunct3;
    SIGinput1ALU    <=     SIGoutput1RF;

    SIGinput2ALU(11 downto 0) <=
    SIGimm12S(11 downto 0) when SIGstore = '1' else
    SIGimm12I(11 downto 0) when (SIGload = '1' OR SIGimmSel = '1' OR SIGjalr = '1') else
    SIGoutput2RF(11 downto 0);

    SIGinput2ALU(31 downto 12) <=
    (others => '0') when (SIGimmSel = '1' OR SIGload = '1' OR SIGstore = '1' OR SIGjalr = '1') AND SIGimm12I(11) = '0' else
    (others => '1') when (SIGimmSel = '1' OR SIGload = '1' OR SIGstore = '1' OR SIGjalr = '1') AND SIGimm12I(11) = '1' else
    SIGoutput2RF(31 downto 12);

    -- data memory
    PROCaddrDM   <= SIGoutputALU;
    PROCinputDM  <= SIGoutput2RF;
    PROCstore    <= SIGstore;
	 
	 funct3Load <= (others=>'0') when procreset='1' else
						SIGfunct3 when rising_edge(proCclock);
						
	 function3 <= funct3Load when writeReg='1' else
						  SIGfunct3;	
	 
	 PROCfunct3 <= function3;
	 
    PROCload     <= SIGload;
	 
	
	 -----------NOP----------------------- 
	 Muxinstruction <= x"00000013" when RegNOPtest = '1' OR RegReset='1'  else
							 PROCinstruction;
							 
	SIGprogcounter <= PCprec when SIGbranch='1' OR SIGjal='1' OR SIGjalr='1' OR SIGload='1' OR SIGoutputALU(31)='1' else --when nop instruction we use the last PC
							PC;
	
	MuxNOPtest <= '1' when SIGbranch='1' OR SIGjal='1' OR SIGjalr='1' OR SIGload='1' OR SIGoutputALU(31)='1' else -- JUMP/JUMPR/LOAD/BEQ(IF)
						'0';
	
	RegNOPtest <= '0' when PROCreset='1' else
						 MuxNOPtest when rising_edge(PROCclock);	 -- if we detect a instruction that need a nop
						 
	RegReset <= '1' when PROCreset='1' else
					PROcreset when rising_edge(PROCclock);
						 
						 
	SigLock <='1' when SIGoutputALU(31)='1' else
					'0';
	------------------------------------
	
--	DMout <= PROCoutputDM;
	
	DMout <= std_logic_vector(resize(signed(PROCoutputDM(7 downto 0)), DMout'length)) when WriteReg='1' and function3 = "000" else
				std_logic_vector(resize(signed(PROCoutputDM(15 downto 0)), DMout'length)) when WriteReg='1' and function3 = "001" else
				PROCoutputDM(31 downto 0) when WriteReg='1' and function3 = "010" else
				std_logic_vector(resize(unsigned(PROCoutputDM(7 downto 0)), DMout'length)) when  WriteReg='1' and function3 = "100" else
				std_logic_vector(resize(unsigned(PROCoutputDM(15 downto 0)), DMout'length)) when  WriteReg='1' and function3 = "101" else
				(others=>'0');
	
--	(others=>'0') when Procreset='1' else
--			PROCoutputDM(7) & PROCoutputDM(7) & PROCoutputDM(7) & PROCoutputDM(7) & PROCoutputDM(7) & PROCoutputDM(7) & PROCoutputDM(7) & PROCoutputDM(7) & PROCoutputDM(7) & PROCoutputDM(7) & PROCoutputDM(7) & PROCoutputDM(7) & PROCoutputDM(7) & PROCoutputDM(7) & PROCoutputDM(7) & PROCoutputDM(7) & PROCoutputDM(7) & PROCoutputDM(7) & PROCoutputDM(7) & PROCoutputDM(7) & PROCoutputDM(7) & PROCoutputDM(7) & PROCoutputDM(7) & PROCoutputDM(7) & PROCoutputDM(7 downto 0) when WriteReg='1' and function3 = "000" else
--			PROCoutputDM(7) & PROCoutputDM(7) & PROCoutputDM(7) & PROCoutputDM(7) & PROCoutputDM(7) & PROCoutputDM(7) & PROCoutputDM(7) & PROCoutputDM(7) & PROCoutputDM(7) & PROCoutputDM(7) & PROCoutputDM(7) & PROCoutputDM(7) & PROCoutputDM(7) & PROCoutputDM(7) & PROCoutputDM(7) & PROCoutputDM(7) & PROCoutputDM(15 downto 0) when WriteReg='1' and function3 = "001" else
--			PROCoutputDM(31 downto 0) when WriteReg='1' and function3 = "010" else
--			x"000000" & PROCoutputDM(7 downto 0) when  WriteReg='1' and function3 = "100" else
--			x"0000" & PROCoutputDM(15 downto 0) when  WriteReg='1' and function3 = "101" else
--			(others=>'0');

    -- INSTANCES
    instPC  : ProgramCounter
    port map(
        PCclock          => PROCclock,
        PCreset          => PROCreset,
        PCoffset         => SIGoffsetPC,--complex
        PCoffsetsign     => SIGoffsetsignPC,--complex
        PCjal            => SIGjal,
        PCjalr           => SIGjalr,
        PCbranch         => SIGbranch,
        PCfunct3         => SIGfunct3,
        PCauipc          => SIGauipc,
        PCalueq          => SIGeqALU,
        PCaluinf         => SIGinfALU,
        PCalusup         => SIGsupALU,
        PCaluinfU        => SIGinfUALU,
        PCalusupU        => SIGsupUALU,
		  PCLoad 			 => Sigload,
		  PClock				 => SigLock,
        PCprogcounter    => PC,
		  PCprec 			 => Pcprec
    );

    instID  : InstructionDecoder
    port map(
        IDinstruction    => Muxinstruction, -- ICI
		  --IDinstruction    => PROCinstruction, -- ICI
        IDopcode         => SIGopcode,
        IDimmSel         => SIGimmSel,
        IDrd             => SIGrdID,
        IDrs1            => SIGrs1,
        IDrs2            => SIGrs2,
        IDfunct3         => SIGfunct3,
        IDfunct7         => SIGfunct7,
        IDimm12I         => SIGimm12I,
        IDimm12S         => SIGimm12S,
        IDimm13B         => SIGimm13B,
        IDimm32U         => SIGimm32U,
        IDimm21J         => SIGimm21J,
        IDload           => SIGload,
        IDstore          => SIGstore,
        IDlui            => SIGlui,
        IDauipc          => SIGauipc,
        IDjal            => SIGjal,
        IDjalr           => SIGjalr,
        IDbranch         => SIGbranch
    );

    instRF  : RegisterFile
    port map(
        RFclock         => PROCclock,
        RFreset         => PROCreset,
        RFin            => SIGinputRF,--complex
        RFrd            => SIGrdRF,
        RFrs1           => SIGrs1,
        RFrs2           => SIGrs2,
        RFout1          => SIGoutput1RF,--complex
        RFout2          => SIGoutput2RF--complex
    );

    instALU : Alu
    port map(
        ALUin1      => SIGinput1ALU,--complex
        ALUin2      => SIGinput2ALU,--complex
        ALUfunct7   => SIGfunct7ALU,--chiant
        ALUfunct3   => SIGfunct3ALU,
        ALUout      => SIGoutputALU,--complex
        ALUeq       => SIGeqALU,
        ALUinf      => SIGinfALU,
        ALUsup      => SIGsupALU,
        ALUinfU     => SIGinfUALU,
        ALUsupU     => SIGsupUALU
    );

    -- END
end archi;
-- END FILE
