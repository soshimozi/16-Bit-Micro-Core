#ifndef SYMBOL_TABLE_H
#define SYMBOL_TABLE_H

#include "base.h"

typedef struct _symbol {
	char *name;
	Type type;
	Value value;
	int decl_linenum;

	// For procedures and functions
	int params;
	Type *param_types;
	
	bool is_global;
	int stack_index;
	struct _symbol *next;
} Symbol;

static Symbol *gloal_symbol_table;

Symbol *symbol_new(char const * name);
Symbol *symbol_lookup(Symbol *symtab, char const *name);
Symbol *symbol_insert(Symbol *symtab, Symbol *symbol);


#endif // SYMBOL_TABLE_H
