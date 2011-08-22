----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    17:14:23 08/09/2011 
-- Design Name: 
-- Module Name:    ycpu_with_memory - Behavioral 
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

entity ycpu_with_memory is
  generic ( IMem_file_name : string := "gasm_text.dat";
				DMem_file_name : string := "gasm_data.dat"  );
  Port ( clk_i : in  STD_LOGIC;
           rst_i : in  STD_LOGIC);
end ycpu_with_memory;

architecture struct of ycpu_with_memory is

	-- Instruction memory bus
	signal inst_cyc_o : std_logic;
	signal inst_stb_o : std_logic;
	signal inst_ack_i : std_logic;
	signal inst_adr_o : unsigned(15 downto 0);
	signal inst_dat_i : std_logic_vector(31 downto 0);
	
	-- Data memory bus
	signal data_cyc_o : std_logic;
	signal data_stb_o : std_logic;
	signal data_we_o : std_logic; 
	signal data_ack_i : std_logic;
	signal data_adr_o : unsigned(15 downto 0);
	signal data_dat_o : std_logic_vector(15 downto 0);
	signal data_dat_i : std_logic_vector(15 downto 0);
	
	
  component ycpu is
    port ( clk_i : in std_logic;
           rst_i : in std_logic;
           -- Instruction memory bus
           inst_cyc_o : out std_logic;
           inst_stb_o : out std_logic;
           inst_ack_i : in std_logic;
           inst_adr_o : out unsigned(15 downto 0);
           inst_dat_i : in std_logic_vector(31 downto 0);
			  -- Data memory bus
			  data_cyc_o : out std_logic;
			  data_stb_o : out std_logic;
			  data_we_o : out std_logic;
			  data_ack_i : in std_logic;
			  data_adr_o : out unsigned(15 downto 0);
			  data_dat_o : out std_logic_vector(15 downto 0);
			  data_dat_i : in std_logic_vector(15 downto 0));
  end component ycpu;

  component inst_mem is
    generic ( IMem_file_name : string );
    port ( clk_i : in std_logic;
           cyc_i : in std_logic;
           stb_i : in std_logic;
           ack_o : out std_logic;
           adr_i : in unsigned(15 downto 0);
           dat_o : out std_logic_vector(31 downto 0) );
  end component inst_mem;
  
	component data_mem is
		generic ( DMem_file_name : string );
		port ( clk_i : in std_logic;
         cyc_i : in std_logic;
         stb_i : in std_logic;
         we_i : in std_logic;
         ack_o : out std_logic;
         adr_i : in unsigned(15 downto 0);
         dat_i : in std_logic_vector(15 downto 0);
         dat_o : out std_logic_vector(15 downto 0) );
	end component data_mem;  

begin

  core : component ycpu
    port map ( clk_i      => clk_i,
               rst_i      => rst_i,
               inst_cyc_o => inst_cyc_o,
               inst_stb_o => inst_stb_o,
               inst_ack_i => inst_ack_i,
               inst_adr_o => inst_adr_o,
               inst_dat_i => inst_dat_i,
					data_cyc_o => data_cyc_o,
               data_stb_o => data_stb_o,
               data_we_o  => data_we_o,
               data_ack_i => data_ack_i,
               data_adr_o => data_adr_o,
               data_dat_o => data_dat_o,
               data_dat_i => data_dat_i);

	core_data_mem : component data_mem
		generic map ( DMem_file_name => DMem_file_name )
		port map ( clk_i => clk_i,
					  cyc_i => data_cyc_o,
					  stb_i => data_stb_o,
					  we_i => data_we_o,
					  ack_o => data_ack_i,
					  adr_i => data_adr_o,
					  dat_i => data_dat_o,
					  dat_o => data_dat_i );

   core_inst_mem : component inst_mem
    generic map ( IMem_file_name => IMem_file_name )
    port map ( clk_i => clk_i,
               cyc_i => inst_cyc_o,
               stb_i => inst_stb_o,
               ack_o => inst_ack_i,
               adr_i => inst_adr_o,
               dat_o => inst_dat_i);
end struct;

