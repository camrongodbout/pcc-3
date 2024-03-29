/*
 *
 * yacc/bison input for simplified C++ parser
 *
 */

%{

	#include "types.h"
	#include "symtab.h"
	#include "bucket.h"
	#include "message.h"
	#include "tree.h"
	#include "expr.h"
	#include <stdio.h>
	#include "defs.h"

    int yylex();
    int yyerror(char *s);

    STDR_TAG currentScope = GDECL;

    int sizeOfType(TYPETAG type);
    void globalDecl(DN dn, TYPE baseType, TYPE derivedType, BOOLEAN shouldDeclare);
	void GLD(DN dn, TYPE baseType, TYPE derivedType, BOOLEAN shouldDeclare);
	BUCKET_PTR buildBucket(BUCKET_PTR bucketPtr, TYPE_SPECIFIER typeSpec);
%}

%union {
	int	y_int;
	double	y_double;
	char *	y_string;
	TYPE_SPECIFIER y_typeSpec;
	BUCKET_PTR y_bucketPtr;
	ST_ID y_stID;
	DN y_DN;
	PARAM_LIST y_PL;
	BOOLEAN y_ref; // Flag for reference type?

	//Expressions
	OP_UNARY y_unop;
	EN y_EN;

};


%token IDENTIFIER INT_CONSTANT DOUBLE_CONSTANT STRING_LITERAL SIZEOF
%token PTR_OP INC_OP DEC_OP LEFT_OP RIGHT_OP LE_OP GE_OP EQ_OP NE_OP
%token AND_OP OR_OP MUL_ASSIGN DIV_ASSIGN MOD_ASSIGN ADD_ASSIGN
%token SUB_ASSIGN LEFT_ASSIGN RIGHT_ASSIGN AND_ASSIGN
%token XOR_ASSIGN OR_ASSIGN TYPE_NAME

%token TYPEDEF EXTERN STATIC AUTO REGISTER
%token CHAR SHORT INT LONG SIGNED UNSIGNED FLOAT DOUBLE CONST VOLATILE VOID
%token STRUCT UNION ENUM ELIPSIS

%token CASE DEFAULT IF ELSE SWITCH WHILE DO FOR GOTO CONTINUE BREAK RETURN

%token BAD

%start translation_unit
%%

 /*******************************
  * Expressions                 *
  *******************************/

primary_expr
	: identifier { 
		//msg("primary_expr 1"); 
	}
	| INT_CONSTANT { 
		//msg("primary_expr 2");
		////msg("INT_CONSTANT is %d", $<y_int>1);
		
		EN node = createConstantIntExpression($<y_int>1);
		$<y_EN>$ = node;

		// printExpression(node);

		// $<y_int>$ = $<y_int>1;
	}
	| DOUBLE_CONSTANT {
		//msg("primary_expr 3");
		// //msg("DOUBLE CONSTANT is %f", $<y_double>$1);
		
		EN node = createConstantDoubleExpression($<y_double>1);
		$<y_EN>$ = node;

		// printExpression(node);

		// $<y_double>$ = $<y_double>1;
	}
	| STRING_LITERAL {
		//msg("primary_expr 4");
		// //msg("STRING LITERAL is %s", $<y_string>$1);
	}
	| '(' expr ')' {
		//msg("primary_expr 5");
		$<y_EN>$ = $<y_EN>2;
	}
	;

postfix_expr
	: primary_expr { //msg("postfix_expr 1"); 
	}
	| postfix_expr '[' expr ']' { //msg("postfix_expr 2"); 
	}
	| postfix_expr '(' argument_expr_list_opt ')' { //msg("postfix_expr 3"); 
	}
	| postfix_expr '.' identifier { //msg("postfix_expr 4"); 
	}
	| postfix_expr PTR_OP identifier { //msg("postfix_expr 5"); 
	}
	| postfix_expr INC_OP { //msg("postfix_expr 6"); 
	}
	| postfix_expr DEC_OP { //msg("postfix_expr 7"); 
	}
	;

argument_expr_list_opt
	: /* null derive */
	| argument_expr_list
	;

