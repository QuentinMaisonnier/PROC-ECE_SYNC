--
-- Projet de fin d'études : RISC-V
-- ECE Paris / SECAPEM
-- Displays VHDL

-- LIBRARIES
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- ENTITY
entity Displays is
	port (
		--INPUTS
		DISPclock : in std_logic;
		DISPreset : in std_logic;
		DISPaddr : in std_logic_vector(31 downto 0);
		DISPinput : in std_logic_vector(31 downto 0);
		DISPwrite :  in std_logic;
		--OUTPUTS
		DISPleds : out std_logic_vector(31 downto 0);
		DISPdisplay1 : out std_logic_vector(31 downto 0);
		DISPdisplay2 : out std_logic_vector(31 downto 0)
	);
end entity;

-- ARCHITECTURE
architecture archi of Displays is
	
		signal combDisplay1, regDisplay1 : std_logic_vector(31 downto 0);
		signal combDisplay2, regDisplay2 : std_logic_vector(31 downto 0);
		signal combLed, regLed : std_logic_vector(31 downto 0);

begin
	-- BEGIN
	
	combDisplay1 <= DISPinput when (DISPwrite='1' and DISPaddr(31)='1' and DISPaddr(7 downto 0)=x"04") else regDisplay1;
	regDisplay1 <= (others => '0') when DISPreset='1' else
					combDisplay1 when rising_edge(DISPclock);
					
	combDisplay2 <= DISPinput when (DISPwrite='1' and DISPaddr(31)='1' and DISPaddr(7 downto 0)=X"08") else regDisplay2;
	regDisplay2 <= (others => '0') when DISPreset='1' else
					combDisplay2 when rising_edge(DISPclock);

	combLed <= DISPinput when (DISPwrite='1' and DISPaddr(31)='1' and DISPaddr(7 downto 0)=X"0C") else regLed;
	regLed <= (others => '0') when DISPreset='1' else
					combLed when rising_edge(DISPclock);
					
	DISPleds <= regLed;
	DISPdisplay1 <= regDisplay1;
	DISPdisplay2 <= regDisplay2;
	
	-- END
end archi;
-- END FILE