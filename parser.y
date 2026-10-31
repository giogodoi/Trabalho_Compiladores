%{
/*--------------------------- Definitions ---------------------------*/
#include <stdio.h>
#include <stdlib.h>

int yylex(void);               /* Compatibilidade com FLEX */
void yyerror(const char *s);   /* Compatibilidade com FLEX */

/* Variaveis e funcoes definidas no analisador lexico (lexer.l) */
extern FILE *yyin;
extern FILE *yyout;
extern char *yytext;
extern int yylineno;
extern int column_number;
extern int token_line;
extern int token_column;
extern int erros_lexicos;
void imprimeTabeladeSimbolos(void);

int erros_sintaticos = 0;
%}

/* Tokens retornados pelo analisador lexico */
%token TYPE IF ELSE WHILE PRINT READ RETURN
%token ID NUM_INT NUM_FLOAT
%token EQOP RELOP
%token PLUS MINUS MULT DIV MOD ASSIGN
%token AND OR NOT
%token SEMI COMMA LPAREN RPAREN LBRACE RBRACE

/* Precedencia e associatividade (da menor para a maior) */
%left OR
%left AND
%left EQOP
%left RELOP
%left PLUS MINUS
%left MULT DIV MOD
%right NOT
%right UMINUS              /* Token ficticio, usado apenas no menos unario */

%%  /* ------- Regras ------- */

/* Um programa e uma sequencia de comandos (declaracoes tambem sao comandos) */
programa
    : lista_comandos
    ;

/* Sequencia de comandos (permite vazio). As regras com "error" fazem a recuperacao
 * em modo panico: descartam tokens ate um ";" ou "}" e continuam a analise. */
lista_comandos
    : lista_comandos comando
    | /* vazio */
    | lista_comandos error SEMI      { yyerrok; }
    | lista_comandos error RBRACE
    ;

/* Dangling else: o comando e dividido em casado (todo if possui else) e aberto
 * (algum if sem else), de modo que cada else se associa ao if mais proximo.
 * O while e dividido da mesma forma, pois tambem termina com um comando. */
comando
    : comando_casado
    | comando_aberto
    ;

comando_casado
    : IF LPAREN expr RPAREN comando_casado ELSE comando_casado
    | WHILE LPAREN expr RPAREN comando_casado
    | comando_simples
    ;

comando_aberto
    : IF LPAREN expr RPAREN comando
    | IF LPAREN expr RPAREN comando_casado ELSE comando_aberto
    | WHILE LPAREN expr RPAREN comando_aberto
    ;

/* Comandos que nao terminam com outro comando */
comando_simples
    : declaracao
    | atribuicao
    | bloco
    | comando_print
    | comando_read
    | comando_return
    | SEMI                            /* comando vazio */
    ;

/* Declaracao de variaveis. Ex.: int a, b = 10; */
declaracao
    : TYPE lista_decl SEMI
    ;

lista_decl
    : item_decl
    | lista_decl COMMA item_decl
    ;

item_decl
    : ID
    | ID ASSIGN expr
    ;

atribuicao
    : ID ASSIGN expr SEMI
    ;

/* Bloco / comando composto */
bloco
    : LBRACE lista_comandos RBRACE
    ;

/* Funcoes predefinidas de entrada e saida */
comando_print
    : PRINT LPAREN expr RPAREN SEMI
    ;

comando_read
    : READ LPAREN ID RPAREN SEMI
    ;

comando_return
    : RETURN expr SEMI
    ;

/* Expressoes aritmeticas, relacionais e logicas. A ambiguidade e resolvida pelas
 * declaracoes de precedencia acima; o menos unario usa a precedencia de UMINUS. */
expr
    : expr OR expr
    | expr AND expr
    | expr EQOP expr
    | expr RELOP expr
    | expr PLUS expr
    | expr MINUS expr
    | expr MULT expr
    | expr DIV expr
    | expr MOD expr
    | NOT expr
    | MINUS expr %prec UMINUS
    | LPAREN expr RPAREN
    | ID
    | NUM_INT
    | NUM_FLOAT
    ;

%%
/*------------------------- User subrotines -------------------------*/

/* Reporta o erro sintatico na posicao (linha e coluna) do token em que ele foi detectado.
 * token_line/token_column sao guardados pelo ImprimeToken() do lexer antes de avancar a coluna. */
void yyerror(const char *s) {
    erros_sintaticos++;

    if (yytext[0] == '\0') {
        fprintf(yyout, "%s on line %d and column %d. Fim de arquivo inesperado.\n", s, yylineno, column_number);
    } else {
        fprintf(yyout, "%s on line %d and column %d. Input -> \"%s\"\n", s, token_line, token_column, yytext);
    }
}

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
    yyparse();
    imprimeTabeladeSimbolos();

    if (erros_lexicos == 0 && erros_sintaticos == 0) {
        fprintf(yyout, "\nAnálise concluída sem erros.\n");
    } else {
        fprintf(yyout, "\nAnálise concluída com %d erro(s) léxico(s) e %d erro(s) sintático(s).\n", erros_lexicos, erros_sintaticos);
    }

    fclose(input);
    return 0;
}