argument_expr_list
	: assignment_expr
	| argument_expr_list ',' assignment_expr
	;

unary_expr
	: postfix_expr { //msg("unary_expr 1"); 
	}
	| INC_OP unary_expr { //msg("unary_expr 2"); 
	}
	| DEC_OP unary_expr { //msg("unary_expr 3"); 
	}
	| unary_operator cast_expr {
		//msg("unary_expr 4"); 
		$<y_EN>$ = createUnaryExpression($<y_unop>1, $<y_EN>2, TRUE);
	}
	| SIZEOF unary_expr { //msg("unary_expr 5"); 
	}
	| SIZEOF '(' type_name ')' { //msg("unary_expr 6"); 
	}
	;

unary_operator
	: '&' { $<y_unop>$ = UNARY_REF; 
	}
	| '*' { $<y_unop>$ = UNARY_DEREF; 
	} 
	| '+' { $<y_unop>$ = UNARY_PLUS; 
	}
	| '-' { $<y_unop>$ = UNARY_MINUS; 
	}
	| '~' { $<y_unop>$ = UNARY_TILDE; 
	}
	| '!' { $<y_unop>$ = UNARY_NOT; 
	}
	;

cast_expr
	: unary_expr 
	| '(' type_name ')' cast_expr
	;

multiplicative_expr
	: cast_expr
	| multiplicative_expr '*' cast_expr
	{
		$<y_EN>$ = createBinaryExpression(BINARY_MULT, $<y_EN>1, $<y_EN>3);
	}
	| multiplicative_expr '/' cast_expr
	{
		$<y_EN>$ = createBinaryExpression(BINARY_DIV, $<y_EN>1, $<y_EN>3);
	}
	| multiplicative_expr '%' cast_expr
	{
		$<y_EN>$ = createBinaryExpression(BINARY_MOD, $<y_EN>1, $<y_EN>3);
	}
	;

additive_expr
	: multiplicative_expr
	| additive_expr '+' multiplicative_expr
	{
		$<y_EN>$ = createBinaryExpression(BINARY_ADD, $<y_EN>1, $<y_EN>3);
	}
	| additive_expr '-' multiplicative_expr
	{
		$<y_EN>$ = createBinaryExpression(BINARY_SUB, $<y_EN>1, $<y_EN>3);
	}
	;

shift_expr
	: additive_expr
	| shift_expr LEFT_OP additive_expr
	{
		$<y_EN>$ = createBinaryExpression(BINARY_SHIFTL, $<y_EN>1, $<y_EN>3);
	}
	| shift_expr RIGHT_OP additive_expr
	{
		$<y_EN>$ = createBinaryExpression(BINARY_SHIFTR, $<y_EN>1, $<y_EN>3);
	}
	;

relational_expr
	: shift_expr 
	| relational_expr '<' shift_expr
	{
		$<y_EN>$ = createBinaryExpression(BINARY_LT, $<y_EN>1, $<y_EN>3);
	}
	| relational_expr '>' shift_expr
	{
		$<y_EN>$ = createBinaryExpression(BINARY_GRT, $<y_EN>1, $<y_EN>3);
	}
	| relational_expr LE_OP shift_expr
	{
		$<y_EN>$ = createBinaryExpression(BINARY_LTE, $<y_EN>1, $<y_EN>3);
	}
	| relational_expr GE_OP shift_expr
	{
		$<y_EN>$ = createBinaryExpression(BINARY_GRTE, $<y_EN>1, $<y_EN>3);
	}
	;

equality_expr
	: relational_expr
	| equality_expr EQ_OP relational_expr
	{
		$<y_EN>$ = createBinaryExpression(BINARY_EQUALS, $<y_EN>1, $<y_EN>3);
	}
	| equality_expr NE_OP relational_expr
	{
		$<y_EN>$ = createBinaryExpression(BINARY_NE, $<y_EN>1, $<y_EN>3);
	}
	;

and_expr
	: equality_expr
	| and_expr '&' equality_expr
	{
		$<y_EN>$ = createBinaryExpression(BINARY_XAND, $<y_EN>1, $<y_EN>3);
	}
	;

