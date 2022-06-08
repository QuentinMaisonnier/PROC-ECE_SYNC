-- Projet de fin d'études : RISC-V
-- ECE Paris / SECAPEM
-- DMin Memory VHDL

-- LIBRARIES
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- ENTITY
entity DataMemory is
	port (
		-- INPUTS
		DMclock		: in std_logic;
		--DMreset		: in std_logic;
		DMstore		: in std_logic;
		DMload		: in std_logic;
		DMaddr		: in std_logic_vector(31 downto 0);
		DMin			: in std_logic_vector(31 downto 0);
		DMfunct3		: in std_logic_vector(2 downto 0);
		-- OUTPUTS
		DMout			: out std_logic_vector(31 downto 0)
	);
end entity;

architecture archi of DataMemory is
	
	
	--signal cs	: std_logic;
	SIGNAL addr : natural;
	SIGNAL selectRAM : std_logic_vector(1 downto 0);
	SIGNAL enWRAM : std_logic_vector(3 downto 0);
	SIGNAL RAMDATAout : std_logic_vector( 31 downto 0);
	
	-- Build a 2-D array type for the RAM
	
	component ram is 
	generic (
		DATA_WIDTH : natural := 8;
		ADDR_WIDTH : natural := 10
		);
	port (
		clk		: in std_logic;
		addr	: in natural range 0 to 2**ADDR_WIDTH - 1;
		data	: in std_logic_vector((DATA_WIDTH-1) downto 0);
		we		: in std_logic := '1';
		q		: out std_logic_vector((DATA_WIDTH -1) downto 0)
		);
	end component;

begin

	--enable writing ram
	enWRAM <= "0001" when DMfunct3 = "000" AND DMstore='1' else
				"0011" when DMfunct3 = "001" AND DMstore='1' else
				(others=>'1') when DMfunct3 = "010" AND DMstore='1' else
				(others=>'0');
				
	addr <= to_integer(unsigned(DMaddr(11 downto 2)));
				
	DMout <= RAMDATAout(31 downto 0) when DMload='1';
	
--	DMout <= RAMDATAout(7) & RAMDATAout(7) & RAMDATAout(7) & RAMDATAout(7) & RAMDATAout(7) & RAMDATAout(7) & RAMDATAout(7) & RAMDATAout(7) & RAMDATAout(7) & RAMDATAout(7) & RAMDATAout(7) & RAMDATAout(7) & RAMDATAout(7) & RAMDATAout(7) & RAMDATAout(7) & RAMDATAout(7) & RAMDATAout(7) & RAMDATAout(7) & RAMDATAout(7) & RAMDATAout(7) & RAMDATAout(7) & RAMDATAout(7) & RAMDATAout(7) & RAMDATAout(7) & RAMDATAout(7 downto 0) when DMload='1' and DMfunct3 = "000" else
--				RAMDATAout(7) & RAMDATAout(7) & RAMDATAout(7) & RAMDATAout(7) & RAMDATAout(7) & RAMDATAout(7) & RAMDATAout(7) & RAMDATAout(7) & RAMDATAout(7) & RAMDATAout(7) & RAMDATAout(7) & RAMDATAout(7) & RAMDATAout(7) & RAMDATAout(7) & RAMDATAout(7) & RAMDATAout(7) & RAMDATAout(15 downto 0) when DMload='1' and DMfunct3 = "001" else
--				RAMDATAout(31 downto 0) when DMload='1' and DMfunct3 = "010" else
--				x"000000" & RAMDATAout(7 downto 0) when DMload='1' and DMfunct3 = "100" else
--				x"0000" & RAMDATAout(15 downto 0) when DMload='1' and DMfunct3 = "101" else
--				(others=>'0');
--				 & RAMDATAout(7 downto 0) when DMload='1' and DMfunct3 = "100" else
--				std_logic_vector( & RAMDATAout(15 downto 0) when DMload='1' and DMfunct3 = "101" else--- 
				
	
	--cs <= not DMaddr(31);
	
	ram7_0 : ram port map(
		clk	=> DMclock,
		addr	=> addr,
		data	=> DMin(7 downto 0),
		we		=> enWRAM(0),--DMstore,
		q		=> RAMDATAout(7 downto 0)
	);
	
	ram15_8 : ram port map(
		clk	=> DMclock,
		addr	=>addr,
		data	=> DMin(15 downto 8),
		we		=> enWRAM(1),--DMstore,
		q		=> RAMDATAout(15 downto 8)
	);
	
	ram23_16 : ram port map(
		clk	=> DMclock,
		addr	=> addr,
		data	=> DMin(23 downto 16),
		we		=> enWRAM(2),--DMstore,
		q		=> RAMDATAout(23 downto 16)
	);
	
	ram31_24 : ram port map(
		clk	=> DMclock,
		addr	=> addr,
		data	=> DMin(31 downto 24),
		we		=> enWRAM(3),--DMstore,
		q		=> RAMDATAout(31 downto 24)
	);
	
end archi;
-- END FILE