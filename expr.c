#include "expr.h"


/***************** Create Functions ***************/
EN createConstantIntExpression(const int val)
{
	//msg("Creating const int expr: %d", val);

	//msg("sizeof EN and EXPR_NODE: %d | %d", sizeof(EN), sizeof(EXPR_NODE));

	EN expression = (EN) malloc(sizeof(EXPR_NODE));

	expression->tag = TAG_CONST_INTEGER;
	expression->u.valInt = val;

	// Push the int onto the stack
	b_push_const_int(val);

	return expression;
}

EN createConstantDoubleExpression(const double val)
{
	//msg("Creating const double expr: %f", val);

	EN expression = (EN) malloc(sizeof(EXPR_NODE));

	expression->tag = TAG_CONST_DOUBLE;
	expression->u.valDouble = val;

	// Push the double onto the stack
	b_push_const_double(val);

	return expression;
}

EN createVariableExpression(ST_ID varStID)
{
	//msg("Creating variable expr");

	EN expression = (EN) malloc(sizeof(EXPR_NODE));

	expression->tag = TAG_VARIABLE;
	expression->u.varStID = varStID;

	// Push the variable to the stack
	int block;
	if (st_tag_lookup(varStID, &block)->tag == GDECL) { // if global:
		//msg("\tvar is global");
		b_push_ext_addr(st_get_id_str(varStID)); // push the variable on the stack
	}
	else if (st_tag_lookup(varStID, &block)->tag == PDECL || st_tag_lookup(varStID, &block)->tag == LDECL) { // if local:
		//msg("\tvar is local");
		// TODO: offset
		int offset; // ???
		b_push_loc_addr(offset); // push offset on the stack
	}

	return expression;
}

EN createFunctionExpression(ST_ID funStID, PARAM_LIST pl)
{
	//msg("Creating function expr");

	EN expression = (EN) malloc(sizeof(EXPR_NODE));

	expression->tag = TAG_FUNCTION;
	expression->u.func.id = funStID;
	expression->u.func.pl = pl;

	return expression;
}

EN createUnaryExpression(OP_UNARY op, EN operand, BOOLEAN prefix)
{
	//msg("Creating unary expr");

	EN expression = (EN) malloc(sizeof(EXPR_NODE));

	expression->tag = TAG_UNARY;
	expression->u.unop.op = op;
	expression->u.unop.operand = operand;
	expression->u.unop.prefix = prefix;		//For prefix vs. postfix operators

	// fprintf(stderr, "Creating Unary: %ld\n", evalExpression(expression->u.unop.operand));

	return expression;
}

EN createBinaryExpression(OP_BINARY op, EN left, EN right)
{
	//msg("Creating binary expr OP_BINARY: %d", op);

	EN expression = (EN) malloc(sizeof(EXPR_NODE));

	expression->tag = TAG_BINARY;
	expression->u.binop.op = op;
	expression->u.binop.leftOperand = left;
	expression->u.binop.rightOperand = right;

	return expression;
}
/***************** Create Functions ***************/

/***************** Eval Expressions ***************/
EN evaluateExpression(EN expr)
{
	//Expr should never be null.
	//msg("in eval expression");
	//printExpression(expr);
	switch(expr->tag)
	{
		case TAG_CONST_INTEGER:
		case TAG_CONST_DOUBLE:
			return expr;

		case TAG_FUNCTION:
		//TODO:
			bug("haven't implemented function expressions yet");
			break;

		case TAG_VARIABLE:
			return evalVariableExpression(expr);

		case TAG_UNARY:
			return evalUnaryExpression(expr);
		
		case TAG_BINARY:
			return evalBinaryExpression(expr);

		default:
			bug("Where's the expression tag in evaluateExpression?");
	}
	//For Default
	return NULL;
}

EN evalIntExpression(EN node)
{
	return node;
	//return node->u.valInt;
}

EN evalDoubleExpression(EN node)
{
	return node;
	//return node->u.valDouble;
}

EN evalVariableExpression(EN node)
{
	ST_ID st_id = node->u.varStID;
	char* identifier = st_get_id_str(st_id);
	//msg("Evaluating Variable: %s", identifier);

	EN returnedNode = (EN) malloc(sizeof(EXPR_NODE));
	

	int block;
	ST_DR st_dr = st_lookup(node->u.varStID, &block);



	//msg("st_dr->u.decl.type: %d TYSIGNEDINT: %d TYDOUBLE: %d", ty_query(st_dr->u.decl.type), TYSIGNEDINT, TYDOUBLE);
	if (ty_query(st_dr->u.decl.type) == TYSIGNEDINT) {
		returnedNode->tag = TAG_CONST_INTEGER;
		b_deref(TYSIGNEDINT);
	}
	else if (ty_query(st_dr->u.decl.type) == TYDOUBLE) {
		returnedNode->tag = TAG_CONST_DOUBLE;
		b_deref(TYDOUBLE);
	}
	else {
		bug("Error in evalVariableExpression. No matching tag.");
	}
	
	return returnedNode;
}

