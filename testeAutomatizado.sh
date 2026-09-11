# ============================================================
# test_lexer.sh
# Script de teste automatizado para o analisador lexico (Flex)
#
# Uso:
#   chmod +x test_lexer.sh
#   ./test_lexer.sh analisador.l
#
# O script:
#   1. Compila o .l com flex + gcc
#   2. Gera um conjunto de arquivos de teste (um por token/caso de erro)
#   3. Executa o analisador contra cada teste
#   4. Mostra a saida e sinaliza se bateu com o esperado (grep simples)
#
# Observacao tecnica: os casos sao guardados em arrays paralelos
# (NOMES, CONTEUDOS, ESPERADOS) em vez de uma unica string separada
# por "|", pois alguns tokens testados (ex.: "||") contem o proprio
# caractere separador, e alguns casos contem quebras de linha no
# conteudo -- ambos quebrariam um parsing baseado em "IFS='|' read".
# ============================================================

set -u

LEX_FILE="${1:-analisador.l}"
BUILD_DIR="build_lexer_test"
TEST_DIR="$BUILD_DIR/casos"
OUT_DIR="$BUILD_DIR/saidas"
BIN="$BUILD_DIR/analisador"

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

PASS_COUNT=0
FAIL_COUNT=0

echo "=============================================="
echo " Teste automatizado do analisador lexico"
echo " Arquivo fonte: $LEX_FILE"
echo "=============================================="

if [ ! -f "$LEX_FILE" ]; then
    echo -e "${RED}ERRO:${NC} arquivo '$LEX_FILE' nao encontrado."
    exit 1
fi

mkdir -p "$TEST_DIR" "$OUT_DIR"

# ---------------------------------------------------------
# 1) Compilacao
# ---------------------------------------------------------
echo
echo "--- Compilando com flex + gcc ---"

flex -o "$BUILD_DIR/lex.yy.c" "$LEX_FILE" 2> "$BUILD_DIR/flex_errors.log"
if [ $? -ne 0 ]; then
    echo -e "${RED}FALHA ao gerar lex.yy.c. Veja $BUILD_DIR/flex_errors.log${NC}"
    cat "$BUILD_DIR/flex_errors.log"
    exit 1
fi

gcc "$BUILD_DIR/lex.yy.c" -o "$BIN" -lfl 2> "$BUILD_DIR/gcc_errors.log"
if [ $? -ne 0 ]; then
    echo -e "${YELLOW}Aviso: build com -lfl falhou, tentando sem -lfl...${NC}"
    gcc "$BUILD_DIR/lex.yy.c" -o "$BIN" 2>> "$BUILD_DIR/gcc_errors.log"
    if [ $? -ne 0 ]; then
        echo -e "${RED}FALHA na compilacao. Veja $BUILD_DIR/gcc_errors.log${NC}"
        cat "$BUILD_DIR/gcc_errors.log"
        exit 1
    fi
fi

echo -e "${GREEN}Compilacao concluida com sucesso.${NC} Binario: $BIN"

# ---------------------------------------------------------
# 2) Geracao dos casos de teste (arrays paralelos)
# ---------------------------------------------------------
NOMES=()
CONTEUDOS=()
ESPERADOS=()

add_caso() {
    # $1 = nome, $2 = conteudo, $3 = padrao esperado (regex para grep -E)
    NOMES+=("$1")
    CONTEUDOS+=("$2")
    ESPERADOS+=("$3")
}

# --- Palavras-chave ---
add_caso "kw_int"      "int"      "INT"
add_caso "kw_float"    "float"    "FLOAT"
add_caso "kw_if"       "if"       "IF"
add_caso "kw_else"     "else"     "ELSE"
add_caso "kw_while"    "while"    "WHILE"
add_caso "kw_print"    "print"    "PRINT"
add_caso "kw_read"     "read"     "READ"
add_caso "kw_return"   "return"   "RETURN"

# --- Operadores relacionais ---
add_caso "op_ge"  ">="  "GE"
add_caso "op_le"  "<="  "LE"
add_caso "op_ne"  "!="  "NE"
add_caso "op_ne2" "<>"  "NE"
add_caso "op_eq"  "=="  "EQ"
add_caso "op_lt"  "<"   "LT"
add_caso "op_gt"  ">"   "GT"

