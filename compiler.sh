#!/usr/bin/env bash

set -e

if [ "$#" -ne 1 ]; then
    echo "Uso: ./compiler.sh <arquivo-fonte>"
    exit 1
fi

# Etapa 1: apenas analisador lexico (Flex), sem Bison
flex -o lexer.c lexer.l
gcc -o main lexer.c -lfl

./main "$1"