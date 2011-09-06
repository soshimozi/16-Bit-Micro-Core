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
#include "simpleprinter_visitor.h"
#include "graphprinter_visitor.h"
#include "c_codegen_visitor.h"
#include "llvm_codegen_visitor.h"

bool simple_flag = FALSE;
bool graph_flag = FALSE;
bool c_flag = FALSE;
bool llvm_flag = FALSE;

int opts;

extern FILE *yyin;

static void yyerror( const char *msg );

static struct AstNode *ast;

%}

%defines
%locations
%pure-parser
%error-verbose

%union {
	char* lexeme;
	int integer;
	int boolean;
	char character;
	int type;
	struct AstNode *astnode;
};

%token <lexeme> IDENTIFIER
%token <type> TYPE_IDENTIFIER
%token <integer> INT_LITERAL
%token <boolean> BOOL_LITERAL
%token <character> CHAR_LITERAL

%token T_PLUSEQ
%token T_WHILE T_IF T_PROGRAM T_FUNCTION T_COLON T_PROC
%token T_COMMA T_SEMICOLON T_LBRACE T_RBRACE T_LPAR T_RPAR
%token T_DO T_DOT T_ASSIGN
%nonassoc IFX
%nonassoc T_ELSE

%left <lexeme> T_OR
%left <lexeme> T_AND
%left <lexeme> T_EQ T_NE
%left <lexeme> T_LT T_GT T_LE T_GE
%left <lexeme> T_PLUS T_MINUS
%left <lexeme> T_STAR T_SLASH
%nonassoc UMINUS
%nonassoc T_PLUSPLUS

%type <astnode> program
%type <astnode> ident
%type <astnode> program_decl
%type <astnode> var_decl_list
%type <astnode> multi_var_decl
%type <astnode> var_decl
%type <astnode> identlist
%type <astnode> single_identifier
%type <astnode> multi_identifier

%type <astnode> proc_func_list
%type <astnode> multi_proc_func_decl
%type <astnode> proc_func_decl
%type <astnode> func_decl
%type <astnode> proc_decl

%type <astnode> param_list
%type <astnode> single_param
%type <astnode> multi_param



%type <astnode> statement_list
%type <astnode> statement_block

%type <astnode> assignment_statement
%type <astnode> while_statement
%type <astnode> if_statement
%type <astnode> if_else_statement
%type <astnode> call

%type <astnode> expr
%type <astnode> simple_expression
%type <astnode> rel_op
%type <astnode> add_op
%type <astnode> mul_op
%type <astnode> factor
%type <astnode> literal
%type <astnode> term
%type <astnode> call_param_list
%type <astnode> call_parameter
%type <astnode> multi_call_parameter
%type <astnode> call_statement

%type <astnode> stmt

%type <type> type

%start program

%%

program:
	program_decl var_decl_list proc_func_list statement_block
	{
		struct AstNode *ast_node;
		ast_node = ast_node_new("Program", PROGRAM, VOID,
					yylloc.last_line, NULL);
		ast_node_add_child(ast_node, $1); // program_decl
		ast_node_add_child(ast_node, $2); // var_decl_list
		ast_node_add_child(ast_node, $3); // proc_func_list
		ast_node_add_child(ast_node, $4); // statement_block
		$$ = ast_node;

		ast = ast_node;
	}
	;

var_decl_list:
	/* empty */ { $$ = NULL; }
	| multi_var_decl
	{
		struct AstNode *ast_node;
		ast_node = ast_node_new("VarDeclList", VARDECL_LIST, VOID,
					yylloc.last_line, NULL);
		ast_node_add_child(ast_node, $1);
		$$ = ast_node;
	}
	;

multi_var_decl:
	var_decl { $$ = $1; } 
	| var_decl multi_var_decl
	{
		ast_node_add_sibling($1, $2);
		$$ = $1;
	}
	;

var_decl:
	type identlist T_SEMICOLON
	{
	        struct AstNode *ast_node;
        	ast_node = ast_node_new("VarDecl", VARDECL, $1,
                                	yylloc.last_line, NULL);
	        ast_node_add_child(ast_node, $2);
	        $$ = ast_node;
	}
	;

