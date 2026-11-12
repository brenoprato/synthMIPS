# Ficha Técnica — SynthMIPS

## 1. Objetivo e Visão Geral da Lógica

O **SynthMIPS** é um mini-estúdio musical interativo e sequenciador dinâmico desenvolvido em Assembly MIPS para o simulador **MARS 4.5+**. O diferencial central do projeto é que a faixa musical **não possui tamanho fixo nem teto estático de passos**: as notas residem na memória *Heap* (`0x10040000`) e o vetor **cresce sob demanda nota a nota** conforme o usuário compõe ou insere passos, por meio da chamada de sistema **`syscall 9` (`sbrk`)**.

O sistema integra:
- **Painel Visual Numerado Passo a Passo (`[01:MI4  ] [02:~~~  ] ...`):** Mostra o nome descritivo do timbre MIDI ativo, a duração base em milissegundos, o total `N` de passos na *Heap* e cada passo indexado de `01` a `N` com notação cromática + oitava calculada por aritmética inteira (`nota % 12` e `(nota / 12) - 1`), além de `~~~` para sustentação (`-2`) e `---` para pausa (`0`).
- **Sustentação Contínua (`-2` = `~~~`) e Equalizador em 1 Única `syscall 4`:** Em `tocar_sequencia`, passos consecutivos de sustentação (`-2`) após uma nota ativa são unidos numa única chamada `syscall 33` com duração `cont_passos * duracao_ms`, eliminando cortes artificiais entre tempos. Além disso, `desenhar_barra_nota` monta toda a linha do equalizador em memória (`buf_linha_eq`) via `sb` e executa uma única `syscall 4`, eliminando 100% do *jitter* de vídeo do console Swing do MARS.
- **Blindagem Total de Entrada (`ler_inteiro_seguro` via `syscall 8`):** Todas as leituras de menus e parâmetros numéricos usam `syscall 8` com validação caractere a caractere em Assembly, impedindo que o MARS sofra exceções fatais caso o usuário digite letras ou aperte `ENTER` vazio.
- **Reprodução Síncrona com Modo Loop (`K` ciclos):** Execução de `1` repetição ou repetição contínua por `K` ciclos consecutivos (`1..20`) com sintetizador MIDI nativo (`syscall 33` e `syscall 32`) e equalizador ASCII no console.
- **Estúdio Completo de Composição e Edição na Heap (Menu `[2]`):** Permanece em laço próprio reexibindo a faixa numerada após cada ação, oferecendo adição contínua ao final (com *lookahead* de `~`/`+`), substituição de passo (`1..N`), **inserção de nota no meio da faixa (`1..N`) com deslocamento à direita**, **remoção de passo específico (`1..N`) com deslocamento à esquerda**, desfazer última nota (*Undo*), substituição completa da música, audição imediata (*PLAY* rápido) e limpeza (`N = 0`).
- **Teclado Musical Expandido (2 Oitavas + Sustenidos + Sustain):** Mapeamento completo das oitavas 3, 4 e 5 (`Z..M` para `DO3..SI3`, `A..L` para `DO4..RE5`, `W E T Y U` para sustenidos `DO#4..LA#4`, `~`/`+`/`=` para sustentação `-2` e `-`/`.` para pausa `0`).
- **Efeitos de Estúdio sobre as `N` Notas:** Transposição de tom (`+2`/`-2` semitons com saturação em `36..96` e proteção de pausas `0` e sustains `-2` via `blez`) e inversão temporal da melodia (*Reverse* *in-place*).
- **5 Músicas Demonstrativas Completas (104–144 Passos) (Menu `[6]`):** *Ode à Alegria* (136 passos, Piano `0`), *Super Mario Bros Overworld Completo* (100+ passos, Synth 8-bit `80`), *Marcha Imperial / Star Wars Completa* (100+ passos, Trompete/Metais `56`), *Asa Branca — Luiz Gonzaga* (100+ passos, Sanfona `21`) e *Brilha, Brilha Estrelinha Completa* (100+ passos, Violão `24`), ajustando automaticamente o timbre e a velocidade de cada música ao carregar.

