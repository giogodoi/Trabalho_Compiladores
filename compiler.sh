#!/usr/bin/env bash

set -e

if [ "$#" -ne 1 ]; then
    echo "Uso: ./compiler.sh <arquivo-fonte>"
    exit 1
fi

# Etapa 2: analisador sintatico (Bison) integrado ao analisador lexico (Flex)
bison -d -o parser.tab.c parser.y   # gera parser.tab.c e parser.tab.h (tokens)
flex -o lexer.c lexer.l             # lexer.l inclui o parser.tab.h
gcc -o main parser.tab.c lexer.c    # sem -lfl/-ly: noyywrap e main/yyerror proprios

./main "$1"