proc_func_list:
	/* empty */ { $$ = NULL; }
	| proc_func_decl multi_proc_func_decl
	{
		struct AstNode *ast_node;
		ast_node = ast_node_new("ProcFuncList", PROCFUNC_LIST, VOID,
					yylloc.last_line, NULL);
		ast_node_add_sibling($1, $2);
		ast_node_add_child(ast_node, $1);

		$$ = ast_node;
	}
	;

multi_proc_func_decl:
	/* empty */ { $$ = NULL; }
	| proc_func_decl multi_proc_func_decl
	{
		ast_node_add_sibling($1, $2);
	}
	;

proc_func_decl:
	proc_decl { $$ = $1; }
	| func_decl { $$ = $1; }
	;

func_decl:
	T_FUNCTION ident T_LPAR param_list T_RPAR T_COLON type T_LBRACE var_decl_list statement_block T_RBRACE
	{	
		Symbol *symtab;
		struct AstNode *ast_node;
		
		ast_node = ast_node_new("FuncDecl", FUNCTION, VOID,
					yylloc.last_line, NULL);
	
		ast_node_add_child(ast_node, $2);	// Identifier
		ast_node_add_child(ast_node, $4);	// ParamList
		ast_node_add_child(ast_node, $9);	// VarDeclList
		ast_node_add_child(ast_node, $10);	// Statements

		$2->symbol->type = $7;

		ast_node->symbol = symbol_new(NULL);
		
		$$ = ast_node;	
	}
	;

proc_decl:
	T_PROC ident T_LPAR param_list T_RPAR T_LBRACE var_decl_list statement_block T_RBRACE
	{
		Symbol *symtab;
		struct AstNode *ast_node;
		
		ast_node = ast_node_new("ProcDecl", PROCEDURE, VOID,
					yylloc.last_line, NULL);
	
		ast_node_add_child(ast_node, $2);	// Identifier
		ast_node_add_child(ast_node, $4);	// ParamList
		ast_node_add_child(ast_node, $7);	// VarDeclList
		ast_node_add_child(ast_node, $8);	// Statements

		ast_node->symbol = symbol_new(NULL);
		
		$$ = ast_node;
	}
	;
	
program_decl:
	T_PROGRAM ident T_SEMICOLON
	{  
		struct AstNode *ast_node;
		
		ast_node = ast_node_new("ProgramDecl", PROGRAM_DECL, VOID,
					yylloc.last_line, NULL);
		ast_node_add_child(ast_node, $2); /* identifier */
		$$ = ast_node;
	}
	;

param_list:
	/* empty */ { $$ = NULL; }
	| single_param multi_param
	{
		struct AstNode *ast_node;
		ast_node = ast_node_new("ParamList", PARAM_LIST, VOID,
					yylloc.last_line, NULL);
		ast_node_add_sibling($1, $2);
		ast_node_add_child(ast_node, $1);
		$$ = ast_node;
	}
	;

multi_param:
	/* empty */ { $$ = NULL; }
	| T_COMMA single_param multi_param
	{
		ast_node_add_sibling($2, $3);
		$$ = $2;
	}
	;
	

single_param:
	type ident
	{
		struct AstNode *ast_node;
		ast_node = ast_node_new("Parameter", PARAMETER, $1,
					yylloc.last_line, NULL);
		ast_node_add_child(ast_node, $2);	// Identifier
		$$ = ast_node;
	}
	;

identlist:
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
	ident { $$ = $1; }
	;

ident:
	IDENTIFIER 
	{
		struct AstNode *ast_node;
	
		ast_node = ast_node_new("Identifier", IDENTIFIER, VOID,	
					yylloc.last_line, NULL);
		ast_node->symbol = symbol_new($1);
		// ast-node->symbol->decl_linenum = yylloc.last_line;
		$$ = ast_node;	 
	}
	;


statement_block:
	statement_list
	{
		struct AstNode *ast_node;
		ast_node = ast_node_new("StatementList", STATEMENT_LIST, VOID,
					yylloc.last_line, NULL);
		ast_node_add_child(ast_node, $1);
		$$ = ast_node; 
	}
	;

