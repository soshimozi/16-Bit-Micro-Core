----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    14:31:45 08/09/2011 
-- Design Name: 
-- Module Name:    inst_mem - Behavioral 
-- Project Name: 
-- Target Devices: 
-- Tool versions: 
-- Description: 
--
-- Dependencies: 
--
-- Revision: 
-- Revision 0.01 - File Created
-- Additional Comments: 
--
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use std.textio.all, ieee.std_logic_textio.all;

use work.definitions.all;

entity inst_mem is
	 generic ( IMem_file_name : string := "gasm_text.dat" );
    Port ( clk_i : in  STD_LOGIC;
           cyc_i : in  STD_LOGIC;
           stb_i : in  STD_LOGIC;
           ack_o : out  STD_LOGIC;
           adr_i : in  unsigned (15 downto 0);
           dat_o : out  STD_LOGIC_VECTOR (31 downto 0));
end inst_mem;

architecture rtl of inst_mem is
 
constant IMem : IMem_array := work.program_text.program;
 
begin

  dat_o <= std_logic_vector(IMem(to_integer(adr_i)));

  ack_o <= cyc_i and stb_i;
  
end rtl;

architecture xst of inst_mem is

  impure function load_IMem (IMem_file_name : in string)
                            return IMem_array is
    file IMem_file : text is in IMem_file_name;
    variable L : line;
    variable instr : std_logic_vector(instruction'range);
    variable IMem : IMem_array;
  begin
    for i in IMem_array'range loop
      readline(IMem_file, L);
      read(L, instr);
      IMem(i) := unsigned(instr);
    end loop;
    return IMem;
  end function;

  constant IMem : IMem_array := load_IMem(IMem_file_name);

begin

  dat_o <= std_logic_vector(IMem(to_integer(adr_i)));

  ack_o <= cyc_i and stb_i;

end architecture xst;

