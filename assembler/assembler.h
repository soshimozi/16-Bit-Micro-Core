#include <vector>
#include <string>

using namespace std;

/* yacc forward declarations */
int yyerror(const char* err);
int yylex();
extern int yylineno;
extern char* yytext;

/* this struct holds our cpu system description */
typedef struct {
	unsigned long imem;
	unsigned long imem_width;
	unsigned long regfile;
	unsigned long opcode_bits;
	unsigned long reg_addr_bits;
	unsigned long dmem;
	unsigned long ibase;
	unsigned long dbase;
} cpu_sysinfo;

/* symbol type enumerations */
typedef enum {
	ST_UNKNOWN = 0,
	ST_LABEL,
	ST_STRING,
	ST_INT,
	ST_REGISTER
} cpu_symboltype;

typedef struct {
	unsigned long imem_ptr;
	int symbol_index;
	int opcode;
} forward_declare;

/* symbol table entry */
typedef struct {
	string name;
	cpu_symboltype type;
	long lvalue;
} cpu_symbol;

typedef unsigned char byte;

/* declaration of symbol table and string table */
typedef vector<cpu_symbol> cpu_symbols;
typedef vector<string> cpu_strings;
typedef vector<forward_declare> forward_declarations;

/* delcaration of global variables */
extern cpu_sysinfo sys;
extern cpu_symbols symbol_table;
extern cpu_strings string_table;
extern forward_declarations unresolved;

extern bool error_flag;
extern bool using_data;
extern bool emit_code;

/* our assembler instructio nmemory */
extern unsigned long* lpimem;

/* data memory pointer */
extern unsigned char* lpdmem;

void alloc_imem(unsigned long newsize);
void alloc_dmem(unsigned long newsize);

/* holds the highest code address */
extern unsigned long codesize;

/* holds the highest data addres */
extern unsigned long datasize;

extern bool verbose;

/* symbol table functions */
int cpu_getsymbol(string name);
cpu_symbol cpu_getsymbol(int i);
int cpu_addsymbol(string name, cpu_symboltype type, long lvalue);
int cpu_addsymbol(string name, cpu_symboltype type, string lvalue);
cpu_symbol* cpu_setsymbol(int i, cpu_symboltype type, long value);
cpu_symbol* cpu_setsymbol(int i, cpu_symboltype type, string value);

/* string table functions */
int cpu_addstring( string s );

/* outputs the assembled instruction memory in various formats */
void out_fmt_hex();
void out_fmt_hex_waddr(int ipl); // ipl = instructions per line
void out_fmt_binary();
void out_fmt_package(const char *, const char *, const char *, const char *);
void out_fmt_package();
void show_sys_info();
void define_byte(byte value);
void define_string(string str);
void fixup_forward_declares();
void add_forward_declare(int symbol_index);

// macro encodes ra, rb, rd into a single operand value
#define ENCR(ra, rb, rd) ( ((ra) << (sys.reg_addr_bits*2)) | ((rb) << sys.reg_addr_bits) | (rd) )
#define ENCRDECL(inst, mem) ( (inst) | ((mem) << (sys.reg_addr_bits)))
#define ENCROFFSET(offset, value, rd) ( ((value - offset) << sys.reg_addr_bits) | (rd) )
/* generates assembler instruction given opcode and operand */
int gen(unsigned char opcode, unsigned int operand);

/* main.c
 */
extern void PrintError(const char *s, ...);

