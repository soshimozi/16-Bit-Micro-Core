--	Package File Template
--
--	Purpose: This package defines supplemental types, subtypes, 
--		 constants, and functions 


library IEEE;
use IEEE.STD_LOGIC_1164.all;
use work.definitions.all;

package program_data is
  constant data : DMem_array := (
    0 => X"0000",
    others => X"0000" );
end package program_data;