exclusive_or_expr
	: and_expr 
	| exclusive_or_expr '^' and_expr
	{
		$<y_EN>$ = createBinaryExpression(BINARY_XNOT, $<y_EN>1, $<y_EN>3);
	}
	;

inclusive_or_expr
	: exclusive_or_expr 
	| inclusive_or_expr '|' exclusive_or_expr
	{
		$<y_EN>$ = createBinaryExpression(BINARY_XOR, $<y_EN>1, $<y_EN>3);
	}
	;

logical_and_expr
	: inclusive_or_expr 
	| logical_and_expr AND_OP inclusive_or_expr
	{
		$<y_EN>$ = createBinaryExpression(BINARY_AND, $<y_EN>1, $<y_EN>3);
	}
	;

logical_or_expr
	: logical_and_expr 
	| logical_or_expr OR_OP logical_and_expr
	{
		$<y_EN>$ = createBinaryExpression(BINARY_OR, $<y_EN>1, $<y_EN>3);
	}
	;

conditional_expr
	: logical_or_expr
	| logical_or_expr '?' expr ':' conditional_expr 
	;

assignment_expr
	: conditional_expr { 
		//msg("assignment_expr expr 1");
		$<y_EN>$ = evaluateExpression($<y_EN>1); 
		printExpression($<y_EN>$);
					   }
	| unary_expr assignment_operator assignment_expr {
		ST_ID left_st_id = $<y_EN>1->u.varStID;
		//msg("Found assignment_expr 2. unary_expr is %s assigment_expr is: %d", st_get_id_str(left_st_id), $<y_EN>3->u.valInt);

		EN returnNode = $<y_EN>1;
		returnNode->u.valInt = $<y_EN>3->u.valInt;
		$<y_EN>$ = returnNode;

		TYPETAG typeTag = getTypeTagFromExpression($<y_EN>3);
		b_assign(typeTag);
	}
	;

assignment_operator
	: '=' | MUL_ASSIGN | DIV_ASSIGN | MOD_ASSIGN | ADD_ASSIGN | SUB_ASSIGN
	| LEFT_ASSIGN | RIGHT_ASSIGN | AND_ASSIGN | XOR_ASSIGN | OR_ASSIGN
	;

expr
	: assignment_expr {//msg("found expr 1");
	}
	| expr ',' assignment_expr {//msg("found expr 2");
	}
	;

constant_expr
	: conditional_expr
	;

expr_opt
	: /* null derive */
	| expr
	;

 /*******************************
  * Declarations                *
  *******************************/

declaration
	: declaration_specifiers ';' { error("no declarator in declaration");}
	| declaration_specifiers init_declarator_list ';' 
	;

declaration_specifiers
	: storage_class_specifier
	| storage_class_specifier declaration_specifiers
	| type_specifier { 
		
		$<y_bucketPtr>$ = buildBucket(NULL, $<y_typeSpec>1);
	}
	| type_specifier declaration_specifiers { 
		
		$<y_bucketPtr>$ = buildBucket($<y_bucketPtr>2, $<y_typeSpec>1);
	}
	| type_qualifier {
		
		$<y_bucketPtr>$ = buildBucket(NULL, $<y_typeSpec>1);
	}
	| type_qualifier declaration_specifiers {
		
		$<y_bucketPtr>$ = buildBucket($<y_bucketPtr>2, $<y_typeSpec>1);
	}
	;

init_declarator_list
	: init_declarator { 
		
		////msg("In init_declarator");
		// print_tree($<y_DN>1);

		TYPE baseType = build_base($<y_bucketPtr>0);
		TYPE derivedType = building_derived_type_and_install_st($<y_DN>1, baseType, currentScope);
		GLD($<y_DN>1, baseType, derivedType, installSuccessful);
	}
	| init_declarator_list ',' init_declarator {
		
		////msg("In init_declarator");
		// building_derived_type_and_install_st($<y_DN>3, build_base($<y_bucketPtr>0));
		TYPE baseType = build_base($<y_bucketPtr>0);
		TYPE derivedType = building_derived_type_and_install_st($<y_DN>3, baseType, currentScope);
		GLD($<y_DN>3, baseType, derivedType, installSuccessful);
	}
	;

