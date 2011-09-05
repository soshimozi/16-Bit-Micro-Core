/* parser.y - parser for YourFirstCPU assembler */
%{
#define YYSTYPE long	/* yyparse() stack type */
#include <malloc.h>
#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <math.h>

#include "assembler.h"
#include "sys.h"

/* global variables
*/

/* our system info struct holds the parameters of our cpu */
cpu_sysinfo sys = {
	DEF_IMEM,
	DEF_IMEM_WIDTH,
	DEF_REGFILE,
	DEF_OPCODE_WIDTH,
	DEF_REG_ADDR_WIDTH,
	DEF_DMEM,
	DEF_IBASE,
	DEF_DBASE
};


/* unresolved table holds the unresolved references */
forward_declarations unresolved;

/* the symbol table holds the identifiers found in teh source file and their value */
cpu_symbols symbol_table;

/* strings are passed from the scanner to the parser in this string table */
cpu_strings string_table;

/* flag that we are using data memory, this is set by the .data directive */
bool using_data = false;

bool error_flag = false;

/* our assember instruction memory */
unsigned long* lpimem = NULL;

/* our assembler data memory */
unsigned char* lpdmem = NULL;

/* holds the highest code address */
unsigned long codesize = 0;

/* holds the highest data address */
unsigned long datasize = 0;

bool verbose = false;

bool emit_code = false;

#define YYERROR_VERBOSE 1
/*
#define YYDEBUG 1
*/

%}

/* standard tokens */
%token NEWLINE COMMA COLON REG IDENTIFIER INTEGER STRING FLOAT END

/* assembler directives */
%token sIMEM sREGFILE sBASE sREGISTER sDEFINE sDMEM sDATA sOPCODE

/* cpu mnemonic tokens */
%token MOV ADC ADD SUB SBB AND OR XOR HALT JMP BRANZ BRAB JSB LDM STM RET

%token DB DS

/* the grammar
*/

%%

input:		/* empty string */
		 | input line { yylineno++; }
		 ;

line: NEWLINE
    | statement NEWLINE
		| asm_expr NEWLINE
		| label_decl NEWLINE
		| register_decl NEWLINE
		| definition NEWLINE
		| END
		;

/* assembler directives */
asm_expr: sIMEM INTEGER { alloc_imem($2); }
	| sDMEM INTEGER { alloc_dmem($2); }
	| sIMEM INTEGER INTEGER { sys.imem_width = $3; alloc_imem($2); }
	| sOPCODE INTEGER { sys.opcode_bits = $2; }
	| sREGFILE INTEGER INTEGER { sys.regfile = $2; sys.reg_addr_bits = $3; }
	| sREGFILE INTEGER { sys.regfile = $2; }
	| sBASE INTEGER { if( !using_data) { sys.ibase = $2; } else { sys.dbase = $2; } }
	| DS STRING { if(!using_data) { yyerror("define string only allowed in data section."); } else define_string( &yytext[1] ); } 
	| sDATA { using_data = true; } 
	| DB format_db_list
	;

/* grammers for each cpu mnemonic */
statement: MOV format_rd_imm 		{ if( using_data) { yyerror("invalid opcode in data section."); } else gen( xMOV, $2); }
				 | MOV format_rd_label  { if( using_data) { yyerror("invalid opcode in data section."); } else gen( xMOV, $2); }
				 | ADD format_ra_rb_rd 	{  if( using_data) { yyerror("invalid opcode in data section."); } else gen( xADD, $2); }
	| SUB format_ra_rb_rd { if( using_data) { yyerror("invalid opcode in data section."); } else gen( xSUB, $2); }
	| SBB format_ra_rb_rd { if( using_data) { yyerror("invalid opcode in data section."); } else gen( xSBB, $2); }
	| AND format_ra_rb_rd { if( using_data) { yyerror("invalid opcode in data section."); } else  gen( xAND, $2); }
	| OR format_ra_rb_rd { if( using_data) { yyerror("invalid opcode in data section."); } else gen( xOR, $2); }
	| XOR format_ra_rb_rd { if( using_data) { yyerror("invalid opcode in data section."); } else gen( xXOR, $2); }
	| JMP format_imm { if( using_data) { yyerror("invalid opcode in data section."); } else gen( xJMP, $2); }
	| JMP format_label { if( using_data) { yyerror("invalid opcode in data section."); } else gen( xJMP, $2); }
	| JSB format_label { if(using_data) { yyerror("invalid opcode in data section."); } else gen( xJSB, $2); }
	| JSB format_imm { if(using_data) { yyerror("invalid opcode in data section."); } else gen( xJSB, $2); }
	| BRANZ format_rd_labeloffset { if( using_data) { yyerror("invalid opcode in data section."); } else gen( xBRANZ, $2); }
	| BRANZ format_rd_immoffset { if( using_data) { yyerror("invalid opcode in data section."); } else gen( xBRANZ, $2); }
	| BRAB format_rd_labeloffset { if( using_data) { yyerror("invalid opcode in data section."); } else gen( xBRAB, $2); }
	| BRAB format_rd_immoffset { if( using_data) { yyerror("invalid opcode in data section."); } else gen( xBRAB, $2); }
	| LDM format_ra_0_rd { if( using_data) { yyerror("invalid opcode in data section."); } else gen(xLDM, $2); }
	| STM format_ra_0_rd { if( using_data) { yyerror("invalid opcode in data section."); } else gen(xSTM, $2); }
	| RET { if(using_data) { yyerror("Invalid opcode in data section."); } else gen(xRET, 0x0000); }
	| HALT { if( using_data) { yyerror("invalid opcode in data section."); } else gen(xHALT, 0x0000 ); }
	;

