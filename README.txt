part1done.
perhaps useful http://www.cs.unh.edu/~pjh/courses/cs980/2007/proj1.html

This directory contains the files comprising the skeleton of the C
compiler "pcc3".


Source files:

Makefile	- Compiler maintenance
defs.h		- Global definitions
gram.y		- The skeleton grammar for Pascal
main.c		- The main routine
message.c	- Message handling routines
message.h	- Definitions for message.c
scan.l		- The specification of the lexical scanner
symtab.c	- Symbol table maintenance
symtab.h	- Definitions for symtab.c
types.c		- Processes Pascal type information
types.h		- Definitions for types.c
backend-x86.c	- Routines for generating x86 assembly code
backend-x86.h	- Definitions for backend-x86.c
utils.c		- Miscellaneous utilities


Files used for testing:

test/T1L80_err.*	- Test files with errors for 80% credit
test/T1L80_ok.*		- Error-free test files for 80% credit
test/T1L90_err.*	- Test files with errors for 90% credit
test/T1L90_ok.*		- Error-free test files for 90% credit
test/T1L100_err.*	- Test files with errors for 100% credit
test/T1L100_ok.*	- Error-free test files for 100% credit
test/T1L110_err.*	- Test files with errors for 10% extra credit
test/T1L110_ok.*	- Error-free test files for 10% extra credit


Scripts:

proj1-test.pl		- (Self-)test
get-backend-calls.pl	- Harvest backend calls from assembly code output


Documentation:

README.txt		- This file
