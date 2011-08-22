%{
#include <ctype.h>
#include <stdio.h>
#include <string.h>
#include <unistd.h>

#include "base.h"
#include "parser.h"
#include "ast.h"
#include "symbol_table.h"


#include "typecheck_visitor.h"
#include "graphprinter_visitor.h"

bool simple_flag = FALSE;
bool graph_flag = FALSE;
bool c_flag = FALSE;
bool llvm_flag = FALSE;

int opts;

extern FILE *yyin;

static void yyerror(/*YYLTYPE *locp, */const char *msg);

static struct AstNode *ast;

%}

%defines
%locations
%pure-parser
%error-verbose


%union {
	char *lexeme;
	int integer;
	int boolean;
	int type;
	struct AstNode *astnode;
}

/* Tokens */
%left <lexeme> T_OR
%left <lexeme> T_AND
%left <lexeme> T_EQUAL T_NOTEQUAL
%left <lexeme> T_LESSER T_GREATER T_LESSEREQUAL T_GREATEREQUAL
%left <lexeme> T_PLUS T_MINUS
%left <lexeme> T_NOT

%token T_PROGRAM
%token T_VAR
%token T_BEGIN
%token T_END

%token T_IF
%token T_THEN
%token T_ELSE
%token T_WHILE
%token T_FOR
%token T_TO
%token T_DO

%token T_ASSIGNMENT

%token T_LPAR
%token T_RPAR
%token T_SEMICOLON
%token T_COLON
%token T_COMMA
%token T_DOT

%token <type> TYPE_IDENTIFIER
%token <lexeme> IDENTIFIER
%token <integer> INT_LITERAL
%token <boolean> BOOL_LITERAL

/* Rule Types */
%type <astnode> program
%type <astnode> program_decl
%type <astnode> vardecl_list
%type <astnode> multi_vardecl
%type <astnode> vardecl
%type <astnode> identifier_list
%type <astnode> multi_identifier
%type <astnode> single_identifier

/*
%type <astnode> vardecl_list
%type <astnode> multi_vardecl
%type <astnode> vardecl
%type <astnode> identifier_list
%type <astnode> multi_identifier
%type <astnode> single_identifier
*/

%type <astnode> identifier;


%start program

%%

program: 
	program_decl vardecl_list 
	{
		struct AstNode * ast_node;
		
		ast_node = ast_node_new("Program", PROGRAM, VOID,
					yyloc.last_line, NULL);


		ast_node_add_child(ast_node, $1); // ProgramDecl
		ast_node_add_child(ast_node, $2); // VarDeclList

		$$ = ast_node;
		ast = ast_node; 
	}
	;

program_decl:
	T_PROGRAM identifier T_SEMICOLON
	{
		struct AstNode  * ast_node;
		ast_node = ast_node_new("ProgramDecl", PROGRAM_DECL, VOID,
					yylloc.last_line, NULL);



		ast_node_add_child(ast_node, $2);
		$$ = ast_node;
	}
	;

vardecl_list:
	/* empty */ { $$ = NULL; }
	| multi_vardecl
	{
		struct AstNode *ast_node;
		ast_node = ast_node_new("VarDeclList", VARDECL_LIST, VOID,
					yylloc.last_line, NULL);
		ast_node_add_child(ast_node, $1);
		$$ = ast_node;
	}
	;

multi_vardecl:
	/* empty */ { $$ = NULL; }
	| vardecl multi_vardecl
	{
		ast_node_add_sibling($1, $2);
		$$ = $1;
	}
	;

vardecl:
	T_VAR identifier_list T_COLON TYPE_IDENTIFIER T_SEMICOLON
	{
		struct AstNode *ast_node;
		ast_node = ast_node_new("VarDecl", VARDECL, $4,
					yylloc.last_line, NULL);
		ast_node_add_child(ast_node, $2);
		$$ = ast_node;
	}
	;

identifier_list:
	single_identifier multi_identifier
	{
		struct AstNode *ast_node;
		ast_node = ast_node_new("IdentifierList", IDENT_LIST, VOID,
					yylloc.last_line, NULL);
		ast_node_add_sibling($1, $2);	
		ast_node_add_child(ast_node, $1);	
		$$ = ast_node;
	}
	;

multi_identifier:
	/* empty */ { $$ = NULL; }
	| T_COMMA single_identifier multi_identifier
	{
		ast_node_add_sibling($2, $3);
		$$ = $2;
	}
	;

single_identifier:
	identifier { $$ = $1; fprintf(stderr, "identifier!\n");  }
	;

identifier:
	IDENTIFIER
	{
		struct AstNode *ast_node;
	
		ast_node = ast_node_new("Identifier", IDENTIFIER, VOID,
					yyloc.last_line, NULL);
		ast_node->symbol = symbol_new($1);
		// ast_node->symbol_decl_linenum = yyloc.last_line;
		$$ = ast_node;
	}
	;

%%

static void
yyerror (/*YYLTYPE *locp,*/ const char *msg)
{
	fprintf(stderr, "Error: line %d: %s\n", yyget_lineno(), msg);
}

int main(int argc, char **argv)
{
	Visitor *visitor;
	
	opterr = 0;

	while ((opts = getopt (argc, argv, "sgcl")) != -1) {
		switch (opts) {
			case 's':
				simple_flag = TRUE;
				break;
			case 'g':
				graph_flag = TRUE;
				break;
			case 'c':
				c_flag = TRUE;
				break;
			case '?':
		                if (optopt == 'o')
                		    fprintf (stderr, "Option -%c requires an argument.\n",
		                             optopt);
                		else if (isprint (optopt))
		                    fprintf (stderr, "Unknown option `-%c'.\n", optopt);
                		else
		                    fprintf (stderr,
                		             "Unknown option character `\\x%x'.\n", optopt);
		}
	}

	if (argc > optind)
		yyin = fopen(argv[optind], "r");
	else
		yyin = stdin;

	yyparse();

	// verify types
	visitor = typecheck_new();
	ast_node_accept(ast, visitor);

	if (ast_node_check_errors(ast)) {
		fprintf(stderr, "Too many errors to compile.\n");
		return 1;
	}	

	if (graph_flag) {
		visitor = graphprinter_new();
	} else 
		visitor = NULL;

	if (visitor != NULL) 
		ast_node_accept(ast, visitor);

	
	return 0;
}