### Contagem de Instruções MIPS Úteis
- **Total em `src/synthmips.asm`:** **~720 instruções MIPS úteis** (desconsiderando comentários, linhas em branco, rótulos isolados e diretivas como `.data`, `.text`, `.word`, `.asciiz`), superando em mais de 7 vezes o requisito mínimo de 100 instruções úteis estabelecido no edital.

---

## 2. Estruturas de Dados (`.data` e Layout da *Heap* `0x10040000`)

### 2.1 Variáveis de Estado no Segmento `.data`

| Rótulo | Diretiva / Tamanho | Função no Programa |
| :--- | :--- | :--- |
| `ptr_sequencia` | `.word 0` | Endereço base do vetor dinâmico na *Heap* (`0x10040000` após a primeira alocação). |
| `tam_sequencia` | `.word 0` | Quantidade atual `N` de notas válidas na música (cresce e encolhe dinamicamente). |
| `cap_alocada` | `.word 0` | Capacidade física `C` (em palavras de 32 bits) já reservada via `syscall 9`. |
| `instrumento` | `.word 0` | Código MIDI do instrumento ativo (`0` Piano, `24` Violão, `33` Baixo, `80` Synth 8-bit, `40` Violino). |
| `duracao_ms` | `.word 220` | Duração de cada passo em milissegundos (`400` Lento, `230` Normal, `150` Rápido, ou customizado pelas Demos). |
| `volume` | `.word 110` | Volume padrão da reprodução MIDI (`0..127`). |
| `demo1_notas` .. `demo4_notas` | `.word` (32 a 36 words cada) | As 4 músicas demonstrativas completas (*Ode à Alegria*, *Super Mario Bros*, *Marcha Imperial* e *Brilha Estrelinha*) com seus respectivos `tam_demo*`, `inst_demo*` e `ms_demo*`. |
| `teclas_validas` | `.byte` (21 bytes) | Tabela das 21 teclas musicais aceitas: `'A'..'L'`, `'W','E','T','Y','U'` e `'Z'..'M'`. |
| `notas_teclas` | `.word` (21 words) | Tabela de notas MIDI correspondentes (`48..74`). |
| `tab_nomes_crom` | `.word` (12 words) | Ponteiros para as 12 cifras cromáticas (`"DO"`, `"DO#"`, `"RE"`, ..., `"SI"`). |
| `tab_tam_crom` | `.word` (12 words) | Comprimento em caracteres de cada cifra cromática para alinhamento tabular de 5 colunas. |
| `buffer_linha` | `.space 64` | Buffer dedicado à leitura segura de inteiros via `syscall 8` (`ler_inteiro_seguro`). |
| `buffer_teclas` | `.space 128` | Buffer para captura de sequências de notas musicais via `syscall 8`. |

### 2.2 Dinâmica do Vetor na Memória *Heap* (`syscall 9` — *sbrk*)

- No MARS, a área de *Heap* inicia no endereço fixo `0x10040000`.
- Quando uma nova nota é adicionada (no final ou inserida no meio) e `tam_sequencia == cap_alocada`, o procedimento `adicionar_nota_heap` executa `syscall 9` com `$a0 = 4`. O MARS expande o *break pointer* da *Heap* e retorna o endereço contíguo da nova palavra em `$v0`.
- Se for a primeira alocação (`cap_alocada == 0`), o endereço retornado (`0x10040000`) é salvo em `ptr_sequencia`.
- Na **inserção no meio da faixa** (`inserir_nota_posicao_heap`), o sistema garante capacidade para `N + 1` elementos na *Heap*, desloca os elementos `pos-1 .. N-1` uma palavra para a direita (`heap[k] = heap[k-1]`) e grava a nova nota em `heap[pos-1]`.
- Na **remoção de passo específico** (`remover_nota_posicao_heap`), os passos `pos .. N-1` são deslocados uma palavra para a esquerda (`heap[k] = heap[k+1]`) e `tam_sequencia` é decrementado (`N - 1`), mantendo `cap_alocada` pronta para reutilização imediata sem desperdício de memória.

