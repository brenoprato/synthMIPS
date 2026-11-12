# Casos de Teste Reproduzíveis — SynthMIPS

Todos os testes abaixo utilizam estados determinísticos e rastreáveis na memória *Heap* (`0x10040000`) e no segmento `.data` do programa, permitindo repetição exata no simulador **MARS 4.5+** sem dependência de aleatoriedade.

---

## Caso de Teste 1: Uso Normal (5 Demos Completas (104–144 Passos) + Estúdio com Sustain `~` + Edição Completa na Heap + Reverse + Loop `2x`)

### Objetivo
Comprovar o carregamento das 5 músicas demonstrativas completas (104–144 passos) com sustentação contínua (`-2` = `~~~`) e ajuste automático de timbre/BPM, a criação e edição completa de uma melodia usando 2 oitavas + sustenidos + sustain no **Estúdio de Composição e Edição** (incluindo substituição de passo, inserção no meio com deslocamento à direita, remoção de passo com deslocamento à esquerda e *Undo*), a inversão *in-place* (*Reverse*) e a reprodução fluida em **Modo Loop (`2x`)** com equalizador de 1 única `syscall 4` por nota.

### Sequência Precisa de Entradas no Console do MARS
1. Iniciar o programa no MARS (`F3` para montar $\rightarrow$ `F5` para executar). O sistema inicia com a **Demo 1 completa (*Ode à Alegria* — 136 passos com sustentação `~~~`, Piano `0`, `140 ms`)**.
2. No menu principal, digitar `6` (*Carregar Música Demonstrativa Completa*) $\rightarrow$ digitar `4` (*Asa Branca — Luiz Gonzaga — 136 passos, Sanfona `21`, `140 ms`*) $\rightarrow$ digitar `0` para voltar ao menu visualizando os 136 passos numerados.
3. No menu principal, digitar `2` (*Estúdio de Composição e Edição na Heap*):
   - Escolher `6` (*Substituir faixa inteira / Começar do zero*) $\rightarrow$ digitar `a s d f w e z x -` e pressionar `ENTER` $\rightarrow$ pressionar `ENTER` vazio (ou `0`) para encerrar a adição contínua.
   - Escolher `2` (*Editar / Substituir nota de um passo*) $\rightarrow$ passo `3` $\rightarrow$ tecla `t` (`FA#4 = 66`).
   - Escolher `3` (*Inserir nota no meio da faixa*) $\rightarrow$ posição `2` $\rightarrow$ tecla `y` (`SOL#4 = 68`).
   - Escolher `4` (*Remover nota de um passo específico*) $\rightarrow$ passo `1`.
   - Escolher `5` (*Desfazer última nota — Undo*).
   - Escolher `0` (*Voltar ao Menu Principal*).
4. No menu principal, digitar `5` (*Efeitos de Estúdio*) $\rightarrow$ digitar `3` (*Inverter Melodia — Reverse*).
5. No menu principal, digitar `1` (*Tocar Faixa — PLAY / Modo Loop*) $\rightarrow$ digitar `2` (*2 repetições*).
6. Digitar `0` (*Sair*).

### Cálculo Manual e Estado da Memória Heap (`0x10040000`)
- **Após gravar `a s d f w e z x -` (`N = 9`):**
  - Espaços são ignorados automaticamente.
  - Notas na *Heap*: `[60, 62, 64, 65, 61, 63, 48, 50, 0]`
    (`[01:DO4  ] [02:RE4  ] [03:MI4  ] [04:FA4  ] [05:DO#4 ] [06:RE#4 ] [07:DO3  ] [08:RE3  ] [09:---  ]`).
- **Após Editar passo `3` para `t` (`FA#4 = 66`):**
  - `heap_seq[2]` passa de `64` (`MI4`) para `66` (`FA#4`).
- **Após Inserir `y` (`SOL#4 = 68`) na posição `2` (`inserir_nota_posicao_heap`):**
  - Os passos `2..9` são deslocados uma palavra para a direita (`N` vai para `10`) e `heap_seq[1]` recebe `68` (`SOL#4`):
    `[60, 68, 62, 66, 65, 61, 63, 48, 50, 0]`.
- **Após Remover o passo `1` (`remover_nota_posicao_heap`):**
  - Os passos `2..10` são deslocados uma palavra para a esquerda (`N` passa para `9`):
    `[68, 62, 66, 65, 61, 63, 48, 50, 0]`.
- **Após *Undo* (`N = 8`):**
  - Remove a pausa final (`0`), restando `8` notas:
    `[68, 62, 66, 65, 61, 63, 48, 50]` (`SOL#4, RE4, FA#4, FA4, DO#4, RE#4, DO3, RE3`).
