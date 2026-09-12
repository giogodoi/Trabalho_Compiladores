%option noyywrap yylineno

%{
/*--------------------------- Definitions ---------------------------*/
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
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

void atualizaColuna(void);
int procuraSimbolo(const char *lexema);
int insereSimbolo (const char *lexema, int linha, int coluna);
void imprimeTabeladeSimbolos(void);
void ImprimeToken(const char* token, const char* lexema);

%}

letra                   [a-zA-Z]
digito                  [0-9]
sinal                   [+-]?
expoente                [Ee]{sinal}{digito}+
inteiro                 {digito}+
float                   {digito}+(\.{digito}+{expoente}?|{expoente})
id                      {letra}({letra}|{digito})*
ws                      [ \t\r]+
comentario_multilinha   "/*"([^*]|\*+[^*/])*\*+\/
comentario_linhaunica   "//".*

%%  /* ------- Regras ------- */


{comentario_multilinha}  { atualizaColuna(); }
{comentario_linhaunica}  { }
\n                       { column_number = 1; }
{ws}                     { column_number += yyleng; }

"int"                        { ImprimeToken("INT", yytext); }
"float"                      { ImprimeToken("FLOAT", yytext); }
"if"                         { ImprimeToken("IF", yytext); }
"else"                       { ImprimeToken("ELSE", yytext); }
"while"                      { ImprimeToken("WHILE", yytext); }
"print"                      { ImprimeToken("PRINT", yytext); }
"read"                       { ImprimeToken("READ", yytext); }
"return"                     { ImprimeToken("RETURN", yytext); }

">="                         { ImprimeToken("GE", yytext); }
"<="                         { ImprimeToken("LE", yytext); }
"!="                         { ImprimeToken("NE", yytext); }
"<>"                         { ImprimeToken("NE", yytext); }
"=="                         { ImprimeToken("EQ", yytext); }
"<"                          { ImprimeToken("LT", yytext); }
">"                          { ImprimeToken("GT", yytext); }

"+"                          { ImprimeToken("PLUS", yytext); }
"-"                          { ImprimeToken("MINUS", yytext); }
"*"                          { ImprimeToken("MULT", yytext); }
"/"                          { ImprimeToken("DIV", yytext); }
"%"                          { ImprimeToken("MOD", yytext); }
"="                          { ImprimeToken("ASSIGN", yytext); }

"&&"                         { ImprimeToken("AND", yytext); }
"||"                         { ImprimeToken("OR", yytext); }
"!"                          { ImprimeToken("NOT", yytext); }

";"                          { ImprimeToken("SEMI", yytext); }
","                          { ImprimeToken("COMMA", yytext); }
"("                          { ImprimeToken("LPAREN", yytext); }
")"                          { ImprimeToken("RPAREN", yytext); }
"{"                          { ImprimeToken("LBRACE", yytext); }
"}"                          { ImprimeToken("RBRACE", yytext); }

{float}                      { insereSimbolo(yytext, yylineno, column_number); ImprimeToken("NUM_FLOAT", yytext); }
{inteiro}                    { insereSimbolo(yytext, yylineno, column_number); ImprimeToken("NUM_INT", yytext); }
{id}                         { insereSimbolo(yytext, yylineno, column_number); ImprimeToken("ID", yytext); }

.                            { fprintf(yyout, "Lexical error on line %d and column %d. Input -> \"%s\"\n", yylineno, column_number, yytext); column_number += yyleng; }



%%
/*------------------------- User subrotines -------------------------*/

/* main customizado que abre o arquivo passado como argv[1].
 * Uso: ./main programa.txt
 */
int main(int argc, char **argv) {
    if (argc != 2) {
        fprintf(stderr, "Uso: %s <arquivo-fonte>\n", argv[0]);
        return 1;
    }

    FILE *input = fopen(argv[1], "r");
    if (!input) {
        fprintf(stderr, "ERRO: nao foi possivel abrir o arquivo '%s'\n", argv[1]);
        return 1;
    }

    yyin = input;
    yylex();
    imprimeTabeladeSimbolos();
    fclose(input);
    return 0;
}

/* O método atualizaColuna serve pra um caso muito específico mas que melhora a especificidade de sinalização do erro.
 Basicamente ele vai percorrer até o final da palavra e, caso não seja uma quebra de linha ao final, ele vai incrementar normalmente.

 Exemplo:
 /* Teste 1
 Teste 2 */ variavelqualquer

 Nesse caso, ele retornaria que o id do lexema "variavelqualquer" está na linha 122, coluna 12.
*/
void atualizaColuna(void) {
    for (int i = 0; i < yyleng; i++) {
        if (yytext[i] == '\n') {
            column_number = 1;
        } else {
            column_number++;
        }
    }
}

int procuraSimbolo (const char *lexema) {
    int i;

    for (i = 0; i < symbol_count; i++) {
        if (strcmp(symbol_table[i].lexema, lexema) == 0) {
            return i;
        }
    }

    return -1;
}

int insereSimbolo (const char *lexema, int linha, int coluna) {
    int position = procuraSimbolo(lexema);

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

void imprimeTabeladeSimbolos(void) {
    int i;

    fprintf(yyout, "\n=== TABELA DE SIMBOLOS LEXICA ===\n");
    fprintf(yyout, "ID\tLEXEMA\tLINHA\tCOLUNA\n");

    for (i = 0; i < symbol_count; i++) {
        fprintf(yyout, "%d\t%s\t%d\t%d\n", i, symbol_table[i].lexema, symbol_table[i].linha, symbol_table[i].coluna);
    }
}

/* O metodo a seguir tem como unica e exclusiva funcionalidade evitar a replicacao de codigo e facilitar a leitura das declaracoes nas regras. Poderiamos ter feito diretamente apos cada
regra as operacoes a seguir. */

void ImprimeToken(const char* token, const char* lexema) {
    token_line = yylineno;
    token_column = column_number;
    printf("%d(%d): %s (%s)\n", yylineno, column_number, lexema, token);
    column_number += strlen(lexema);
}
