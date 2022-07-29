
-- ------------------------------------------------------------------------------- --
-- THIS SDRAM CONTROLLER IS USED FOR A 50 MHz CLOCK                                --
-- AND an SDRAM Architecture as "32M x 16" :                                       --
-- 8M (addresses) * 4 (Banks) * 16 (16 bits Data) = 512 Mb SDRAM <=> 64 MB SDRAM   --
-- ------------------------------------------------------------------------------- --


library IEEE;
library work;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.SDRAM_package.ALL;
USE work.simulPkg.ALL;

entity SDRAM_controller is 
    Port (
        clk, Reset                           : in STD_LOGIC;
        SDRAM_ADDR   	                     : out STD_LOGIC_VECTOR (12 downto 0);  			    -- SDRAM : Address
		  SDRAM_DQ   	                        : inout STD_LOGIC_VECTOR ((DATA_WIDTH-1) downto 0); -- SDRAM : data input / output
		  SDRAM_BA   	                        : out STD_LOGIC_VECTOR (1 downto 0);  				    -- SDRAM : Bank Select
		  SDRAM_DQM		                        : out STD_LOGIC_VECTOR ((DQM_WIDTH-1) downto 0);    -- SDRAM : DQM Mask
		  SDRAM_RAS_N, SDRAM_CAS_N, SDRAM_WE_N : out STD_LOGIC;  			                         -- SDRAM : RAS + CAS + WE = CMD
		  SDRAM_CKE, SDRAM_CS_N                : out STD_LOGIC ;           					          -- SDRAM : CKE (clock rising edge) | CS (chip select)
		  SDRAM_CLK                            : out STD_LOGIC ;												 -- SDRAM : Clock
		  Data_OUT                             : out STD_LOGIC_VECTOR ((DATA_WIDTH-1) downto 0);	 -- Output : Data (read)
		  Data_IN                              : in STD_LOGIC_VECTOR ((DATA_WIDTH-1) downto 0);	 -- Input  : Data (write)
		  DQM                                  : in STD_LOGIC_VECTOR ((DQM_WIDTH-1) downto 0);		 -- Input  : DQM
		  Address_IN                           : in STD_LOGIC_VECTOR (24 downto 0);					 -- Input  : Address 
		  Write_IN                             : in STD_LOGIC;											    -- Input  : Write/Read select
		  Select_IN                            : in STD_LOGIC;												 -- Input  : Chip Select (allow communictaion)
		  Ready                                : out STD_LOGIC;												 -- Output : Memory Ready
		  Data_Ready                           : out STD_LOGIC 												 -- Output : Data Ready
	);
end SDRAM_controller;

architecture vhdl of SDRAM_controller is 

Type state is (S_First, S_Start, S_PRECHARGE_INIT, S_Refresh_INIT, S_NOP_INIT, S_LoadRegister, S_IDLE, S_Active ,S_Write_WRITE1, S_Precharge,
	  S_Read_READ, S_NOP1_READ, S_NOP2_READ, S_Refresh, S_Refresh_NOP1, S_Refresh_NOP2, S_Refresh_NOP3);
		
signal currentState, nextState : state;

signal Reg_D, muxRegD : STD_LOGIC_VECTOR ((DATA_WIDTH-1) downto 0);
signal Reg_A, muxRegA : STD_LOGIC_VECTOR (24 downto 0);
signal Reg_DQM, muxRegDQM : STD_LOGIC_VECTOR ((DQM_WIDTH-1) downto 0);


signal S_DQM, R_DQM : STD_LOGIC_VECTOR ((DQM_WIDTH-1) downto 0);
signal S_DOE, R_DOE, reg_DataReady, reg_Ready, S_Write_IN, R_Write_IN : STD_LOGIC;
signal S_BA, R_BA : STD_LOGIC_VECTOR (1 downto 0);
signal S_CMD, R_CMD : STD_LOGIC_VECTOR (4 downto 0);
signal S_ADDR, R_ADDR : STD_LOGIC_VECTOR (12 downto 0);
signal S_CPT_DATA, R_CPT_DATA : STD_LOGIC_VECTOR (3 downto 0);
signal S_CPT, R_CPT : STD_LOGIC_VECTOR (13 downto 0);
signal S_CPT_REFRESH, R_CPT_REFRESH : STD_LOGIC_VECTOR (21 downto 0);
signal DIN, S_DOUT, R_DOUT : STD_LOGIC_VECTOR ((DATA_WIDTH-1) downto 0);
signal RegRead2, MuxRead2 : STD_LOGIC_VECTOR ((DATA_WIDTH-1) downto 0);



