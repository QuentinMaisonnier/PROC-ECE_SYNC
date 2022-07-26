-- Ludovic Quiterio - Projet de fin d'études : RISC-V
-- ECE Paris / SECAPEM
-- Instruction Decoder VHDL

-- 06/07/2022 : Decoupage de l'instruction load en deux parties:
-- Partie 1 : IDload effectue la requête de lecture à la mémoire mais n'incrémente pas son PC. L'instruction LOAD doit rester sur le bus d'instruction (pas de requête de  nouvelle instruction).
-- Partie 2 : IDloadP2 récupère la données provenant de la mémoire et la stock dans le banc de registre. La requête de la nouvelle instruction est effectuee

-- LIBRARIES
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- ENTITY
entity InstructionDecoder is
	port (
		-- INPUTS
		-- instruction endianness must be Big Endian !
		hold				: in std_logic;
		reset, clock	: in std_logic;
		IDinstruction 	: in std_logic_vector (31 downto 0);
		-- OUTPUTS
		IDopcode 		: out std_logic_vector (6 downto 0);
		IDimmSel 		: out std_logic;
		IDrd 			   : out std_logic_vector (4 downto 0);
		IDrs1 			: out std_logic_vector (4 downto 0);
		IDrs2 			: out std_logic_vector (4 downto 0);
		IDfunct3 		: out std_logic_vector (2 downto 0);
		IDfunct7 		: out std_logic;
		IDimm12I 		: out std_logic_vector (11 downto 0);
		IDimm12S 		: out std_logic_vector (11 downto 0);
		IDimm13B 		: out std_logic_vector (12 downto 0);
		IDimm32U 		: out std_logic_vector (31 downto 0);
		IDimm21J 		: out std_logic_vector (20 downto 0);
		IDload 			: out std_logic;
		IDloadP2		   : out std_logic;
		IDstore 		   : out std_logic;
		--IDstoreP2 		: out std_logic;
		IDlui 			: out std_logic;
		IDauipc 		   : out std_logic;
		IDjal 			: out std_logic;
		IDjalr 			: out std_logic;
		IDbranch 		: out std_logic
	);
end entity;

-- ARCHITECTURE
architecture archi of InstructionDecoder is

SIGNAL SIGIDload, SIGIDloadP2 : STD_LOGIC;
Type state is (LoadP1state, LoadP2state);
signal currentState, nextState : state;

SIGNAL SIGIDstore: STD_LOGIC;

begin
	--BEGIN
	-- opcode
	IDopcode(6 downto 0) 	<= IDinstruction(6 downto 0);
	-- immediate operation selector
	IDimmSel 			<= NOT IDinstruction(5);
	-- register destination
	IDrd(4 downto 0) 		<= IDinstruction(11 downto 7);
	-- register source 1
	IDrs1(4 downto 0) 	<= IDinstruction(19 downto 15);
	-- register source 2
	IDrs2(4 downto 0) 	<= IDinstruction(24 downto 20);
	-- funct 3
	IDfunct3(2 downto 0) 	<= IDinstruction(14 downto 12);
	-- funct7 bit 6
	IDfunct7 			<= IDinstruction(30);
	-- immediate value for I-type
	IDimm12I(11 downto 0) 	<= IDinstruction(31 downto 20);
	-- immediate value for S-type
	IDimm12S(11 downto 5) 	<= IDinstruction(31 downto 25);
	IDimm12S(4 downto 0) 	<= IDinstruction(11 downto 7);
	-- immediate value for B-type
	IDimm13B(12) 		<= IDinstruction(31);
	IDimm13B(11) 		<= IDinstruction(7);
	IDimm13B(10 downto 5) 	<= IDinstruction(30 downto 25);
	IDimm13B(4 downto 1) 	<= IDinstruction(11 downto 8);
	IDimm13B(0) 		<= '0';
	-- immediate value for U-type
	IDimm32U(31 downto 12) <= IDinstruction(31 downto 12);
	IDimm32U(11 downto 0) 	<= "000000000000";
	-- immediate value for J-type
	IDimm21J(20) 		<= IDinstruction(31);
	IDimm21J(19 downto 12) 	<= IDinstruction(19 downto 12);
	IDimm21J(11) 		<= IDinstruction(20);
	IDimm21J(10 downto 1) 	<= IDinstruction(30 downto 21);
	IDimm21J(0) 	<= '0';
	
	-- Load instruction ?
	
	
	loadProcess : PROCESS (Hold, IDinstruction, currentState)
	BEGIN
	
		nextState <= currentState;
		SIGIDload <= '0';
		SIGIDloadP2 <= '0';
		
		CASE currentState IS
		
			WHEN LoadP1state=> 
			
				IF Hold='0' AND IDinstruction(6 downto 0) = "0000011" THEN
					nextState <= LoadP2state;
					SIGIDload <= '1';
				END IF;
				
			WHEN LoadP2state=> 
				SIGIDloadP2 <= '1';
				
				IF Hold='0' THEN
					nextState <= LoadP1state;
				END IF;
			
		END CASE;
	END PROCESS loadProcess;
	
	currentState <= LoadP1state when reset = '1' else
				       nextState when rising_edge(Clock);
	
	IDloadP2 <= SIGIDloadP2;
	IDload   <= SIGIDload;
	
	-- Store instruction ?
	IDstore 	<= '1' when IDinstruction(6 downto 0) = "0100011" else '0';					 
	-- LUI instruction ?
	IDlui 	<= '1' when IDinstruction(6 downto 0) = "0110111" else '0';
	-- AUIPC instruction ?
	IDauipc 	<= '1' when IDinstruction(6 downto 0) = "0010111" else '0';
	-- JAL instruction ?
	IDjal 	<= '1' when IDinstruction(6 downto 0) = "1101111" else '0';
	-- JALR instruction ?
	IDjalr 	<= '1' when IDinstruction(6 downto 0) = "1100111" else '0';
	-- Branch instruction ?
	IDbranch 	<= '1' when IDinstruction(6 downto 0) = "1100011" else '0';
	-- END
end archi;
-- END FILE