EN evalFunctionExpression(EN node)
{//TODO:
	return node;
}

EN evalUnaryExpression(EN node)
{
	EN returnedNode = NULL;

	EN expr = NULL;
//msg("here");

	switch(node->u.unop.op)
	{
		//TODO:
		case UNARY_DEREF: 		//*ptr
			//
			//msg("here1");
			break;
		case UNARY_REF:			//&identifier
		//msg("here2");
			break;

		case UNARY_PLUS:		//+3
		//msg("here3");
			returnedNode = evaluateExpression(node->u.unop.operand);
			break;

		case UNARY_MINUS:		//-1
		//msg("here4");
			expr = evaluateExpression(node->u.unop.operand);
			if(isIntExpression(expr) == TRUE)
			{
				expr->u.valInt = -1 * expr->u.valInt;
				returnedNode = expr;
			}
			else if(isDoubleExpression(expr) == TRUE)
			{
				expr->u.valDouble = -1 * expr->u.valDouble;
				returnedNode = expr;
			}
			else if(isVariableExpression(expr) == TRUE)
			{
				//TODO:
			}
			else
				error("Illegal Unary Minus in expression");
			break;

		//TODO:
		case UNARY_INCREMENT:	//i++ or ++i
		//msg("here5");
			break;
		case UNARY_DECREMENT:	//i-- or --i
		//msg("here6");
			break;
		
		case UNARY_NOT:			//!true
		//msg("here7");
			expr = evaluateExpression(node->u.unop.operand);
			if(isIntExpression(expr) == TRUE)
			{
				if(getIntFromExpression(expr) == 0) //!false == true
					expr->u.valInt = TRUE;	
				else								//!true == false
					expr->u.valInt = FALSE;
			}
			else
			{
				error("Cannot Perform !(expr) becuase of invalid type");
			}
			break;

		case UNARY_TILDE:		//~ bitwise not
			break;
		case UNARY_DOT:			//a.b()
			break;
		case UNARY_PTR_OP:		//a->b()
			break;

		case UNARY_CAST:		// (double) x
			break;

		//Might not be needed
		case UNARY_PAREN:		// (a)
			break;
		case UNARY_BRACKETS:	//a[10]
			break;

		default:
			bug("Wheres the unary operator in the expression?");
	}
	
/*	if (isIntExpression(returnedNode)) {
		b_push_const_int(returnedNode->u.valInt);
	}
	else if (isDoubleExpression(returnedNode)) {
		b_push_const_double(returnedNode->u.valDouble);
	}*/

	return returnedNode;
}