statement_list:
	statement_list stmt 
	{ 
	        ast_node_add_sibling($2, $1);
        	$$ = $2;
	}
	| { $$ = NULL; } /* NULL */
	;
	
type:	
	TYPE_IDENTIFIER 
	;
	
stmt:
	assignment_statement { $$ = $1; }
	| while_statement { $$ = $1; }
	| T_DO stmt T_WHILE T_LPAR expr T_RPAR T_SEMICOLON { $$ = NULL;}
	| if_statement { $$ = $1; }
	| if_else_statement { $$ = $1; }
	| call_statement { $$ = $1; }
	| T_LBRACE statement_block T_RBRACE { $$ = $2;}
	;

call_statement:
	call T_SEMICOLON { $$ = $1; }
	;

if_statement:
	T_IF T_LPAR expr T_RPAR stmt %prec IFX 
	{ 
		struct AstNode *ast_node;
		ast_node = ast_node_new("IfStatement", IF_STMT, VOID,
					yylloc.last_line, NULL);
		ast_node_add_child(ast_node, $3);
		ast_node_add_child(ast_node, $5);
		$$ = ast_node;
	}
	;

if_else_statement:
	T_IF T_LPAR expr T_RPAR stmt T_ELSE stmt
	{ 
		struct AstNode *ast_node;
		ast_node = ast_node_new("IfStatement", IF_STMT, VOID,
					yylloc.last_line, NULL);
		ast_node_add_child(ast_node, $3);
		ast_node_add_child(ast_node, $5);
		ast_node_add_child(ast_node, $7);
		$$ = ast_node;
	}
	;

assignment_statement:
	ident T_ASSIGN expr T_SEMICOLON 
	{ 
        	struct AstNode *ast_node;
	        ast_node = ast_node_new("Assignment", ASSIGNMENT_STMT, VOID,
        	                        yylloc.last_line, NULL);
        	ast_node_add_child(ast_node, $1);
        	ast_node_add_child(ast_node, $3);
        	$$ = ast_node;
	}
	;

while_statement:
	T_WHILE T_LPAR expr T_RPAR stmt 
	{ 
		struct AstNode *ast_node;
		ast_node = ast_node_new("WhileStatement", WHILE_STMT, VOID,
					yylloc.last_line, NULL);
		ast_node_add_child(ast_node, $3);
		ast_node_add_child(ast_node, $5);

		$$ = ast_node; 
	}
	;

expr:
	simple_expression
	{
		$$ = $1;
	}
	| simple_expression rel_op simple_expression
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
	| ident T_PLUSPLUS
	{
		/* equivalent to lval += 1 => lval = lval + 1 */
		fprintf(stderr, "Plus plus worked!\n");
		$$ = NULL;
	}
	| simple_expression add_op term
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
	factor { $$ = $1; }
	| term mul_op factor
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

factor:
	ident { $$ = $1; }
	| literal { $$ = $1; }
	| call { $$ = $1; }
	| T_LPAR expr T_RPAR { $$ = $2; }
	;

call:
	ident T_LPAR call_param_list T_RPAR
	{
		struct AstNode *ast_node;
		ast_node = ast_node_new("Call", CALL, VOID,
					yylloc.last_line, NULL);
		ast_node_add_child(ast_node, $1);	
		ast_node_add_child(ast_node, $3);
		$$ = ast_node;
	}
	;

call_param_list:
	/* empty */ { $$ = NULL; }
	| call_parameter multi_call_parameter
	{
		struct AstNode *ast_node;
		ast_node = ast_node_new("CallParamList", CALLPARAM_LIST, VOID,
					yylloc.last_line, NULL);
		ast_node_add_sibling($1, $2);
		ast_node_add_child(ast_node, $1);
		
		$$ = ast_node;
	}
	;

multi_call_parameter:
	/* empty */ { $$ = NULL; }
	| T_COMMA call_parameter multi_call_parameter
	{
		ast_node_add_sibling($2, $3);
		$$ = $2;
	}
	;

