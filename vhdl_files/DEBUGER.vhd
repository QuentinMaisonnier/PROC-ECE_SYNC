-- Projet de fin d'études : RISC-V
-- ECE Paris / SECAPEM

-- LIBRARIES
LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;
USE work.simulPkg.ALL;

-- ENTITY
ENTITY debuger IS
	PORT (
		-- INPUTS
		TOPclock    : IN  STD_LOGIC; --must go through pll
		reset    : IN  STD_LOGIC; --SW0
		-- DEMO OUTPUTS
		TOPdisplay1 : OUT STD_LOGIC_VECTOR(31 DOWNTO 0); --0x80000004
		TOPleds     : OUT STD_LOGIC_VECTOR(31 DOWNTO 0) --0x8000000c
		--TestLed     : OUT STD_LOGIC
	);
END ENTITY;

ARCHITECTURE archi OF debuger IS
begin
END archi;
-- END FILE