-- Projet de fin d'études : RISC-V
-- ECE Paris / SECAPEM

-- LIBRARIES
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.simulPkg.all;

-- ENTITY
entity TestBenchTop is
end entity;

architecture VHDL of TestBenchTop is
	component Top is
    port (
		enableDebug, switchSEL, switchSEL2 : IN STD_LOGIC; -- input for debuger
		TOPclock    			  : IN  STD_LOGIC; --must go through pll
		buttonClock				  : IN STD_LOGIC;
		reset    				  : IN  STD_LOGIC; --SW0
		
		-- OUTPUTS
		TOPdisplay1 			  : OUT STD_LOGIC_VECTOR(31 DOWNTO 0); --0x80000004
		TOPdisplay2 			  : OUT STD_LOGIC_VECTOR(31 DOWNTO 0); --0x80000008
		TOPleds     			  : OUT STD_LOGIC_VECTOR(31 DOWNTO 0); --0x8000000c
		
		SDRAM_ADDR   	 		  : out STD_LOGIC_VECTOR (12 downto 0);  -- Address
	   SDRAM_DQ   	 			  : inout STD_LOGIC_VECTOR ((31) downto 0); -- data input / output
		SDRAM_BA   	 			  : out STD_LOGIC_VECTOR (1 downto 0);  -- BA0 / BA1 ?
	   SDRAM_DQM				  : out STD_LOGIC_VECTOR ((31) downto 0);          -- LDQM ? UDQM ?
		SDRAM_RAS_N, SDRAM_CAS_N, SDRAM_WE_N : out STD_LOGIC;  -- RAS + CAS + WE = CMD
		SDRAM_CKE, SDRAM_CS_N  : out STD_LOGIC ;             -- CKE (clock rising edge) | CS ?
		SDRAM_CLK 				  : out STD_LOGIC 

	);
	end component;

	signal reset, ck : std_logic;
	signal dataReady_32b : std_logic;
	signal counter, progcounter, instr: std_logic_vector(31 downto 0);
	signal R_In_Addr: std_logic_vector(25 downto 0);
    
	signal dataAddr: std_logic_vector(31 downto 0);
	signal load, store : std_logic;
	signal dataLength : std_logic_vector(2 downto 0);
	signal inputData, outputData: std_logic_vector(31 downto 0);
   
	
	signal reg00, reg01, reg02, reg03, reg04, reg05, reg06, reg07, reg08, reg09, reg0A, reg0B, reg0C, reg0D, reg0E, reg0F, reg10, reg11, reg12, reg13, reg14, reg15, reg16, reg17, reg18, reg19, reg1A, reg1B, reg1C, reg1D, reg1E, reg1F : std_logic_vector(31 downto 0);
	signal SigTOPdisplay1, SigTOPdisplay2 : std_logic_vector (31 downto 0);

	TYPE instructiontab IS ARRAY (0 TO 59) OF STD_LOGIC_vector(31 downto 0);
