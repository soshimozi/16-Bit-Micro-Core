%{
// scanner.l -- our assembler input scanning program

	#include <stdio.h>
	#include <string.h>
	#include <stdlib.h>
	#include "parser.h"

	extern YYSTYPE yylval;

	#include "assembler.h"
%}

%option noyywrap

delim 			[ \t]
whitesp 		{delim}+
digit				[0-9]
alpha				[a-zA-Z]
alphanum		[a-zA-Z0-9]
number			[-]?{digit}*[.]?{digit}*
integer			[-]?{digit}+
hex					"0x"[0-9a-fA-F]+
string			\"[^\"]*\"
register		[rR][-]?{digit}+
comment			"#"[^\n]*
identifier	{alphanum}[a-zA-Z0-9_]*

%%

{register} 	{ sscanf(yytext+1, "%d", &yylval); return REG; }
{integer}  	{ sscanf(yytext, "%ld", (long *)&yylval); return INTEGER; }
{hex}      	{ sscanf(yytext+2, "%lx", (unsigned long *)&yylval); return INTEGER; }

"\n"			{ return NEWLINE; }
","			{ return COMMA;	 }
":"			{ return COLON; }
"MOV"			{ return MOV; }
"ADD"			{ return ADD; }
"ADC"			{ return ADC; }
"SUB"			{ return SUB; }
"SBB"			{ return SBB; }
"OR"			{ return OR; }
"XOR"			{ return XOR; }
"HALT"			{ return HALT; }
"JMP"			{ return JMP; } 
"BRANZ"			{ return BRANZ; }
"BRAB"			{ return BRAB; }
"JSB"			{ return JSB; }
"RET"			{ return RET; }
"LDM"			{ return LDM; }
"STM"			{ return STM; }
"DB"			{ return DB; }
"DS"			{ return DS; }
".imem"			{ return sIMEM; }
".regfile"		{ return sREGFILE; }
".base"			{ return sBASE; }
".define"		{ return sDEFINE; }
".register" 		{ return sREGISTER; }
".dmem"			{ return sDMEM; }
".data"			{ return sDATA; }
".end"			{ return END; }
".opcode"		{ return sOPCODE; }

{identifier} {
	yylval = cpu_getsymbol(yytext);
	if(yylval<0) {

		yylval = cpu_addsymbol(yytext, ST_UNKNOWN, 0);
	}
	return IDENTIFIER;
}

{string} {
	yytext[strlen(yytext)-1] = 0;
	yylval = cpu_addstring(&yytext[1]);
	return STRING;
}

{whitesp} { /* No action and no return */ }
{comment} { /* No action and no return */ }


