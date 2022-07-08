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

signal R_Data_Ready_32,	signal_Ready_32b  : STD_LOGIC;
signal S_CPT, R_CPT 	: STD_LOGIC_VECTOR(3 downto 0);
signal DQM, R_DQM, S_DQM 	: STD_LOGIC_VECTOR(3 downto 0);

signal R_DATA, S_DATA	: STD_LOGIC_VECTOR(31 downto 0);

signal R_IN_Data_32, S_IN_Data_32, Muxdata	: STD_LOGIC_VECTOR(31 downto 0);
signal R_IN_Function3, S_IN_Function3	: STD_LOGIC_VECTOR(1 downto 0);
signal R_IN_Address, S_IN_Address	: STD_LOGIC_VECTOR(25 downto 0);

Type state is (WAITING, READ_LSB_SEND, READ_MSB_SEND, READ_LSB_GET, READ_MSB_GET, WRITE_LSB, WRITE_MSB);
signal currentState, nextState : state;

begin

PKG_R_In_Addr <= R_IN_Address;-- Test Bench

Ready_32b <= signal_Ready_32b;

fsm : Process( Clock, Reset, currentState, Ready_16b, DataOut_16b, R_CPT, R_DATA, IN_Write_Select, IN_Address, IN_Data_32, IN_Select, Data_Ready_16b, R_IN_Address, DQM, R_IN_Data_32)
begin 
	OUT_Address <= (others=>'0');
	OUT_Write_Select <= '0';
	OUT_Data_16 <= (others=>'0');
	OUT_Select <= '0';
	OUT_DQM <= (others=>'0');
	S_DATA <= R_DATA;
	signal_Ready_32b <= '0';
	R_Data_Ready_32 <= '0';
	nextState <= currentState;
	S_CPT <= R_CPT;

CASE currentState IS

when WAITING =>

	if(unsigned(R_CPT) < 2)then
		S_CPT <= STD_LOGIC_VECTOR(unsigned(R_CPT) + 1);
	end if;
	
	if(Ready_16b = '1' AND IN_Write_Select = '0')then
		signal_Ready_32b <= '1';
	else
		if(Ready_16b = '1' AND unsigned(R_CPT) >= 2)then
			signal_Ready_32b <= '1';
		else
			signal_Ready_32b <= '0';
		end if;
	end if;
	
	if(IN_Select = '1' AND Ready_16b = '1') then
			if(IN_Write_Select = '1') then
				nextState <= WRITE_MSB;
			else
				nextState <= READ_MSB_SEND;
			end if;
			S_CPT <= (others =>'0');
	end if;
	
	
when WRITE_MSB =>
	OUT_Address 	  <= R_IN_Address(25 downto 2) & '0'; 
	OUT_Write_Select <= '1';							
	OUT_Data_16 	  <= R_IN_Data_32(31 downto 16);
	OUT_Select		  <= '1';
	OUT_DQM			  <= DQM(2) & DQM(3);
	
	if(Ready_16b = '1')then
		nextstate <= WRITE_LSB;
	end if;



when WRITE_LSB =>
	OUT_Address 	  <= R_IN_Address(25 downto 2) & '1';
	OUT_Write_Select <= '1';
	OUT_Data_16 	  <= R_IN_Data_32(15 downto 0);
	OUT_Select		  <= '1';
	OUT_DQM			  <= DQM(0) & DQM(1);
	
	if(Ready_16b = '1')then
		nextstate <= WAITING;
	end if;

when READ_MSB_SEND =>
	--ready_32b <= '0';
	OUT_Address 	  <= R_IN_Address(25 downto 2) & '0';
	OUT_Write_Select <= '0';
	OUT_Select		  <= '1';
	OUT_DQM			  <= "00";
	
	if(Ready_16b = '1')then
		nextstate <= READ_LSB_SEND;
	end if;

when READ_LSB_SEND =>
	--ready_32b <= '0';
	OUT_Address 	  <= R_IN_Address(25 downto 2) & '1';
	OUT_Write_Select <= '0';
	OUT_Select		  <= '1';
	OUT_DQM			  <= "00";

	if(Ready_16b = '1')then
		nextstate <= READ_MSB_GET;
	end if;
	
