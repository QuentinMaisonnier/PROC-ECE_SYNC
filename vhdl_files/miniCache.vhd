-- Projet de fin d'études : RISC-V
-- ECE Paris / SECAPEM
-- miniCache entity VHDL = Processor + DataMemory + InstructionMemory

-- description of Minicache
-- It is located between the Proc and the SDRAM_32b
-- It converts the simple bus from the SDRAM to a instruction bus and a data bus for the Proc

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

--output signals to proc(riscv)
SIGNAL Reginstruction, SIGinstruction, Muxinstruction  : STD_LOGIC_VECTOR(31 downto 0);
SIGNAL Regdata, Muxdata					                   : STD_LOGIC_VECTOR(31 downto 0);
SIGNAL SIGHold                                         : STD_LOGIC;


TYPE state IS (INIT, IDLE, LOADdataGet, STOREdataEnd, NEXTinstGet);
SIGNAL currentState, nextState : state;	


--- output signals/mux to module 32b
SIGNAL Muxfunct3             : STD_LOGIC_VECTOR(2 DOWNTO 0);
SIGNAL MuxwriteSelect        : STD_LOGIC;
SIGNAL MuxcsDM, SIGcsDMCache : STD_LOGIC;
SIGNAL MuxAddressDM          : STD_LOGIC_VECTOR(31 DOWNTO 0);
SIGNAL MuxinputDM            : STD_LOGIC_VECTOR(31 DOWNTO 0);
SIGNAL SIGstore              : STD_LOGIC;


---------------------------------------------------------------------------------
----------------------SIGNALS INIT SDRAM (BOOTLOADER)----------------------------
---------------------------------------------------------------------------------
SIGNAL RcptAddr, SIGcptAddr : STD_LOGIC_VECTOR(31 downto 0); -- counter that serves as an address
SIGNAL SIGinstructionInit : STD_LOGIC_VECTOR(31 downto 0);   -- transmits instructions from SRAM to SDRAM
SIGNAL funct3boot                                    : STD_LOGIC_VECTOR(2 DOWNTO 0);
SIGNAL inputDMboot             : STD_LOGIC_VECTOR(31 DOWNTO 0);
SIGNAL SIGstoreboot, csDMboot                        : STD_LOGIC;
CONSTANT SizeSRAM                                    : INTEGER := 1023;

TYPE stateInit IS (WAITING, cpy, next_Addr, stop);
SIGNAL currentStateInit, nextStateInit : stateInit;
---------------------------------------------------------------------------------

begin

	------------------------------------------------------------
	----------------------MUX OUTPUT----------------------------
	------------------------------------------------------------
----FUNCTION3
	funct3 <= Muxfunct3;
	
	Muxfunct3 <= funct3boot when currentStateInit /= STOP else
			       "010"	    when currentState = NEXTinstGet OR nextState = NEXTinstGet else
			       PROCfunct3;
----writeSelect				
	writeSelect <= MuxwriteSelect;

	MuxwriteSelect <= SIGstoreboot when currentStateInit /= STOP else
				         SIGstore;
----CSDM

	csDM <= MuxcsDM;
	
	MuxcsDM <= csDMboot when currentStateInit /= STOP else
			     SIGcsDMCache;
----AddressDM		

	AddressDM <= MuxAddressDM;
						 
	MuxAddressDM <= RcptAddr when currentStateInit /= STOP else
			          PROCaddrDM when  nextState=STOREdataEnd OR nextState = LOADdataGet else
			          PROCprogcounter;
---- INPUTDM
	inputDM <= MuxinputDM;
	MuxinputDM <= inputDMboot when currentStateInit /= STOP else
			        PROCinputDM;