- **Após *Reverse* (`inverter_sequencia`, `N = 8`):**
  - Vetor invertido *in-place* na *Heap*:
    **`[50, 48, 63, 61, 65, 66, 62, 68]`**
    (`[01:RE3  ] [02:DO3  ] [03:RE#4 ] [04:DO#4 ] [05:FA4  ] [06:FA#4 ] [07:RE4  ] [08:SOL#4]`).

### Resultado Observado e Justificativa
- **Resultado Observado:** Todas as operações atualizam imediatamente a grade numerada `[01:..]`, tocam o som correspondente e reproduzem os 2 ciclos completos do Modo Loop sem erros, finalizando com `$sp = 0x7fffeffc`.
- **Justificativa:** Os procedimentos `inserir_nota_posicao_heap`, `remover_nota_posicao_heap` e `inverter_sequencia` manipulam os deslocamentos de palavras de 32 bits (`sll $t*, $i, 2`) diretamente sobre o bloco contíguo da *Heap*.

---

## Caso de Teste 2: Blindagem contra Entradas Inválidas (Letras em Menus, `ENTER` Vazio, Passo `> N`, Tecla Inválida e Loop Fora de Faixa)

### Objetivo
Comprovar que o procedimento **`ler_inteiro_seguro`** (baseado em `syscall 8`) elimina 100% das exceções fatais do MARS quando o usuário digita letras ou aperta `ENTER` vazio em menus numéricos, e que todas as validações de domínio preservam a integridade da memória *Heap*.

### Sequência Precisa de Entradas no Console do MARS
1. Iniciar o programa no MARS (`N = 32`, Demo 1 carregada).
2. No menu principal, digitar `abc` e pressionar `ENTER` *(letras em menu numérico)*.
3. No menu principal, apenas pressionar `ENTER` vazio *(linha vazia)*.
4. No menu principal, digitar `99` e pressionar `ENTER` *(opção numérica inexistente)*.
5. Digitar `2` (*Estúdio de Composição*) $\rightarrow$ escolher `2` (*Editar passo*) $\rightarrow$ digitar `99` *(passo inválido `99 > 32`)*.
6. Ainda no Estúdio, escolher `2` (*Editar passo*) $\rightarrow$ digitar passo `1` (*válido*) $\rightarrow$ digitar `?` *(tecla musical inválida)*.
7. Digitar `0` para voltar ao menu principal $\rightarrow$ digitar `1` (*Tocar Faixa*) $\rightarrow$ digitar `0` *(repetições de loop inválidas `< 1`)*.
8. Digitar `0` (*Sair*).

### Resultado Esperado e Observado
- **Etapas 2 e 3 (`abc` e `ENTER` vazio):** `ler_inteiro_seguro` lê a string via `syscall 8`, detecta ausência de dígitos válidos e retorna `$v0 = -1` sem jamais invocar `syscall 5` (que abortaria o MARS). O menu exibe `[!] Opcao invalida! Digite um numero valido do menu.` e continua normalmente.
- **Etapa 5 (Passo `99 > N`):** O sistema compara a posição com `tam_sequencia` (`32`), rejeita o índice fora de faixa e preserva a *Heap* intacta.
- **Etapa 6 (Tecla `'?'`):** `traduzir_tecla('?')` percorre as 21 teclas válidas, retorna `-1` e mantém o passo `1` (`MI4`) inalterado.
- **Etapa 7 (Loop `0`):** A verificação `blt $t1, 1, opt_tocar_err_loop` intercepta o valor inválido e retorna ao menu.
- **Estado Final:** A Demo 1 permanece 100% intacta na *Heap* (`N = 32`) e `$sp = 0x7fffeffc`.

---

## Caso de Teste 3: Situação Limite (Faixa Vazia `N = 0` + Saturação no Teto `96` e Piso `36` com Pausa `0`)

### Objetivo
Avaliar o comportamento do sistema sob condições extremas de fronteira:
1. Tentativa de tocar, editar, remover ou aplicar efeitos quando a faixa está vazia (`tam_sequencia == 0`).
2. Comportamento da transposição (`+2` / `-2` semitons) na fronteira superior (`96` = `DO7`) e na preservação de pausas (`0`), exibindo os nomes cromáticos reais (`DO7  ` e `---  `).

