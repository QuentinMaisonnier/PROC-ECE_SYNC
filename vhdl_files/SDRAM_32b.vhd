library IEEE;
library work;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.SDRAM_package.ALL;


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
		  Ready_32b				: out STD_LOGIC;
		  Data_Ready_32b		: out STD_LOGIC;
		  DataOut_32b			: out STD_LOGIC_VECTOR(31 downto 0);
		  
		  -- Test Outputs (16bits)
		  Ready_16b				: in STD_LOGIC;
		  Data_Ready_16b		: in STD_LOGIC;
		  DataOut_16b			: in STD_LOGIC_VECTOR(15 downto 0)
	);
end SDRAM_32b;

architecture vhdl of SDRAM_32b is 

signal R_address_in, S_address_in 	: STD_LOGIC_VECTOR(23 downto 0);
signal address_select, R_Data_Ready_32	: STD_LOGIC;
signal DQM 	: STD_LOGIC_VECTOR(3 downto 0);

signal R_DATA, S_DATA	: STD_LOGIC_VECTOR(31 downto 0);

Type state is (WAITING, READ_LSB_SEND, READ_MSB_SEND, READ_LSB_GET, READ_MSB_GET, WRITE_LSB, WRITE_MSB);
signal currentState, nextState : state;

begin


-- Data_Ready_16b in the sensitivity list : cause peut-être un BUG
fsm : Process( Clock, Reset, DQM, currentState, Ready_16b, DataOut_16b, R_DATA, IN_Write_Select, IN_Address, IN_Data_32, IN_Function3, IN_Select, Data_Ready_16b)
begin 
	OUT_Address <= (others=>'0');
	OUT_Write_Select <= '0';
	OUT_Data_16 <= (others=>'0');
	OUT_Select <= '0';
	OUT_DQM <= (others=>'0');
	S_DATA <= R_DATA;
	ready_32b <= '1';
	R_Data_Ready_32 <= '0';
	nextState <= currentState;

CASE currentState IS

when WAITING =>
	if(IN_Select = '1' AND Ready_16b = '1') then
			if(IN_Write_Select = '1') then
				nextState <= WRITE_MSB;
			else
				nextState <= READ_MSB_SEND;
			end if;
	end if;
	
	
when WRITE_MSB =>
	ready_32b <= '0';
	OUT_Address 	  <= IN_Address(25 downto 2) & '0'; 
	OUT_Write_Select <= '1';							
	OUT_Data_16 	  <= IN_Data_32(31 downto 16);
	OUT_Select		  <= '1';
	OUT_DQM			  <= DQM(2) & DQM(3);
	
	if(Ready_16b = '1')then
		nextstate <= WRITE_LSB;
	end if;



when WRITE_LSB =>
	ready_32b <= '0';
	OUT_Address 	  <= IN_Address(25 downto 2) & '1';
	OUT_Write_Select <= '1';
	OUT_Data_16 	  <= IN_Data_32(15 downto 0);
	OUT_Select		  <= '1';
	OUT_DQM			  <= DQM(0) & DQM(1);
	
	if(Ready_16b = '1')then
		nextstate <= WAITING;
	end if;

when READ_MSB_SEND =>
	ready_32b <= '0';
	OUT_Address 	  <= IN_Address(25 downto 2) & '0';
	OUT_Write_Select <= '0';
	OUT_Select		  <= '1';
	OUT_DQM			  <= "00";
	
	if(Ready_16b = '1')then
		nextstate <= READ_LSB_SEND;
	end if;

when READ_LSB_SEND =>
	ready_32b <= '0';
	OUT_Address 	  <= IN_Address(25 downto 2) & '1';
	OUT_Write_Select <= '0';
	OUT_Select		  <= '1';
	OUT_DQM			  <= "00";

	if(Ready_16b = '1')then
		nextstate <= READ_MSB_GET;
	end if;
	
when READ_MSB_GET =>
	ready_32b <= '0';
	
	if(Data_Ready_16b = '1') then
		S_DATA(31 downto 16) <= DataOut_16b;
		nextstate <= READ_LSB_GET;
	end if;

when READ_LSB_GET =>
	ready_32b <= '0';
	OUT_Address 	  <= IN_Address(25 downto 2) & '1';
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

R_address_in <= (others => '0') when Reset='1' else
						S_address_in when rising_edge(Clock);
						
S_address_in <= IN_Address when address_select = '1' else
					  R_address_in;
			 
R_DATA <= (others => '0') when reset = '1' else
		    S_DATA when rising_edge(Clock);
			 
DataOut_32b <= R_DATA 				 				   when  DQM="0000" else
					x"000000" & R_DATA(7 downto 0)   when  DQM="1110" else
					x"000000" & R_DATA(15 downto 8)  when  DQM="1101" else
					x"000000" & R_DATA(23 downto 16) when  DQM="1011" else
					x"000000" & R_DATA(31 downto 24) when  DQM="0111" else
					x"0000" 	 & R_DATA(15 downto 0)  when  DQM="1100" else
					x"0000" 	 & R_DATA(31 downto 16) when  DQM="0011" else
					(others=>'0');

DQM <= "0000" when IN_Function3 = "10" else 											     -- 4 octets
		 "1100" when IN_Function3 = "01" AND IN_Address(1) =  '0' else 			  -- 2 octets
		 "0011" when IN_Function3 = "01" AND IN_Address(1) =  '1' else  			  -- 2 octets 
		 "1110" when IN_Function3 = "00" AND IN_Address(1 downto 0) =  "00" else  -- 1 octet 
		 "1101" when IN_Function3 = "00" AND IN_Address(1 downto 0) =  "01" else  -- 1 octet
		 "1011" when IN_Function3 = "00" AND IN_Address(1 downto 0) =  "10" else  -- 1 octet
		 "0111" when IN_Function3 = "00" AND IN_Address(1 downto 0) =  "11" else  -- 1 octet
		 "1111";

end vhdl;
