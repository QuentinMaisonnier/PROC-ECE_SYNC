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
	signal dqm		  : std_LOGIC_vector(3 downto 0);
	signal dataReady_32b, selectSDRAM, storeSDRAM : std_logic;
	signal counter, progcounter, instr, dataIN: std_logic_vector(31 downto 0);
	signal R_In_Addr: std_logic_vector(25 downto 0);
    
	signal dataAddr: std_logic_vector(31 downto 0);
	signal load, store : std_logic;
	signal dataLength : std_logic_vector(2 downto 0);
	signal inputData, outputData: std_logic_vector(31 downto 0);
   
	
	signal reg00, reg01, reg02, reg03, reg04, reg05, reg06, reg07, reg08, reg09, reg0A, reg0B, reg0C, reg0D, reg0E, reg0F, reg10, reg11, reg12, reg13, reg14, reg15, reg16, reg17, reg18, reg19, reg1A, reg1B, reg1C, reg1D, reg1E, reg1F : std_logic_vector(31 downto 0);
	signal SigTOPdisplay1, SigTOPdisplay2 : std_logic_vector (31 downto 0);

	type mem is array(0 to 1023) of std_logic_vector(31 downto 0);
	signal TabInstruction : mem :=(
		x"00001137" , x"064000ef" , x"00100073" , x"0000006f" , x"fe050513" , x"0ff57513" , x"03f00793" , x"00a7ea63",
		x"12800793" , x"00a787b3" , x"0007c503" , x"00008067" , x"07f00513" , x"00008067" , x"ff010113" , x"00012623",
		x"00000793" , x"00a7c863" , x"00012623" , x"01010113" , x"00008067" , x"00c12703" , x"00178793" , x"00170713",
		x"00e12623" , x"fe1ff06f" , x"435557b7" , x"fd010113" , x"f4378793" , x"00f12023" , x"000057b7" , x"54f78793",
		x"02812423" , x"02912223" , x"03212023" , x"00f11223" , x"02112623" , x"800007b7" , x"fff00713" , x"00e7a223",
		x"00010737" , x"fff70713" , x"00e7a423" , x"00001737" , x"ccc70713" , x"00e7a623" , x"00810493" , x"00000413",
		x"00600913" , x"008107b3" , x"0007c503" , x"00140413" , x"00448493" , x"f3dff0ef" , x"fea4ae23" , x"ff2414e3",
		x"00812783" , x"00c12703" , x"800006b7" , x"00879793" , x"00e7e7b3" , x"00f6a423" , x"01012783" , x"01412703",
		x"01879793" , x"01071713" , x"00e7e7b3" , x"01c12703" , x"00e7e7b3" , x"01812703" , x"00871713" , x"00e7e7b3",
		x"00f6a223" , x"0000006f" , x"7f7f7fff" , x"7f7f7f7f" , x"7f7f7f7f" , x"7f7fbf7f" , x"b0a4f9c0" , x"f8829299",
		x"7f7f9080" , x"7f7f7f7f" , x"c683887f" , x"c28e86a1" , x"8ae1fb8b" , x"c0abaac7" , x"92ce988c" , x"95b5c187",
		x"7fa49189" , x"f77f7f7f" , x"00000000" , x"00000000" , x"00000000" , x"00000000" , x"00000000" , x"00000000",
		x"00000000" , x"00000000" , x"00000000" , x"00000000" , x"00000000" , x"00000000" , x"00000000" , x"00000000",
		x"00000000" , x"00000000" , x"00000000" , x"00000000" , x"00000000" , x"00000000" , x"00000000" , x"00000000",
		x"00000000" , x"00000000" , x"00000000" , x"00000000" , x"00000000" , x"00000000" , x"00000000" , x"00000000",
		x"00000000" , x"00000000" , x"00000000" , x"00000000" , x"00000000" , x"00000000" , x"00000000" , x"00000000",
		x"00000000" , x"00000000" , x"00000000" , x"00000000" , x"00000000" , x"00000000" , x"00000000" , x"00000000",
		x"00000000" , x"00000000" , x"00000000" , x"00000000" , x"00000000" , x"00000000" , x"00000000" , x"00000000",
		x"00000000" , x"00000000" , x"00000000" , x"00000000" , x"00000000" , x"00000000" , x"00000000" , x"00000000",
		x"00000000" , x"00000000" , x"00000000" , x"00000000" , x"00000000" , x"00000000" , x"00000000" , x"00000000",
		x"00000000" , x"00000000" , x"00000000" , x"00000000" , x"00000000" , x"00000000" , x"00000000" , x"00000000",
		x"00000000" , x"00000000" , x"00000000" , x"00000000" , x"00000000" , x"00000000" , x"00000000" , x"00000000",
		x"00000000" , x"00000000" , x"00000000" , x"00000000" , x"00000000" , x"00000000" , x"00000000" , x"00000000",
		x"00000000" , x"00000000" , x"00000000" , x"00000000" , x"00000000" , x"00000000" , x"00000000" , x"00000000",
		x"00000000" , x"00000000" , x"00000000" , x"00000000" , x"00000000" , x"00000000" , x"00000000" , x"00000000",
		x"00000000" , x"00000000" , x"00000000" , x"00000000" , x"00000000" , x"00000000" , x"00000000" , x"00000000",
		x"00000000" , x"00000000" , x"00000000" , x"00000000" , x"00000000" , x"00000000" , x"00000000" , x"00000000",
		x"00000000" , x"00000000" , x"00000000" , x"00000000" , x"00000000" , x"00000000" , x"00000000" , x"00000000",
		x"00000000" , x"00000000" , x"00000000" , x"00000000" , x"00000000" , x"00000000" , x"00000000" , x"00000000",
		x"00000000" , x"00000000" , x"00000000" , x"00000000" , x"00000000" , x"00000000" , x"00000000" , x"00000000",
		x"00000000" , x"00000000" , x"00000000" , x"00000000" , x"00000000" , x"00000000" , x"00000000" , x"00000000",
		x"00000000" , x"00000000" , x"00000000" , x"00000000" , x"00000000" , x"00000000" , x"00000000" , x"00000000",
		x"00000000" , x"00000000" , x"00000000" , x"00000000" , x"00000000" , x"00000000" , x"00000000" , x"00000000",
		x"00000000" , x"00000000" , x"00000000" , x"00000000" , x"00000000" , x"00000000" , x"00000000" , x"00000000",
		x"00000000" , x"00000000" , x"00000000" , x"00000000" , x"00000000" , x"00000000" , x"00000000" , x"00000000",
		x"00000000" , x"00000000" , x"00000000" , x"00000000" , x"00000000" , x"00000000" , x"00000000" , x"00000000",
		x"00000000" , x"00000000" , x"00000000" , x"00000000" , x"00000000" , x"00000000" , x"00000000" , x"00000000",
		x"00000000" , x"00000000" , x"00000000" , x"00000000" , x"00000000" , x"00000000" , x"00000000" , x"00000000",
		x"00000000" , x"00000000" , x"00000000" , x"00000000" , x"00000000" , x"00000000" , x"00000000" , x"00000000",
		x"00000000" , x"00000000" , x"00000000" , x"00000000" , x"00000000" , x"00000000" , x"00000000" , x"00000000",
		x"00000000" , x"00000000" , x"00000000" , x"00000000" , x"00000000" , x"00000000" , x"00000000" , x"00000000",
		x"00000000" , x"00000000" , x"00000000" , x"00000000" , x"00000000" , x"00000000" , x"00000000" , x"00000000",
		x"00000000" , x"00000000" , x"00000000" , x"00000000" , x"00000000" , x"00000000" , x"00000000" , x"00000000",
		x"00000000" , x"00000000" , x"00000000" , x"00000000" , x"00000000" , x"00000000" , x"00000000" , x"00000000",
		x"00000000" , x"00000000" , x"00000000" , x"00000000" , x"00000000" , x"00000000" , x"00000000" , x"00000000",
		x"00000000" , x"00000000" , x"00000000" , x"00000000" , x"00000000" , x"00000000" , x"00000000" , x"00000000",
		x"00000000" , x"00000000" , x"00000000" , x"00000000" , x"00000000" , x"00000000" , x"00000000" , x"00000000",
		x"00000000" , x"00000000" , x"00000000" , x"00000000" , x"00000000" , x"00000000" , x"00000000" , x"00000000",
		x"00000000" , x"00000000" , x"00000000" , x"00000000" , x"00000000" , x"00000000" , x"00000000" , x"00000000",
		x"00000000" , x"00000000" , x"00000000" , x"00000000" , x"00000000" , x"00000000" , x"00000000" , x"00000000",
		x"00000000" , x"00000000" , x"00000000" , x"00000000" , x"00000000" , x"00000000" , x"00000000" , x"00000000",
		x"00000000" , x"00000000" , x"00000000" , x"00000000" , x"00000000" , x"00000000" , x"00000000" , x"00000000",
		x"00000000" , x"00000000" , x"00000000" , x"00000000" , x"00000000" , x"00000000" , x"00000000" , x"00000000",
		x"00000000" , x"00000000" , x"00000000" , x"00000000" , x"00000000" , x"00000000" , x"00000000" , x"00000000",
		x"00000000" , x"00000000" , x"00000000" , x"00000000" , x"00000000" , x"00000000" , x"00000000" , x"00000000",
		x"00000000" , x"00000000" , x"00000000" , x"00000000" , x"00000000" , x"00000000" , x"00000000" , x"00000000",
		x"00000000" , x"00000000" , x"00000000" , x"00000000" , x"00000000" , x"00000000" , x"00000000" , x"00000000",
		x"00000000" , x"00000000" , x"00000000" , x"00000000" , x"00000000" , x"00000000" , x"00000000" , x"00000000",
		x"00000000" , x"00000000" , x"00000000" , x"00000000" , x"00000000" , x"00000000" , x"00000000" , x"00000000",
		x"00000000" , x"00000000" , x"00000000" , x"00000000" , x"00000000" , x"00000000" , x"00000000" , x"00000000",
		x"00000000" , x"00000000" , x"00000000" , x"00000000" , x"00000000" , x"00000000" , x"00000000" , x"00000000",
		x"00000000" , x"00000000" , x"00000000" , x"00000000" , x"00000000" , x"00000000" , x"00000000" , x"00000000",
		x"00000000" , x"00000000" , x"00000000" , x"00000000" , x"00000000" , x"00000000" , x"00000000" , x"00000000",
		x"00000000" , x"00000000" , x"00000000" , x"00000000" , x"00000000" , x"00000000" , x"00000000" , x"00000000",
		x"00000000" , x"00000000" , x"00000000" , x"00000000" , x"00000000" , x"00000000" , x"00000000" , x"00000000",
		x"00000000" , x"00000000" , x"00000000" , x"00000000" , x"00000000" , x"00000000" , x"00000000" , x"00000000",
		x"00000000" , x"00000000" , x"00000000" , x"00000000" , x"00000000" , x"00000000" , x"00000000" , x"00000000",
		x"00000000" , x"00000000" , x"00000000" , x"00000000" , x"00000000" , x"00000000" , x"00000000" , x"00000000",
		x"00000000" , x"00000000" , x"00000000" , x"00000000" , x"00000000" , x"00000000" , x"00000000" , x"00000000",
		x"00000000" , x"00000000" , x"00000000" , x"00000000" , x"00000000" , x"00000000" , x"00000000" , x"00000000",
		x"00000000" , x"00000000" , x"00000000" , x"00000000" , x"00000000" , x"00000000" , x"00000000" , x"00000000",
		x"00000000" , x"00000000" , x"00000000" , x"00000000" , x"00000000" , x"00000000" , x"00000000" , x"00000000",
		x"00000000" , x"00000000" , x"00000000" , x"00000000" , x"00000000" , x"00000000" , x"00000000" , x"00000000",
		x"00000000" , x"00000000" , x"00000000" , x"00000000" , x"00000000" , x"00000000" , x"00000000" , x"00000000",
		x"00000000" , x"00000000" , x"00000000" , x"00000000" , x"00000000" , x"00000000" , x"00000000" , x"00000000",
		x"00000000" , x"00000000" , x"00000000" , x"00000000" , x"00000000" , x"00000000" , x"00000000" , x"00000000",
		x"00000000" , x"00000000" , x"00000000" , x"00000000" , x"00000000" , x"00000000" , x"00000000" , x"00000000",
		x"00000000" , x"00000000" , x"00000000" , x"00000000" , x"00000000" , x"00000000" , x"00000000" , x"00000000",
		x"00000000" , x"00000000" , x"00000000" , x"00000000" , x"00000000" , x"00000000" , x"00000000" , x"00000000",
		x"00000000" , x"00000000" , x"00000000" , x"00000000" , x"00000000" , x"00000000" , x"00000000" , x"00000000",
		x"00000000" , x"00000000" , x"00000000" , x"00000000" , x"00000000" , x"00000000" , x"00000000" , x"00000000",
		x"00000000" , x"00000000" , x"00000000" , x"00000000" , x"00000000" , x"00000000" , x"00000000" , x"00000000",
		x"00000000" , x"00000000" , x"00000000" , x"00000000" , x"00000000" , x"00000000" , x"00000000" , x"00000000",
		x"00000000" , x"00000000" , x"00000000" , x"00000000" , x"00000000" , x"00000000" , x"00000000" , x"00000000",
		x"00000000" , x"00000000" , x"00000000" , x"00000000" , x"00000000" , x"00000000" , x"00000000" , x"00000000",
		x"00000000" , x"00000000" , x"00000000" , x"00000000" , x"00000000" , x"00000000" , x"00000000" , x"00000000",
		x"00000000" , x"00000000" , x"00000000" , x"00000000" , x"00000000" , x"00000000" , x"00000000" , x"00000000",
		x"00000000" , x"00000000" , x"00000000" , x"00000000" , x"00000000" , x"00000000" , x"00000000" , x"00000000",
		x"00000000" , x"00000000" , x"00000000" , x"00000000" , x"00000000" , x"00000000" , x"00000000" , x"00000000",
		x"00000000" , x"00000000" , x"00000000" , x"00000000" , x"00000000" , x"00000000" , x"00000000" , x"00000000",
		x"00000000" , x"00000000" , x"00000000" , x"00000000" , x"00000000" , x"00000000" , x"00000000" , x"00000000",
		x"00000000" , x"00000000" , x"00000000" , x"00000000" , x"00000000" , x"00000000" , x"00000000" , x"00000000",
		x"00000000" , x"00000000" , x"00000000" , x"00000000" , x"00000000" , x"00000000" , x"00000000" , x"00000000",
		x"00000000" , x"00000000" , x"00000000" , x"00000000" , x"00000000" , x"00000000" , x"00000000" , x"00000000",
		x"00000000" , x"00000000" , x"00000000" , x"00000000" , x"00000000" , x"00000000" , x"00000000" , x"00000000",
		x"00000000" , x"00000000" , x"00000000" , x"00000000" , x"00000000" , x"00000000" , x"00000000" , x"00000000",
		x"00000000" , x"00000000" , x"00000000" , x"00000000" , x"00000000" , x"00000000" , x"00000000" , x"00000000",
		x"00000000" , x"00000000" , x"00000000" , x"00000000" , x"00000000" , x"00000000" , x"00000000" , x"00000000",
		x"00000000" , x"00000000" , x"00000000" , x"00000000" , x"00000000" , x"00000000" , x"00000000" , x"00000000",
		x"00000000" , x"00000000" , x"00000000" , x"00000000" , x"00000000" , x"00000000" , x"00000000" , x"00000000",
		x"00000000" , x"00000000" , x"00000000" , x"00000000" , x"00000000" , x"00000000" , x"00000000" , x"00000000",
		x"00000000" , x"00000000" , x"00000000" , x"00000000" , x"00000000" , x"00000000" , x"00000000" , x"00000000",
		x"00000000" , x"00000000" , x"00000000" , x"00000000" , x"00000000" , x"00000000" , x"00000000" , x"00000000",
		x"00000000" , x"00000000" , x"00000000" , x"00000000" , x"00000000" , x"00000000" , x"00000000" , x"00000000",
		x"00000000" , x"00000000" , x"00000000" , x"00000000" , x"00000000" , x"00000000" , x"00000000" , x"00000000",
		x"00000000" , x"00000000" , x"00000000" , x"00000000" , x"00000000" , x"00000000" , x"00000000" , x"00000000",
		x"00000000" , x"00000000" , x"00000000" , x"00000000" , x"00000000" , x"00000000" , x"00000000" , x"00000000",
		x"00000000" , x"00000000" , x"00000000" , x"00000000" , x"00000000" , x"00000000" , x"00000000" , x"00000000",
		x"00000000" , x"00000000" , x"00000000" , x"00000000" , x"00000000" , x"00000000" , x"00000000" , x"00000000",
		x"00000000" , x"00000000" , x"00000000" , x"00000000" , x"00000000" , x"00000000" , x"00000000" , x"00000000",
		x"00000000" , x"00000000" , x"00000000" , x"00000000" , x"00000000" , x"00000000" , x"00000000" , x"00000000",
		x"00000000" , x"00000000" , x"00000000" , x"00000000" , x"00000000" , x"00000000" , x"00000000" , x"00000000",
		x"00000000" , x"00000000" , x"00000000" , x"00000000" , x"00000000" , x"00000000" , x"00000000" , x"00000000",
		x"00000000" , x"00000000" , x"00000000" , x"00000000" , x"00000000" , x"00000000" , x"00000000" , x"00000000",
		x"00000000" , x"00000000" , x"00000000" , x"00000000" , x"00000000" , x"00000000" , x"00000000" , x"00000000",
		x"00000000" , x"00000000" , x"00000000" , x"00000000" , x"00000000" , x"00000000" , x"00000000" , x"00000000",
		x"00000000" , x"00000000" , x"00000000" , x"00000000" , x"00000000" , x"00000000" , x"00000000" , x"00000000",
		x"00000000" , x"00000000" , x"00000000" , x"00000000" , x"00000000" , x"00000000" , x"00000000" , x"00000000",
		x"00000000" , x"00000000" , x"00000000" , x"00000000" , x"00000000" , x"00000000" , x"00000000" , x"00000000",
		x"00000000" , x"00000000" , x"00000000" , x"00000000" , x"00000000" , x"00000000" , x"00000000" , x"00000000",
		x"00000000" , x"00000000" , x"00000000" , x"00000000" , x"00000000" , x"00000000" , x"00000000" , x"00000000",
		x"00000000" , x"00000000" , x"00000000" , x"00000000" , x"00000000" , x"00000000" , x"00000000" , x"00000000",
		x"00000000" , x"00000000" , x"00000000" , x"00000000" , x"00000000" , x"00000000" , x"00000000" , x"00000000",
		x"00000000" , x"00000000" , x"00000000" , x"00000000" , x"00000000" , x"00000000" , x"00000000" , x"00000000",
		x"00000000" , x"00000000" , x"00000000" , x"00000000" , x"00000000" , x"00000000" , x"00000000" , x"00000000",
		x"00000000" , x"00000000" , x"00000000" , x"00000000" , x"00000000" , x"00000000" , x"00000000" , x"00000000",
		x"00000000" , x"00000000" , x"00000000" , x"00000000" , x"00000000" , x"00000000" , x"00000000" , x"00000000",
		x"00000000" , x"00000000" , x"00000000" , x"00000000" , x"00000000" , x"00000000" , x"00000000" , x"00000000"
	);
															 

	BEGIN
	dqm <= PKG_DQM;
	selectSDRAM <= PKG_SDRAMselect;
	dataIN      <= PKG_inputData32;
	R_In_Addr <= "00" & PKG_R_In_Addr(25 downto 2);
	storeSDRAM <= PKG_SDRAMwrite;
	
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
			
			IF selectSDRAM='1' AND storeSDRAM='1' THEN
				wait for 21 ns;
				IF dqm="0000" THEN
					TabInstruction(to_integer(unsigned(R_In_Addr))) <= dataIN;
				ELSIF dqm="1100" THEN
					TabInstruction(to_integer(unsigned(R_In_Addr)))(15 downto 0) <= dataIN(15 downto 0);
				ELSIF dqm="0011" THEN
					TabInstruction(to_integer(unsigned(R_In_Addr)))(31 downto 16) <= dataIN(31 downto 16);
				ELSIF dqm="1110" THEN
					TabInstruction(to_integer(unsigned(R_In_Addr)))(7 downto 0) <= dataIN(7 downto 0);
				ELSIF dqm="1101" THEN
					TabInstruction(to_integer(unsigned(R_In_Addr)))(15 downto 8) <= dataIN(15 downto 8);
				ELSIF dqm="1011" THEN
					TabInstruction(to_integer(unsigned(R_In_Addr)))(23 downto 16) <= dataIN(23 downto 16);
				ELSIF dqm="0111" THEN
					TabInstruction(to_integer(unsigned(R_In_Addr)))(31 downto 24) <= dataIN(31 downto 24);
				ELSE
					TabInstruction(to_integer(unsigned(R_In_Addr))) <= dataIN;
				END IF;
				
				
			END IF;
			
			IF dataReady_32b='1' THEN
--				outputData <= TabInstruction(cpt);
				outputData <= TabInstruction(to_integer(unsigned(R_In_Addr)));
				CPT := CPT + 1;
				wait for 19 ns;
				
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