constant  T_REFRESH   	  : std_logic_vector(21 downto 0) := REFRESH_PERIOD; -- Refresh period (can be changed in the "SDRAM_package")
constant  T_START      	  : std_logic_vector(13 downto 0) := START_DELAY;	  -- Initialization Delay (refers DataSheet) (can be changed in the "SDRAM_package")
constant  T_TRC      	  : std_logic_vector(13 downto 0) := TRC;            -- TRC delay (number of NOP commands needed during a refresh cycle)
constant  T_INIT_REFRESH  : std_logic_vector(13 downto 0) := INIT_REFRESH;   -- Number of refresh cycles during initialization (refers datasheet)


-- Constant Timers --
constant  T_RESET      	  : std_logic_vector(13 downto 0) := B"00000000000001";
constant  T_RESET_REFRESH : std_logic_vector(21 downto 0) := B"0000000000000000000001";

signal Refresh_Toggle : STD_LOGIC; -- DEBUG


begin



-- PACKAGE --

-- TESTBENCH RISC-V --

-- Controler -> SDRAM (write) -- 
PKG_inputData_SDRAM <= Data_IN;
PKG_DQM_SDRAM <= DQM;
PKG_SDRAMselect <= Select_IN;
-- SDRAM -> Controler (read) -- 
PKG_dataReady_SDRAM <= '0' when reset = '1' else
								reg_DataReady when rising_edge(clk);
-- PACKAGE --

-- others --
PKG_AddrSDRAM <= Address_IN;
PKG_SDRAMwrite <= Write_IN;

-- PACKAGE -- 
-- TESTBENCH RISC-V --


SDRAM_CLK <= clk;

-- COMMAND --
SDRAM_CKE   <= R_CMD(4); -- CKE
SDRAM_CS_N  <= R_CMD(3); -- CS
SDRAM_RAS_N <= R_CMD(2); -- RAS
SDRAM_CAS_N <= R_CMD(1); -- CAS
SDRAM_WE_N  <= R_CMD(0); -- WE
-- COMMAND --



muxRegA <= address_in when reg_ready = '1' else 
			  Reg_A;
			  
Reg_A <= (others=>'0') when reset='1' else 
			muxRegA when rising_edge(clk);
		 
muxRegD <= Data_IN when reg_ready = '1' else 
			  Reg_D;
			  
Reg_D <= (others=>'0') when reset='1' else 
			muxRegD when rising_edge(clk);

muxRegDQM <= DQM when reg_Ready = '1' else
				 Reg_DQM;
			 
Reg_DQM <= (others=>'0') when reset='1' else 
				muxRegDQM when rising_edge(clk);



fsm : Process(reg_Ready, pkg_simulON, currentState, clk, Reset, Reg_A, Reg_D, R_Write_IN, R_CPT, R_CPT_DATA, R_DOUT, R_DOE, R_BA, R_CPT_REFRESH, Data_IN, Write_IN, Select_IN, Address_IN, reg_DQM, R_DQM)
begin 

	Refresh_Toggle <= '0'; -- DEBUG

	S_DQM <= R_DQM;
	S_BA <= R_BA;
	S_DOUT <= R_DOUT;
	S_DOE <= R_DOE;
	S_CPT <= R_CPT;
	S_CPT_REFRESH <= STD_LOGIC_VECTOR(unsigned(R_CPT_REFRESH) + 1);
	S_Write_IN <= R_Write_IN;
	reg_Ready <= '0';
	S_CPT_DATA <= R_CPT_DATA;
	reg_DataReady <= '0';
	
	S_CMD<=NOP;
	S_ADDR<=A_NOP;

	nextState <= currentState;
	
CASE currentState IS