call_parameter:
	expr
	{
		struct AstNode *ast_node;
		ast_node = ast_node_new("CallParameter", CALLPARAM,
					((struct AstNode*) $1)->type,
					yylloc.last_line, NULL);
		ast_node_add_child(ast_node, $1);
		$$ = ast_node;
	}
	;	

add_op:
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
		ast_node = ast_node_new($1, T_OR, INTEGER,
		                        yylloc.last_line, NULL);
		$$ = ast_node;
	}
	;

mul_op:
	T_STAR	
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
	| T_AND
	{
		struct AstNode *ast_node;
		ast_node = ast_node_new($1, T_AND, INTEGER,
		                        yylloc.last_line, NULL);
		$$ = ast_node;
	}
	;

rel_op:
	T_LT
	{
		struct AstNode *ast_node;
		ast_node = ast_node_new($1, T_LT, BOOLEAN,	
					yylloc.last_line, NULL);
		$$ = ast_node;
	}
	|
	T_LE
	{
		struct AstNode *ast_node;
		ast_node = ast_node_new($1, T_LE, BOOLEAN,	
					yylloc.last_line, NULL);
		$$ = ast_node;
	}
	|
	T_GT
	{
		struct AstNode *ast_node;
		ast_node = ast_node_new($1, T_GT, BOOLEAN,	
					yylloc.last_line, NULL);
		$$ = ast_node;
	}	
	|
	T_GE
	{
		struct AstNode *ast_node;
		ast_node = ast_node_new($1, T_GE, BOOLEAN,	
					yylloc.last_line, NULL);
		$$ = ast_node;
	}
	|
	T_EQ
	{
		struct AstNode *ast_node;
		ast_node = ast_node_new($1, T_EQ, BOOLEAN,	
					yylloc.last_line, NULL);
		$$ = ast_node;
	}
	|
	T_NE
	{
		struct AstNode *ast_node;
		ast_node = ast_node_new($1, T_NE, BOOLEAN,	
					yylloc.last_line, NULL);
		$$ = ast_node;
	}
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
	|
	BOOL_LITERAL
	{
		struct AstNode *ast_node;
		ast_node = ast_node_new("BoolLiteral", BOOL_LITERAL, BOOLEAN,
					yylloc.last_line, NULL);
		value_set_from_int(&ast_node->value, $1);	
		$$ = ast_node;
	}
	|
	CHAR_LITERAL
	{
		struct AstNode *ast_node;
		ast_node = ast_node_new("CharLiteral", CHAR_LITERAL, CHAR,
					yylloc.last_line, NULL);
		value_set_from_int(&ast_node->value, $1);	
		$$ = ast_node;
	}
	;
%%

static void yyerror(const char *msg)
{
	fprintf(stderr, "Error(%d): %s\n", yyget_lineno(),  msg);
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
            case 'l':
                llvm_flag = TRUE;
                break;
            /*case 'o':
                output = optarg;
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
            */
            default:
                return 1;
        }
    }

    if (argc > optind)
        yyin = fopen(argv[optind], "r");
    else
        yyin = stdin;

    /*yylloc.first_line = yylloc.last_line = 1;
    yylloc.first_column = yylloc.last_column = 0;*/

    yyparse();

    /* Verificacao de tipos. */
    visitor = typecheck_new();
    ast_node_accept(ast, visitor);

    if (ast_node_check_errors(ast)) {
        fprintf(stderr, "Too many errors to compile.\n");
        if (!graph_flag)
            return 1;
    }

    /* Mostra estrutura da AST em forma de texto. */
    if (simple_flag)
        visitor = simpleprinter_new();

    /* Desenha grafo da AST. */
    else if (graph_flag)
        visitor = graphprinter_new();

    /* Gera codigo em linguagem C. */
    else if (c_flag)
        visitor = c_codegen_new();

    /* Gera codigo em assembly LLVM. */
    else if (llvm_flag)
        visitor = llvm_codegen_new();

    else
        visitor = NULL;

    if (visitor != NULL)
        ast_node_accept(ast, visitor);

    return 0;

}