/* grammers for each of the menomonic formats */
format_db_list: define_byte { if( !using_data ) { yyerror("define_byte allowed in data section only."); } else define_byte((byte)$1); } 
			        | format_db_list COMMA define_byte { if( !using_data ) { yyerror("define_byte allowed in data section only."); } else define_byte((byte)$3); }
							;
define_byte: INTEGER;
format_imm: INTEGER { $$ = ENCR( ($1 >> (sys.reg_addr_bits*2)), ($1 >> sys.reg_addr_bits), $1); };
format_label: labelconstant { $$ = ENCR( ($1 >> (sys.reg_addr_bits*2)), ($1 >> sys.reg_addr_bits), $1); };
format_rd_imm: reg COMMA INTEGER { $$ = ENCR( ($3 >> sys.reg_addr_bits), $3, $1 ); };
format_rd_immoffset: reg COMMA INTEGER { $$ = ENCROFFSET( ($3 >> sys.reg_addr_bits), $3, $1); };
format_rd_labeloffset: reg COMMA labelconstant {  $$ = ENCROFFSET(sys.ibase - 1, $3, $1); };
format_rd_label: reg COMMA labelconstant { $$ = ENCR( ($3 >> sys.reg_addr_bits), $3, $1); };
format_ra_rb_rd: reg COMMA reg COMMA reg { $$ = ENCR( $1, $3, $5 ); };
format_ra_0_rd: reg COMMA reg { $$ = ENCR( $1, 0, $3 ); };
/*format_0_rb_0: reg { $$ = ENCR( 0, $1, 0 ); };*/
/*format_ra_rb_0: reg COMMA reg { $$ = ENCR( $1, $2, 0); };*/
/*format_label_ra: label COMMA reg { $$ = ENCR($3, $1, ($1 >> sys.reg_addr_bits) ); };*/
/*format_label_rd: label COMMA reg { $$ = ENCR( ($1 >> sys.reg_addr_bits), $1, $3 ); };*/
/*format_0_label: label { $$ = ENCR(0, $1, ($1 >> sys.reg_addr_bits) ); };*/

label_decl: IDENTIFIER COLON { cpu_setsymbol( $1, ST_LABEL, using_data ? sys.dbase : sys.ibase); };
register_decl: sREGISTER REG IDENTIFIER { cpu_setsymbol( $3, ST_REGISTER, $2); };
definition: sDEFINE IDENTIFIER INTEGER { cpu_setsymbol($2, ST_INT, $3); }
	| sDEFINE IDENTIFIER STRING { cpu_setsymbol($2, ST_STRING, $3); }
	;

/* a label is a reference to a memory address, a constant is also valid */
/*label: INTEGER { $$ = $1; }
     | IDENTIFIER { cpu_symbol s = cpu_getsymbol($1); if(s.type==ST_LABEL) $$ = s.lvalue; else if( s.type == ST_UNKNOWN ) add_forward_declare($1);  else yyerror("unexpected label"); }
		 ;
*/

labelconstant: IDENTIFIER { cpu_symbol s = cpu_getsymbol($1); if(s.type==ST_INT || s.type==ST_LABEL) $$ = s.lvalue; else if( s.type == ST_UNKNOWN ) add_forward_declare($1); else  yyerror("labelconstant: unexpected label."); };

/* a reg is a reference to a register */
reg: REG { $$ = $1; }
	 | IDENTIFIER { cpu_symbol s = cpu_getsymbol($1); if(s.type==ST_REGISTER) $$ = s.lvalue; else yyerror("unexpected register"); }
	 ;

%%

/* yacc uses this function to report an error */
int yyerror(const char* err)
{
	//  a more sophisticated error-function
 	//PrintError(err);

	error_flag = true;
	fprintf(stderr, "ERROR: %s.  Line: %d\n", err, yylineno);
}

