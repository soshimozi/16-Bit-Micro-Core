#ifndef BASE_H
#define BASE_H

#define VOID(var)	((void*) &var)
#define IS_LITERAL(k)	(k == BOOL_LITERAL || \
			 k == INT_LITERAL)

typedef enum {
	FALSE = 0,
	TRUE
} bool;

typedef enum TypeEnum {
	ERROR = -1,
	VOID,
	INTEGER,
	BOOLEAN,
} Type;

typedef enum KindEnum {
	NONE_KIND = -1,
	PROGRAM,
	PROGRAM_DECL,
    	VARDECL_LIST,
    	VARDECL,
    	IDENT_LIST,
    	STATEMENT_LIST,
    	ASSIGNMENT_STMT,
    	IF_STMT,
    	WHILE_STMT,
    	FOR_STMT,
    	REL_EXPR,
    	ADD_EXPR,
    	MUL_EXPR,
    	NOTFACTOR,
	//IDENTIFIER defined as token
	//INT_LITERAL, BOOL_LITERAL, CHAR_LITERAL defined as tokens
} Kind;

typedef union {
	int integer;
	bool boolean;
} Value;

char *type_get_lexeme(Type type);
Type type_get_from_lexeme(const char *lexeme);

void value_get(Value *value, Type type, void *val);
void value_set(Value *value, Type type, void *val);

void value_set_from_int(Value *value, int val);
void value_set_from_bool(Value *value, bool val);

void value_print(FILE *file, Value *value, Type type);

#endif // BASE_H

