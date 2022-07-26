library IEEE;
library work;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.SDRAM_package.ALL;
USE work.simulPkg.ALL;


entity SDRAM_32b is 
    Port (
		  -- SDRAM Inputs
        Clock, Reset : in STD_LOGIC;
		
		  -- Inputs (32bits)
		  IN_Address 		: in STD_LOGIC_VECTOR(25 downto 0);
		  IN_Write_Select	: in STD_LOGIC;
		  IN_Data_32		: in STD_LOGIC_VECTOR(31 downto 0);
		  IN_Select			: in STD_LOGIC;
		  IN_Function3		: in STD_LOGIC_VECTOR(1 downto 0);
		  
		  -- Outputs (16b)
		  OUT_Address 			: out STD_LOGIC_VECTOR(24 downto 0);
		  OUT_Write_Select	: out STD_LOGIC;
		  OUT_Data_16			: out STD_LOGIC_VECTOR(15 downto 0);
		  OUT_Select			: out STD_LOGIC;
		  OUT_DQM				: out STD_LOGIC_VECTOR(1 downto 0);
		 
		  -- Test Outputs (32bits)
		  Ready_32b				: out STD_LOGIC := '0';
		  Data_Ready_32b		: out STD_LOGIC;
		  DataOut_32b			: out STD_LOGIC_VECTOR(31 downto 0);
		  
		  -- Test Outputs (16bits)
		  Ready_16b				: in STD_LOGIC;
		  Data_Ready_16b		: in STD_LOGIC;
		  DataOut_16b			: in STD_LOGIC_VECTOR(15 downto 0)
	);
end SDRAM_32b;

architecture vhdl of SDRAM_32b is 

SIGNAL Mux_IN_Write_Select, Reg_IN_Write_Select : STD_LOGIC;
signal Reg_Data_Ready_32,	SIG_Ready_32b, SIG_data_Ready_32  : STD_LOGIC;
signal SIG_CPT, Reg_CPT 	: STD_LOGIC_VECTOR(3 downto 0);
signal DQM              : STD_LOGIC_VECTOR(3 downto 0);
signal SIG_selectOUT16	: std_logic;

SIGNAL R_DATA_part1, S_DATA_part1, R_DATA_part2, S_DATA_part2 : STD_LOGIC_VECTOR(15 downto 0);
signal R_DATA, S_DATA, Reg_DataOut, SIGDataOut_32b	: STD_LOGIC_VECTOR(31 downto 0);

signal Reg_IN_Data_32, Mux_IN_Data_32, Mux_data32	: STD_LOGIC_VECTOR(31 downto 0);
signal Reg_IN_Function3, Mux_IN_Function3	: STD_LOGIC_VECTOR(1 downto 0);
signal Reg_IN_Address, Mux_IN_Address	: STD_LOGIC_VECTOR(25 downto 0);

Type state is (WAITING, READ_LSB_SEND, READ_MSB_SEND, READ_LSB_GET, READ_MSB_GET, WRITE_LSB, WRITE_MSB, END_WRITE);
signal currentState, nextState : state;

begin

fsm : Process(R_DATA_part2, R_DATA_part1, Mux_IN_Data_32, Reg_IN_Address, Mux_IN_Address, Mux_IN_Write_Select, currentState, Ready_16b, DataOut_16b, Reg_CPT, R_DATA, IN_Select, Data_Ready_16b, DQM, Reg_IN_Data_32)
begin 
	OUT_Address <= (others=>'0');
	OUT_Write_Select <= '0';
	OUT_Data_16 <= (others=>'0');
	SIG_selectOUT16 <= '0';
	OUT_DQM <= (others=>'0');
	S_DATA <= R_DATA;
	SIG_Ready_32b <= '0';
	Reg_Data_Ready_32 <= '0';
	nextState <= currentState;
	SIG_CPT <= Reg_CPT;
	
	S_DATA_part1 <= R_DATA_part1;
	S_DATA_part2 <= R_DATA_part2;
CASE currentState IS

when WAITING =>

--	if(unsigned(Reg_CPT) < 2)then
--		SIG_CPT <= STD_LOGIC_VECTOR(unsigned(Reg_CPT) + 1);
--	end if;
	
	if(Ready_16b = '1')then
		SIG_Ready_32b <= '1';
	else
		SIG_Ready_32b <= '0';
	end if;

