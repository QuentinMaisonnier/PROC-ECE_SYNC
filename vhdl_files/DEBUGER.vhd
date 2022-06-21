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
		--TOPclock    : IN STD_LOGIC; --must go through pll
		enable 		: IN STD_LOGIC;
		SwitchSel	: IN STD_LOGIC;
		SwitchSel2	: IN STD_LOGIC;
		--reset    	: IN STD_LOGIC; --SW0
		PCregister  : IN STD_LOGIC_VECTOR(15 downto 0);
		Instruction : IN STD_LOGIC_VECTOR(31 downto 0);
		--OUTPUTS
		TOPdisplay2 : OUT STD_LOGIC_VECTOR(31 DOWNTO 0); --0x80000004
		TOPdisplay1 : OUT STD_LOGIC_VECTOR(31 DOWNTO 0); --0x80000004
		TOPleds     : OUT STD_LOGIC_VECTOR(31 DOWNTO 0) --0x8000000c

	);
END ENTITY;	

ARCHITECTURE archi OF debuger IS

SIGNAL display1, display2, display3, display4, display5, display6 : STD_LOGIC_VECTOR(3 downto 0);

COMPONENT SegmentDecoder IS
	PORT (
		Sin7seg  : in  STD_LOGIC_VECTOR(3 downto 0);
		decodeOut : out  STD_LOGIC_VECTOR(7 downto 0));
END COMPONENT;


begin

display1 <= PCregister(15 downto 12) when enable='1' AND SwitchSel='1' else
				Instruction(31 downto 28) when enable='1' AND SwitchSel2='0' else
				Instruction(23 downto 20) when enable='1' AND SwitchSel2='1' else
				x"f";
				
display2 <= PCregister(11 downto 8) when enable='1' AND SwitchSel='1' else
				Instruction(27 downto 24) when enable='1' AND SwitchSel2='0' else
				Instruction(19 downto 16) when enable='1' AND SwitchSel2='1' else
				x"f";
				
display3 <= PCregister(7 downto 4) when enable='1' AND SwitchSel='1' else
				Instruction(23 downto 20) when enable='1' AND SwitchSel2='0' else
				Instruction(15 downto 12) when enable='1' AND SwitchSel2='1' else
				x"f";
				
display4 <= PCregister(3 downto 0) when enable='1' AND SwitchSel='1' else
				Instruction(19 downto 16) when enable='1' AND SwitchSel2='0' else
				Instruction(11 downto 8) when enable='1' AND SwitchSel2='1' else
				x"f";
				
display5 <= x"f" when enable='1' AND SwitchSel='1' else
				Instruction(15 downto 12) when enable='1' AND SwitchSel2='0' else
				Instruction(7 downto 4) when enable='1' AND SwitchSel2='1' else
				x"f";
				
display6 <= x"f" when enable='1' AND SwitchSel='1' else
				Instruction(11 downto 8) when enable='1' AND SwitchSel2='0' else
				Instruction(3 downto 0) when enable='1' AND SwitchSel2='1' else
				x"f";


decoder1 : SegmentDecoder
PORT MAP(
	Sin7seg		=>	display1,
	decodeOut	=> TOPdisplay2(15 downto 8)
);
decoder2 : SegmentDecoder
PORT MAP(
	Sin7seg		=> display2,
	decodeOut	=> TOPdisplay2(7 downto 0)
);
decoder3 : SegmentDecoder
PORT MAP(
	Sin7seg		=> display3,
	decodeOut	=> TOPdisplay1(31 downto 24)
);
decoder4 : SegmentDecoder
PORT MAP(
	Sin7seg		=> display4,
	decodeOut	=> TOPdisplay1(23 downto 16)
);
decoder5 : SegmentDecoder
PORT MAP(
	Sin7seg		=> display5,
	decodeOut	=> TOPdisplay1(15 downto 8)
);
decoder6 : SegmentDecoder
PORT MAP(
	Sin7seg		=> display6,
	decodeOut	=> TOPdisplay1(7 downto 0)
);
	
END archi;
-- END FILE

