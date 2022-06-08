-- Projet de fin d'études : RISC-V
-- ECE Paris / SECAPEM
-- Instruction Memory VHDL

-- LIBRARIES
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- ENTITY
entity InstructionMemory is
	port (
		-- INPUTS
		IMclock			: in std_logic;
		IMprogcounter	: in std_logic_vector(31 downto 0);
		-- OUTPUTS
		IMout				: out std_logic_vector(31 downto 0)
	);
end entity;

-- ARCHITECTURE
architecture archi of InstructionMemory is

	component IM is
	PORT
	(
		address		: IN STD_LOGIC_VECTOR (9 DOWNTO 0);
		clock		: IN STD_LOGIC  := '1';
		q		: OUT STD_LOGIC_VECTOR (31 DOWNTO 0)
	);
	end component;
	
	signal SIGlitendianIM : STD_LOGIC_VECTOR (31 DOWNTO 0);
	
begin

	IMout( 7 downto  0) <= SIGlitendianIM(31 downto 24);
	IMout(15 downto  8) <= SIGlitendianIM(23 downto 16);
	IMout(23 downto 16) <= SIGlitendianIM(15 downto  8);
	IMout(31 downto 24) <= SIGlitendianIM( 7 downto  0);
	
	instIM  : IM
	port map(
		address	=> IMprogcounter(11 downto 2),
		clock		=> IMclock,
		q			=> SIGlitendianIM
	);
	
end archi;
-- END FILE