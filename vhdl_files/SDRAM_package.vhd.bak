LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;

PACKAGE SDRAM_package IS

	-- 			8M (columns * Raw) x 16 (data) x 4 (banks) = (32M x 16)			--
	
	CONSTANT SDRAM_NUMBER : NATURAL := 1; -- number of SDRAM
	
	-- SDRAM BUS WIDTH Configuration :
	-- DATA BUS 
	CONSTANT DATA_WIDTH_OF_SDRAM : NATURAL := 16;
	-- Address BUS :
	CONSTANT COLUMN_WIDTH : NATURAL := 10; -- 1K (A0 - A9)
	CONSTANT ROW_WIDTH 	 : NATURAL := 13; -- 8K (A0 - A12)
	CONSTANT BANK_WIDTH	 : NATURAL := 2;  -- BA0 - BA1
	
	CONSTANT DQM_WIDTH  : NATURAL := SDRAM_NUMBER*2; -- number of SDRAM
	CONSTANT DATA_WIDTH : NATURAL := DATA_WIDTH_OF_SDRAM*SDRAM_NUMBER;
	
	--			   ------------------------------------------------------- 			--
	
	-- Constant Timers --
	constant  START_DELAY   : std_logic_vector(13 downto 0) := std_logic_vector(to_unsigned(5000, 14)); -- 100 us délai au démarrage de la SDRAM (5 000 cycles à 50 MHZ)
	constant  INIT_REFRESH  : std_logic_vector(13 downto 0) := B"00000000000010"; -- 2 refreshs à l'INIT
	constant  TRC      	   : std_logic_vector(13 downto 0) := B"00000000000011"; -- 3 : Command Period (REF to REF / ACT to ACT)
	
	-- Taux de Rafraichissement --
	constant  T_64MS      : std_logic_vector(21 downto 0) := B"1100001101010000000000"; -- REFRESH CYCLE =>   64 ms <=> 3 200 000 cycles à 50 MHz ERROR address 0x15404D
	constant  T_32K       : std_logic_vector(21 downto 0) := B"0000001000000000000000"; -- REFRESH CYCLE => 0.65 ms <=> 32 768 cycles à 50 MHz ERROR address 0x15404D
	constant  T_8K        : std_logic_vector(21 downto 0) := B"0000000010000000000000"; -- REFRESH CYCLE => 0.16 ms <=> 8 192 cycles à 50 MHz OKAY Fonctionne
	constant  T_400       : std_logic_vector(21 downto 0) := B"0000000000000110010000"; -- REFRESH CYCLE => 0.008 ms <=> 400 cycles à 50 MHz OKAY Fonctionne
	 
	constant  REFRESH_PERIOD   : std_logic_vector(21 downto 0) := T_400;
	
	
	-- Commande -- (CKE & CS & RAS & CAS & WE) --
	constant NOP        : std_logic_vector(4 downto 0) := B"10111";
	constant ACTIVE     : std_logic_vector(4 downto 0) := B"10011";
	constant READ       : std_logic_vector(4 downto 0) := B"10101";
	constant WRITE      : std_logic_vector(4 downto 0) := B"10100";
	constant PRECHARGE  : std_logic_vector(4 downto 0) := B"10010";
	constant REFRESH    : std_logic_vector(4 downto 0) := B"10001"; -- Auto Refresh
	constant LOAD       : std_logic_vector(4 downto 0) := B"10000";
	constant BST        : std_logic_vector(4 downto 0) := B"10110"; -- Burst Stop
	
	-- Constant address --
	constant  A_NOP      	  : std_logic_vector(12 downto 0) := B"0000000000000";
	constant  A_ALL_BANK 	  : std_logic_vector(12 downto 0) := B"0010000000000"; -- A(10) HIGH
	constant  A_MODE   		  : std_logic_vector(12 downto 0) := B"0000000100000"; -- Burst Mode NOT Activated 
	--constant  A_MODE   		  : std_logic_vector(12 downto 0) := B"0000000100111"; -- Burst Mode Activated 
	
	 
END PACKAGE SDRAM_package;
