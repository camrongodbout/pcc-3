#include "defs.h"
#include "types.h"
#include "symtab.h"
#include "bucket.h"

#include <stdio.h>

FILE *errfp;		/* file to which message.c will write */

/* For debugging purposes only */
#ifdef YYDEBUG
extern int yydebug;
#endif

int main()
{
	int status, yyparse();

	errfp = stderr;
	ty_types_init();
	st_init_symtab();
	init_bucket_module();
	st_establish_data_dump_func(stdr_dump);
	st_establish_tdata_dump_func(stdr_dump);
#ifdef YYDEBUG
	yydebug = 1;		/* DEBUG */
#endif
	status = yyparse();     /* Parse and translate the source */
#if 1
        if (status == 0)        /* If parse was successful */
            st_dump();          /* Dump the symbol table */
#endif
	return status;
}

