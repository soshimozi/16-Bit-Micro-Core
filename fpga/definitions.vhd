--	Package File Template
--
--	Purpose: This package defines supplemental types, subtypes, 
--		 constants, and functions 


library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.ALL;

package definitions is

	constant IMem_addr_width : positive := 16;
	constant IMem_size : positive := 2**IMem_addr_width;
	subtype IMem_addr is unsigned(IMem_addr_width-1 downto 0);
	
	subtype instruction is unsigned(31 downto 0);
	type instruction_array is array (natural range <>) of instruction;
	
	subtype IMem_array is instruction_array(0 to IMem_size - 1);
	
	constant DMem_size : positive := 16384;
	subtype unsigned_word is unsigned(15 downto 0);
	type unsigned_word_array is
		array(natural range <>) of unsigned_word;
		
	--subtype unsigned_byte is unsigned(7 downto 0);
	--type unsigned_byte_array is
	--	array(natural range <>) of unsigned_byte;
	subtype DMem_array is unsigned_word_array(0 to DMem_size - 1);
	
	subtype opcode is std_logic_vector(4 downto 0);
	subtype reg is std_logic_vector(7 downto 0);
	subtype disp is std_logic_vector(15 downto 0);
	subtype addr is std_logic_vector(15 downto 0);
	
	-- instruction --
	--   00000         X          0000    0000   0000
	-- [ opcode ] [ dont care ]  [ RA ]  [ RB ] [ RD ]
	
-- Declare constants
	constant opc_mov : opcode := "00000";  	-- direct mov:  mov RD, #34 (RA:RB)
	constant opc_ldm : opcode := "00001"; 	-- memory read ldm r2, r3, r5 (loads r5 with location pointed to by r2:r3
	constant opc_stm : opcode := "00011"; 	-- memory store: stm r2, #345 MEM[[RD]], RA:RB
	constant opc_add : opcode := "00110";
	constant opc_adc : opcode := "00111";
	constant opc_sub : opcode := "01000";
	constant opc_sbb : opcode := "01001";
	constant opc_and : opcode := "01010";
	constant opc_or : opcode := "01011";
	constant opc_xor : opcode := "01100";
	constant opc_shl : opcode := "01101";		-- shl r1, r2, #5  (shifts left value in r2 5 times and stores result in r1)
	constant opc_shr : opcode := "01110";
	constant opc_branz : opcode := "10000";	-- branch if zero flag set
	constant opc_brab : opcode := "10001"; 	-- branch if carry flag set
	constant opc_jmp : opcode := "10010"; 		-- jump to address
	constant opc_jsb : opcode := "10011"; 		-- call subroutine
	constant opc_ret : opcode := "11000";		-- return from subroutine (ops return address off stack)
	constant opc_halt  : opcode := "11111";

end definitions;


package body definitions is
end definitions;
