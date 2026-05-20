%{

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

extern int yylineno;
int yylex();
extern FILE *f;

%}

%union {
  int intVal;
  double dblVal;
  char *strVal;
  char chVal;
}

%token <strVal> INT_TYPE DOUBLE_TYPE FLOAT_TYPE VOID_TYPE
%token <chVal> ';' '(' ')' '{' '}'
%token <strVal> IDENT

%type <strVal> program declaration

%%

program:
declaration
| program declaration
;

declaration:
VOID_TYPE IDENT '(' ')' ';'
| VOID_TYPE IDENT '(' ')' '{' '}' {
  fprintf(f, ".global %s\n", $2);
  fprintf(f, "%s:\n", $2);
  fprintf(f, "  addi sp,sp,-16\n");
  fprintf(f, "  sw s0,12(sp)\n");
  fprintf(f, "  addi s0,sp,16\n");

  fprintf(f, "  nop\n");

  fprintf(f, "  lw s0,12(sp)\n");
  fprintf(f, "  addi sp,sp,16\n");
  fprintf(f, "  jr ra\n");
}
;

%%

int main(void) {
  f = fopen("codegen.S","w");
  if (f == NULL) {
    fprintf(stderr,"Error: Unable to open codegen.S\n");
    return 0;
  }
  yyparse();
  fclose(f);
  return 0;
}

void yyerror(char * msg) {
  fprintf(stderr, "YACC> Error at line %d. \n", yylineno); 
  fprintf(stderr, "This input won't happen in the testcases\n");
  exit(1);
}
