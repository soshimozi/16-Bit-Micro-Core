#ifndef TYPECHECK_VISITOR_H
#define TYPECHECK_VISITOR_H

#include "ast.h"
#include "base.h"
#include "symbol_table.h"

//static bool is_vardecl = FALSE;
static Type declared_type = VOID;
static Symbol *symtab;
static Symbol *global_symtab;

Visitor *typecheck_new();

void typecheck_visit_program (struct _Visitor *, struct AstNode *);
void typecheck_visit_programdecl (struct _Visitor *, struct AstNode *);
void typecheck_visit_vardecl_list (struct _Visitor *, struct AstNode *);
void typecheck_visit_vardecl (struct _Visitor *, struct AstNode *);
void typecheck_visit_statement_list (struct _Visitor *, struct AstNode *);
void typecheck_visit_assignment_stmt(struct _Visitor *, struct AstNode *);
void typecheck_visit_if_stmt (struct _Visitor *, struct AstNode *);
void typecheck_visit_for_stmt (struct _Visitor *, struct AstNode *);
void typecheck_visit_while_stmt (struct _Visitor *, struct AstNode *);
void typecheck_visit_for_stmt (struct _Visitor *, struct AstNode *);
void typecheck_visit_binary_expr (struct _Visitor *, struct AstNode *);
void typecheck_visit_notfactor (struct _Visitor *, struct AstNode *);
void typecheck_visit_identifier_list (struct _Visitor *, struct AstNode *);
void typecheck_visit_identifier (struct _Visitor *, struct AstNode *);

#endif // TYPECHECK_VISITR_H