EN evalBinaryExpression(EN node)
{
	EN evaluated = NULL;
	EN evalLeft = NULL;
	EN evalRight = NULL;

	switch(node->u.binop.op)
	{
		/*** BINARY_ASSIGNMENT not needed, since assignment is handled in the grammar (though this may be incorrect)***		

		case BINARY_ASSIGNMENT:  // a = EXPR
		//TODO: Complete the rest of the logic
		//Set the left operand to be the evlauted expression of the right operand


			evalRight = evaluateExpression(node->u.binop.rightOperand);
			
			//Lookup left operand: node->u.binop.leftOperand..
			//set that value to be == the evalRight...

			printExpression(evalRight);
			evaluated = evalRight;

			break;
		***/

		case BINARY_MULT: 	// a * b

			evalLeft = evaluateExpression(node->u.binop.leftOperand);
			evalRight = evaluateExpression(node->u.binop.rightOperand);


			if(isDoubleExpression(evalLeft) || isDoubleExpression(evalRight))
			{
				//Make evaluated be Double Expression After Multiplying.
/*				evalLeft->u.valDouble = getDoubleFromExpression(evalLeft) 
											* getDoubleFromExpression(evalRight);*/
				evalLeft->tag = TAG_CONST_DOUBLE;
				evaluated = evalLeft;
				b_arith_rel_op (B_MULT, TYDOUBLE);
			}
			else if(isIntExpression(evalLeft) && isIntExpression(evalRight))
			{
				//Make evaluated be Integer Expression after Multiplying.
/*				evalLeft->u.valInt = getIntFromExpression(evalLeft)
											* getIntFromExpression(evalRight);*/
				evalLeft->tag = TAG_CONST_INTEGER;
				evaluated = evalLeft;
				b_arith_rel_op (B_MULT, TYSIGNEDINT);
			}
			else
			{
				error("Cannot multiply these two expressions");
			}
				

			break;

		case BINARY_DIV:		// a / 


			evalLeft = evaluateExpression(node->u.binop.leftOperand);
			evalRight = evaluateExpression(node->u.binop.rightOperand);

			//msg("%d, %d Doubles?", isDoubleExpression(evalLeft), isDoubleExpression(evalRight));
			if(isDoubleExpression(evalLeft) || isDoubleExpression(evalRight))
			{
				// //msg("%f, %f vals?", evalLeft->u.valInt, evalRight->u.valDouble);
				//msg("%f, %f vals?", getDoubleFromExpression(evalLeft), getDoubleFromExpression(evalRight));
				//Make evaluated be Double Expression After Multiplying.
/*				evalLeft->u.valDouble = getDoubleFromExpression(evalLeft) 
											/ getDoubleFromExpression(evalRight);*/
				evalLeft->tag = TAG_CONST_DOUBLE;
				evaluated = evalLeft;
				b_arith_rel_op (B_DIV, TYDOUBLE);
			}
			else if(isIntExpression(evalLeft) && isIntExpression(evalRight))
			{
				//Make evaluated be Integer Expression after Multiplying.
/*				evalLeft->u.valInt = getIntFromExpression(evalLeft)
											/ getIntFromExpression(evalRight);*/
				evalLeft->tag = TAG_CONST_INTEGER;
				evaluated = evalLeft;
				b_arith_rel_op (B_DIV, TYSIGNEDINT);
			}
			else
			{
				error("Cannot divide these two expressions");
			}
			break;

		case BINARY_MOD:		// a % b

			evalLeft = evaluateExpression(node->u.binop.leftOperand);
			evalRight = evaluateExpression(node->u.binop.rightOperand);


			if(isIntExpression(evalLeft) && isIntExpression(evalRight))
			{
				//Make evaluated be Integer Expression after Modulo Operator.
			}
			else
			{
				error("Cannot mod these two expressions");
			}

			break;

		case BINARY_ADD:		// a + b
			
			evalLeft = evaluateExpression(node->u.binop.leftOperand);
			evalRight = evaluateExpression(node->u.binop.rightOperand);

			if(isDoubleExpression(evalLeft) || isDoubleExpression(evalRight))
			{
				//Make evaluated be Double Expression After Multiplying.
/*				evalLeft->u.valDouble = getDoubleFromExpression(evalLeft) 
											+ getDoubleFromExpression(evalRight);*/
				evalLeft->tag = TAG_CONST_DOUBLE;
				evaluated = evalLeft;
				b_arith_rel_op (B_ADD, TYDOUBLE);
			}
			else if(isIntExpression(evalLeft) && isIntExpression(evalRight))
			{
				//Make evaluated be Integer Expression after Multiplying.
/*				evalLeft->u.valInt = getIntFromExpression(evalLeft)
											+ getIntFromExpression(evalRight);*/
				evalLeft->tag = TAG_CONST_INTEGER;
				evaluated = evalLeft;
				b_arith_rel_op (B_ADD, TYSIGNEDINT);
			}
			else
			{
				error("Cannot add these two expressions");
			}

			break;

		case BINARY_SUB:		// a - b

			evalLeft = evaluateExpression(node->u.binop.leftOperand);
			evalRight = evaluateExpression(node->u.binop.rightOperand);


			if(isDoubleExpression(evalLeft) || isDoubleExpression(evalRight))
			{
				//Make evaluated be Double Expression After Multiplying.
/*				evalLeft->u.valDouble = getDoubleFromExpression(evalLeft) 
											- getDoubleFromExpression(evalRight);*/
				evalLeft->tag = TAG_CONST_DOUBLE;
				evaluated = evalLeft;
				b_arith_rel_op (B_SUB, TYDOUBLE);
			}
			else if(isIntExpression(evalLeft) && isIntExpression(evalRight))
			{
				//Make evaluated be Integer Expression after Multiplying.
/*				evalLeft->u.valInt = getIntFromExpression(evalLeft)
											- getIntFromExpression(evalRight);*/
				evalLeft->tag = TAG_CONST_INTEGER;
				evaluated = evalLeft;
				b_arith_rel_op (B_SUB, TYSIGNEDINT);
			}
			else
			{
				error("Cannot sub these two expressions");
			}

			break;

		case BINARY_SHIFTL:	// a << b
		case BINARY_SHIFTR:	// a >> b
			break;

		//Boolean Comparators
		case BINARY_LT:		// a < b
			
			evalLeft = evaluateExpression(node->u.binop.leftOperand);
			evalRight = evaluateExpression(node->u.binop.rightOperand);

			//Make evaluated be int Expression After comparing
			if(isDoubleExpression(evalLeft) || isDoubleExpression(evalRight))
			{
				evalLeft->u.valInt = getDoubleFromExpression(evalLeft) 
											< getDoubleFromExpression(evalRight);
				evalLeft->tag = TAG_CONST_INTEGER;
				evaluated = evalLeft;
				b_arith_rel_op (B_LT, TYDOUBLE);
			}
			else if(isIntExpression(evalLeft) && isIntExpression(evalRight))
			{
				evalLeft->u.valInt = getIntFromExpression(evalLeft)
											< getIntFromExpression(evalRight);
				evaluated = evalLeft;
				b_arith_rel_op (B_LT, TYSIGNEDINT);
			}
			else
			{
				error("Cannot compare '<' with these two expressions");
			}
			break;

		case BINARY_GRT:		// a > b

			evalLeft = evaluateExpression(node->u.binop.leftOperand);
			evalRight = evaluateExpression(node->u.binop.rightOperand);

			//Make evaluated be int Expression After comparing
			if(isDoubleExpression(evalLeft) || isDoubleExpression(evalRight))
			{
				evalLeft->u.valInt = getDoubleFromExpression(evalLeft) 
											> getDoubleFromExpression(evalRight);
				evalLeft->tag = TAG_CONST_INTEGER;
				evaluated = evalLeft;
				b_arith_rel_op (B_GT, TYDOUBLE);
			}
			else if(isIntExpression(evalLeft) && isIntExpression(evalRight))
			{
				evalLeft->u.valInt = getIntFromExpression(evalLeft)
											> getIntFromExpression(evalRight);
				evaluated = evalLeft;
				b_arith_rel_op (B_GT, TYSIGNEDINT);
			}
			else
			{
				error("Cannot compare '>' with these two expressions");
			}
			break;

		case BINARY_LTE:		// a <= b

			evalLeft = evaluateExpression(node->u.binop.leftOperand);
			evalRight = evaluateExpression(node->u.binop.rightOperand);

			//Make evaluated be int Expression After comparing
			if(isDoubleExpression(evalLeft) || isDoubleExpression(evalRight))
			{
				evalLeft->u.valInt = getDoubleFromExpression(evalLeft) 
											<= getDoubleFromExpression(evalRight);
				evalLeft->tag = TAG_CONST_INTEGER;
				evaluated = evalLeft;
				b_arith_rel_op (B_LE, TYDOUBLE);

			}
			else if(isIntExpression(evalLeft) && isIntExpression(evalRight))
			{
				evalLeft->u.valInt = getIntFromExpression(evalLeft)
											<= getIntFromExpression(evalRight);
				evaluated = evalLeft;
				b_arith_rel_op (B_LE, TYSIGNEDINT);
			}
			else
			{
				error("Cannot compare '<=' with these two expressions");
			}
			break;

		case BINARY_GRTE: 	// a >= b

			evalLeft = evaluateExpression(node->u.binop.leftOperand);
			evalRight = evaluateExpression(node->u.binop.rightOperand);

			//Make evaluated be int Expression After comparing
			if(isDoubleExpression(evalLeft) || isDoubleExpression(evalRight))
			{
				evalLeft->u.valInt = getDoubleFromExpression(evalLeft) 
											>= getDoubleFromExpression(evalRight);
				evalLeft->tag = TAG_CONST_INTEGER;
				evaluated = evalLeft;
				b_arith_rel_op (B_GE, TYDOUBLE);
			}
			else if(isIntExpression(evalLeft) && isIntExpression(evalRight))
			{
				evalLeft->u.valInt = getIntFromExpression(evalLeft)
											>= getIntFromExpression(evalRight);
				evaluated = evalLeft;
				b_arith_rel_op (B_GE, TYSIGNEDINT);
			}
			else
			{
				error("Cannot compare '>=' with these two expressions");
			}
			break;

		case BINARY_EQUALS:	// a == b

			evalLeft = evaluateExpression(node->u.binop.leftOperand);
			evalRight = evaluateExpression(node->u.binop.rightOperand);

			//Make evaluated be int Expression After comparing
			if(isDoubleExpression(evalLeft) || isDoubleExpression(evalRight))
			{
				evalLeft->u.valInt = getDoubleFromExpression(evalLeft) 
											== getDoubleFromExpression(evalRight);
				evalLeft->tag = TAG_CONST_INTEGER;
				evaluated = evalLeft;
				b_arith_rel_op (B_EQ, TYDOUBLE);
			}
			else if(isIntExpression(evalLeft) && isIntExpression(evalRight))
			{
				evalLeft->u.valInt = getIntFromExpression(evalLeft)
											== getIntFromExpression(evalRight);
				evaluated = evalLeft;
				b_arith_rel_op (B_EQ, TYSIGNEDINT);
			}
			else
			{
				error("Cannot compare '==' with these two expressions");
			}
			break;

		case BINARY_NE:		// a != b

			evalLeft = evaluateExpression(node->u.binop.leftOperand);
			evalRight = evaluateExpression(node->u.binop.rightOperand);

			//Make evaluated be int Expression After comparing
			if(isDoubleExpression(evalLeft) || isDoubleExpression(evalRight))
			{
				evalLeft->u.valInt = getDoubleFromExpression(evalLeft) 
											!= getDoubleFromExpression(evalRight);
				evalLeft->tag = TAG_CONST_INTEGER;
				evaluated = evalLeft;
				b_arith_rel_op (B_NE, TYDOUBLE);

			}
			else if(isIntExpression(evalLeft) && isIntExpression(evalRight))
			{
				evalLeft->u.valInt = getIntFromExpression(evalLeft)
											!= getIntFromExpression(evalRight);
				evaluated = evalLeft;
				b_arith_rel_op (B_NE, TYSIGNEDINT);
			}
			else
			{
				error("Cannot compare '!=' with these two expressions");
			}
			break;

		case BINARY_AND:		// a && b
		case BINARY_OR:		// a || b
		case BINARY_TERNARY:	// a ? a1 : a2, Technically not a binary op, will we use?
			break;
		//End Boolean Comparators

		case BINARY_XAND:	// a & b
		case BINARY_XOR:		// a | b
		case BINARY_XNOT:		// a ^ b
			break;

		default:
			bug("Where's the binary operator tag in the expression?");

	}

	return evaluated;
}