---

## 3. Procedimentos Principais e Uso da Pilha (`$sp`)

Todos os procedimentos seguem rigorosamente a convenção MIPS (salvamento de `$ra` e registradores `$s0..$s7` pelos procedimentos chamados; parâmetros em `$a0..$a3`; retornos em `$v0..$v1`):

| Procedimento | Tipo | Parâmetros (`$a*`) e Retorno (`$v*`) | Quadro de Pilha (`$sp`) | Responsabilidade Principal |
| :--- | :--- | :--- | :--- | :--- |
| `main` | Raiz | — | — | Inicializa com Demo 1 completa (32 notas) na *Heap*, coordena o menu principal (`0..6`) usando `ler_inteiro_seguro` e despacha para os módulos. |
| `ler_inteiro_seguro` | Folha | $\rightarrow$ `$v0`: inteiro $\ge 0$ ou `-1` se inválido | Sem pilha (folha) | Lê linha com `syscall 8`, ignora espaços/tabs e converte dígitos ASCII `'0'..'9'` em inteiro sem risco de abortar o MARS. |
| `exibir_painel` | Não-folha | `$a0`: `ptr_sequencia`, `$a1`: `tam_sequencia`, `$a2`: `instrumento`, `$a3`: `duracao_ms` | **20 bytes:**<br>`0($sp)`: `$s0`<br>`4($sp)`: `$s1`<br>`8($sp)`: `$s2`<br>`12($sp)`: `$s3`<br>`16($sp)`: `$ra` | Exibe cabeçalho, chama `imprimir_nome_instrumento`, mostra BPM, total `N` e chama `exibir_grade_notas`. |
| `imprimir_nome_instrumento` | Folha | `$a0`: código MIDI | Sem pilha (folha) | Imprime o nome por extenso do timbre ativo (`Piano Acustico (0)`, `Synth 8-bit Square (80)`, etc.). |
| `exibir_grade_notas` | Não-folha | `$a0`: `ptr_sequencia`, `$a1`: `tam_sequencia` | **16 bytes:**<br>`0($sp)`: `$s0`<br>`4($sp)`: `$s1`<br>`8($sp)`: `$s2`<br>`12($sp)`: `$ra` | Percorre `heap_seq[0..N-1]` imprimindo cada passo numerado `[01:DO4  ] [02:RE4  ] ...` (8 passos por linha). |
| `imprimir_nome_nota` | Folha | `$a0`: nota MIDI | Sem pilha (folha) | Usa `div $t0, 12` (`mfhi` = `nota % 12`, `mflo` = `nota / 12`) para imprimir qualquer nota MIDI com nome cromático + oitava alinhado em 5 colunas (`DO4  `, `SOL#3`, `---  `). |
| `adicionar_nota_heap` | Folha | `$a0`: nota MIDI $\rightarrow$ `$v0`: novo `N`, `$v1`: endereço | Sem pilha (folha) | Verifica se `N == cap_alocada`. Se necessário, chama `syscall 9` (`$a0 = 4`), atualiza `cap_alocada` e grava em `ptr_sequencia + 4 * N`. |
| `inserir_nota_posicao_heap` | Não-folha | `$a0`: posição `1..N`, `$a1`: nota MIDI | **12 bytes:**<br>`0($sp)`: `$s0`<br>`4($sp)`: `$s1`<br>`8($sp)`: `$ra` | Expande a *Heap* (`adicionar_nota_heap`), desloca os passos `pos..N` para a direita e grava a nova nota em `pos`. |
| `remover_nota_posicao_heap` | Folha | `$a0`: posição `1..N` $\rightarrow$ `$v0`: novo `N` | Sem pilha (folha) | Desloca os passos seguintes uma casa para a esquerda e decrementa `tam_sequencia`. |
| `tocar_nota_unica` | Não-folha | `$a0`: passo (`1..N`), `$a1`: nota MIDI | **12 bytes:**<br>`0($sp)`: `$s0`<br>`4($sp)`: `$s1`<br>`8($sp)`: `$ra` | Chama `desenhar_barra_nota` e dispara `syscall 33` (nota ativa) ou `syscall 32` (pausa `0`). |
| `tocar_sequencia` | Não-folha | `$a0`: `ptr_sequencia`, `$a1`: `tam_sequencia`, `$a2`: repetições `K` $\rightarrow$ `$v0`: total de notas | **28 bytes:**<br>`0($sp)`: `$s0`..`20($sp)`: `$s5`<br>`24($sp)`: `$ra` | Executa o **Modo Loop**: laço externo `1..K` e laço interno `0..N-1`, invocando `tocar_nota_unica`. |
| `desenhar_barra_nota` | Não-folha | `$a0`: passo (`1..N`), `$a1`: nota MIDI | **12 bytes:**<br>`0($sp)`: `$s0`<br>`4($sp)`: `$s1`<br>`8($sp)`: `$ra` | Imprime `" Passo XX [NOTA ] | "` e desenha barra de `'#'` de tamanho `(nota - 34) / 2` (ou `'.'` se pausa). |
| `traduzir_tecla` | Folha | `$a0`: byte ASCII $\rightarrow$ `$v0`: nota MIDI (`48..74`, `0` ou `-1`) | Sem pilha (folha) | Converte minúsculas para maiúsculas e busca nas 21 teclas de `teclas_validas` / `notas_teclas` (ou `-`/`.` para pausa). |
| `ler_tecla_musical` | Não-folha | $\rightarrow$ `$v0`: nota MIDI ou `-1` | **4 bytes:**<br>`0($sp)`: `$ra` | Lê linha via `syscall 8`, ignora espaços iniciais e invoca `traduzir_tecla`. |
| `compor_faixa` | Não-folha | — | **20 bytes:**<br>`0($sp)`: `$s0`..`12($sp)`: `$s3`<br>`16($sp)`: `$ra` | Laço interativo do Estúdio de Composição e Edição (`[1]` Adição contínua, `[2]` Editar passo, `[3]` Inserir no meio, `[4]` Remover passo, `[5]` Undo, `[6]` Substituir tudo, `[7]` PLAY rápido, `[8]` Limpar faixa). |
| `modo_teclado_livre` | Não-folha | — | **20 bytes:**<br>`0($sp)`: `$s0`..`12($sp)`: `$s3`<br>`16($sp)`: `$ra` | Lê sequência via `syscall 8`, toca cada nota imediatamente e oferece opção de anexar à *Heap*. |
| `configurar_estudio` | Não-folha | — | **4 bytes:**<br>`0($sp)`: `$ra` | Permite alternar entre os 5 instrumentos MIDI e 3 velocidades de andamento (BPM) usando `ler_inteiro_seguro`. |
| `aplicar_transposicao` | Folha | `$a0`: `ptr_sequencia`, `$a1`: `tam_sequencia`, `$a2`: `delta` (`+2`/`-2`) $\rightarrow$ `$v0`: notas alteradas | **8 bytes:**<br>`0($sp)`: `$s0`<br>`4($sp)`: `$s1` | Varre as `N` notas na *Heap*, protege pausas (`0`), soma `delta` e aplica saturação (*clamping*) em `[36, 96]`. |
| `inverter_sequencia` | Folha | `$a0`: `ptr_sequencia`, `$a1`: `tam_sequencia` | Sem pilha (usa `$t0..$t5`) | Inverte o vetor *in-place* na *Heap* trocando `heap_seq[i] <-> heap_seq[N - 1 - i]`. |
| `carregar_demo` | Não-folha | `$a0`: demo (`1..4`) $\rightarrow$ `$v0`: `1` (sucesso) / `0` (erro) | **16 bytes:**<br>`0($sp)`: `$s0`..`8($sp)`: `$s2`<br>`12($sp)`: `$ra` | Configura instrumento e BPM ideais da música escolhida, zera `tam_sequencia` e carrega os 32 ou 36 passos na *Heap*. |