--	if(Ready_16b = '1' AND Mux_IN_Write_Select = '0')then
--		SIG_Ready_32b <= '1';
--	else
--		if(Ready_16b = '1' AND unsigned(Reg_CPT) >= 2)then
--			SIG_Ready_32b <= '1';
--		else
--			SIG_Ready_32b <= '0';
--		end if;
--	end if;
	
	if(IN_Select = '1' AND Ready_16b = '1') then
			if(Mux_IN_Write_Select = '1') then
				--nextState <= WRITE_MSB;
				
				OUT_Address 	  <= Mux_IN_Address(25 downto 2) & '0'; 
				OUT_Write_Select <= '1';							
				OUT_Data_16 	  <= Mux_IN_Data_32(31 downto 16);
				SIG_selectOUT16  <= '1';
				OUT_DQM			  <= DQM(3) & DQM(2);

				nextstate <= WRITE_LSB;

			else
				--nextState <= READ_MSB_SEND;
				
				OUT_Address 	  <= Mux_IN_Address(25 downto 2) & '0';
				OUT_Write_Select <= '0';
				SIG_selectOUT16  <= '1';
				OUT_DQM			  <= "00";
				
				nextstate <= READ_LSB_SEND;
				
			end if;
			SIG_CPT <= (others =>'0');
	end if;
	
	
when WRITE_MSB =>
	OUT_Address 	  <= Mux_IN_Address(25 downto 2) & '0'; 
	OUT_Write_Select <= '1';							
	OUT_Data_16 	  <= Mux_IN_Data_32(31 downto 16);
	SIG_selectOUT16		  <= '1';
	OUT_DQM			  <= DQM(3) & DQM(2);
	
	if(Ready_16b = '1')then
		nextstate <= WRITE_LSB;
	end if;



when WRITE_LSB =>
	
	OUT_Address 	  <= Mux_IN_Address(25 downto 2) & '1';
	OUT_Write_Select <= '1';
	OUT_Data_16 	  <= Mux_IN_Data_32(15 downto 0);
	SIG_selectOUT16  <= '1';
	OUT_DQM			  <= DQM(1) & DQM(0);
	
	if(Ready_16b = '1')then
		nextstate <= END_WRITE;
	end if;
	
when END_WRITE =>

	if(Ready_16b = '0')then
		nextstate <= WAITING;
	end if;

when READ_MSB_SEND =>
	--ready_32b <= '0';
	OUT_Address 	  <= Mux_IN_Address(25 downto 2) & '0';
	OUT_Write_Select <= '0';
	SIG_selectOUT16		  <= '1';
	OUT_DQM			  <= "00";
	
	if(Ready_16b = '1')then
		nextstate <= READ_LSB_SEND;
	end if;

when READ_LSB_SEND =>
	--ready_32b <= '0';
	OUT_Address 	  <= Mux_IN_Address(25 downto 2) & '1';
	OUT_Write_Select <= '0';
	SIG_selectOUT16		  <= '1';
	OUT_DQM			  <= "00";

	if(Ready_16b = '1')then
		nextstate <= READ_MSB_GET;
	end if;
	
when READ_MSB_GET =>
	--ready_32b <= '0';
	
	if(Data_Ready_16b = '1') then
--		S_DATA(31 downto 16) <= DataOut_16b;
		S_DATA_part1 <= DataOut_16b;
		nextstate <= READ_LSB_GET;
	end if;

when READ_LSB_GET =>
	--ready_32b <= '0';
	OUT_Address 	  <= Mux_IN_Address(25 downto 2) & '1';
	OUT_Write_Select <= '0';
	--SIG_selectOUT16		<= '1';
	OUT_DQM			  <= "00";
	
	if(Data_Ready_16b = '1') then
--		S_DATA(15 downto 0) <= DataOut_16b;
		S_DATA_part2 <= DataOut_16b;
		nextstate <= WAITING;
		Reg_Data_Ready_32 <= '1';
		--Data_Ready_32b <= '1';
	end if;

END CASE;
END PROCESS fsm;

R_DATA_part1 <= (others => '0') when reset='1' else
					 S_DATA_part1 when rising_edge(clock);
					 
R_DATA_part2 <= (others => '0') when reset='1' else
					 S_DATA_part2 when rising_edge(clock);

-------------------DATA READY-----------------

currentState <= WAITING when reset = '1' else
				    nextState when rising_edge(Clock);
			 
Reg_CPT <= (others => '0') when reset = '1' else
			SIG_CPT when rising_edge(Clock);


----------------------------IN-----------------------------
Reg_IN_Write_Select <= '0' when reset='1' else
					        Mux_IN_Write_Select when rising_edge(clock);
Mux_IN_Write_Select <= In_write_Select when IN_Select='1' else
					        Reg_IN_Write_Select;
					   
Reg_IN_Address <= (others => '0') when reset = '1' else
				      Mux_IN_Address when rising_edge(Clock);		 