int getIntFromExpression(EN node)
{
	if(isIntExpression(node))
		return node->u.valInt;
	else
		return (int) node->u.valDouble;
}

double getDoubleFromExpression(EN node)
{
	if(isIntExpression(node))
		return (double) node->u.valInt;
	else
		return node->u.valDouble;
}


ST_ID getIDFromVariableExpression(EN node)
{
	ST_ID id = NULL;

	if(isVariableExpression(node))
		id = node->u.varStID;

	return id;
}

TYPETAG getTypeTagFromExpression(EN node) 
{
	TYPETAG tag;

	switch (node->tag) {
		case TAG_CONST_INTEGER:
			tag = TYSIGNEDINT;
			break;
		case TAG_CONST_DOUBLE:
			tag = TYDOUBLE;
			break;
		default:
			bug("getTypeTagFromExpression was passed a node without a valid EXPR_TAG");
	}

	return tag;
}
/***************** Eval Expressions ***************/

BOOLEAN isIntExpression(EN node)
{
	if(node!=NULL && node->tag == TAG_CONST_INTEGER)
		return TRUE;
	return FALSE;
}

BOOLEAN isDoubleExpression(EN node)
{
	if(node!=NULL && node->tag == TAG_CONST_DOUBLE)
		return TRUE;
	return FALSE;
}

BOOLEAN isVariableExpression(EN node)
{
	if(node!=NULL && node->tag == TAG_VARIABLE)
		return TRUE;
	return FALSE;
}

void printExpression(EN node)
{
	switch(node->tag)
	{
		case TAG_CONST_INTEGER:
			//msg("Integer Expression: %d", node->u.valInt);
			break;
		case TAG_CONST_DOUBLE:
			//msg("Double Expression: %f", node->u.valDouble);
			break;

		case TAG_FUNCTION:
			//msg("Function Expression");
			break;

		case TAG_VARIABLE:
			//msg("Variable Expression");
			break;

		case TAG_UNARY:
			//msg("Unary Expression");
			break;
		
		case TAG_BINARY:
			//msg("Binary Expression");
			break;

		default:
			bug("Where's the expression tag in evaluateExpression?");
	}
}