when READ_MSB_GET =>
	--ready_32b <= '0';
	
	if(Data_Ready_16b = '1') then
		S_DATA(31 downto 16) <= DataOut_16b;
		nextstate <= READ_LSB_GET;
	end if;

when READ_LSB_GET =>
	--ready_32b <= '0';
	OUT_Address 	  <= R_IN_Address(25 downto 2) & '1';
	OUT_Write_Select <= '0';
	OUT_Select		  <= '1';
	OUT_DQM			  <= "00";
	
	if(Data_Ready_16b = '1') then
		S_DATA(15 downto 0) <= DataOut_16b;
		nextstate <= WAITING;
		R_Data_Ready_32 <= '1';
		--Data_Ready_32b <= '1';
	end if;

END CASE;
END PROCESS fsm;

Data_Ready_32b <= '0' when reset = '1' else
						R_Data_Ready_32 when rising_edge(clock);

currentState <= WAITING when reset = '1' else
				    nextState when rising_edge(Clock);
			 
R_DATA <= (others => '0') when reset = '1' else
		    S_DATA when rising_edge(Clock);
			 
R_CPT <= (others => '0') when reset = '1' else
			S_CPT when rising_edge(Clock);
			
			
R_IN_Data_32 <= (others => '0') when reset = '1' else
		    S_IN_Data_32 when rising_edge(Clock);
R_IN_Function3 <= (others => '0') when reset = '1' else
		    S_IN_Function3 when rising_edge(Clock);
R_IN_Address <= (others => '0') when reset = '1' else
		    S_IN_Address when rising_edge(Clock);		 
			
					 
S_IN_Address <= IN_Address when IN_Select='1' else
					 R_IN_Address;
S_IN_Function3 <= IN_Function3 when IN_Select='1' else
					 R_IN_Function3;
			 
DataOut_32b <= MuxData 				 				    when  DQM="0000" else
					x"000000" & MuxData(7 downto 0)   when  DQM="1110" else
					x"000000" & MuxData(15 downto 8)  when  DQM="1101" else
					x"000000" & MuxData(23 downto 16) when  DQM="1011" else
					x"000000" & MuxData(31 downto 24) when  DQM="0111" else
					x"0000" 	 & MuxData(15 downto 0)  when  DQM="1100" else
					x"0000" 	 & MuxData(31 downto 16) when  DQM="0011" else
					(others=>'0');
					
MuxData <= PKG_outputDM when PKG_simulON = '1' else
			  R_DATA;
			  
S_IN_Data_32 <= IN_Data_32 				  							when IN_Select='1' AND DQM = "0000" else
					 x"0000" & IN_Data_32(15 downto 0)           when IN_Select='1' AND DQM = "1100" else
					 IN_Data_32(31 downto 16) & x"0000"          when IN_Select='1' AND DQM = "0011" else
					 x"000000" & IN_Data_32(7 downto 0)          when IN_Select='1' AND DQM = "1110" else
					 x"0000" & IN_Data_32(15 downto 8) & x"00"   when IN_Select='1' AND DQM = "1101" else
					 x"00" & IN_Data_32(23 downto 16) & x"0000"  when IN_Select='1' AND DQM = "1011" else
					 IN_Data_32(31 downto 24) & x"000000" 			when IN_Select='1' AND DQM = "0111" else
					 R_IN_Data_32;
					 
DQM <= "0000" when R_IN_Function3 = "10" else 											     -- 4 octets
		 "1100" when R_IN_Function3 = "01" AND R_IN_Address(1) =  '0' else 			  -- 2 octets
		 "0011" when R_IN_Function3 = "01" AND R_IN_Address(1) =  '1' else  			  -- 2 octets 
		 "1110" when R_IN_Function3 = "00" AND R_IN_Address(1 downto 0) =  "00" else  -- 1 octet 
		 "1101" when R_IN_Function3 = "00" AND R_IN_Address(1 downto 0) =  "01" else  -- 1 octet
		 "1011" when R_IN_Function3 = "00" AND R_IN_Address(1 downto 0) =  "10" else  -- 1 octet
		 "0111" when R_IN_Function3 = "00" AND R_IN_Address(1 downto 0) =  "11" else  -- 1 octet
		 "1111";

end vhdl;