---

## 4. Localização dos Requisitos Técnicos no Código (`src/synthmips.asm`)

- **Alocação Dinâmica na Heap:** Procedimentos `adicionar_nota_heap` e `inserir_nota_posicao_heap` (`syscall 9`), variáveis `ptr_sequencia`, `tam_sequencia` e `cap_alocada`.
- **E/S Segura e Chamadas de Sistema:** Leitura de strings e inteiros blindada contra exceções (`syscall 8` em `ler_inteiro_seguro`), reprodução MIDI síncrona (`syscall 33`), pausas temporizadas (`syscall 32`), impressões no console (`syscall 4` e `syscall 1`) e finalização (`syscall 10`).
- **Aritmética Inteira (`div`, `mflo`, `mfhi`, `mul`):** Conversão de dígitos ASCII em `ler_inteiro_seguro` (`mul $v0, $v0, 10`) e decomposição musical `nota / 12` e `nota % 12` em `imprimir_nome_nota`.
- **Endereçamento e Manipulação de Vetores:** Cálculo de endereços indexados (`sll $t*, $i, 2`), deslocamento de subvetores para a direita (`inserir_nota_posicao_heap`) e para a esquerda (`remover_nota_posicao_heap`), e permutação *in-place* com dois ponteiros em `inverter_sequencia`.
- **Uso Justificado da Pilha (`$sp`):** Preservação estrita de `$ra` e registradores `$s*` em todos os procedimentos não-folha, mantendo `$sp = 0x7fffeffc` inalterado ao final da execução.

