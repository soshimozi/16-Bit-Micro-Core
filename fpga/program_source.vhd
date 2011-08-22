library IEEE;
use IEEE.STD_LOGIC_1164.all;
use work.definitions.all;

package program_text is
  constant program : IMem_array := (
    others => X"00000000");
end package program_text;