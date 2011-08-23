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


%type <astnode> program_body
%type <astnode> statement_list
%type <astnode> multi_statement
%type <astnode> statement
%type <astnode> statement_matched
/*%type <astnode> statement_unmatched*/

%type <astnode> expression
%type <astnode> simple_expression
%type <astnode> not_factor
%type <astnode> factor
%type <astnode> term

%type <astnode> assignment
%type <astnode> identifier
%type <astnode> literal

%type <astnode> addop
%type <astnode> relop
%type <astnode> notop
%type <astnode> mulop


%start program

%%

program: 
	program_decl vardecl_list program_body 
	{
		struct AstNode * ast_node;
		
		ast_node = ast_node_new("Program", PROGRAM, VOID,
					yyloc.last_line, NULL);


		ast_node_add_child(ast_node, $1); // ProgramDecl
		ast_node_add_child(ast_node, $2); // VarDeclList
		ast_node_add_child(ast_node, $3); // program_body

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

program_body:
	/* empty */ { $$ = NULL; }
	| T_BEGIN statement_list T_END T_DOT { $$ = $2; }
	;

statement_list:
	/* empty */ { $$ = NULL; }
	| statement multi_statement
	{
		struct AstNode *ast_node;
		ast_node = ast_node_new("StatementList", STATEMENT_LIST, VOID,
					yylloc.last_line, NULL);
		ast_node_add_sibling($1, $2);
		ast_node_add_child(ast_node, $1);
		$$ = ast_node;
	}
	;

multi_statement:
	/* empty */ { $$ = NULL; }
	| T_SEMICOLON statement multi_statement
	{
		ast_node_add_sibling($2, $3);
		$$ = $2;
	}
	;

statement:
	statement_matched { $$ = $1; }
	| { $$ = NULL }
/*	| statement_unmatched { $$ = $1 } */
	;

statement_matched:
	assignment { $$ = $1; }
	;

assignment:
	identifier T_ASSIGNMENT expression
	{
		struct AstNode *ast_node;
		ast_node = ast_node_new("Assignment", ASSIGNMENT_STMT, VOID,
					yylloc.last_line, NULL);
		ast_node_add_child(ast_node, $1);
		ast_node_add_child(ast_node, $3);
		$$ = ast_node;
	}
	;

expression:
	simple_expression { $$ = $1; }
	| simple_expression relop simple_expression
	{
		struct AstNode *ast_node;
		ast_node = ast_node_new("RelExpression", REL_EXPR, BOOLEAN,
					yylloc.last_line, NULL);
		ast_node_add_child(ast_node, $1);
		ast_node_add_child(ast_node, $2);
		ast_node_add_child(ast_node, $3);
		$$ = ast_node;
	}
	;

simple_expression:
	term { $$ = $1; }
	| simple_expression addop term
	{
		struct AstNode *ast_node;
		Type type = ((struct AstNode *) $2)->type;
		
		ast_node = ast_node_new("AddExpression", ADD_EXPR, type,
					yylloc.last_line, NULL);
		ast_node_add_child(ast_node, $1);
		ast_node_add_child(ast_node, $2);
		ast_node_add_child(ast_node, $3);
		$$ = ast_node;
	}
	;

term:
	not_factor { $$ = $1; }
	| term mulop not_factor
	{
		struct AstNode *ast_node;
		Type type = ((struct AstNode *) $2)->type;
		
		ast_node = ast_node_new("MulExpression", MUL_EXPR, type,
					yylloc.last_line, NULL);

		ast_node_add_child(ast_node, $1);
		ast_node_add_child(ast_node, $2);
		ast_node_add_child(ast_node, $3);
		$$ = ast_node;
    	}	
    	;

not_factor:
    factor { $$ = $1; }
    | notop factor
    {
        struct AstNode *ast_node;
        struct AstNode *op_ast_node;
        ast_node = ast_node_new("NotFactor", NOTFACTOR, BOOLEAN,
                                yylloc.last_line, NULL);
        ast_node_add_child(ast_node, $2);
        $$ = ast_node;
    }
    ;

factor:
    identifier { $$ = $1; }
    | literal { $$ = $1; }
/*    | Call { $$ = $1; }*/
    | T_LPAR expression T_RPAR { $$ = $2; }
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
	identifier { $$ = $1; }
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

addop:
    T_PLUS
    {
        struct AstNode *ast_node;
        ast_node = ast_node_new($1, T_PLUS, INTEGER,
                                yylloc.last_line, NULL);
        $$ = ast_node;
    }
    | T_MINUS
    {
        struct AstNode *ast_node;
        ast_node = ast_node_new($1, T_MINUS, INTEGER,
                                yylloc.last_line, NULL);
        $$ = ast_node;
    }
    | T_OR
    {
        struct AstNode *ast_node;
        ast_node = ast_node_new($1, T_OR, BOOLEAN,
                                yylloc.last_line, NULL);
        $$ = ast_node;
    }
    ;

mulop:
/*    T_STAR
    {
        struct AstNode *ast_node;
        ast_node = ast_node_new($1, T_STAR, INTEGER,
                                yylloc.last_line, NULL);
        $$ = ast_node;
    }
    | T_SLASH
    {
        struct AstNode *ast_node;
        ast_node = ast_node_new($1, T_SLASH, INTEGER,
                                yylloc.last_line, NULL);
        $$ = ast_node;
    }
    | */
    T_AND
    {
        struct AstNode *ast_node;
        ast_node = ast_node_new($1, T_AND, BOOLEAN,
                                yylloc.last_line, NULL);
        $$ = ast_node;
    }
    ;

relop:
    T_LESSER
    {
        struct AstNode *ast_node;
        ast_node = ast_node_new($1, T_LESSER, BOOLEAN,
                                yylloc.last_line, NULL);
        $$ = ast_node;
    }
    | T_LESSEREQUAL
    {
        struct AstNode *ast_node;
        ast_node = ast_node_new($1, T_LESSEREQUAL, BOOLEAN,
                                yylloc.last_line, NULL);
        $$ = ast_node;
    }
    | T_GREATER
    {
        struct AstNode *ast_node;
        ast_node = ast_node_new($1, T_GREATER, BOOLEAN,
                                yylloc.last_line, NULL);
        $$ = ast_node;
    }
    | T_GREATEREQUAL
    {
        struct AstNode *ast_node;
        ast_node = ast_node_new($1, T_GREATEREQUAL, BOOLEAN,
                                yylloc.last_line, NULL);
        $$ = ast_node;
    }
    | T_EQUAL
    {
        struct AstNode *ast_node;
        ast_node = ast_node_new($1, T_EQUAL, BOOLEAN,
                                yylloc.last_line, NULL);
        $$ = ast_node;
    }
    | T_NOTEQUAL
    {
        struct AstNode *ast_node;
        ast_node = ast_node_new($1, T_NOTEQUAL, BOOLEAN,
                                yylloc.last_line, NULL);
        $$ = ast_node;
    }
    ;

notop:
    T_NOT { $$ = NULL; }
    ;

literal:
    INT_LITERAL
    {
        struct AstNode *ast_node;
        ast_node = ast_node_new("IntLiteral", INT_LITERAL, INTEGER,
                                yylloc.last_line, NULL);
        value_set_from_int(&ast_node->value, $1);
        $$ = ast_node;
    }
    | BOOL_LITERAL
    {
        struct AstNode *ast_node;
        ast_node = ast_node_new("BoolLiteral", BOOL_LITERAL, BOOLEAN,
                                yylloc.last_line, NULL);
        value_set_from_bool(&ast_node->value, $1);
        $$ = ast_node;
    }
/*(    | CHAR_LITERAL
    {
        struct AstNode *ast_node;
        ast_node = ast_node_new("CharLiteral", CHAR_LITERAL, CHAR,
                                yylloc.last_line, NULL);
        value_set_from_char(&ast_node->value, $1);
        $$ = ast_node;
    }*/
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

