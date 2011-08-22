-- TestBench Template 

  LIBRARY ieee;
  USE ieee.std_logic_1164.ALL;
  USE ieee.numeric_std.ALL;
  use work.definitions.all;

  ENTITY testbench IS
  END testbench;

  ARCHITECTURE behavior OF testbench IS 

  signal syscon_clk_o : std_logic;
  signal syscon_rst_o : std_logic;

  component ycpu_with_memory is
    port ( clk_i : in std_logic;
           rst_i : in std_logic);
  end component ycpu_with_memory;
         

  BEGIN

  reset_gen : syscon_rst_o <= '0',
                              '1' after   5 ns,
                              '0' after  25 ns;

  clk_gen : process
  begin
    syscon_clk_o <= '0';
    wait for 10 ns;
    loop
      syscon_clk_o <= '1', '0' after 5 ns;
      wait for 10 ns;
    end loop;
  end process clk_gen;

  dut : component ycpu_with_memory
    port map ( clk_i      => syscon_clk_o,
               rst_i      => syscon_rst_o);


  END;
