#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include "graphprinter_visitor.h"

static void _print_arrow(struct AstNode *node);
static void _print_symbol_table(struct AstNode *node);
static void _print_symbols(Symbol *symbol);

Visitor *
graphprinter_new()
{
    Visitor *visitor = (Visitor *) malloc (sizeof(Visitor));

    visitor->visit_program = &graphprinter_visit_program;
    visitor->visit_programdecl = &graphprinter_visit_programdecl;
    visitor->visit_vardecl_list = &graphprinter_visit_vardecl_list;
    visitor->visit_vardecl = &graphprinter_visit_simplenode;
    visitor->visit_identifier_list = &graphprinter_visit_identifier_list;
    visitor->visit_statement_list = &graphprinter_visit_statement_list;
    visitor->visit_assignment_stmt = &graphprinter_visit_simplenode;
    visitor->visit_if_stmt = &graphprinter_visit_simplenode;
    visitor->visit_while_stmt = &graphprinter_visit_simplenode;
    visitor->visit_for_stmt = &graphprinter_visit_simplenode;
    visitor->visit_rel_expr = &graphprinter_visit_binary_expr;
    visitor->visit_add_expr = &graphprinter_visit_binary_expr;
    visitor->visit_mul_expr = &graphprinter_visit_binary_expr;
    visitor->visit_notfactor = &graphprinter_visit_simplenode;
    visitor->visit_identifier = &graphprinter_visit_identifier;
    visitor->visit_literal = &graphprinter_visit_literal;
    visitor->visit_add_op = NULL;
    visitor->visit_mul_op = NULL;
    visitor->visit_rel_op = NULL;
    visitor->visit_not_op = NULL;

    return visitor;
}

void
graphprinter_visit_program(struct _Visitor *visitor, struct AstNode *node)
{
    printf("/* toypasc AST graph. */\n");
    printf("digraph {\n");

    printf("\tremincross=true;\n");
    printf("\tordering=out;\n");
    printf("\tcompound=true;\n");
    printf("\tranksep=1.0;\n");
    printf("\tnode [fontsize=11,fontname=Courier];\n");
    printf("\tedge [color="COLOR_EDGE_GROUP"];\n\n");

    printf("\tnode_%x [label=\"%s\",fontsize=16,fontname=Courier,",
           (unsigned int)node, node->name);
    printf("style=filled,color=black,fillcolor="COLOR_FILL_GLOBAL"];\n");

    _print_symbol_table(node);

    ast_node_accept_children(node->children, visitor);

    printf("}\n");
}

void
graphprinter_visit_simplenode (struct _Visitor *visitor, struct AstNode *node)
{
    _print_arrow(node);
    printf("\tnode_%x [label=\"%s\\n[line: %d]\",style=filled,",
           (unsigned int)node, node->name, node->linenum);
    printf("fillcolor="COLOR_FILL_COMMON",color=%s];\n",
           (node->type == ERROR) ? COLOR_EDGE_ERROR : COLOR_FILL_COMMON);
    ast_node_accept_children(node->children, visitor);
}

void
graphprinter_visit_programdecl(struct _Visitor *visitor, struct AstNode *node)
{
    _print_arrow(node);
    printf("\tnode_%x [label=\"%s\\n[line: %d]\",style=filled,",
           (unsigned int)node, node->name, node->linenum);
    printf("color="COLOR_EDGE_GROUP",fillcolor="COLOR_FILL_COMMON"];\n");
    ast_node_accept(node->children, visitor);
    printf("\tnode_%x -> symbol_%x [color=lightgray];\n", (unsigned int)node->children, (unsigned int)node->children->symbol);
}

void
graphprinter_visit_vardecl_list (struct _Visitor *visitor, struct AstNode *node)
{
    _print_arrow(node);
    printf("\tnode_%x [label=\"%s\",style=filled,", (unsigned int)node, node->name);
    printf("color="COLOR_EDGE_GROUP",fillcolor="COLOR_FILL_COMMON"];\n");
    printf("\nsubgraph cluster_%x {\n\tstyle=dotted;\n", (unsigned int)node);
    ast_node_accept_children(node->children, visitor);
    printf("}\n\n");
}

void
graphprinter_visit_identifier_list (struct _Visitor *visitor, struct AstNode *node)
{
    _print_arrow(node);
    printf("\tnode_%x [label=\"%s\",style=filled,", (unsigned int)node, node->name);
    printf("color="COLOR_EDGE_GROUP",fillcolor="COLOR_FILL_COMMON"];\n");
    printf("\nsubgraph cluster_%x {\n\tstyle=dotted;\n", (unsigned int)node);
    ast_node_accept_children(node->children, visitor);
    printf("}\n\n");
}

