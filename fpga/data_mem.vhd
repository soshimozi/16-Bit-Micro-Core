----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    21:48:30 08/09/2011 
-- Design Name: 
-- Module Name:    data_mem - Behavioral 
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

entity data_mem is
	 generic ( DMem_file_name : string := "gasm_data.dat" );
    Port ( clk_i : in  STD_LOGIC;
           cyc_i : in  STD_LOGIC;
           stb_i : in  STD_LOGIC;
           we_i : in  STD_LOGIC;
           ack_o : out  STD_LOGIC;
           adr_i : in  unsigned (15 downto 0);
           dat_i : in  STD_LOGIC_VECTOR (15 downto 0);
           dat_o : out  STD_LOGIC_VECTOR (15 downto 0));
end data_mem;

architecture rtl of data_mem is

  signal DMem : DMem_array := work.program_data.data;
  signal read_ack : std_logic;

begin

  data_mem : process (clk_i) is
  begin
    if rising_edge(clk_i) then
      if to_X01(cyc_i) = '1' and to_X01(stb_i) = '1' then
        if to_X01(we_i) = '1' then
          DMem(to_integer(adr_i)) <= unsigned(dat_i);
          dat_o <= dat_i;
          read_ack <= '0';
        else
          dat_o <= std_logic_vector(DMem(to_integer(adr_i)));
          read_ack <= '1';
        end if;
      else
        read_ack <= '0';
      end if;
    end if;
  end process data_mem;

  ack_o <= cyc_i and stb_i and (we_i or read_ack);

end architecture rtl;

architecture xst of data_mem is

  impure function load_DMem (DMem_file_name : in string := "gasm_data.dat")
                            return DMem_array is
    file DMem_file : text is in DMem_file_name;
    variable L : line;
    variable data : std_logic_vector(unsigned_word'range);
    variable DMem : DMem_array;
  begin
    for i in DMem_array'range loop
      readline(DMem_file, L);
      read(L, data);
      DMem(i) := unsigned(data);
    end loop;
    return DMem;
  end function;

  signal DMem : DMem_array := load_DMem(DMem_file_name);
  signal read_ack : std_logic;

begin

  data_mem : process (clk_i) is
  begin
    if rising_edge(clk_i) then
      if to_X01(cyc_i) = '1' and to_X01(stb_i) = '1' then
        if to_X01(we_i) = '1' then
          DMem(to_integer(adr_i)) <= unsigned(dat_i);
          dat_o <= dat_i;
          read_ack <= '0';
        else
          dat_o <= std_logic_vector(DMem(to_integer(adr_i)));
          read_ack <= '1';
        end if;
      else
        read_ack <= '0';
      end if;
    end if;
  end process data_mem;

  ack_o <= cyc_i and stb_i and (we_i or read_ack);

end architecture xst;