when S_First =>

	S_CPT_DATA <= (others => '0');
	reg_Ready <= '0';
	S_CPT <= T_RESET;
	S_CPT_REFRESH <= T_RESET_REFRESH;
	nextState <= S_Start;

-- ----- START INITIALIZATION ----- --
-- SDRAM initialization commands, --
-- refers datasheet before modifications --

WHEN S_Start =>
	S_DOE <= '0';
	S_BA <= (others => '0');
	S_DQM <= (others => '0');
	
	-- CMD
	S_CMD <= NOP;
	S_ADDR <= A_NOP;
							
	-- (100 us delay at the SDRAM start)				
	if(R_CPT = T_START OR pkg_simulON = '1') then
		nextState <= S_PRECHARGE_INIT;
	else
		S_CPT <= STD_LOGIC_VECTOR(unsigned(R_CPT) + 1);
		nextState <= S_Start;
	end if;
	
	
WHEN S_PRECHARGE_INIT =>
	
	S_DOE <= '0';
	S_BA <= (others => '0');

	-- CMD
	S_CMD <= PRECHARGE; 
	S_ADDR <= A_ALL_BANK;
	
	S_CPT <= T_RESET;
	
	nextState <= S_Refresh_INIT;
	
	
WHEN S_Refresh_INIT =>
	
	S_DOE <= '0';
	S_BA <= (others => '0');
	
	-- CMD
	S_CMD <= REFRESH; 
	S_ADDR <= A_NOP;
	
	nextState <= S_NOP_INIT;
	
	
WHEN S_NOP_INIT =>
	
	S_DOE <= '0';
	S_BA <= (others => '0');
	
	-- CMD
	S_CMD <= NOP; 
	S_ADDR <= A_NOP;
	
	
	if(R_CPT = T_INIT_REFRESH) then -- 2 refreshs during the SDRAM initialization
		nextState <= S_LoadRegister;
	else
		S_CPT <= STD_LOGIC_VECTOR(unsigned(R_CPT) + 1);
		nextState <= S_Refresh_INIT;
	end if;
	

-- ----- LOAD ----- --
WHEN S_LoadRegister =>
	
	S_DOE <= '0';
	S_BA <= (others => '0');
	
	-- CMD
	S_CMD <= LOAD; 
	S_ADDR <= A_MODE;
	
	nextState <= S_IDLE;
-- ----- ---- ----- --

-- ----- END INITIALIZATION ----- --

-- ----- IDLE ----- --
WHEN S_IDLE =>
	
	S_CPT_DATA <= (others => '0');
	S_CPT <= T_RESET;

	if( R_CPT_REFRESH <= (STD_LOGIC_VECTOR(unsigned(T_REFRESH) - 8))) then -- Verify REFRESH TIMING
		reg_Ready <= '1'; -- SDRAM Ready to receive new command
	else
		reg_Ready <= '0'; -- SDRAM Need to do a refresh cycle
	end if;
	
	S_DOE <= '0';
	S_BA <= (others => '0');
	S_DQM <= (others => '0');
	
	-- CMD
	S_CMD <= NOP; 
	S_ADDR <= A_NOP;
	
	if( (R_CPT_REFRESH > (STD_LOGIC_VECTOR(unsigned(T_REFRESH) - 6))) OR (Select_IN = '0' AND R_CPT_REFRESH > ('0' & STD_LOGIC_VECTOR(unsigned(T_REFRESH(21 downto 1)))))) then
		nextState <= S_Refresh; -- Auto refresh
	elsif(Select_IN = '1') then
		S_Write_IN <= Write_IN; -- Save the read/write command in a register
		nextState <= S_Active;
	else
		nextState <= S_IDLE;
	end if;
-- ----- ---- ----- --

-- ----- ACTIVE ----- --
WHEN S_Active =>
	
	reg_Ready <= '0'; -- SDRAM  BUSY
	
	S_DOE <= '0';
	S_DQM <= reg_DQM;
	S_BA <= Reg_A(24 downto 23); --
	
	-- CMD
	S_CMD <= ACTIVE; 
	S_ADDR <= Reg_A(22 downto 10); -- ROW

	
	if(R_Write_IN = '1') then 
		nextState <= S_Write_WRITE1; -- Write is selected 	
	else
		nextState <= S_Read_READ;    -- read is selected
	end if;
	
