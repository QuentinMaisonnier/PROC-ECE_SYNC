library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package simulPkg is

	
	signal PKG_simulON        : std_logic 	:= '1';
	signal PKG_dataReady_32b  : std_logic;
	signal PKG_R_In_Addr  	  : std_logic_vector(25 downto 0);
	signal PKG_inputData32	  : std_logic_vector(31 downto 0);
	SIGNAL PKG_SDRAMselect : std_logic;

	SIGNAL PKG_SDRAMwrite: std_logic;

	signal PKG_store       : std_logic;
	signal PKG_load        : std_logic;
	signal PKG_funct3      : std_logic_vector(2 downto 0);
	signal PKG_addrDM      : std_logic_vector(31 downto 0);
	signal PKG_counter     : std_logic_vector(31 downto 0);
	signal PKG_inputDM     : std_logic_vector(31 downto 0);
	signal PKG_outputDM    : std_logic_vector(31 downto 0);
	signal PKG_progcounter : std_logic_vector(31 downto 0);
	signal PKG_instruction : std_logic_vector(31 downto 0);
	
	signal PKG_reg00	: std_logic_vector(31 downto 0);
	signal PKG_reg01	: std_logic_vector(31 downto 0);
	signal PKG_reg02	: std_logic_vector(31 downto 0);
	signal PKG_reg03	: std_logic_vector(31 downto 0);
	signal PKG_reg04	: std_logic_vector(31 downto 0);
	signal PKG_reg05	: std_logic_vector(31 downto 0);
	signal PKG_reg06	: std_logic_vector(31 downto 0);
	signal PKG_reg07	: std_logic_vector(31 downto 0);
	signal PKG_reg08	: std_logic_vector(31 downto 0);
	signal PKG_reg09	: std_logic_vector(31 downto 0);
	signal PKG_reg0A	: std_logic_vector(31 downto 0);
	signal PKG_reg0B	: std_logic_vector(31 downto 0);
	signal PKG_reg0C	: std_logic_vector(31 downto 0);
	signal PKG_reg0D	: std_logic_vector(31 downto 0);
	signal PKG_reg0E	: std_logic_vector(31 downto 0);
	signal PKG_reg0F	: std_logic_vector(31 downto 0);
	signal PKG_reg10	: std_logic_vector(31 downto 0);
	signal PKG_reg11	: std_logic_vector(31 downto 0);
	signal PKG_reg12	: std_logic_vector(31 downto 0);
	signal PKG_reg13	: std_logic_vector(31 downto 0);
	signal PKG_reg14	: std_logic_vector(31 downto 0);
	signal PKG_reg15	: std_logic_vector(31 downto 0);
	signal PKG_reg16	: std_logic_vector(31 downto 0);
	signal PKG_reg17	: std_logic_vector(31 downto 0);
	signal PKG_reg18	: std_logic_vector(31 downto 0);
	signal PKG_reg19	: std_logic_vector(31 downto 0);
	signal PKG_reg1A	: std_logic_vector(31 downto 0);
	signal PKG_reg1B	: std_logic_vector(31 downto 0);
	signal PKG_reg1C	: std_logic_vector(31 downto 0);
	signal PKG_reg1D	: std_logic_vector(31 downto 0);
	signal PKG_reg1E	: std_logic_vector(31 downto 0);
	signal PKG_reg1F	: std_logic_vector(31 downto 0);
	
end package simulPkg ; 