------------------------------------------------

	--------------------------------------------------
	---------------- FSM SDRAM MEMORY-----------------
	--------------------------------------------------
	
	FSM_SDRAMmemory : PROCESS (ready_32b, PROCLoad, PROCstore, currentState, data_Ready_32b, dataOut_32b, currentStateInit, Reginstruction, PROCaddrDM)
	BEGIN
		SIGHold <='1'; -- hold at 1 = blocked
		nextState <= currentState;
		SIGinstruction <= Reginstruction;
		SIGstore 		<= '0';  --- store at 0 = read / store at 1 = store
		SIGcsDMCache	<= '0';  --- csDM at 0 = memory disable
		
		CASE currentState IS
   ------------------- INIT -----------------------
			WHEN INIT => --waiting for the end of the bootloader
				IF currentStateInit=Stop AND Ready_32b = '1' THEN
					nextstate <= IDLE;
				END IF;
  ------------------- IDLE -----------------------
			WHEN IDLE =>
			
				IF ready_32b = '1' THEN
					SIGHold <='0'; 
					SIGcsDMCache <= '1';
					
					IF PROCLoad ='1' THEN
						nextstate    <= LOADdataGet;
					ELSIF PROCstore ='1' AND PROCaddrDM(31)='0' THEN ---activate memory if the store is inside
						SIGstore     <= '1';
						nextState    <= STOREdataEnd;
					ELSE
						nextstate    <= NEXTinstGet;
					END IF;
				END IF;		
------------------- LOADdataGet -----------------------
			WHEN LOADdataGet =>
				
				IF ready_32b = '1' THEN
					SIGHold      <= '0'; -- TEST
					SIGstore     <= '0';
					SIGcsDMCache <= '1';
					nextstate    <= NEXTinstGet;
				END IF;
					
------------------- STOREdataEnd -----------------------
			WHEN STOREdataEnd =>
				IF ready_32b = '1' THEN
					SIGstore      <= '0';
					SIGcsDMCache  <= '1';
					nextstate     <= NEXTinstGet;
				END IF;
------------------- NEXTinstGet -----------------------	
			WHEN NEXTinstGet =>
			
				IF data_Ready_32b = '1' THEN
					SIGinstruction <= dataOut_32b;
				END IF;
				
				IF ready_32b = '1'THEN
					nextState <= IDLE;
				END IF;
			
	   END CASE;
	END PROCESS FSM_SDRAMmemory;

	
	
	currentState <= INIT WHEN reset = '1' ELSE
					    nextState WHEN rising_edge(Clock);
					
					
	--------------------------------------------------------
	---------------- output to proc (riscv)-----------------
	--------------------------------------------------------
			
	------------- We store the instruction and we give it at the same time to the proc ---------------	
	PROCinstruction <= Muxinstruction;

	Reginstruction <= (others => '0') WHEN reset = '1' ELSE
					      Muxinstruction WHEN rising_edge(Clock);
					   
	Muxinstruction <= SIGinstruction when data_Ready_32b='1' AND  currentState=NEXTinstGet else
					      Reginstruction;
	--------------

	------------- We store the data and we give it at the same time to the proc ---------------	
				  
	PROCoutputDM <= Muxdata;
	
	Regdata <= (others => '0') WHEN reset = '1' ELSE
			     Muxdata WHEN rising_edge(Clock);
	
	Muxdata <= dataOut_32b when data_Ready_32b='1' AND currentState=LOADdataGet else
			     Regdata;
				  
	--- Hold signal
	ProChold <= SIGHold;	
	
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
		bootfinish <= '0';
		

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
				
				IF Ready_32b = '1' THEN
					SIGcptAddr <= STD_LOGIC_VECTOR(unsigned(RcptAddr) + 4);
					nextStateInit  <= WAITING;
				END IF;

			WHEN stop      =>
				bootfinish <= '1';
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
	data_a    => (OTHERS => '0'), -- Instruction in
	data_b    => (OTHERS => '0'), -- Data in
	enable    => '1',
	wren_a    => '0',           -- Write Instruction Select
	wren_b    => '0',           -- Write Data Select
	q_a       => SIGinstructionInit -- DataOut Instruction
	--q_b       => SIGoutputDM 						-- DataOut Data
);
END archi;
-- END FILE