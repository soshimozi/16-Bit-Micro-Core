%{
#include <stdio.h>
#include "base.h"
#include "parser.h"

#define uploc	{ yylloc->first_column = yylloc->last_column + 1; yylloc->last_column += yyleng; }

#define CAST_BOOLEAN(strb) strcasecmp(strb, "False") ? 1 : 0

%}

%option yylineno
%option bison-bridge
%option bison-locations
%option noyywrap
%option nounput
%x COMMENT

%%

"/*"			{ uploc; BEGIN( COMMENT ); }
<COMMENT>"*"+"/"	{ uploc; BEGIN( INITIAL ); }
<COMMENT>"*"+[^*/]*	{ uploc; }
	
"program"		{ uploc; return T_PROGRAM; }
"function"		{ uploc; return T_FUNCTION; }
"proc"			{ uploc; return T_PROC; }
"int"|"bool"|"char"	{ 
				uploc;
			  	yylval->type = type_get_from_lexeme(yytext);
			  	return TYPE_IDENTIFIER;
			}
"while"			{ uploc; return T_WHILE; }
"if"			{ uploc; return T_IF; }
"else"			{ uploc; return T_ELSE; }
"do"			{ uploc; return T_DO; }
","			{ uploc; return T_COMMA; }
"="			{ uploc; return T_ASSIGN; }
"("			{ uploc; return T_LPAR; }
")"			{ uploc; return T_RPAR; }

">="			{ uploc; yylval->lexeme=strdup(yytext); return T_GE; }
"<="			{ uploc; yylval->lexeme=strdup(yytext); return T_LE; }
"=="			{ uploc; yylval->lexeme=strdup(yytext); return T_EQ; }
"!="			{ uploc; yylval->lexeme=strdup(yytext); return T_NE; }
"+"			{ uploc; yylval->lexeme=strdup(yytext); return T_PLUS; }
"-"			{ uploc; yylval->lexeme=strdup(yytext); return T_MINUS; }
"*"			{ uploc; yylval->lexeme=strdup(yytext); return T_STAR; }
"/"			{ uploc; yylval->lexeme=strdup(yytext); return T_SLASH; }
"&&"			{ uploc; yylval->lexeme=strdup(yytext); return T_AND; }
"||"			{ uploc; yylval->lexeme=strdup(yytext); return T_OR; }
">"			{ uploc; yylval->lexeme=strdup(yytext); return T_GT; }
"<"			{ uploc; yylval->lexeme=strdup(yytext); return T_LT; }

";"			{ uploc; return T_SEMICOLON; }
"."			{ uploc; return T_DOT; }
"{"			{ uploc; return T_LBRACE; }
"}"			{ uploc; return T_RBRACE; }
":"			{ uploc; return T_COLON; }

"true"|"false"		{ 
				uploc; 
			  	yylval->boolean=CAST_BOOLEAN(yytext);
			  	return BOOL_LITERAL;
			}
"'"."'"			{ 
				uploc; 
				yylval->character=yytext[1];
				return CHAR_LITERAL;
			}
[0-9]+                 	{ 
				uploc; 
				yylval->integer=atoi(yytext);
				return INT_LITERAL; 
			}
[A-Za-z][A-Za-z0-9_]*  	{ 
				uploc; 
				yylval->lexeme=strdup(yytext);
                              	return IDENTIFIER;
                        }
[ \t]+	; /* ignore whitespace */
[\n]			{ 
				yylloc->first_line = yylloc->last_line = yylineno;
			  	yylloc->first_column = 1;
			  	yylloc->last_column = 0;
			}
.			{
				uploc;
				fprintf (stderr, "Syntax Error: unexpected character '%s' at line %d\n", yytext, yylloc->first_line);
			}
%%

