----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    09:06:53 08/09/2011 
-- Design Name: 
-- Module Name:    ycpu - Behavioral 
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
use work.definitions.all;

entity ycpu is
    Port ( clk_i : in  STD_LOGIC;
           rst_i : in  STD_LOGIC;
           -- Instruction memory bus
           inst_cyc_o : out std_logic;
           inst_stb_o : out std_logic;
           inst_ack_i : in std_logic;
           inst_adr_o : out unsigned(15 downto 0);
           inst_dat_i : in STD_LOGIC_VECTOR(31 downto 0);
			  -- Data memory bus
           data_cyc_o : out  std_logic;
           data_stb_o : out  std_logic;
           data_we_o : out  std_logic;
			  data_ack_i : in std_logic;
           data_adr_o : out  unsigned (15 downto 0);
           data_dat_o : out  std_logic_vector (15 downto 0);
           data_dat_i : in  std_logic_vector (15 downto 0)		  
         );
end ycpu;

architecture rtl_unpipelined of ycpu is

-- selected register values, corresponds to RA, RB, and RD selection in corrent opcode
signal RA : std_logic_vector(15 downto 0);
signal RB : std_logic_vector(15 downto 0);
signal RD : std_logic_vector(15 downto 0);

-- program counter
signal PC : unsigned(15 downto 0); 					

-- instruction data
signal IR : std_logic_vector(31 downto 0); 		

-- accumulator, working register
signal W : std_logic_vector(15 downto 0); 			

-- temp data bus
signal data_D : unsigned(15 downto 0);

-- control flags
signal data_state : std_logic;
signal branch_taken : std_logic;
signal decode_jump : std_logic;

-- temp ALU registers
signal ALU_result : std_logic_vector(15 downto 0);
signal ALU_Z : std_logic;
signal ALU_C : std_logic;

-- carry and zero flags
signal cc_Z : std_logic;
signal cc_C : std_logic;
  
constant SP_length : positive := 8;
signal SP : unsigned(SP_length - 1 downto 0);
signal stack_top : IMem_addr;
  
alias IR_opcode : opcode is IR(31 downto 27);	-- current instruction opcode
alias IR_RA : reg is IR(23 downto 16);
alias IR_RB : reg is IR(15 downto 8);
alias IR_RD : reg is IR(7 downto 0);
alias IR_disp : disp is IR(31 downto 16);
alias IR_addr : addr is IR(15 downto 0);

-- the control states of the cpu
type control_state is ( fetch_state, 
								decode_state, 
								execute_state, 
								mem_state,
								write_back_state);
								
signal current_state, next_state : control_state;

begin

Control : process(current_state, IR_opcode, inst_ack_i, data_ack_i)
begin
	case current_state is
		when fetch_state =>
			if inst_ack_i = '0' then
			
				next_state <= fetch_state;
				
			else
			
				next_state <= decode_state;
				
			end if;
		when decode_state =>
			if IR_opcode /= opc_halt then
			
				next_state <= execute_state;
				
			else
			
				next_state <= decode_state;
				
			end if;
		when execute_state =>
			if IR_opcode = opc_mov or 
				IR_opcode = opc_sub or 
				IR_opcode = opc_sbb or 
				IR_opcode = opc_add or 
				IR_opcode = opc_adc or 
				IR_opcode = opc_and or 
				IR_opcode = opc_or or 
				IR_opcode = opc_xor or
				IR_opcode = opc_shl or
				IR_opcode = opc_shr then
			
				next_state <= write_back_state;
				
			elsif IR_opcode = opc_stm or 
					IR_opcode = opc_ldm then
					
				next_state <= mem_state;
				
			else
			
				next_state <= fetch_state;
				
			end if;
		when mem_state =>
        if (IR_opcode = opc_ldm or 
				IR_opcode = opc_stm) and data_ack_i = '0' then
				
				next_state <= mem_state;
				
			elsif IR_opcode = opc_ldm then
			
				next_state <= write_back_state;
				
			else
			
				next_state <= fetch_state;
				
			end if;
		when write_back_state =>
			next_state <= fetch_state;
			
	end case;
end process Control;

State : process(clk_i, rst_i)
begin
	if rst_i = '1' then
		current_state <= fetch_state;
	elsif rising_edge(clk_i) then
		current_state <= next_state;
	end if;
end process State;

with IR_opcode select
    branch_taken <=  not cc_Z when opc_branz,
							cc_C when opc_brab,
                    'X'      when others;
						  
with IR_opcode select
	decode_jump <= '1' when opc_jmp,
						'1' when opc_jsb,
						'X' when others;
						  
PC_reg : process(clk_i, rst_i)
begin
	if rst_i = '1' then
		PC <= (others => '0');
	elsif rising_edge(clk_i) then
		if current_state = fetch_state and inst_ack_i = '1' then
			PC <= PC + 1;
		elsif current_state = decode_state then
			if branch_taken = '1' then
				PC <= unsigned(signed(PC) + signed(IR_disp));
			elsif decode_jump = '1' then
				PC <= unsigned(IR_addr);
			elsif IR_opcode = opc_ret then
				PC <= stack_top;				
			end if;
		end if;
	end if;
end process PC_reg;

inst_cyc_o <= '1' when current_state = fetch_state else '0';
inst_stb_o <= '1' when current_state = fetch_state else '0';
inst_adr_o <= PC;
  
