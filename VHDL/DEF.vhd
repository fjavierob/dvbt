--
--	Package File Template
--
--	Purpose: This package defines supplemental types, subtypes, 
--		 constants, and functions 
--
--   To use any of the example code shown below, uncomment the lines and modify as necessary
--

library IEEE;
use IEEE.STD_LOGIC_1164.all;

package DEF is

	type complex10 is record
		re : std_logic_vector(9 downto 0);
		im : std_logic_vector(9 downto 0);
	end record;
	
	type complex15 is record
		re : std_logic_vector(14 downto 0);
		im : std_logic_vector(14 downto 0);
	end record;

end DEF;