### Sequência Precisa de Entradas no Console do MARS
1. Iniciar o programa no MARS (`N = 32`).
2. Digitar `2` (*Estúdio de Composição*) $\rightarrow$ escolher `8` (*Limpar / Zerar faixa*, `N = 0`) $\rightarrow$ escolher `0` (*Voltar*).
3. No menu principal, tentar tocar a faixa vazia: digitar `1` (*Tocar Faixa*).
4. Digitar `2` (*Estúdio de Composição*) $\rightarrow$ `1` (*Adicionar ao final*) $\rightarrow$ digitar `-l` (`Pausa = 0` e `RE5 = 74`) e pressionar `ENTER` $\rightarrow$ pressionar `ENTER` vazio para concluir $\rightarrow$ digitar `0` para voltar ao menu.
5. No menu principal, acessar `5` (*Efeitos de Estúdio*) $\rightarrow$ digitar `1` (*Transpor +2 semitons*) **12 vezes consecutivas**.
6. Digitar `0` (*Sair*).

### Cálculo Manual e Rastreamento da Situação Limite
- **Na etapa 3 (PLAY com Faixa Vazia `N = 0`):**
  - O sistema verifica `bgtz $t0, opt_tocar_pedir_loop`, imprime `[!] A faixa esta vazia (0 notas)!` e não acessa a *Heap*.
- **Na etapa 4 (Composição de `-l`):**
  - `-` gera Pausa (`0` $\rightarrow$ `---  `).
  - `l` gera `RE5` (`74` $\rightarrow$ `RE5  `).
  - Vetor na *Heap*: `tam_sequencia = 2`, `heap_seq[0] = 0` e `heap_seq[1] = 74`.
- **Evolução das 12 Transposições (`+2` semitons cada):**
  - **Passo 1 (`heap_seq[0] = 0`):** A guarda `beq $t2, $zero, transp_proximo` pula a soma em todas as 12 execuções. A pausa permanece rigorosamente em **`0`** (`[01:---  ]`).
  - **Passo 2 (`heap_seq[1]` inicial = `74`):**
    - Após 11 transposições: `74 + 22 = 96` (`[02:DO7  ]`, limite máximo seguro).
    - **Na 12ª transposição (Fronteira Extrema):** `96 + 2 = 98`. O *clamping* `ble $t2, 96, transp_salvar` satura o valor em **`96`**.
  - **Resultado Final no Painel (`N = 2`):**
    **`Faixa: [01:---  ] [02:DO7  ]`** (`0` e `96` na *Heap*).

---

## Trechos Centrais Recomendados para a Prova Individual

### 1. `imprimir_nome_nota` — Decomposição Cromática (`nota % 12`) e Oitava (`(nota / 12) - 1`)
```mips
imprimir_nome_nota:
    move $t0, $a0
    blez $t0, inn_pausa

    # Calcula quociente (nota / 12) e resto (nota % 12)
    li   $t1, 12
    div  $t0, $t1
    mflo $t2                        # $t2 = nota / 12
    mfhi $t3                        # $t3 = nota % 12 (0..11)
    addi $t2, $t2, -1               # $t2 = oitava = (nota / 12) - 1

    # Imprime o nome cromatico correspondente na tabela tab_nomes_crom
    sll  $t4, $t3, 2
    la   $t5, tab_nomes_crom
    add  $t5, $t5, $t4
    lw   $a0, 0($t5)
    li   $v0, 4
    syscall

    # Imprime o numero da oitava
    move $a0, $t2
    li   $v0, 1
    syscall
```

### 2. `inserir_nota_posicao_heap` — Expansão da Heap (`syscall 9`) e Deslocamento à Direita
```mips
    # Garante espaco para N+1 anexando ao final via syscall 9 se necessario
    move $a0, $s1
    jal  adicionar_nota_heap        # tam_sequencia passa para N_novo = N + 1

    lw   $t0, ptr_sequencia
    lw   $t1, tam_sequencia         # $t1 = N_novo
    addi $t2, $t1, -1               # $t2 = k = N_novo - 1
    addi $t3, $s0, -1               # $t3 = idx = pos - 1

inph_shift_loop:
    ble  $t2, $t3, inph_gravar
    addi $t4, $t2, -1
    sll  $t4, $t4, 2
    add  $t4, $t0, $t4              # &heap[k - 1]
    lw   $t5, 0($t4)
    sll  $t6, $t2, 2
    add  $t6, $t0, $t6              # &heap[k]
    sw   $t5, 0($t6)                # heap[k] = heap[k - 1]
    addi $t2, $t2, -1
    j    inph_shift_loop

inph_gravar:
    sll  $t4, $t3, 2
    add  $t4, $t0, $t4              # &heap[pos - 1]
    sw   $s1, 0($t4)                # Grava a nota inserida
```