Instruction_reg : process (clk_i)
begin
	if rising_edge(clk_i) then
		if current_state = fetch_state and inst_ack_i = '1' then
			IR <= inst_dat_i;
		end if;
	end if;
end process Instruction_reg;

stack_mem : process (clk_i, rst_i)
 constant stack_depth : positive := 2**SP_length;
 subtype stack_index is natural range 0 to stack_depth - 1;
 type stack_array is array (stack_index) of IMem_addr;
 variable stack : stack_array;
begin
 if rst_i = '1' then
	SP <= (others => '0');
 elsif rising_edge(clk_i) then
	if current_state = decode_state then
	  if IR_opcode = opc_jsb then
		 stack(to_integer(SP)) := PC;
		 SP <= SP + 1;
	  elsif IR_opcode = opc_ret then
		 SP <= SP - 1;
	  end if;
	end if;
	stack_top <= stack(to_integer(SP - 1));
 end if;
end process stack_mem;
	
RegisterFile : process (clk_i, rst_i)

	 type rf_type is array (0 to 255) of 
        std_logic_vector(15 downto 0);
    variable write_data : std_logic_vector(15 downto 0);
    variable RegFile : rf_type := (others => X"0000");
 begin
    if rst_i = '1' then
      RegFile := (others => (others => '0'));
    elsif rising_edge(clk_i) then
		
		-- store the ALU working register into the destination register
		if current_state = write_back_state then
		
			if IR_opcode = opc_ldm then
				write_data := std_logic_vector(data_D); -- load data read from memory
			else
				write_data := W;
			end if;
			
			RegFile(to_integer(unsigned(IR_RD))) := write_data;
		end if;
		
      if current_state = decode_state then
        RA <= std_logic_vector(RegFile(to_integer(unsigned(IR_RA))));
        RB <= std_logic_vector(RegFile(to_integer(unsigned(IR_RB))));
		  RD <= std_logic_vector(RegFile(to_integer(unsigned(IR_RD))));
      end if;
    end if;
 end process RegisterFile;
 
 ALU : process(RA, RB, RD, IR_opcode, IR, cc_C)
	variable tmp_result : unsigned(unsigned_word'length downto 0);
 begin
	case IR_opcode is
		when opc_branz =>
			tmp_result := '0' & unsigned(RA);
		when opc_brab =>
			tmp_result := '0' & unsigned(RA);
		when opc_mov =>
			tmp_result := '0' & unsigned(IR_RA) & unsigned(IR_RB);
		when opc_stm =>
			tmp_result := '0' & unsigned(RA);
		when opc_ldm =>
			tmp_result :=  '0' & unsigned(RA);
		when opc_adc =>
			tmp_result := ('0' & unsigned(RA)) + ('0' & unsigned(RB))
                                       + unsigned'(0 => cc_C);
		when opc_add =>
			tmp_result := ('0' & unsigned(RA)) + ('0' & unsigned(RB));
		when opc_sub =>
			tmp_result := ('0' & unsigned(RA)) - ('0' & unsigned(RB));
		when opc_sbb =>
			tmp_result := ('0' & unsigned(RA)) - ('0' & unsigned(RB))
                                       - unsigned'(0 => cc_C);
		when opc_or =>
			tmp_result := ('0' & unsigned(RA)) or ('0' & unsigned(RB));
		when opc_xor =>
			tmp_result := ('0' & unsigned(RA)) xor ('0' & unsigned(RB));
		when opc_shl =>
			tmp_result := ('0' & unsigned(RA)) sll to_integer(unsigned(IR_RB));
		when opc_shr =>
			tmp_result := ('0' & unsigned(RA)) srl to_integer(unsigned(IR_RB));
		when others =>
			tmp_result := '0' & X"0000";
	end case;

	ALU_result <= std_logic_vector(tmp_result(unsigned_word'length -1 downto 0));
	ALU_C <= tmp_result(unsigned_word'length);
	
 end process ALU;

ALU_Z <= '1' when unsigned(ALU_result) = 0 else
           '0'; 
			  
W_reg : process (clk_i)
 begin
    if rising_edge(clk_i) then
      if current_state = execute_state then
        W <= ALU_result;
      end if;
    end if;
 end process W_reg;

cc_reg : process (clk_i, rst_i)
begin
 if rst_i = '1' then
	cc_Z <= '0';
	cc_C <= '0';
 elsif rising_edge(clk_i) then
	if current_state = execute_state then
	  cc_Z <= ALU_Z;
	  cc_C <= ALU_C;
	end if;
 end if;
end process cc_reg;

data_state <= '1' when (current_state = execute_state or current_state = mem_state)
							 and (IR_opcode = opc_ldm or IR_opcode = opc_stm) else '0';

data_cyc_o <= '1' when data_state = '1' else '0';
data_stb_o <= '1' when data_state = '1' else '0';
data_we_o  <= '1' when data_state = '1' and (IR_opcode = opc_stm) else '0';

data_adr_o <= unsigned(ALU_result);
data_dat_o <= RD;

data_reg : process (clk_i)
begin
 if rising_edge(clk_i) then
	if data_state = '1' and (IR_opcode = opc_ldm) and data_ack_i = '1' then
	  data_D <= unsigned(data_dat_i);
	end if;
 end if;
end process data_reg;
  
end rtl_unpipelined;

