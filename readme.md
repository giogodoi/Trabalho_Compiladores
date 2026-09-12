# Etapa 1: Analisador Léxico (Flex)

*Alunos:*
*Giovane Felipe Godoi Oliveira & Luiz Fellipe Resende Lima*

## Visão Geral
Esta etapa consiste no desenvolvimento do Analisador Léxico utilizando a ferramenta **Flex** para a mini-linguagem imperativa definida na disciplina de Compiladores (GCC130). O analisador lê o código-fonte, reconhece os tokens, gerencia a contagem de linhas e colunas, trata erros léxicos e constrói a Tabela de Símbolos.

---

## Decisões de Projeto

### 1. Tabela de Símbolos
- **Estrutura:** Implementada como um vetor estático de estruturas (`Simbolo`) com capacidade para até 1000 elementos.
- **Inserção Seletiva:** Apenas **identificadores (`ID`)** e **literais numéricos (`NUM_INT`, `NUM_FLOAT`)** são armazenados na tabela. Palavras reservadas e operadores não são inseridos para evitar redundância.
- **Evitando Duplicatas:** A função `procuraSimbolo()` verifica se o lexema já existe na tabela antes de inseri-lo. Se o lexema já existe, ele não é duplicado, mantendo o registro da **primeira ocorrência** (linha e coluna).

### 2. Controle de Linhas e Colunas
- **Linhas:** Utilizou-se a diretiva `%option yylineno` do Flex, que atualiza automaticamente a variável interna `yylineno`.
- **Colunas:** A contagem é gerenciada manualmente por uma variável global `column_number`:
  - Resetada para `1` a cada quebra de linha (`\n`).
  - Incrementada pelo tamanho do lexema (`yyleng`) em espaços/tabs e na função `ImprimeToken()`.

### 3. Tratamento de Comentários e Espaços em Branco
- **Espaços em branco (`ws`):** Ignorados pelo analisador, mas atualizam o contador de colunas (`column_number += yyleng`).
- **Comentários de linha única (`//`):** Ignorados até o fim da linha.
- **Comentários multilinhas (`/* ... */`):** Desconsiderados diretamente pela regra de expressão regular no Flex.

### 4. Tratamento de Erros Léxicos
- Qualquer caractere não reconhecido pelas regras anteriores é capturado pelo padrão genérico `.`.
- O erro é exibido imediatamente no `yyout`/`stdout` informando o caractere inválido e sua posição exata (linha e coluna), permitindo que a análise prssiga para os próximos tokens.

### 5. Suporte a Números Negativos
- A linguagem trata o sinal negativo (`-`) como o operador aritmético unário/binário (`MINUS`). O agrupamento do sinal com o número para formar um valor negativo é delegado para a etapa de **Análise Sintática/Semântica**, garantindo maior flexibilidade gramatical.

---

## Resumo das Regras de Tokens

| Categoria | Tokens / Expressões |
| :--- | :--- |
| **Tipos de Dados** | `int` (`INT`), `float` (`FLOAT`) |
| **Palavras-chave** | `if`, `else`, `while`, `print`, `read`, `return` |
| **Operadores Relacionais** | `>=` (`GE`), `<=` (`LE`), `!=` / `<>` (`NE`), `==` (`EQ`), `<` (`LT`), `>` (`GT`) |
| **Operadores Aritméticos** | `+` (`PLUS`), `-` (`MINUS`), `*` (`MULT`), `/` (`DIV`), `%` (`MOD`), `=` (`ASSIGN`) |
| **Operadores Lógicos** | `&&` (`AND`), `\|\|` (`OR`), `!` (`NOT`) |
| **Pontuação / Delimitadores** | `;` (`SEMI`), `,` (`COMMA`), `(` (`LPAREN`), `)` (`RPAREN`), `{` (`LBRACE`), `}` (`RBRACE`) |
| **Identificadores (`ID`)** | Começam com letra seguidos de letras ou dígitos: `[a-zA-Z][a-zA-Z0-9]*` |
| **Numéricos (`NUM_INT`, `NUM_FLOAT`)** | Suporta inteiros (`10`) e floats com notação científica opcional (`2.5E+1`, `0.5e-2`) |

---

## Como Executar

### Pré-requisitos
- `flex`
- `gcc`

### Passos
1. **Utilize o script junto ao arquivo que deseja testar:**
   ```bash
   ./compiler.sh <arquivo-fonte>