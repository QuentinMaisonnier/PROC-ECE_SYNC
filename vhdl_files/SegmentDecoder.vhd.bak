library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity SegmentDecoder is 
    Port (
      Sin7seg  : in  STD_LOGIC_VECTOR(3 downto 0);
		decodeOut : out  STD_LOGIC_VECTOR(7 downto 0));
end SegmentDecoder;

architecture vhdl of SegmentDecoder is 
begin

decodeOut <= "11000000" when Sin7seg="0000" else
             "11111001" when Sin7seg="0001" else
             "10100100" when Sin7seg="0010" else
             "10110000" when Sin7seg="0011" else
             "10011001" when Sin7seg="0100" else
             "10010010" when Sin7seg="0101" else
             "10000010" when Sin7seg="0110" else
             "11111000" when Sin7seg="0111" else
             "10000000" when Sin7seg="1000" else
             "10010000" when Sin7seg="1001" else
             "10001000" when Sin7seg="1010" else
             "10000011" when Sin7seg="1011" else
             "11000110" when Sin7seg="1100" else
             "10100001" when Sin7seg="1101" else
             "10000110" when Sin7seg="1110" else
             "10001110" when Sin7seg="1111";

end vhdl;