---

## 5. Contribuição por Frentes de Trabalho

| Frente de Trabalho | Integrantes / Responsabilidades |
| :--- | :--- |
| **Frente 1 — Gerenciador da Heap, Leitura Segura e Painel Numerado** | Modelagem da *Heap* (`syscall 9`), `ler_inteiro_seguro`, `exibir_painel`, `exibir_grade_notas`, `imprimir_nome_instrumento` e `imprimir_nome_nota` (`nota % 12`). |
| **Frente 2 — Motor MIDI Síncrono e Modo Loop** | Implementação de `tocar_sequencia` (Modo Loop `K` ciclos), `tocar_nota_unica` e `desenhar_barra_nota` com gestão de pilha `$sp`. |
| **Frente 3 — Teclado de 2 Oitavas + Sustenidos e Estúdio Completo** | Procedimentos `traduzir_tecla` (21 teclas), `compor_faixa` (inserção no meio, remoção de passo, edição, adição contínua, Undo e PLAY rápido) e `modo_teclado_livre`. |
| **Frente 4 — Efeitos de Estúdio e 4 Demos Completas** | Algoritmos `aplicar_transposicao` (*clamping* `36..96`), `inverter_sequencia` (*swap in-place*), `configurar_estudio` e `carregar_demo` (4 clássicos completos). |
| **Frente 5 — Testes Reproduzíveis e Documentação** | Execução e documentação dos casos de teste determinísticos no MARS, rastreamento manual de registradores e consolidação da documentação técnica. |

*(Integrantes do grupo: Breno Porto Pinheiro do Prado, Felipe Pereira Silva, Guilherme Bento Ramos, José Rubens Freitas Pinheiro e Luis Fernando Giaquinto Zólio).*
