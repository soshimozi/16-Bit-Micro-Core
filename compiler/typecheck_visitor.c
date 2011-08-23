#include <stdlib.h>
#include <stdio.h>
#include "typecheck_visitor.h"

static struct AstNode *_inside_procfunc = NULL;
static void _typecheck_print_stmt(struct AstNode *node, Type type, const char *ptype_str);
static Symbol *_complete_symbol_lookup(Symbol *sym);

Visitor *
typecheck_new()
{
    Visitor *visitor = (Visitor *) malloc (sizeof(Visitor));

    visitor->visit_program = &typecheck_visit_program;
    visitor->visit_programdecl = &typecheck_visit_programdecl;
    visitor->visit_vardecl_list = &typecheck_visit_vardecl_list;
    visitor->visit_vardecl = &typecheck_visit_vardecl;
    visitor->visit_statement_list = &typecheck_visit_statement_list;
    visitor->visit_assignment_stmt = &typecheck_visit_assignment_stmt;
    visitor->visit_if_stmt = &typecheck_visit_if_stmt;
    visitor->visit_while_stmt = &typecheck_visit_while_stmt;
    visitor->visit_for_stmt = &typecheck_visit_for_stmt;
    visitor->visit_rel_expr = &typecheck_visit_binary_expr;
    visitor->visit_add_expr = &typecheck_visit_binary_expr;
    visitor->visit_notfactor = &typecheck_visit_notfactor;
    visitor->visit_identifier_list = &typecheck_visit_identifier_list;
    visitor->visit_identifier = &typecheck_visit_identifier;
    visitor->visit_literal = NULL;
    visitor->visit_add_op = NULL;
    visitor->visit_rel_op = NULL;
    visitor->visit_not_op = NULL;

    return visitor;
}

void
typecheck_visit_program(struct _Visitor *visitor, struct AstNode *node)
{
	// create symbol for program
	// this will also be gst
	node->symbol = symbol_new(NULL);
	global_symtab = node->symbol;
	symtab = global_symtab;
	_inside_procfunc = NULL;
	ast_node_accept_children(node->children, visitor);
}

void
typecheck_visit_programdecl (struct _Visitor *visitor, struct AstNode *node)
{
    node->children->symbol->decl_linenum = node->linenum;
    ast_node_accept(node->children, visitor);
}

void
typecheck_visit_vardecl_list(struct _Visitor *visitor, struct AstNode *node)
{
	struct AstNode *child;
	
	for (child = node->children; child != NULL; child = child->sibling)
		ast_node_accept(child, visitor);
}

void typecheck_visit_vardecl(struct _Visitor *visitor, struct AstNode *node)
{
	node->children->type = node->type;
	ast_node_accept(node->children, visitor);
}

void typecheck_visit_statement_list(struct _Visitor *visitor, struct AstNode *node)
{
	ast_node_accept_children(node->children, visitor);
}

void typecheck_visit_assignment_stmt(struct _Visitor *visitor, struct AstNode *node)
{
	struct AstNode *lnode = node->children;
	struct AstNode *rnode = lnode->sibling;

	ast_node_accept(lnode, visitor);
	ast_node_accept(rnode, visitor);

	if (lnode->type != ERROR && rnode->type != ERROR &&
		lnode->type != rnode->type ) {
		node->type = ERROR;
		fprintf(stderr,
			"Error: Incompatible types on assignment "
			"operation in line %d.\n", node->linenum);
	}
}

void
typecheck_visit_if_stmt (struct _Visitor *visitor, struct AstNode *node)
{
	struct AstNode *expr = node->children;
	struct AstNode *stmt = expr->sibling;
	
	ast_node_accept(expr, visitor);
	ast_node_accept(stmt, visitor);
	
	if (expr->type != BOOLEAN) {
		node->type = ERROR;
		fprintf(stderr,
			"Error: Condition for if statement must be of Boolean type. "
			"Check line %d.\n", node->linenum);
	}
}

void
typecheck_visit_while_stmt (struct _Visitor *visitor, struct AstNode *node)
{
	struct AstNode *expr = node->children;	
	struct AstNode *stmt = expr->sibling;

	ast_node_accept(expr, visitor);
	ast_node_accept(stmt, visitor);

	if (expr->type != BOOLEAN) {
		node->type = ERROR;
		fprintf(stderr,
			"Error: Condition for While statement must be of Boolean type. "
			"Check line %d.\n", node->linenum);
	}
}