# --- Operadores aritmeticos e atribuicao ---
add_caso "op_plus"   "+"  "PLUS"
add_caso "op_minus"  "-"  "MINUS"
add_caso "op_mult"   "*"  "MULT"
add_caso "op_div"    "/"  "DIV"
add_caso "op_mod"    "%"  "MOD"
add_caso "op_assign" "="  "ASSIGN"

# --- Operadores logicos ---
add_caso "op_and" "&&" "AND"
add_caso "op_or"  "||" "OR"
add_caso "op_not" "!"  "NOT"

# --- Pontuacao ---
add_caso "pt_semi"   ";" "SEMI"
add_caso "pt_comma"  "," "COMMA"
add_caso "pt_lparen" "(" "LPAREN"
add_caso "pt_rparen" ")" "RPAREN"
add_caso "pt_lbrace" "{" "LBRACE"
add_caso "pt_rbrace" "}" "RBRACE"

# --- Numeros validos ---
add_caso "num_int_simples"     "42"          "NUM_INT"
add_caso "num_int_zero"        "0"           "NUM_INT"
add_caso "num_int_zero_esq"    "007"         "NUM_INT"
add_caso "num_float_ponto"     "3.14"        "NUM_FLOAT"
add_caso "num_float_expoente"  "5e3"         "NUM_FLOAT"
add_caso "num_float_ponto_exp" "2.5e-3"      "NUM_FLOAT"
add_caso "num_float_ponto_Exp" "1.2E+10"     "NUM_FLOAT"

# --- Identificadores validos ---
add_caso "id_simples"      "contador"    "ID"
add_caso "id_com_digito"   "var1"        "ID"
add_caso "id_maiuscula"    "Nome"        "ID"

# --- Comentarios (nao devem gerar token, mas nao podem quebrar o restante) ---
add_caso "comentario_linha"  "// isso eh um comentario"$'\n'"int"          "INT"
add_caso "comentario_bloco"  "/* comentario"$'\n'"em varias"$'\n'"linhas */ int"  "INT"

# --- Espacos em branco (nao devem gerar token, mas nao podem quebrar) ---
add_caso "espacos_tabs"  "int    x"$'\n'$'\t'"= 5;"  "INT"

# --- Casos de ERRO LEXICO esperado ---
add_caso "erro_simbolo_arroba" "@"        "Lexical error"
add_caso "erro_simbolo_cifrao" "\$"       "Lexical error"

# ---------------------------------------------------------
# 3) Execucao dos casos
# ---------------------------------------------------------
echo
echo "--- Executando casos de teste ---"
printf "%-28s %-12s %s\n" "CASO" "RESULTADO" "TRECHO DA SAIDA"
echo "------------------------------------------------------------------------------"

N=${#NOMES[@]}
for ((idx=0; idx<N; idx++)); do
    nome="${NOMES[$idx]}"
    conteudo="${CONTEUDOS[$idx]}"
    esperado="${ESPERADOS[$idx]}"

    in_file="$TEST_DIR/$nome.txt"
    out_file="$OUT_DIR/$nome.out"

    printf '%s\n' "$conteudo" > "$in_file"

    "$BIN" < "$in_file" > "$out_file" 2>&1

    if grep -qE "$esperado" "$out_file"; then
        printf "%-28s ${GREEN}%-12s${NC} %s\n" "$nome" "PASS" "$(tr '\n' ' ' < "$out_file" | cut -c1-70)"
        PASS_COUNT=$((PASS_COUNT+1))
    else
        printf "%-28s ${RED}%-12s${NC} %s\n" "$nome" "FAIL" "$(tr '\n' ' ' < "$out_file" | cut -c1-70)"
        FAIL_COUNT=$((FAIL_COUNT+1))
    fi
done

# ---------------------------------------------------------
# 4) Resumo
# ---------------------------------------------------------
echo "------------------------------------------------------------------------------"
TOTAL=$((PASS_COUNT + FAIL_COUNT))
echo -e "Total de casos: $TOTAL | ${GREEN}Passaram: $PASS_COUNT${NC} | ${RED}Falharam: $FAIL_COUNT${NC}"
echo
echo "Arquivos de entrada gerados em: $TEST_DIR"
echo "Saidas completas do analisador em: $OUT_DIR"

if [ "$FAIL_COUNT" -gt 0 ]; then
    exit 1
fi
exit 0
