#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include "symbol_table.h"

Symbol *
symbol_new(char const * name)
{
	Symbol * symbol = (Symbol *) malloc (sizeof(Symbol));
	symbol->type = VOID;
	value_set(&symbol->value, symbol->type, NULL);
	symbol->params = -1;
	symbol->param_types = NULL;
	symbol->decl_linenum = 0;
	symbol->is_global = FALSE;
	symbol->stack_index = -1;

	symbol->next = NULL;

	if (name != NULL)
		symbol->name = strdup(name);
	else
		symbol->name = NULL;

	return symbol;
}

/* Insert a symbol in the indicated table.
* in case that the symbol already exists, the memory of 
* the symbol of the set free parameter sera. 
* Returns: The last symbol as parameter, 
* in case that this not yet is in the table, 
* or a hand for the joined symbol. 
*/
Symbol *
symbol_insert(Symbol *symtab, Symbol *symbol)
{
	Symbol *sym;

	if (symbol == NULL)
		return NULL;

	sym = symbol_lookup(symtab, symbol->name);

	if (sym != NULL) {
		free (symbol->name);
		free (symbol);
		return sym;
	}

	symbol->next = symtab->next;
	symtab->next = symbol;

	return symbol;
}

Symbol *
symbol_lookup(Symbol *symtab, char const *name)
{
	Symbol *temp;

	if (symtab == NULL)
		return NULL;

	for(temp = symtab->next; temp != NULL; temp = temp->next) {
		if (!strcmp (temp->name, name))
			return temp;
	}

	return temp;
}

void 
symbol_table_destroy(Symbol *symtab)
{
	Symbol *first;
	Symbol *to_kill;
	first = symtab->next;
	symtab->next = NULL;

	while (first != NULL) {
		to_kill = first;
		if (to_kill->name != NULL)	
			free(to_kill->name);
		free(to_kill);
	}
}

void 
symbol_print(Symbol *symbol)
{
	if (symbol == NULL) {
		printf("NULL\n\n");
		return;
	}

	printf("Symbol: %x\n", (unsigned int)symbol);
	printf("name: %s\n", symbol->name);
	printf("type: %d\n", symbol->type);
	printf("value:");
	value_print(stdout, &symbol->value, symbol->type);
	printf("\ndeclaration line: %d\n", symbol->decl_linenum);
	printf("next: %x\n\n", (unsigned int)symbol->next);
}


void
symbol_table_dump(Symbol *symtab)
{
	Symbol *temp = symtab;
	
	for (temp = symtab->next; temp != NULL; temp = temp->next)
		symbol_print(temp);
}