void
typecheck_visit_for_stmt (struct _Visitor *visitor, struct AstNode *node)
{
	struct AstNode *asgn = node->children;	
	struct AstNode *expr = asgn->sibling;	
	struct AstNode *stmt = expr->sibling;
	struct AstNode *id_node = asgn->children;

	ast_node_accept(expr, visitor);
	ast_node_accept(asgn, visitor);

	if (id_node->type != INTEGER) {
		node->type = ERROR;
		fprintf(stderr,
			"Error: Identifier '%s' is of %s type; it must be Integer. "				      "Check line %d.\n", id_node->symbol->name,
				type_get_lexeme(id_node->type), id_node->linenum);
	}

	if (expr->type != INTEGER) {
		node->type = ERROR;
		fprintf(stderr,
			"Error: value of stop condtion is not of Integer type. "				      "Check line %d.\n", id_node->linenum);
		
	}

	ast_node_accept(stmt, visitor);
}

void
typecheck_visit_binary_expr (struct _Visitor *visitor, struct AstNode *node)
{
	struct AstNode *lnode = node->children;	
	struct AstNode *op = lnode->sibling;	
	struct AstNode *rnode = op->sibling;

	ast_node_accept(lnode, visitor);
	ast_node_accept(rnode, visitor);

	if (lnode->type != ERROR && rnode->type != ERROR &&
		lnode->type != rnode->type) {
		node->type = ERROR;
		fprintf(stderr,
			"Error: Operation '%s' over incompatible types on line %d.\n", 
				op->name, op->linenum);
	}
}

void
typecheck_visit_notfactor (struct _Visitor *visitor, struct AstNode *node)
{
	ast_node_accept(node->children, visitor);
	
	if (node->children->type != BOOLEAN) {
		node->type = ERROR;
		fprintf(stderr,
			"ERROR: Operation 'not' over non-boolean "
			"operand on line %d.\n", node->linenum);
	}
}

void
typecheck_visit_identifier_list (struct _Visitor *visitor, struct AstNode *node)
{
    struct AstNode *child;

    for (child = node->children; child != NULL; child = child->sibling) {
        child->type = node->type;
        child->symbol->decl_linenum = node->linenum;
        ast_node_accept(child, visitor);
    }
}

void
typecheck_visit_identifier (struct _Visitor *visitor, struct AstNode *node)
{
    Symbol *sym = symbol_lookup(symtab, node->symbol->name);
    Symbol *_sym = sym;

	// The attribute ' decl_linenum' > 0 indicates a reference 
	// as value 0 indecates a variable

    void __fetch_symbol(struct AstNode *node, Symbol *sym) {
        symbol_table_destroy(node->symbol);
        node->symbol = sym;
        node->type = sym->type;
    }

    if (sym == NULL) {

        // Symbol possesss declaration line: It inserts in the table of symbols.
        if (node->symbol->decl_linenum > 0) {
            node->symbol->type = node->type;
            node->symbol->is_global = (symtab == global_symtab);

            node->symbol = symbol_insert(symtab, node->symbol);

        } else if ((sym = symbol_lookup(global_symtab, node->symbol->name))
                   != NULL) {
            __fetch_symbol(node, sym);

        // Without declaration line == eh fetch of 0 variable not declared.
        } else {
            node->symbol->type = node->type = ERROR;
            fprintf(stderr, "Error: Undeclared symbol '%s' in line %d\n",
                    node->symbol->name, node->linenum);
        }

    // Symbol found in the table and eh fetch: OK. Or it can be global.
    } else if (node->symbol->decl_linenum == 0) {
        __fetch_symbol(node, sym);

	// Symbol possesss declaration line but it was found in the table: 
	// redefinition attempt.
    } else {
        node->symbol->type = node->type = ERROR;
        fprintf(stderr, "Error: Symbol '%s' already defined in line %d. "
                "Check line %d.\n",
                _sym->name, _sym->decl_linenum, node->linenum);
    }

}