void fixup_forward_declares()
{
	char yerr[1024];

	//printf("Linking forward declarations.\n");
	
	for(forward_declarations::const_iterator f=unresolved.begin(), _f = unresolved.end(); f!=_f; f++) {
		cpu_symbol s = cpu_getsymbol(f->symbol_index);
	
		if( s.type == ST_UNKNOWN ) {
			sprintf(yerr, "Unresolved declaration: %s", s.name.c_str());
			yyerror(yerr);
		} else {
			unsigned char opcode = (lpimem[f->imem_ptr] >> (sys.imem_width - sys.opcode_bits)) & 0x1f;
			//printf("forward declare for index %d at %lx.  Opcode: %d\n", f->symbol_index, f->imem_ptr, opcode);
		}
	}
}

void add_forward_declare(int symbol_index)
{
	forward_declare decl;

	// save symbol index
	decl.symbol_index = symbol_index;

	// save current instruction location
	decl.imem_ptr = sys.ibase;

	unresolved.push_back(decl);
}

void define_byte(byte value)
{

	//printf("defining byte: %d at 0x%lx\n", value, sys.dbase);

	if( sys.dbase < sys.dmem ) {
		lpdmem[sys.dbase] = value;
		sys.dbase++;

		if( datasize < sys.dbase ) {
			datasize = sys.dbase;
		}

	} else {
		yyerror("out of data memory");
	}
}

void define_string(string str)
{
	if( sys.dbase + str.size() + 1 < sys.dmem ) {
		//printf("defining string %s at 0x%lx\n", str.c_str(), sys.dbase);
		memcpy(&lpdmem[sys.dbase], str.c_str(), str.size());
		lpdmem[sys.dbase+str.size()] = 0x00;
		sys.dbase += (str.size()+1);

		if( datasize < sys.dbase ) {
			datasize = sys.dbase;
		}
	} else {
		yyerror("string to big to fit in data memory");
	}
}

/* allocates our data memory that we will assemble to */
void alloc_dmem(unsigned long newsize)
{
	if(!lpdmem || (newsize != sys.dmem) ) {
		if(lpdmem) {
			//fprintf(stderr, "reallocating %ld bytes for data memory\n", newsize * sizeof(unsigned char));
			lpdmem = (unsigned char*)realloc(lpdmem, newsize * sizeof(unsigned char) );
			memset(lpdmem + sys.dmem, 0x00, newsize * sizeof(unsigned char) - sys.dmem );
		} else {
			//fprintf(stderr, "allocating %ld bytes for data memory\n", newsize * sizeof(unsigned char));
			lpdmem = (unsigned char *)malloc(newsize * sizeof(unsigned char) );
			memset( lpdmem, 0x00, newsize * sizeof(unsigned char));
		}
		sys.dmem = newsize;
	}
}

/* allocates our instruction memory that we will assembl to */
void alloc_imem(unsigned long newsize)
{
	if (!lpimem || (newsize != sys.imem) )	{
		unsigned long buffer_size = newsize * sizeof(unsigned long);
		unsigned long *ptr = (unsigned long *)realloc(lpimem, buffer_size);
		//fprintf(stderr, "reallocating %ld bytes for instruction memory\n", buffer_size);
		if( ptr != NULL ) {
			int remaining = newsize - sys.imem;
			if( !lpimem ) {
				remaining = newsize;
			}

			fprintf(stderr, "success!\n");
			lpimem = ptr;

			memset(lpimem, 0xff, newsize * sizeof(unsigned long));
		}

		sys.imem = newsize;
	}
}

void show_sys_info() 
{
	fprintf(stderr, "# %35s: %ld\n", "Instruction Width",  sys.imem_width);
	fprintf(stderr, "# %35s: %ld\n", "Instruction Memory size", sys.imem );
	fprintf(stderr, "# %35s: %ld\n", "Data Memory size",  sys.dmem );
	fprintf(stderr, "# %35s: %ld\n", "Register Width",  sys.reg_addr_bits );
	fprintf(stderr, "# %35s: %ld\n", "Opcode Bits", sys.opcode_bits);
}

int cpu_getsymbol(string name)
{
	int i = 0;
	for(cpu_symbols::const_iterator s=symbol_table.begin(), _s = symbol_table.end(); s!=_s; s++,i++) {

		if(s->name == name)
			return i;
	}
	return -1;
}

cpu_symbol cpu_getsymbol(int i)
{
	
	if(i<symbol_table.size()) {
		cpu_symbol s = symbol_table[i];
		//printf("get SYMBOL(#%d, n: '%s', t:%d, v:%ld)\n", i, s.name.c_str(), s.type, s.lvalue);
		return s;
	}
	else {
		yyerror("symbol ordinal out of range.");
		exit(-1);
	}
}

