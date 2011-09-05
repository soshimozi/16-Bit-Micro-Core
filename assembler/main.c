
#include <cstdlib>
#include <stdio.h>
#include <math.h>

#include <string.h>


#include <stdarg.h>


#include "assembler.h"

int output_symbols = 0;
int yyparse();

void print_usage() 
{
	printf("usage:\n");
	printf("assembler [-l<library name> -p<package name>] -o<output file> <input file>\n");
}

void clean_up() 
{
	//printf("clean up called.\n");
	if( lpimem )
		free(lpimem);

	if( lpdmem )
		free(lpdmem);
}

int main(int argc, const char* argv[])
{
	extern FILE *yyin;
	
	if( !lpimem )
		alloc_imem(sys.imem);

	if( !lpdmem )
		alloc_dmem(sys.dmem);


	const char * ppackage = NULL;
	const char * plibrary = NULL;
	const char * ptype = NULL;
	const char * pvar = NULL;

	bool binary = false;

	if(argc>1) {

		for(int i=1; i<argc; i++) {
			if( argv[i][0] == '-' ) {
				switch( argv[i][1] )  {
					case 'b':
						binary = true;
						break;
					case 'l':
						plibrary = &argv[i][2];
						break;
					case 'p':
						ppackage = &argv[i][2];
						break;
					case 't':
						ptype = &argv[i][2];
						break;
					case 'V':
						pvar = &argv[i][2];
						break;
					case 'v':
						verbose = true;
						break;
					case 's':
						output_symbols = 1;
						break;
				}
			}
		}

		const char *pinput_filename = argv[argc-1];
		if( !pinput_filename ) {
			print_usage();
			clean_up();
			exit(1);
		}
			

		// make first pass to build symbol table
		yyin = fopen(pinput_filename, "r");
		yyparse();
		fclose(yyin);
		
		if( !error_flag ) {
			fixup_forward_declares();
			// reset parser
			sys.ibase = sys.dbase = 0;
			yylineno = 1;

			codesize = 0;
			using_data = false;
			emit_code = true;

			// make second pass to emit instructions
			yyin = fopen(pinput_filename, "r");
			yyparse();

			//yyparse();
			fclose(yyin);

			if( !binary ) {
				if(output_symbols) {
					printf("\n############################################################################################################\n");
					printf("#                                                Symbols                                                   #\n");
					printf("#                                                                                                          #\n");
					for(cpu_symbols::const_iterator s=symbol_table.begin(), _s=symbol_table.end(); s!=_s; s++) {
						switch(s->type) {
							case ST_UNKNOWN : printf("#    %15s  UNKNOWN\n", s->name.c_str() ); break;
							case ST_LABEL   : printf("#    %15s  LABEL 	0x%08lx\n", s->name.c_str(), s->lvalue ); break;
							case ST_STRING  : printf("#    %15s  STRING 	\"%s\"\n", s->name.c_str(), string_table[s->lvalue].c_str()); break;
							case ST_INT	: printf("#    %15s  INT 	%ld\n", s->name.c_str(), s->lvalue ); break;
							case ST_REGISTER: printf("#    %15s  REGISTER	r%ld\n", s->name.c_str(), s->lvalue ); break;        
							default		: printf("#    %15s  ERROR\n", s->name.c_str());
						}
					}
					printf("############################################################################################################\n");
				}

				if( verbose )
					show_sys_info();

				printf("\n");	
				out_fmt_package(plibrary, ppackage, ptype, pvar);
			}
			else {
				out_fmt_binary();
			}
		}
	
	} else {
		
		print_usage();
		clean_up();
		exit(1);
	}

	clean_up();
	return 0;
}