-- ----- ------ ----- --


-- ----- WRITE ----- --
WHEN S_Write_WRITE1 =>

	S_CPT <= STD_LOGIC_VECTOR(unsigned(R_CPT) + 1);
	
	if( R_CPT_REFRESH <= (STD_LOGIC_VECTOR(unsigned(T_REFRESH) - 7))) then -- Verify REFRESH TIMING
		reg_Ready <= '1'; -- SDRAM Ready to receive new command
	else
		reg_Ready <= '0'; -- SDRAM will need to do a refresh cycle
	end if;
	S_DOE <= '1';
	S_BA <= R_BA; --
	S_DQM <= reg_DQM;
	
	-- CMD
	S_CMD <= WRITE; 
	S_ADDR <= "000" & Reg_A(9 downto 0); -- COLUMN
	S_DOUT <= Reg_D;
	
	
	if(SELECT_IN = '1' AND R_CPT_REFRESH <= (STD_LOGIC_VECTOR(unsigned(T_REFRESH) - 7)) AND (Reg_A(24 downto 10) = Address_IN(24 downto 10))) then
		nextState <= S_Write_WRITE1; -- Continue to write if columns/page addresses doesn't change, and if no refresh is required
	else
		nextState <= S_Precharge; 	  -- Or stop write cycles
	end if;
	

-- ----- ----- ----- --

-- ----- READ ----- --
WHEN S_Read_READ =>

	S_CPT <= STD_LOGIC_VECTOR(unsigned(R_CPT) + 1);
	
	if( R_CPT_REFRESH <= (STD_LOGIC_VECTOR(unsigned(T_REFRESH) - 9))) then -- Verify REFRESH TIMING
		reg_Ready <= '1'; -- SDRAM Ready to receive new command
	else
		reg_Ready <= '0'; -- SDRAM will need to do a refresh cycle
	end if;
	S_DOE <= '0';
	S_BA <= Reg_A(24 downto 23);
	S_DQM <= reg_DQM;
	
	-- CMD
	S_CMD <= READ; 
	S_ADDR <= "000" & Reg_A(9 downto 0);
	
	if(SELECT_IN = '1' AND R_CPT_REFRESH <= (STD_LOGIC_VECTOR(unsigned(T_REFRESH) - 9)) AND (Reg_A(24 downto 10) = Address_IN(24 downto 10))) then
		nextState <= S_Read_READ; -- Continue to read if columns/page addresses doesn't change, and if no refresh is required
	else
		nextState <= S_NOP1_READ; -- Or stop read cycles
	end if;
	
	
	if(unsigned(R_CPT_DATA) < "0010")then 		-- CAS latency 
		S_CPT_DATA <= (STD_LOGIC_VECTOR(unsigned(R_CPT_DATA) + 1));
		reg_DataReady <= '0';
	else
		reg_DataReady <= '1';
	end if;
	
	
WHEN S_NOP1_READ =>

	S_CPT <= STD_LOGIC_VECTOR(unsigned(R_CPT) + 1);
	
	reg_Ready <= '0';
	S_DOE <= '0';
	S_BA <= (others => '0');
	S_DQM <= (others => '0');
	
	if(unsigned(R_CPT_DATA) > 1)then
		reg_DataReady <= '1';
	else
		reg_DataReady <= '0';
	end if;
	
	-- CMD
	S_CMD <= NOP; 
	S_ADDR <= A_NOP;
	
	nextState <= S_NOP2_READ;

WHEN S_NOP2_READ =>

	reg_Ready <= '0';

	S_CPT <= STD_LOGIC_VECTOR(unsigned(R_CPT) + 1);
	
	S_DOE <= '0';
	S_BA <= (others => '0');
	
	reg_DataReady <= '1';
	
	-- CMD
	S_CMD <= NOP; 
	S_ADDR <= A_NOP;
	
	nextState <= S_Precharge;

	

