%option noyywrap yylineno

%{
/*--------------------------- Definitions ---------------------------*/
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "parser.tab.h"   /* Tokens declarados no parser.y (gerado por bison -d) */
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
int erros_lexicos = 0;

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
id                      {letra}({letra}|{digito}|_)*
ws                      [ \t\r]+
comentario_multilinha   "/*"([^*]|\*+[^*/])*\*+\/
comentario_nao_fechado  "/*"([^*]|\*+[^*/])*\**
comentario_linhaunica   "//".*

%%  /* ------- Regras ------- */


{comentario_multilinha}  { atualizaColuna(); }
{comentario_linhaunica}  { }
\n                       { column_number = 1; }
{ws}                     { column_number += yyleng; }

    /* Cada regra de token imprime o token e o retorna ao parser (Bison) */

"int"|"float"                { ImprimeToken("TYPE", yytext); return TYPE; }
"if"                         { ImprimeToken("IF", yytext); return IF; }
"else"                       { ImprimeToken("ELSE", yytext); return ELSE; }
"while"                      { ImprimeToken("WHILE", yytext); return WHILE; }
"print"                      { ImprimeToken("PRINT", yytext); return PRINT; }
"read"                       { ImprimeToken("READ", yytext); return READ; }
"return"                     { ImprimeToken("RETURN", yytext); return RETURN; }

    /* Igualdade separada dos relacionais para ter precedencia menor no parser (como em C) */
"=="|"!="|"<>"               { ImprimeToken("EQOP", yytext); return EQOP; }
">"|"<"|"<="|">="            { ImprimeToken("RELOP", yytext); return RELOP; }

"+"                          { ImprimeToken("PLUS", yytext); return PLUS; }
"-"                          { ImprimeToken("MINUS", yytext); return MINUS; }
"*"                          { ImprimeToken("MULT", yytext); return MULT; }
"/"                          { ImprimeToken("DIV", yytext); return DIV; }
"%"                          { ImprimeToken("MOD", yytext); return MOD; }
"="                          { ImprimeToken("ASSIGN", yytext); return ASSIGN; }

"&&"                         { ImprimeToken("AND", yytext); return AND; }
"||"                         { ImprimeToken("OR", yytext); return OR; }
"!"                          { ImprimeToken("NOT", yytext); return NOT; }

";"                          { ImprimeToken("SEMI", yytext); return SEMI; }
","                          { ImprimeToken("COMMA", yytext); return COMMA; }
"("                          { ImprimeToken("LPAREN", yytext); return LPAREN; }
")"                          { ImprimeToken("RPAREN", yytext); return RPAREN; }
"{"                          { ImprimeToken("LBRACE", yytext); return LBRACE; }
"}"                          { ImprimeToken("RBRACE", yytext); return RBRACE; }

{float}                      { ImprimeToken("NUM_FLOAT", yytext); return NUM_FLOAT; }
{inteiro}                    { ImprimeToken("NUM_INT", yytext); return NUM_INT; }

    /* Tratativas de erros com especificidade (erros lexicos nao retornam token ao parser) */

    /* Comentario aberto e nunca fechado: o padrao nao aceita "*" seguido de "/", entao consome
     * todo o restante do arquivo ate o EOF (se houver fechamento, comentario_multilinha casa
     * um caractere a mais e vence). Assim o conteudo interno nao vira tokens. Como o yylineno
     * ja foi avancado pelas quebras de linha consumidas, descontamos para reportar a linha de inicio. */
{comentario_nao_fechado}     { int linha_inicio = yylineno;
                               for (int i = 0; i < yyleng; i++) {
                                   if (yytext[i] == '\n') {
                                       linha_inicio--;
                                   }
                               }
                               fprintf(yyout, "Lexical error on line %d and column %d. Input -> \"/*\"\n Comentário não fechado: o restante do arquivo foi descartado.\n", linha_inicio, column_number);
                               erros_lexicos++;
                               atualizaColuna(); }
{digito}+{letra}+{digito}*   { fprintf (yyout, "Lexical error on line %d and column %d. Input -> \"%s\"\n Não é permitido iniciar um identificador com dígito.\n", yylineno, column_number, yytext); erros_lexicos++; column_number += yyleng; }
{id}                         { insereSimbolo(yytext, yylineno, column_number); ImprimeToken("ID", yytext); return ID; }

    /* Tratativas de erro genérico */

.                            { fprintf(yyout, "Lexical error on line %d and column %d. Input -> \"%s\"\n", yylineno, column_number, yytext); erros_lexicos++; column_number += yyleng; }



%%
/*------------------------- User subrotines -------------------------*/

/* O main foi movido para o parser.y (Etapa 2), que chama yyparse(). */

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
