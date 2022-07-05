-- Projet de fin d'études : RISC-V
-- ECE Paris / SECAPEM
-- miniCache entity VHDL = Processor + DataMemory + InstructionMemory

-- LIBRARIES
LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;
USE work.simulPkg.ALL;
USE work.SDRAM_package.ALL;

-- ENTITY
ENTITY miniCache IS
	PORT (
		-- INPUTS
		clock             : IN  STD_LOGIC;
		reset             : IN  STD_LOGIC;

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
END ENTITY;

architecture archi of miniCache is


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

----------------------SIGNALS SDRAM MEMORY/PROC RISCV----------------------------

SIGNAL Reginstruction, SIGinstruction        : STD_LOGIC_VECTOR(31 downto 0);
SIGNAL Regdata, SIGdata        : STD_LOGIC_VECTOR(31 downto 0);

SIGNAL SIGstore, SIGcsDM                        : STD_LOGIC;
TYPE state IS (INIT, IDLE, LOADdataGet, STOREdataEnd, NEXTinstGet);
SIGNAL currentState, nextState : state;	

----------------------SIGNALS INIT SDRAM (BOOTLOADER)----------------------------
SIGNAL RcptAddr, SIGcptAddr : STD_LOGIC_VECTOR(31 downto 0);
SIGNAL SIGinstructionInit : STD_LOGIC_VECTOR(31 downto 0);
SIGNAL funct3boot                                    : STD_LOGIC_VECTOR(2 DOWNTO 0);
SIGNAL inputDMboot             : STD_LOGIC_VECTOR(31 DOWNTO 0);
SIGNAL SIGstoreboot, csDMboot                        : STD_LOGIC;
CONSTANT SizeSRAM                                    : INTEGER := 1023;

TYPE stateInit IS (WAITING, cpy, next_Addr, stop, testwrite);
SIGNAL currentStateInit, nextStateInit : stateInit;
---------------------------------------------------------------------------------

begin

	funct3 <= funct3boot when currentStateInit /= STOP else
				 "010";
				 --PROCfunct3;
						
	writeSelect <= SIGstoreboot when currentStateInit /= STOP else
						SIGstore;
						
	csDM <= csDMboot when currentStateInit /= STOP else
			  SIGcsDM;
						
	AddressDM <= RcptAddr when currentStateInit /= STOP else
			       PROCaddrDM when nextState /= NEXTinstGet else
					 PROCprogcounter;
	
	inputDM <= inputDMboot when currentStateInit /= STOP else
			     PROCinputDM;
				  
	PROCinstruction <= Reginstruction;
	
	PROCoutputDM <= Regdata;
	
	--PKG_instruction   <= inputDM;
	
	---------------------------------------------
	----------------SDRAM MEMORY-----------------
	---------------------------------------------
	
	
	
	SDRAMmemory : PROCESS (ready_32b, PROCload, PROCstore, currentState, data_Ready_32b, dataOut_32b, currentStateInit, REGdata, Reginstruction)
	BEGIN
		PROChold <='1';
		nextState <= currentState;
		SIGinstruction <= Reginstruction;
		SIGdata			<= REGdata;
		SIGstore 		<= '0';
		SIGcsDM				<= '0';
		CASE currentState IS
   ------------------- INIT -----------------------
			WHEN INIT =>
				IF currentStateInit=Stop AND Ready_32b = '1' THEN
					SIGstore  <= '0';
					SIGcsDM   <= '1';
					nextstate <= NEXTinstGet;
				END IF;
  ------------------- IDLE -----------------------
			WHEN IDLE =>
			
				
				IF ready_32b = '1' THEN
					IF PROCload ='1' THEN
						SIGstore <= '0';
						SIGcsDM     <= '1';
						nextstate <= LOADdataGet;
					ELSIF PROCstore ='1' THEN
						SIGstore <= '1';
						SIGcsDM     <= '1';
						nextstate <= STOREdataEnd;
					ELSE
						PROChold <='0'; -- TEST
						SIGstore <= '0';
						SIGcsDM     <= '1';
						nextstate <= NEXTinstGet;
					END IF;
				END IF;
------------------- LOADdataReq -----------------------			
------------------- LOADdataGet -----------------------
			WHEN LOADdataGet =>
			
				IF data_Ready_32b = '1' THEN
					SIGdata <= dataOut_32b;
				END IF;
				
				IF ready_32b = '1' THEN
					SIGstore <= '0';
					SIGcsDM     <= '1';
					nextstate <= NEXTinstGet;
					PROChold <='0'; -- TEST
				END IF;

------------------- STOREdataReq -----------------------
------------------- STOREdataEnd -----------------------
			WHEN STOREdataEnd =>
			
				IF ready_32b = '1' THEN
					PROChold <='0'; -- TEST
					SIGstore <= '0';
					SIGcsDM     <= '1';
					nextstate <= NEXTinstGet;
				END IF;
------------------- NEXTinstReq -----------------------
------------------- NEXTinstGet -----------------------	
			WHEN NEXTinstGet =>
				IF data_Ready_32b = '1' THEN
					SIGinstruction <= dataOut_32b;
				END IF;
				
				IF ready_32b = '1' THEN
					nextstate <= IDLE;
				END IF;
			
	   END CASE;
	END PROCESS;
	
	currentState <= INIT WHEN reset = '1' ELSE
					    nextState WHEN rising_edge(Clock);
						 
	Reginstruction <= (others => '0') WHEN reset = '1' ELSE
					      SIGinstruction WHEN rising_edge(Clock);
						 
	Regdata <= (others => '0') WHEN reset = '1' ELSE
				  SIGdata WHEN rising_edge(Clock);
   ---------------------------------------------
	
	
	---------------------------------------------
	-----------------BOOT LOADER-----------------
	---------------------------------------------
	load : PROCESS (Ready_32b, RcptAddr, SIGinstructionInit, currentStateInit)
	BEGIN
		funct3boot   <= "010";
		SIGcptAddr   <= RcptAddr;
		SIGstoreboot <= '0';
		inputDMboot  <= SIGinstructionInit;
		csDMboot     <= '0';
		nextStateInit    <= currentStateInit;
		

		CASE currentStateInit IS

			WHEN WAITING =>
				IF unsigned(RcptAddr) < SizeSRAM THEN
					IF Ready_32b = '1' THEN
						nextStateInit <= cpy;
					END IF;
				ELSE
					nextStateInit <= stop;
				END IF;

			WHEN cpy =>
				SIGstoreboot <= '1';
				csDMboot     <= '1';
				nextStateInit    <= next_Addr;

			WHEN next_Addr =>
				csDMboot   <= '0';
				SIGcptAddr <= STD_LOGIC_VECTOR(unsigned(RcptAddr) + 4);
				nextStateInit  <= WAITING;

			WHEN stop      =>

			WHEN testwrite =>
				SIGstoreboot <= '1';
				csDMboot     <= '1';
				nextStateInit    <= stop;
		END CASE;
	END PROCESS;

	currentStateInit <= WAITING WHEN reset = '1' ELSE
							  nextStateInit WHEN rising_edge(Clock);
							  
	RcptAddr <= (OTHERS => '0') WHEN reset = '1' ELSE
					SIGcptAddr WHEN rising_edge(clock);
					
-----------------------------------------------------------------
		
Memory : RAM_2PORT
PORT MAP(
	address_a => RcptAddr(13 DOWNTO 2), --  Addr instruction (divided by 4 because we use 32 bits memory)
	address_b => (OTHERS => '0'),       --  Addr memory (divided by 4 because we use 32 bits memory)
	clock     => clock,
	data_a => (OTHERS => '0'), -- Instruction in
	data_b => (OTHERS => '0'), -- Data in
	enable    => '1',
	wren_a    => '0',           -- Write Instruction Select
	wren_b    => '0',           -- Write Data Select
	q_a       => SIGinstructionInit -- DataOut Instruction
	--q_b       => SIGoutputDM 						-- DataOut Data
);
END archi;
-- END FILE