init_declarator
	: declarator 
	| declarator '=' initializer {
		//msg("here1");
	}
	;

storage_class_specifier	
	: TYPEDEF | EXTERN | STATIC | AUTO | REGISTER
	;

type_specifier
	: VOID { $<y_typeSpec>$ = VOID_SPEC;} 
	| CHAR { $<y_typeSpec>$ = CHAR_SPEC;} 
	| SHORT { $<y_typeSpec>$ = SHORT_SPEC;} 
	| INT { $<y_typeSpec>$ = INT_SPEC;} 
	| LONG { $<y_typeSpec>$ = LONG_SPEC;}
	| FLOAT { $<y_typeSpec>$ = FLOAT_SPEC;} 
	| DOUBLE { $<y_typeSpec>$ = DOUBLE_SPEC;} 
	| SIGNED { $<y_typeSpec>$ = SIGNED_SPEC;} 
	| UNSIGNED { $<y_typeSpec>$ = UNSIGNED_SPEC;}
	| struct_or_union_specifier { $<y_typeSpec>$ = STRUCT_SPEC;}
	| enum_specifier { $<y_typeSpec>$ = ENUM_SPEC;}
	| TYPE_NAME { $<y_typeSpec>$ = TYPENAME_SPEC;}
	;

struct_or_union_specifier
	: struct_or_union '{' struct_declaration_list '}'
	| struct_or_union identifier '{' struct_declaration_list '}'
	| struct_or_union identifier
	;

struct_or_union
	: STRUCT
	| UNION
	;

struct_declaration_list
	: struct_declaration
	| struct_declaration_list struct_declaration
	;

struct_declaration
	: specifier_qualifier_list struct_declarator_list ';'
	;

specifier_qualifier_list
	: type_specifier specifier_qualifier_list_opt
	| type_qualifier specifier_qualifier_list_opt
	;

specifier_qualifier_list_opt
	: /* null derive */ {
		////msg("Found *");
	}
	| specifier_qualifier_list 
	;

struct_declarator_list
	: struct_declarator
	| struct_declarator_list ',' struct_declarator
	;

struct_declarator
	: declarator
	| ':' constant_expr
	| declarator ':' constant_expr
	;

enum_specifier
	: ENUM '{' enumerator_list '}'
	| ENUM identifier '{' enumerator_list '}'
	| ENUM identifier
	;

enumerator_list
	: enumerator
	| enumerator_list ',' enumerator
	;

enumerator
	: identifier
	| identifier '=' constant_expr {
		//msg("here2");
	}
	;

type_qualifier
	: CONST { 
		$<y_typeSpec>$ = CONST_SPEC;
	}
	| VOLATILE {
		$<y_typeSpec>$ = VOLATILE_SPEC;
	}
	;

declarator
	: direct_declarator
	| pointer declarator {
		
		//if($<y_ref>1 == TRUE)
			////msg("Reference passed");
		//else;
			////msg("Found 'pointer declarator'");
		$<y_DN>$ = makePtrNode($<y_DN>2, $<y_ref>1);
		//}
	}
	;

direct_declarator
	: identifier
	| '(' declarator ')' { 
		////msg("Found ( declarator )");
		$<y_DN>$ = $<y_DN>2;
	}
	| direct_declarator '[' ']'
	| direct_declarator '[' constant_expr ']' { 
			$<y_DN>$ = makeArrayNode($<y_DN>1, getIntFromExpression($<y_EN>3));
	}
	| direct_declarator '(' parameter_type_list ')' {
			if(checkParam($<y_PL>3))
				$<y_DN>$ = makeFnNode($<y_DN>1, $<y_PL>3);
			else
				$<y_DN>$ = NULL;
	}
	| direct_declarator '(' ')' {
		$<y_DN>$ = makeFnNode($<y_DN>1, NULL);
	}
	| direct_declarator '(' identifier_list ')'
	;

pointer
	: '*' specifier_qualifier_list_opt
		  { $<y_ref>$ = FALSE; }
   	| '&' { $<y_ref>$ = TRUE;}
	;

