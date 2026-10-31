# Etapas 1 e 2: Analisador Léxico (Flex) e Analisador Sintático (Bison)

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
- **Comentário não fechado (`/*` sem `*/`):** o padrão `comentario_nao_fechado` consome todo o restante do arquivo até o EOF, reportando o erro na linha e coluna onde o comentário foi aberto. Assim, o conteúdo do comentário não é convertido em tokens.

### 5. Suporte a Números Negativos
- A linguagem trata o sinal negativo (`-`) como o operador aritmético unário/binário (`MINUS`). O agrupamento do sinal com o número para formar um valor negativo é delegado para a etapa de **Análise Sintática/Semântica**, garantindo maior flexibilidade gramatical.

---

## Resumo das Regras de Tokens

| Categoria | Tokens / Expressões |
| :--- | :--- |
| **Tipos de Dados** | `int`, `float` (`TYPE`) |
| **Palavras-chave** | `if`, `else`, `while`, `print`, `read`, `return` |
| **Operadores de Igualdade** | `==`, `!=`, `<>` (`EQOP`) |
| **Operadores Relacionais** | `<`, `>`, `<=`, `>=` (`RELOP`) |
| **Operadores Aritméticos** | `+` (`PLUS`), `-` (`MINUS`), `*` (`MULT`), `/` (`DIV`), `%` (`MOD`), `=` (`ASSIGN`) |
| **Operadores Lógicos** | `&&` (`AND`), `\|\|` (`OR`), `!` (`NOT`) |
| **Pontuação / Delimitadores** | `;` (`SEMI`), `,` (`COMMA`), `(` (`LPAREN`), `)` (`RPAREN`), `{` (`LBRACE`), `}` (`RBRACE`) |
| **Identificadores (`ID`)** | Começam com letra seguida de letras, dígitos ou underscore: `[a-zA-Z][a-zA-Z0-9_]*` |
| **Numéricos (`NUM_INT`, `NUM_FLOAT`)** | Suporta inteiros (`10`) e floats com notação científica opcional (`2.5E+1`, `0.5e-2`) |

---

## Etapa 2: Analisador Sintático (Bison)

### Integração com o Flex
- O `parser.y` declara os tokens (`%token`); o `bison -d` gera o `parser.tab.h`, incluído pelo `lexer.l`.
- Cada regra de token do lexer faz `return TOKEN`; espaços, comentários e erros léxicos não retornam nada ao parser.
- O `main` foi movido para o `parser.y` e chama `yyparse()`; ao final são impressas a tabela de símbolos e a quantidade de erros léxicos e sintáticos.

### Gramática
- **Comandos:** declaração (`int a, b = 10;`), atribuição (`a = expr;`), `if`/`else`, `while`, blocos `{ }`, `print(expr);`, `read(id);`, `return expr;` e comando vazio (`;`). Declarações são comandos, podendo aparecer dentro de blocos.
- **Dangling else:** resolvido na própria gramática, dividindo os comandos em *casados* (todo `if` tem `else`) e *abertos* (Aula 7). O `else` sempre pertence ao `if` mais próximo e o Bison não reporta conflitos. O `while` foi dividido da mesma forma, pois também termina com um comando.
- **Precedência e associatividade** (da menor para a maior, todas à esquerda, exceto os unários):

  | Nível | Operadores |
  | :--- | :--- |
  | 1 | `\|\|` |
  | 2 | `&&` |
  | 3 | `==` `!=` `<>` |
  | 4 | `<` `>` `<=` `>=` |
  | 5 | `+` `-` |
  | 6 | `*` `/` `%` |
  | 7 | `!` |
  | 8 | `-` unário (`%prec UMINUS`) |

- **Números negativos:** o lexer sempre gera números sem sinal; o `-` é resolvido no parser como binário (por precedência) ou unário (`MINUS expr %prec UMINUS`).

### Erros Sintáticos
- `yyerror` informa a linha e a coluna do token onde o erro foi detectado (ou o fim de arquivo inesperado).
- Recuperação em modo pânico: as regras `lista_comandos error SEMI { yyerrok; }` e `lista_comandos error RBRACE` descartam tokens até um `;` ou `}` e a análise continua, permitindo reportar vários erros em uma única execução.

---

## Como Executar

### Pré-requisitos
- `flex`
- `bison`
- `gcc`

### Passos
1. **Utilize o script junto ao arquivo que deseja testar:**
   ```bash
   ./compiler.sh <arquivo-fonte>
   ```

### Arquivos de Teste
- `programa.txt`: programa válido cobrindo toda a gramática (termina com um comentário não fechado, testando a correção da Etapa 1).
- `teste_sintatico_invalido.txt`: erros sintáticos e recuperação.
- `teste_completo.txt`: teste léxico da Etapa 1.