%{
#include <stdio.h>
#include "base.h"
#include "parser.h"

#define uploc { yylloc->first_column = yylloc->last_column + 1; yylloc->last_column += yyleng; }

#define CAST_BOOLEAN(strb) strcasecmp(strb, "False") ? TRUE : FALSE

%}


%option noyywrap
%option yylineno
%option bison-bridge
%option bison-locations
%option nounput
%option case-insensitive

%%
"{"			{ 
				int c;
				while ((c = input())) {
                                	if (c == '}')
                                    		break;
                                	else if (c == '\n') {
                                    		yylloc->first_line = yylloc->last_line = yylineno;
                                    		yylloc->first_column = 1;
                                    		yylloc->last_column = 0;
                                	} else if (c == EOF) {
                                    	fprintf (stderr,
                                             "Error: unexpected EOF inside comment "
                                             "at line %d\n",
                                             yylineno);
                                    	exit (1);
                                	}
                        	}
			}

"program"		{ uploc; return T_PROGRAM; }		
"var"			{ uploc; return T_VAR; }
"integer"|"boolean"	{ uploc; yylval->type = type_get_from_lexeme(yytext); return TYPE_IDENTIFIER;	}
"begin"			{ uploc; return T_BEGIN; }
"end"			{ uploc; return T_END; }
"if"			{ uploc; return T_IF; }
"then"			{ uploc; return T_THEN; }
"else"			{ uploc; return T_ELSE; }
"while"			{ uploc; return T_WHILE; }
"for"			{ uploc; return T_FOR; }
"to"			{ uploc; return T_TO; }
"do"			{ uploc; return T_DO; }
":="			{ uploc; return T_ASSIGNMENT; }
"("			{ uploc; return T_LPAR; }
")"			{ uploc; return T_RPAR; }
"+"			{ uploc; yylval->lexeme=strdup(yytext);
				return T_PLUS;
			}
"-"			{ uploc; yylval->lexeme=strdup(yytext);
				return T_MINUS;
			}
"and"			{ uploc; yylval->lexeme=strdup(yytext);
				return T_AND;
			}
"or"			{ uploc; yylval->lexeme=strdup(yytext);
				return T_OR;
			}
"not"			{ uploc; yylval->lexeme=strdup(yytext);
				return T_NOT;
			}
">"			{ uploc; yylval->lexeme=strdup(yytext);
				return T_GREATER;
			}
"<"			{ uploc; yylval->lexeme=strdup(yytext);
				return T_LESSER;
			}
"=" 			{ uploc; yylval->lexeme=strdup(yytext);
				return T_EQUAL;
			}
"<>"			{ uploc; yylval->lexeme=strdup(yytext);
				return T_NOTEQUAL;
			} 
">=" 			{ uploc; yylval->lexeme=strdup(yytext);
				return T_GREATEREQUAL;
			}
"<="			{ uploc; yylval->lexeme=strdup(yytext);
				return T_LESSEREQUAL;
			} 
";" 			{ uploc; return T_SEMICOLON; }
":" 			{ uploc; return T_COLON; }
"." 			{ uploc; return T_DOT; }
"," 			{ uploc; return T_COMMA; }

"true|false"		{ uploc;
			  yylval->boolean=CAST_BOOLEAN(yytext);
			  return BOOL_LITERAL;
			}
[0-9]+			{ uploc;
				yylval->integer=atoi(yytext);
				return INT_LITERAL;
			}

[A-Za-z][A-Za-z0-9_]*	{ uploc; yylval->lexeme=strdup(yytext);
				return IDENTIFIER;
			}
[ \t]+                      /* ignor whitespace */;
[\n]                        { yylloc->first_line = yylloc->last_line = yylineno;
                              yylloc->first_column = 1;
                              yylloc->last_column = 0;
                            }
.                           { uploc;
                              fprintf (stderr,
                                       "Syntax Error: unexpected "
                                       "character '%s' at line %d\n",
                                       yytext, yylloc->first_line);
                            }
%%