-- ----- ---- ----- --

	
-- ----- PRECHARGE ----- --
WHEN S_Precharge =>
	
	S_CPT_DATA <= (others => '0');					   
	reg_Ready <= '0';
	
	S_DOE <= '0';
	S_BA <= (others => '0');
	S_DQM <= (others => '0');
	
	reg_DataReady <= '0';
	
	S_CPT <= T_RESET;
	
	-- CMD
	S_CMD <= PRECHARGE; 
	S_ADDR <= A_ALL_BANK;
	
	if(SELECT_IN = '1' AND R_CPT_REFRESH <= (STD_LOGIC_VECTOR(unsigned(T_REFRESH) - 6)))then
		nextState <= S_Active;
	else				 
		nextState <= S_IDLE;
	end if;
-- ----- --------- ----- --
	
-- ----- REFRESH ----- --
WHEN S_Refresh =>

	Refresh_Toggle <= '1'; -- DEBUG

	reg_Ready <= '0'; -- SDRAM Busy

	S_DOE <= '0';
	S_BA <= (others => '0');
	S_DQM <= (others => '0');
	
	S_CPT_REFRESH <= T_RESET_REFRESH; -- reset refresh counter
	
	-- CMD
	S_CMD <= REFRESH; 
	S_ADDR <= A_NOP;
	
	S_CPT <= T_RESET;
	
	nextState <= S_Refresh_NOP1;
	
	
	
WHEN S_Refresh_NOP1 =>

	Refresh_Toggle <= '1'; -- DEBUG

	reg_Ready <= '0';
	
	S_DOE <= '0';
	S_BA <= (others => '0');
	
	S_CPT <= STD_LOGIC_VECTOR(unsigned(R_CPT) + 1); -- Counter for Trc delay
	
	-- CMD
	S_CMD <= NOP; 
	S_ADDR <= A_NOP;
	
	if(R_CPT >= T_TRC)then
		nextState <= S_IDLE;
	else
		nextState <= S_Refresh_NOP1;
	end if;
	
WHEN S_Refresh_NOP2 =>
	
WHEN S_Refresh_NOP3 =>

-- ----- -------- ----- --
	

END CASE;

END PROCESS fsm;

-- --
currentState <= S_First when reset = '1' else
				    nextState when rising_edge(clk);
-- --
R_ADDR <= A_NOP when reset = '1'
		    else S_ADDR when falling_edge(clk);
SDRAM_ADDR <= R_ADDR;
-- --
R_CMD <= NOP when reset = '1'
		    else S_CMD when falling_edge(clk);
-- --
R_DOUT <= (others => '0') when reset = '1'
		    else S_DOUT when falling_edge(clk);
-- --
R_BA <= "00" when reset = '1'
		else S_BA when falling_edge(clk);
SDRAM_BA <= R_BA;
-- --
R_DOE <= '0' when reset = '1'
		else S_DOE when falling_edge(clk);
-- --
R_CPT <= T_RESET when reset = '1'
		else S_CPT when rising_edge(clk);
-- --
R_CPT_REFRESH <= T_RESET_REFRESH when reset = '1'
		else S_CPT_REFRESH when rising_edge(clk);
-- --
R_CPT_DATA <= (others => '0') when reset = '1'
		else S_CPT_DATA when rising_edge(clk);
-- --
Ready <= reg_Ready;
-- --
R_Write_IN <= '0' when reset = '1'
		else S_Write_IN when falling_edge(clk);
-- --
R_DQM <= (others => '0') when reset = '1'
		else S_DQM when falling_edge(clk);
SDRAM_DQM <= R_DQM;
-- --


-- Data INOUT --
SDRAM_DQ <= R_DOUT when R_DOE = '1'
				else (others => 'Z');
Din <= SDRAM_DQ;

-- --
RegRead2 <= (others=>'0') when reset='1' 
			else MuxRead2 when rising_edge(clk);
			
MuxRead2 <= Din when reg_DataReady = '1'
				else RegRead2;

Data_Ready <= '0' when reset = '1' else
					reg_DataReady when rising_edge(clk);

Data_OUT <= PKG_outputData_SDRAM when PKG_simulON = '1' else
				RegRead2;
-- Data INOUT --

end vhdl;