void
graphprinter_visit_statement_list (struct _Visitor *visitor, struct AstNode *node)
{
    _print_arrow(node);
    printf("\tnode_%x [label=\"%s\",style=filled,", (unsigned int)node, node->name);
    printf("color="COLOR_EDGE_GROUP",fillcolor="COLOR_FILL_COMMON"];\n");
    printf("\nsubgraph cluster_%x {\n\tstyle=dotted;\n", (unsigned int)node);
    ast_node_accept_children(node->children, visitor);
    printf("}\n\n");
}

void
graphprinter_visit_binary_expr (struct _Visitor *visitor, struct AstNode *node)
{
    _print_arrow(node);
    printf("\tnode_%x [label=\"%s\\n'%s'\",style=filled,",
           (unsigned int)node, node->name, node->children->sibling->name);
    printf("fillcolor="COLOR_FILL_COMMON",color=%s];\n",
           (node->type == ERROR) ? COLOR_EDGE_ERROR : COLOR_FILL_COMMON);
    ast_node_accept_children(node->children, visitor);
}

void
graphprinter_visit_identifier (struct _Visitor *visitor, struct AstNode *node)
{
    _print_arrow(node);

    printf("\tnode_%x [label=\"", (unsigned int)node);

    if (node->symbol->decl_linenum == 0)
        printf("UNDECLARED\\n");

    printf("%s\\n'%s'\\n<%s>\",style=filled,color=",
           node->name, node->symbol->name, type_get_lexeme(node->type));

    if (node->symbol->decl_linenum == 0)
        printf(COLOR_EDGE_ERROR);
    else if (node->symbol->is_global)
        printf(COLOR_FILL_GLOBAL);
    else
        printf(COLOR_FILL_LOCAL);

    printf(",fillcolor=");

    if (node->symbol->is_global)
        printf(COLOR_FILL_GLOBAL);
    else
        printf(COLOR_FILL_LOCAL);

    printf("];\n");
}

void
graphprinter_visit_literal (struct _Visitor *visitor, struct AstNode *node)
{
    printf("\tnode_%x -> literal_%x;\n", (unsigned int)node->parent, (unsigned int)node);
    printf("\tliteral_%x [label=\"", (unsigned int)node);
    value_print(stdout, &node->value, node->type);
    printf("\\n<%s>\",style=filled,color="COLOR_FILL_LITERAL"];\n",
           node->name, type_get_lexeme(node->type));
    ast_node_accept_children(node->children, visitor);
}

// Helper functions ----------------------------------------------------------

static void
_print_arrow(struct AstNode *node)
{
    printf("\tnode_%x -> node_%x [label=\"%d\",",
           (unsigned int)node->parent, (unsigned int)node, ast_node_get_child_counter(node->parent));
    printf("fontsize=11,fontname=Courier];\n");
}

static void
_print_symbol_table(struct AstNode *node)
{
    if (node->symbol->next == NULL)
        return;

    printf("\tnode_%x -> symbol_%x [lhead=cluster_symtab_%x,color=",
           (unsigned int)node, (unsigned int)node->symbol->next, (unsigned int)node);
    if (node->parent == NULL)
        printf("black];\n");
    else
        printf("blue];\n");

    printf("\n\tsubgraph cluster_symtab_%x {\n", (unsigned int)node);

    if (node->parent == NULL)
        printf("\t\tcolor=black;\n");
    else
        printf("\t\tcolor=blue;\n");

    printf("\t\tstyle=filled;\n\t\tfillcolor="COLOR_FILL_GLOBAL";\n\t\tfontname=Courier;\n");
    printf("\t\tnode [style=filled,color=white,fillcolor="COLOR_FILL_SYMBOL"];\n");

    _print_symbols(node->symbol->next);

    printf("\t}\n\n");
}

static void
_print_symbols(Symbol *symbol)
{
    if (symbol == NULL)
        return;

    if (symbol->name != NULL) {
        printf("\t\tsymbol_%x [shape=record,label=\"{", (unsigned int)symbol);
        printf("Symbol|Address: 0x%x\\l|lexeme: %s\\l|", (unsigned int)symbol, symbol->name);
        printf("type: %s\\l}\"", type_get_lexeme(symbol->type));
        printf(",style=filled,color=white,fillcolor="COLOR_FILL_SYMBOL"];\n");

        if (symbol->next != NULL)
            printf("\tsymbol_%x -> symbol_%x;\n", (unsigned int)symbol, (unsigned int)symbol->next);

    }

    _print_symbols(symbol->next);
}

