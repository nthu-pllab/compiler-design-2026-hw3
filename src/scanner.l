%option yylineno

%{

#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include "y.tab.h"
FILE *f;

%}

id ([_A-Za-z][A-Za-z0-9_]*)
space ([ \t])

%%

int {
  yylval.strVal = strdup(yytext);
  return INT_TYPE;
}
double {
  yylval.strVal = strdup(yytext);
  return DOUBLE_TYPE;
}
float {
  yylval.strVal = strdup(yytext);
  return FLOAT_TYPE;
}
void {
  yylval.strVal = strdup(yytext);
  return VOID_TYPE;
}
{id} {
  yylval.strVal = (char*)strdup(yytext);
  return IDENT;
}
";" {
  yylval.chVal = yytext[0];
  return yytext[0];
}
"(" {
  yylval.chVal = yytext[0];
  return yytext[0];
}
")" {
  yylval.chVal = yytext[0];
  return yytext[0];
}
"{" {
  yylval.chVal = yytext[0];
  return yytext[0];
}
"}" {
  yylval.chVal = yytext[0];
  return yytext[0];
}
{space} {
}
\n {
}

%%

void tokenerror()
{
    fprintf(stderr,"Error at line %d: %s\n", yylineno, yytext);
    exit(1);
}

