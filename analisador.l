%option noyywrap yylineno

%{
/*--------------------------- Definitions ---------------------------*/
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "parser.h"
#define MAX_SYMBOLS 1000

typedef struct {
    char lexema[100];
    int linha;
    int coluna;
} Simbolo;

int column_number = 1;
int token_line = 1;
int token_column = 1;
Simbolo symbol_table[MAX_SYMBOLS];
int symbol_count = 0;

void update_multiline_column(void);
int search_symbol(const char *lexema);
int insert_symbol(const char *lexema, int linha, int coluna);
void print_symbol_table(void);
void print_token(const char* token, const char* lexema);
%}

letra                   [a-zA-Z]
digito                  [0-9]
digitonz                [1-9]
sinal                   [+-]?
expoente                [Ee]{sinal}{digito}+
inteiro                 (0|{digitonz}{digito}*)
float                   (0|{digitonz}{digito}*)(\.{digito}+{expoente}?|{expoente})
id                      {letra}({letra}|{digito})*
inteiro_malformado      {inteiro}{letra}({letra}|{digito})*
float_malformado        {float}{letra}({letra}|{digito})*
ws                      [ \t\r]+
comentario_multilinha   "/*"([^*]|\*+[^*/])*\*+\/
comentario_linhaunica   "//"([^\n])*

%%
{comentario_multilinha}  { update_multiline_column(); }
{comentario_linhaunica}  { }
\n                       { column_number = 1; }
{ws}                     { column_number += yyleng; }

"int"                        { print_token("INT", yytext); return INT; }
"float"                      { print_token("FLOAT", yytext); return FLOAT; }
"if"                         { print_token("IF", yytext); return IF; }
"else"                       { print_token("ELSE", yytext); return ELSE; }
"while"                      { print_token("WHILE", yytext); return WHILE; }
"print"                      { print_token("PRINT", yytext); return PRINT; }
"read"                       { print_token("READ", yytext); return READ; }
"return"                     { print_token("RETURN", yytext); return RETURN; }

">="                         { print_token("GE", yytext); return GE; }
"<="                         { print_token("LE", yytext); return LE; }
"!="                         { print_token("NE", yytext); return NE; }
"<>"                         { print_token("NE", yytext); return NE; }
"=="                         { print_token("EQ", yytext); return EQ; }
"<"                          { print_token("LT", yytext); return LT; }
">"                          { print_token("GT", yytext); return GT; }

"+"                          { print_token("PLUS", yytext); return PLUS; }
"-"                          { print_token("MINUS", yytext); return MINUS; }
"*"                          { print_token("MULT", yytext); return MULT; }
"/"                          { print_token("DIV", yytext); return DIV; }
"%"                          { print_token("MOD", yytext); return MOD; }
"="                          { print_token("ASSIGN", yytext); return ASSIGN; }

"&&"                         { print_token("AND", yytext); return AND; }
"||"                         { print_token("OR", yytext); return OR; }
"!"                          { print_token("NOT", yytext); return NOT; }

";"                          { print_token("SEMI", yytext); return SEMI; }
","                          { print_token("COMMA", yytext); return COMMA; }
"("                          { print_token("LPAREN", yytext); return LPAREN; }
")"                          { print_token("RPAREN", yytext); return RPAREN; }
"{"                          { print_token("LBRACE", yytext); return LBRACE; }
"}"                          { print_token("RBRACE", yytext); return RBRACE; }

{float}                      { yylval = install_symbol(yytext, yylineno, column_number); print_token("NUM_FLOAT", yytext); return NUM_FLOAT; }
{inteiro}                    { yylval = install_symbol(yytext, yylineno, column_number); print_token("NUM_INT", yytext); return NUM_INT; }
{float_malformado}           { fprintf(yyout, "Lexical error on line %d and column %d. Identificador invalido: nao pode comecar com numero. Input -> \"%s\"\n", yylineno, column_number, yytext); column_number += yyleng; }
{inteiro_malformado}         { fprintf(yyout, "Lexical error on line %d and column %d. Identificador invalido: nao pode comecar com numero. Input -> \"%s\"\n", yylineno, column_number, yytext); column_number += yyleng; }

{id}                         { yylval = install_symbol(yytext, yylineno, column_number); print_token("ID", yytext); return ID; }

.                            { fprintf(yyout, "Lexical error on line %d and column %d. Input -> \"%s\"\n", yylineno, column_number, yytext); column_number += yyleng; }



%%
/*------------------------- User subrotines -------------------------*/
void update_multiline_column(void) {
    int i;

    for (i = 0; i < yyleng; i++) {
        if (yytext[i] == '\n') {
            column_number = 1;
        } else {
            column_number++;
        }
    }
}

int search_symbol(const char *lexema) {
    int i;

    for (i = 0; i < symbol_count; i++) {
        if (strcmp(symbol_table[i].lexema, lexema) == 0) {
            return i;
        }
    }

    return -1;
}

int insert_symbol(const char *lexema, int linha, int coluna) {
    int position = search_symbol(lexema);

    if (position != -1) {
        return position;
    }

    if (symbol_count >= MAX_SYMBOLS) {
        fprintf(yyout, "Erro: tabela de simbolos cheia. Identificador \"%s\" nao inserido.\n", lexema);
        return -1;
    }

    strncpy(symbol_table[symbol_count].lexema, lexema, sizeof(symbol_table[symbol_count].lexema) - 1);
    symbol_table[symbol_count].lexema[sizeof(symbol_table[symbol_count].lexema) - 1] = '\0';
    symbol_table[symbol_count].linha = linha;
    symbol_table[symbol_count].coluna = coluna;
    symbol_count++;

    return symbol_count - 1;
}

int install_symbol(const char *lexema, int linha, int coluna) {
    return insert_symbol(lexema, linha, coluna);
}

void print_symbol_table(void) {
    int i;

    fprintf(yyout, "\n=== TABELA DE SIMBOLOS LEXICA ===\n");
    fprintf(yyout, "ID\tLEXEMA\tLINHA\tCOLUNA\n");

    for (i = 0; i < symbol_count; i++) {
        fprintf(yyout, "%d\t%s\t%d\t%d\n", i, symbol_table[i].lexema, symbol_table[i].linha, symbol_table[i].coluna);
    }
}

void print_token(const char* token, const char* lexema) {
    token_line = yylineno;
    token_column = column_number;
    printf("%d(%d): %s (%s)\n", yylineno, column_number, lexema, token);
    column_number += strlen(lexema);
}