Mux_IN_Address <= IN_Address when IN_Select='1' else
				      Reg_IN_Address;
				  		  
Reg_IN_Function3 <= (others => '0') when reset = '1' else
				  Mux_IN_Function3 when rising_edge(Clock);
Mux_IN_Function3 <= IN_Function3 when IN_Select='1' else
					Reg_IN_Function3;	

Reg_IN_Data_32 <= (others => '0') when reset = '1' else
						Mux_IN_Data_32 when rising_edge(Clock);	 
				
Mux_IN_Data_32 <= IN_Data_32 				  				  when IN_Select='1' AND DQM = "0000" else
						x"0000" & IN_Data_32(15 downto 0)           when IN_Select='1' AND DQM = "1100" else
						IN_Data_32(31 downto 16) & x"0000"          when IN_Select='1' AND DQM = "0011" else
						x"000000" & IN_Data_32(7 downto 0)          when IN_Select='1' AND DQM = "1110" else
						x"0000" & IN_Data_32(15 downto 8) & x"00"   when IN_Select='1' AND DQM = "1101" else
						x"00" & IN_Data_32(23 downto 16) & x"0000"  when IN_Select='1' AND DQM = "1011" else
				      IN_Data_32(31 downto 24) & x"000000" 		  when IN_Select='1' AND DQM = "0111" else
				      Reg_IN_Data_32;
				  
-------------------------DQM------------------------				 
DQM <= "0000" when Mux_IN_Function3 = "10" 										  else  -- 4 octets
	   "1100" when Mux_IN_Function3 = "01" AND Mux_IN_Address(1) =  '0' 		  else  -- 2 octets
	   "0011" when Mux_IN_Function3 = "01" AND Mux_IN_Address(1) =  '1' 		  else  -- 2 octets 
	   "1110" when Mux_IN_Function3 = "00" AND Mux_IN_Address(1 downto 0) =  "00" else  -- 1 octet 
	   "1101" when Mux_IN_Function3 = "00" AND Mux_IN_Address(1 downto 0) =  "01" else  -- 1 octet
	   "1011" when Mux_IN_Function3 = "00" AND Mux_IN_Address(1 downto 0) =  "10" else  -- 1 octet
	   "0111" when Mux_IN_Function3 = "00" AND Mux_IN_Address(1 downto 0) =  "11" else  -- 1 octet
	   "1111";
--
--Mux_IN_Data_32 <= IN_Data_32 when IN_Select='1' else
--					   Reg_IN_Data_32;
----------------	
------------------------------OUT---------------------------
---------------------------DATA OUT 32b------------------------------------------
DataOut_32b <= SIGDataOut_32b;

SIGDataOut_32b	<= (others=> '0') when reset='1' else
				   Reg_DataOut when rising_edge(clock);
				   
Reg_DataOut <= Mux_data32 				 				       when  DQM="0000" else
					x"000000" & Mux_data32(7 downto 0)      when  DQM="1110" else
					x"000000" & Mux_data32(15 downto 8)     when  DQM="1101" else
					x"000000" & Mux_data32(23 downto 16)    when  DQM="1011" else
					x"000000" & Mux_data32(31 downto 24)    when  DQM="0111" else
					x"0000"   & Mux_data32(15 downto 0)     when  DQM="1100" else
					x"0000"   & Mux_data32(31 downto 16)    when  DQM="0011" else
					(others=>'0');

Mux_data32 <= --PKG_outputDM when PKG_simulON = '1' else
			     S_DATA_part1 & S_DATA_part2 when Reg_Data_Ready_32='1'  else
			     R_DATA;
			  
R_DATA <= (others => '0') when reset = '1' else
		    Mux_data32 when rising_edge(Clock); 
----------------------------
Data_Ready_32b <= SIG_data_Ready_32;

SIG_data_Ready_32 <= '0' when reset = '1' else
				         Reg_Data_Ready_32 when rising_edge(clock);
---------------------------
--Ready_32b <= '0' when reset='1' else
--			    SIG_Ready_32b when rising_edge(clock);
Ready_32b <= SIG_Ready_32b;
-----------------------------SIMULATION--------------------------------------
--PKG_dataReady_32b <= Reg_Data_Ready_32;
--PKG_inputData32   <= Mux_IN_Data_32;
--PKG_SDRAMselect   <= IN_Select;
--PKG_DQM           <= DQM;
--PKG_R_In_Addr     <= Mux_IN_Address;-- Test Bench
--PKG_SDRAMwrite    <= Mux_In_write_Select;
------------------------------
OUT_Select <= SIG_selectOUT16;


end vhdl;
