-- Projet de fin d'études : RISC-V
-- ECE Paris / SECAPEM
-- Counter VHDL

-- LIBRARIES
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- ENTITY
entity Counter is
	port (
		CPTclock	: in std_logic;
		CPTreset	: in std_logic;
		CPTwrite :  in std_logic;
		CPTaddr  : in std_logic_vector(31 downto 0);
		CPTinput : in std_logic_vector(31 downto 0);

		CPTcounter	: out std_logic_vector(31 downto 0)
	);
end entity;

-- ARCHITECTURE
architecture archi of Counter is
	signal combCpt, regCpt : std_logic_vector(31 downto 0);
begin
	
	combCpt <= CPTinput when (CPTwrite = '1' and CPTaddr(31)='1' and CPTaddr(7 downto 0)=x"00") else std_logic_vector(unsigned(regCpt)+1);
	regCpt <= (others => '0') when CPTreset='1' else
					combCpt when rising_edge(CPTclock);
		
	CPTcounter <= regCpt;
						
	-- END
end archi;
-- END FILE