int cpu_addsymbol(string name, cpu_symboltype type, long value)
{
	cpu_symbol si;
	si.name = name;
	si.type = type;
	si.lvalue = value;
	symbol_table.insert(symbol_table.end(), si);
	//printf("ADD SYMBOL(n: '%s', t:%d, v:%ld)\n", si.name.c_str(), si.type, si.lvalue);
	return symbol_table.size()-1;
}

cpu_symbol* cpu_setsymbol(int i, cpu_symboltype type, long value)
{
	if(i>=symbol_table.size())
		return NULL;

	cpu_symbol* s = &symbol_table[i];
	s->type = type;
	s->lvalue = value;
	//printf("SET SYMBOL(#%d, n: '%s', t:%d, v:%ld)\n", i, s->name.c_str(), s->type, s->lvalue);
	return s;
}

int cpu_addstring(string s)
{
	//printf("cpu_add string: %s\n", s.c_str());
	int i = string_table.size();
	string_table.insert(string_table.end(), s);
	return i;
}

/* code generation routines */
void out_fmt_binary() 
{
	/* output instruction memory buffer as binary */
	for(int i=0; i<codesize; i++) {
		unsigned long value = lpimem[i];
		for(int j=sys.imem_width-1; j>=0; j--) {
			unsigned int bit = ((value >> j) & 1);
			printf("%01d", bit);
		}
		printf("\n");
	}
	for(int i=codesize; i<sys.imem; i++) {
		for(int j=sys.imem_width-1; j>=0; j--) {
			printf("1");
		}
		printf("\n");
	}
}

void out_fmt_hex()
{
	/* output the instruction memory buffer as hex ints */
	for(int i = 0; i<codesize; i++)
		printf("0x%08lx\n", lpimem[i] );
}

void convert_to_binary(int index, unsigned long value) {

	printf("\t\t%d => \"", index);
	for (int i=sys.imem_width-1; i>=0; i--) {
		unsigned int bit = ((value >> i) & 1);
		printf("%01d", bit);
	}											
	printf("\",\n");
		
}

void out_fmt_package() {
	
	printf("\n");

	for(int i=0; i<codesize; i++) {
		convert_to_binary(i, lpimem[i]);
	}

	printf("\t\tothers => \"");
	for(int j=sys.imem_width-1; j>=0; j--) {
		printf("1");
	}
	printf("\"\n");

}

void out_fmt_package(	const char * plibname, 
			const char * ppackagename, 
			const char * ptypename,
			const char * pvarname
			)
{

	if( !ppackagename )
		ppackagename = "program_text"; 	// default package name

	if( !plibname )
		plibname = "defs"; 	 	// default lib name

	if( !ptypename )
		ptypename = "memory_type";  	// default type name

	if( !pvarname )
		pvarname = "program";  		// default program name

	printf("library IEEE;\nuse IEEE.std.logic_1164.all;\nuse work.%s.all;\n", plibname);
	printf("package %s is\n\tconstant %s : %s := (\n", ppackagename, pvarname, ptypename);
	
	/* output the instruction memory buffer as hex ints */
	for(int i=0; i<codesize; i++) {
		convert_to_binary(i, lpimem[i]);
	}

	printf("\t\tothers => \"");
	for(int j=sys.imem_width-1; j>=0; j--) {
		printf("1");
	}
	printf("\");\n");
	//printf("\t\tothers => X\"00000000\");\n");
	printf("end package %s;\n", ppackagename);
}

void out_fmt_hex_waddr(int ipl)
{
	/* output the instruction memory buffer as hex ints */
	for(int i = 0; i<codesize; i++) {
		if( (i % ipl) == 0 ) {
			if(i>0) printf("\n");
				printf("0x%04x: ", i);
		}
		printf("0x%04lx ", lpimem[i] );
	}
	printf("\n");
}

int gen(unsigned char opcode, unsigned int operand)
{
	unsigned long instr;
	int exponent = sys.reg_addr_bits * 3;
	unsigned long flag = (unsigned long)pow(2, exponent);
	unsigned long operand_part = (operand & (flag - 1));

	instr = ((opcode & 0x1f) << (sys.imem_width-sys.opcode_bits)) | operand_part;
	if( emit_code ) {
		if(sys.ibase < sys.imem) {
			// check to see if we already have an instruction here
			if(lpimem[sys.ibase] != 0xffffffff) {
				char yerr[1024];
				sprintf(yerr, "line %d : Buffer overrun at address 0x%08lx.\n", yylineno, sys.ibase );
				yyerror( yerr );
				exit(1);
			} else {
				lpimem[sys.ibase] = instr;
			}

		} else {
			yyerror("out of instruction memory");
			exit(1);
		}
	}

	sys.ibase++;

	if(codesize < sys.ibase)
		codesize = sys.ibase;

	return 0;
}

