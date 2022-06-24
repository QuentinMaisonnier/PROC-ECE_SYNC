-- Projet de fin d'études : RISC-V
-- ECE Paris / SECAPEM
-- Register File VHDL

-- LIBRARIES
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.simulPkg.all;

-- ENTITY
entity RegisterFile is
    port (
        -- INPUTS
		  hold		: in std_logic;
        RFclock	: in std_logic;
        RFreset	: in std_logic;
        RFin		: in std_logic_vector(31 downto 0);
        RFrd		: in std_logic_vector(4 downto 0);
        RFrs1		: in std_logic_vector(4 downto 0);
        RFrs2		: in std_logic_vector(4 downto 0);
        -- OUTPUTS
        RFout1		: out std_logic_vector(31 downto 0);
        RFout2		: out std_logic_vector(31 downto 0)
    );
end entity;

-- ARCHITECTURE
architecture archi of RegisterFile is

	 TYPE regfile IS ARRAY (0 TO 31) OF STD_LOGIC_vector(31 downto 0);
	 signal RFreg, RFMux : regfile;

begin
	--BEGIN
	-- output 1
	RFout1 	<= RFreg(0) WHEN RFrs1 = "00000" else 
               RFreg(1) WHEN RFrs1 = "00001" else 
               RFreg(2) WHEN RFrs1 = "00010" else 
               RFreg(3) WHEN RFrs1 = "00011" else 
               RFreg(4) WHEN RFrs1 = "00100" else 
               RFreg(5) WHEN RFrs1 = "00101" else 
               RFreg(6) WHEN RFrs1 = "00110" else 
               RFreg(7) WHEN RFrs1 = "00111" else 
               RFreg(8) WHEN RFrs1 = "01000" else 
               RFreg(9) WHEN RFrs1 = "01001" else 
               RFreg(10) WHEN RFrs1 = "01010" else 
               RFreg(11) WHEN RFrs1 = "01011" else 
               RFreg(12) WHEN RFrs1 = "01100" else 
               RFreg(13) WHEN RFrs1 = "01101" else 
               RFreg(14) WHEN RFrs1 = "01110" else 
               RFreg(15) WHEN RFrs1 = "01111" else 
               RFreg(16) WHEN RFrs1 = "10000" else 
               RFreg(17) WHEN RFrs1 = "10001" else 
               RFreg(18) WHEN RFrs1 = "10010" else 
               RFreg(19) WHEN RFrs1 = "10011" else 
               RFreg(20) WHEN RFrs1 = "10100" else 
               RFreg(21) WHEN RFrs1 = "10101" else 
               RFreg(22) WHEN RFrs1 = "10110" else 
               RFreg(23) WHEN RFrs1 = "10111" else 
               RFreg(24) WHEN RFrs1 = "11000" else 
               RFreg(25) WHEN RFrs1 = "11001" else 
               RFreg(26) WHEN RFrs1 = "11010" else 
               RFreg(27) WHEN RFrs1 = "11011" else 
               RFreg(28) WHEN RFrs1 = "11100" else 
               RFreg(29) WHEN RFrs1 = "11101" else 
               RFreg(30) WHEN RFrs1 = "11110" else 
               RFreg(31) WHEN RFrs1 = "11111" else 
               (others => '0');
	-- output 1
	RFout2 	<= RFreg(0) WHEN RFrs2 = "00000" else 
               RFreg(1) WHEN RFrs2 = "00001" else 
               RFreg(2) WHEN RFrs2 = "00010" else 
               RFreg(3) WHEN RFrs2 = "00011" else 
               RFreg(4) WHEN RFrs2 = "00100" else 
               RFreg(5) WHEN RFrs2 = "00101" else 
               RFreg(6) WHEN RFrs2 = "00110" else 
               RFreg(7) WHEN RFrs2 = "00111" else 
               RFreg(8) WHEN RFrs2 = "01000" else 
               RFreg(9) WHEN RFrs2 = "01001" else 
               RFreg(10) WHEN RFrs2 = "01010" else 
               RFreg(11) WHEN RFrs2 = "01011" else 
               RFreg(12) WHEN RFrs2 = "01100" else 
               RFreg(13) WHEN RFrs2 = "01101" else 
               RFreg(14) WHEN RFrs2 = "01110" else 
               RFreg(15) WHEN RFrs2 = "01111" else 
               RFreg(16) WHEN RFrs2 = "10000" else 
               RFreg(17) WHEN RFrs2 = "10001" else 
               RFreg(18) WHEN RFrs2 = "10010" else 
               RFreg(19) WHEN RFrs2 = "10011" else 
               RFreg(20) WHEN RFrs2 = "10100" else 
               RFreg(21) WHEN RFrs2 = "10101" else 
               RFreg(22) WHEN RFrs2 = "10110" else 
               RFreg(23) WHEN RFrs2 = "10111" else 
               RFreg(24) WHEN RFrs2 = "11000" else 
               RFreg(25) WHEN RFrs2 = "11001" else 
               RFreg(26) WHEN RFrs2 = "11010" else 
               RFreg(27) WHEN RFrs2 = "11011" else 
               RFreg(28) WHEN RFrs2 = "11100" else 
               RFreg(29) WHEN RFrs2 = "11101" else 
               RFreg(30) WHEN RFrs2 = "11110" else 
               RFreg(31) WHEN RFrs2 = "11111" else 
               (others => '0');
	-- registers update on clock event and with rd
	
	RFreg(0)	<= (others => '0');

	gen:
	for i in 1 to 31 generate
		RFMux(i) <= RFin when to_integer(unsigned(RFrd))=i AND hold='0' else RFreg(i);
		RFreg(i)	<= (others => '0') WHEN (RFreset = '1')
						else RFMux(i) WHEN rising_edge(RFclock);
	end generate gen;


    PKG_reg00	<= RFreg(0);
    PKG_reg01	<= RFreg(1);
    PKG_reg02	<= RFreg(2);
    PKG_reg03	<= RFreg(3);
    PKG_reg04	<= RFreg(4);
    PKG_reg05	<= RFreg(5);
    PKG_reg06	<= RFreg(6);
    PKG_reg07	<= RFreg(7);
    PKG_reg08	<= RFreg(8);
    PKG_reg09	<= RFreg(9);
    PKG_reg0A	<= RFreg(10);
    PKG_reg0B	<= RFreg(11);
    PKG_reg0C	<= RFreg(12);
    PKG_reg0D	<= RFreg(13);
    PKG_reg0E	<= RFreg(14);
    PKG_reg0F	<= RFreg(15);
    PKG_reg10	<= RFreg(16);
    PKG_reg11	<= RFreg(17);
    PKG_reg12	<= RFreg(18);
    PKG_reg13	<= RFreg(19);
    PKG_reg14	<= RFreg(20);
    PKG_reg15	<= RFreg(21);
    PKG_reg16	<= RFreg(22);
    PKG_reg17	<= RFreg(23);
    PKG_reg18	<= RFreg(24);
    PKG_reg19	<= RFreg(25);
    PKG_reg1A	<= RFreg(26);
    PKG_reg1B	<= RFreg(27);
    PKG_reg1C	<= RFreg(28);
    PKG_reg1D	<= RFreg(29);
    PKG_reg1E	<= RFreg(30);
    PKG_reg1F	<= RFreg(31);
	-- END
end archi;
-- END FILE