parameter_type_list
	: parameter_list	{ $<y_PL>$ = $<y_PL>1;}
	| parameter_list ',' ELIPSIS { error("Elipsis not allowed"); }
	;

parameter_list
	: parameter_declaration	{
			$<y_PL>$ = $<y_PL>1;
			$<y_PL>$->prev = $<y_PL>1;
	}
	| parameter_list ',' parameter_declaration {
		if(($<y_PL>3 == NULL) || $<y_PL>1 == NULL)
			$<y_PL>$ = NULL;
		else {
			$<y_PL>$ = linkParams($<y_PL>1, $<y_PL>3);
		}
	}
	;

parameter_declaration
	: declaration_specifiers declarator {
		TYPE baseType = build_base($<y_bucketPtr>1);
		$<y_PL>$ = build_Param($<y_DN>2, baseType, NULL);
	}
	| declaration_specifiers { error("no id in parameter list"); $<y_PL>$ = NULL; }
	| declaration_specifiers abstract_declarator
	;

identifier_list
	: identifier
	| identifier_list ',' identifier
	;

type_name
	: specifier_qualifier_list
	| specifier_qualifier_list abstract_declarator
	;

abstract_declarator
	: pointer
	| direct_abstract_declarator
	| pointer abstract_declarator
	;

direct_abstract_declarator
	: '(' abstract_declarator ')'
	| '[' ']'
	| '[' constant_expr ']'
	| direct_abstract_declarator '[' ']'
	| direct_abstract_declarator '[' constant_expr ']'
	| '(' ')'
	| '(' parameter_type_list ')'
	| direct_abstract_declarator '(' ')'
	| direct_abstract_declarator '(' parameter_type_list ')'
	;

initializer
	: assignment_expr
	| '{' initializer_list comma_opt '}'
	;

comma_opt
	: /* Null derive */
	| ','
	;

initializer_list
	: initializer
	| initializer_list ',' initializer
	;

 /*******************************
  * Statements                  *
  *******************************/

statement
	: labeled_statement {//msg("found statement 6");
	}
	| { st_enter_block(); } compound_statement {//msg("found statement 1"); currentScope = LDECL; st_exit_block();
	}
	| expression_statement {//msg("found statement 2");
	}
	| selection_statement {//msg("found statement 3");
	}
	| iteration_statement {//msg("found statement 4");
	}
	| jump_statement {//msg("found statement 5");
	}
	;

labeled_statement
	: identifier ':' statement
	| CASE constant_expr ':' statement
	| DEFAULT ':' statement
	;

compound_statement
	: '{' '}'
	| '{' statement_list '}' {//msg("found compound_statement 1");
	}
	| '{' declaration_list '}' {//msg("found compound_statement 2");
	}
	| '{' declaration_list statement_list '}' {//msg("found compound_statement 3");
	}
	;

declaration_list
	: declaration
	| declaration_list declaration
	;

statement_list
	: statement { //msg("found statement_list 1");
	}
	| statement_list statement { //msg("found statement_list 2");
	}
	;

expression_statement
	: expr_opt ';' {
		// TODO: emit assembly code, output value of expression
		//msg("expr_opt ';' value is: %d", $<y_EN>1->u.valInt);
	}
	;

selection_statement
	: IF '(' expr ')' statement
	| IF '(' expr ')' statement ELSE statement
	| SWITCH '(' expr ')' statement
	;

iteration_statement
	: WHILE '(' expr ')' statement
	| DO statement WHILE '(' expr ')' ';'
	| FOR '(' expr_opt ';' expr_opt ';' expr_opt ')' statement
	;

jump_statement
	: GOTO identifier ';'
	| CONTINUE ';'
	| BREAK ';'
	| RETURN expr_opt ';'
	;

 /*******************************
  * Top level                   *
  *******************************/

translation_unit
	: external_declaration
	| translation_unit external_declaration
	;

external_declaration
	: function_definition
	| declaration
	;

function_definition
	: declarator compound_statement {
		//fprintf(stderr, "inside function_definition w {}\n");
	}
	| declaration_specifiers declarator compound_statement {
		//fprintf(stderr, "inside function_definition w {}\n");
	}
	;

 /*******************************
  * Identifiers                 *
  *******************************/