--	signal TabInstruction : instructiontab := (x"00001137", x"03c000ef", x"fe010113", x"01212823", x"00005937",
--															 x"00812c23", x"00912a23", x"01312623", x"00112e23", x"00100493",
--															 x"00000413", x"00a00993", x"e2090913", x"00149493", x"01341663",
--															 x"00902623", x"00090513", x"00140413", x"f89ff0ef", x"ff010113",
--															 x"00012623", x"00000793", x"00a7c863", x"00c12703", x"00000000",x"00178793"
--															 );

	signal TabInstruction : instructiontab := (x"00001137", x"03c000ef", x"00100073", x"0000006f", x"ff010113",
															 x"00012623", x"00000793", x"00a7c863", x"00012623", x"01010113",
															 x"00008067", x"00c12703", x"00178793", x"00170713", x"00e12623",
															 x"fe1ff06f", x"fe010113", x"01212823", x"00005937", x"00812c23",
															 x"00912a23", x"01312623", x"00112e23", x"00100493", x"00000413",
															 x"00a00993", x"e2090913", x"00149493", x"01341663", x"00100493",
															 x"00000413", x"00902623", x"00090513", x"00140413", x"f89ff0ef",
															 x"fe1ff06f", x"00000000", x"00000000", x"00000000", x"00000000",
															 x"00000000", x"00000000", x"00000000", x"00000000", x"00000000",
															 x"00000000", x"00000000", x"00000000", x"00000000", x"00000000",
															 x"00000000", x"00000000", x"00000000", x"00000000", x"00000000",
															 x"00000000", x"00000000", x"00000000", x"00000000", x"00000000"
															 );

	BEGIN
	
	R_In_Addr <= "00" & PKG_R_In_Addr(25 downto 2);
	
	dataReady_32b <= PKG_dataReady_32b;
	
	--instanciation de l'entité PROC
	iTop : Top port map (
	
		TOPclock        => ck,
		reset        	 => reset,
		TOPdisplay1     => SigTOPdisplay1,
		TOPdisplay2     => SigTOPdisplay2,
		
		enableDebug 	 => '0',
		switchSEL		 => '0',
		switchSEL2      => '0',
		buttonClock		 => '0'
		
	);
    
    counter     <= PKG_counter;
    store       <= PKG_store;      
    load        <= PKG_load;       
    dataLength  <= PKG_funct3;     
    dataAddr    <= PKG_addrDM;     
    inputData   <= PKG_inputDM;    
    --outputData  <= PKG_outputDM; 
	 PKG_outputDM  <= outputData;	 
    progcounter <= PKG_progcounter;
    instr       <= PKG_instruction;
    reg00       <= PKG_reg00;
    reg01       <= PKG_reg01;
    reg02       <= PKG_reg02;
    reg03       <= PKG_reg03;
    reg04       <= PKG_reg04;
    reg05       <= PKG_reg05;
    reg06       <= PKG_reg06;
    reg07       <= PKG_reg07;
    reg08       <= PKG_reg08;
    reg09       <= PKG_reg09;
    reg0A       <= PKG_reg0A;
    reg0B       <= PKG_reg0B;
    reg0C       <= PKG_reg0C;
    reg0D       <= PKG_reg0D;
    reg0E       <= PKG_reg0E;
    reg0F       <= PKG_reg0F;
    reg10       <= PKG_reg10;
    reg11       <= PKG_reg11;
    reg12       <= PKG_reg12;
    reg13       <= PKG_reg13;
    reg14       <= PKG_reg14;
    reg15       <= PKG_reg15;
    reg16       <= PKG_reg16;
    reg17       <= PKG_reg17;
    reg18       <= PKG_reg18;
    reg19       <= PKG_reg19;
    reg1A       <= PKG_reg1A;
    reg1B       <= PKG_reg1B;
    reg1C       <= PKG_reg1C;
    reg1D       <= PKG_reg1D;
    reg1E       <= PKG_reg1E;
    reg1F       <= PKG_reg1F;
	 
	 datatestbench: process
	 VARIABLE cpt : integer:=0;
		begin
			
			IF dataReady_32b='1' THEN
--				outputData <= TabInstruction(cpt);

				outputData <= TabInstruction(to_integer(unsigned(R_In_Addr)));
				CPT := CPT + 1;
				wait for 20 ns;
				
			ELSE
				outputData <= (others => 'Z');
				wait for 1 ns;
			END IF;
			
--			IF CPT>25 THEN
--				outputData <= (others => 'Z');
--				wait;
--			END IF;
--			
		end process;

	clocktestbench: process
		begin
		-- init  simulation
			ck <= '1';
			wait for 10 ns;
			ck <= '0';
			wait for 10 ns;
		end process;
		
		resetTestbench : process
		begin
		-- init  simulation
			reset <= '1';
			wait for 2 ns;
			reset <= '0';
			wait;
		end process;
END vhdl;