-- Projet de fin d'études : RISC-V
-- ECE Paris / SECAPEM

-- LIBRARIES
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.simulPkg.all;
use work.SDRAM_package.ALL;

-- ENTITY
entity TestBenchTop is
end entity;

architecture VHDL of TestBenchTop is
	component Top is
    port (
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
	end component;

	signal reset, ck : std_logic;
	signal counter, progcounter, instr : std_logic_vector(31 downto 0);
    
	signal dataAddr: std_logic_vector(31 downto 0);
	signal load, store : std_logic;
	signal dataLength : std_logic_vector(2 downto 0);
	signal inputData, outputData: std_logic_vector(31 downto 0);
	
	-- SDRAM SIMULATION --
	signal outputData_SDRAM, inputData_SDRAM: std_logic_vector(15 downto 0);
	signal AddrSDRAM, AddrSDRAM2, AddrSDRAM3, AddrSDRAM4: std_logic_vector(24 downto 0);
	signal DQM_SDRAM		  : std_LOGIC_vector(1 downto 0);
	signal dataReady_SDRAM, SDRAMselect, SDRAMwrite : std_logic;
	-- SDRAM SIMULATION --
   
	
	signal reg00, reg01, reg02, reg03, reg04, reg05, reg06, reg07, reg08, reg09, reg0A, reg0B, reg0C, reg0D, reg0E, reg0F, reg10, reg11, reg12, reg13, reg14, reg15, reg16, reg17, reg18, reg19, reg1A, reg1B, reg1C, reg1D, reg1E, reg1F : std_logic_vector(31 downto 0);
	signal SigTOPdisplay1, SigTOPdisplay2 : std_logic_vector (31 downto 0);

	type mem is array(0 to 2047) of std_logic_vector(15 downto 0);
	signal TabMemory : mem :=(others => (others => '0'));
	
															 

	BEGIN
	
	-- SDRAM SIMULATION --
	--outputData_SDRAM <= PKG_outputData_SDRAM;
	PKG_outputData_SDRAM <= outputData_SDRAM;
	DQM_SDRAM <= PKG_DQM_SDRAM;
	SDRAMselect <= PKG_SDRAMselect;
	inputData_SDRAM <= PKG_inputData_SDRAM;
	AddrSDRAM <= PKG_AddrSDRAM;
	SDRAMwrite <= PKG_SDRAMwrite;
	dataReady_SDRAM <= PKG_dataReady_SDRAM;
	-- SDRAM SIMULATION --
	
	AddrSDRAM2 <= AddrSDRAM when(rising_edge(ck));
	AddrSDRAM3 <= AddrSDRAM2 when(rising_edge(ck));
	AddrSDRAM4 <= AddrSDRAM3 when(rising_edge(ck));
	
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
	 --PKG_outputDM  <= outputData;
	 
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
		begin
			
			IF SDRAMselect='1' AND SDRAMwrite='1' THEN
				IF DQM_SDRAM="00" THEN
					TabMemory(to_integer(unsigned(AddrSDRAM))) <= inputData_SDRAM;
				ELSIF DQM_SDRAM="10" THEN
					TabMemory(to_integer(unsigned(AddrSDRAM)))(7 downto 0) <= inputData_SDRAM(7 downto 0);
				ELSIF DQM_SDRAM="01" THEN
					TabMemory(to_integer(unsigned(AddrSDRAM)))(15 downto 8) <= inputData_SDRAM(15 downto 8);
				END IF;
			END IF;
			
			IF dataReady_SDRAM='1' THEN
				outputData_SDRAM <= TabMemory(to_integer(unsigned(AddrSDRAM4)));
			ELSE
				outputData_SDRAM <= (others => 'Z');
			END IF;
			
			wait for 1 ns;
			
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