identifier
	: IDENTIFIER { 
		// Do a symbol table lookup to see if identifier has already been defined
		ST_ID st_id = st_lookup_id($<y_string>1);
		if (st_id != NULL) {
			// identifier has already been defined in symtab.

			int block;
			ST_DR dr = st_lookup(st_id, &block);
			int value = dr->u.econst.val;
			//msg("Found INDENTIFIER; %s already exists in symtab with value %d !", $<y_string>1, value);

			$<y_EN>$ = createVariableExpression(st_id);
		} 
		else {
			//msg("Found IDENTIFIER; Enrolling %s",$<y_string>1); 
			ST_ID varName = st_enter_id($<y_string>1);
			$<y_DN>$ = makeIdNode(varName);
		}
	}
	;
%%

extern int column;

int sizeOfType(TYPETAG type)
{
	int returnedSizeOf = -1;

	returnedSizeOf = get_size_basic(type);

	return returnedSizeOf;
}

void globalDecl(DN dn, TYPE baseType, TYPE derivedType, BOOLEAN shouldDeclare)
{
	if(!shouldDeclare)
		return;

	// fprintf(stderr, "Base | Derived: %d | %d\n", ty_query(baseType), ty_query(derivedType));

	//Get the id from the Symbol Table
	char* id = st_get_id_str( getSTID(dn) );
	// fprintf(stderr, "ID: %s\n", id);

	unsigned int size = 0;
	if(ty_query(derivedType) == TYARRAY)
	{//For Arrays

		//Then we want to create the size in bytes of the base type
		size = sizeOfType(ty_query(baseType));

		//Queries the array to return the size of the array
		unsigned int sizeOfArray;
		DIMFLAG aDimFlag;
		ty_query_array(derivedType, &aDimFlag, &sizeOfArray);

		// fprintf(stderr, "size of the array: %d\n", sizeOfArray);

		//Allocate for arrays
		b_global_decl(id, size, size*sizeOfArray);
		b_skip(size*sizeOfArray); //Only for no Initialization pieces


		//TODO: CHECK FOR MULTIPLE ARRAYS: int x[10][1000];

	}
	else if(ty_query(derivedType) == TYFUNC)
	{//For Functions, Do we even allocate for the back end data?
		//Maybe b_func_epilogue(char *);

	}
	else
	{
		size = sizeOfType(ty_query(derivedType));
		b_global_decl(id, size, size);
		b_skip(size);
		//b_alloc_int, double, etc....;
	}


}
void GLD(DN dn, TYPE baseType, TYPE derivedType, BOOLEAN shouldDeclare)
{
		if(!shouldDeclare)
			return;
		// if very last node is a pointer always will return align 4 size 4
		BOOLEAN funcFlag = FALSE;
		int align = sizeOfType(ty_query(baseType));
		int size = 0;
		int array_total = 1;
		char* id; 
		while(dn != NULL)
		{
			switch(dn->tag) {
			case ARRAY:
				if(dn->u.array_dim.dim <= 0)
				{
					return;
				}
				array_total *= dn->u.array_dim.dim;
				break;
			case PTR:
				align = 4;
				size = 4;
				array_total = 1;
				break;
			case FUNC:
				if(dn->n_node->tag == ID)
					funcFlag = TRUE;
				break;
			case REF:
				break;
			case ID:
				if(funcFlag)
					return;
				else
				{
					id = st_get_id_str( getSTID(dn) );
					size = array_total * align;
				}
				break;
			default:
				bug("where's the tag? \"stdr_dump\"");
				
			}
	
		dn = dn->n_node;
		}
		b_global_decl(id, align, size);
		b_skip(size);
}
int yyerror(char *s)
{
	error("%s (column %d)",s,column);
        return 0;  /* never reached */
}

BUCKET_PTR buildBucket(BUCKET_PTR bucketPtr, TYPE_SPECIFIER typeSpec) {
	BUCKET_PTR updatedBucket = update_bucket(bucketPtr, typeSpec, NULL);
	if (is_error_decl(updatedBucket)) {

		//error("Semantic error");
	}

	return updatedBucket;
}