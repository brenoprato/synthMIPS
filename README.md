# SynthMIPS — Mini-Estúdio Musical e Sequenciador Dinâmico em Assembly MIPS

Projeto desenvolvido para o **Criathon MIPS** da disciplina de **Arquitetura e Organização de Computadores** (ICT Unifesp — **Profa. Denise Stringhini**).

O **SynthMIPS** transforma o simulador **MARS 4.5** em um mini-estúdio musical completo e sequenciador interativo com **alocação dinâmica na Heap via `syscall 9` (*sbrk*)**, **sustentação contínua de notas (`~~~`, valor `-2`) sem cortes rítmicos**, **equalizador ASCII renderizado em 1 única `syscall 4` por nota** (zero *jitter* no console Swing do MARS), **painel visual numerado passo a passo (`[01:MI4  ] [02:~~~  ] ...`)**, **teclado musical expandido de 2 oitavas + sustenidos + sustain** e **5 músicas demonstrativas completas de 100+ passos**. O programa sintetiza áudio MIDI real (`syscall 33`), controla pausas rítmicas (`syscall 32`), possui blindagem total de entrada (`syscall 8` em `ler_inteiro_seguro`, evitando exceções fatais do MARS ao digitar letras) e aplica transformações algorítmicas diretamente sobre o vetor na memória *Heap*.

---

## Integrantes do Grupo

- **Breno Porto Pinheiro do Prado**
- **Felipe Pereira Silva**
- **Guilherme Bento Ramos**
- **José Rubens Freitas Pinheiro**
- **Luis Fernando Giaquinto Zólio**

---

## Diferencial Arquitetural: Vetor Dinâmico na Heap (`syscall 9`) e Blindagem de Entrada

Diferente de sequenciadores estáticos limitados a um número fixo de passos em `.data`, a faixa musical do **SynthMIPS** **não possui tamanho fixo nem limite pré-configurado**:
- A música reside na memória *Heap* do MARS (a partir de `0x10040000`).
- Conforme o usuário compõe ou insere novas notas, o sistema invoca a chamada de sistema **`syscall 9` (`sbrk`, `$a0 = 4`)**, alocando blocos contíguos de 4 bytes sob demanda e reaproveitando capacidade física (`cap_alocada`) após remoções ou *Undo*.
- **Blindagem contra crashes do MARS (`ler_inteiro_seguro`):** Todas as leituras de opções numéricas utilizam `syscall 8` com parser próprio em Assembly MIPS (ignorando espaços/tabs e validando dígitos `'0'..'9'`), eliminando 100% das exceções fatais que a `syscall 5` causaria caso o usuário pressionasse `ENTER` vazio ou digitasse letras por engano nos menus.

---

## Principais Funcionalidades

1. **Painel Visual Numerado Passo a Passo (`[01:MI4  ] [02:~~~  ] ...`):**
   - Exibe o **nome por extenso do instrumento MIDI ativo** (ex.: `Piano Acustico (0)`, `Synth 8-bit Square (80)`, `Sanfona / Acordeao (21)`), o andamento base em milissegundos e o total `N` de passos na *Heap*.
   - Imprime cada passo numerado de `01` a `N` (8 passos por linha) com a **cifra cromática real + oitava** de qualquer nota MIDI calculada via divisão por 12 (`nota % 12` e `(nota / 12) - 1`), como `DO4`, `FA#4`, `SOL3`, `~~~` para sustentação contínua (`-2`) ou `---` para pausa (`0`).
2. **`[1]` Tocar Faixa (PLAY / Modo Loop Fluido + Equalizador em 1 `syscall`):**
   - Reproduz a composição uma única vez (`K = 1`) ou em **Modo Loop** por `K` repetições consecutivas (`1..20`).
   - **Sustentação Contínua (`-2` = `~~~`):** Ao tocar uma nota no passo `i`, o motor olha à frente (`i+1, i+2...`) somando `+duracao_ms` para cada passo `~~~` consecutivo e dispara **uma única `syscall 33`** com a duração total (`cont_passos * duracao_ms`), produzindo semínimas, mínimas e notas pontuadas perfeitamente ligadas sem buracos mudos!
   - **Zero Jitter no MARS Gráfico:** A linha inteira do equalizador (`" Passo 01 [MI4  ] | ###############===\n"`) é montada em memória (`buf_linha_eq`) via `sb` e impressa com **uma única `syscall 4`** por nota.
3. **`[2]` Estúdio de Composição e Edição na Heap (Laço Interativo Completo):**
   - Permanece dentro do Estúdio reexibindo a faixa numerada `[01:DO4  ]...` e o guia do teclado após cada operação:
   - `[1]` **Adicionar notas ao final (Modo Contínuo na Heap):** Digite sequências inteiras (ex.: `asdfghjkl`, `wetyu`, `zxcvbnm`) ou nota por nota; espaços são ignorados e cada nota expande a *Heap* (`syscall 9`) e toca na hora. Digite `0` ou `ENTER` vazio para encerrar.
   - `[2]` **Editar / Substituir nota de um passo (`1..N`):** Exibe qual nota está atualmente no passo escolhido, lê a nova tecla, toca o novo som e atualiza na *Heap*.
   - `[3]` **Inserir nota no meio da faixa (`1..N`):** Expande a *Heap* (`+4` bytes), desloca os passos `pos..N` uma casa para a direita e insere a nova nota na posição exata!
   - `[4]` **Remover nota de um passo específico (`1..N`):** Remove o passo escolhido deslocando os passos seguintes uma casa para a esquerda e decrementando `tam_sequencia`.
   - `[5]` **Desfazer última nota (*Undo* rápido):** Remove imediatamente a última nota (`N = N - 1`).
   - `[6]` **Substituir faixa inteira (Começar nova música do zero):** Zera a faixa e abre imediatamente a gravação contínua.
   - `[7]` **Ouvir faixa atual (*PLAY* rápido 1x):** Toca a faixa inteira sem sair do editor.
   - `[8]` **Limpar / Zerar faixa (`N = 0`):** Esvazia a faixa mantendo o usuário no estúdio.
4. **`[3]` Modo Teclado Livre (Improvisação em 2 Oitavas + Sustenidos):**
   - Permite improvisar livremente e oferece a opção de anexar a sequência tocada ao final da faixa na *Heap*.
5. **`[4]` Configurar Instrumento e Andamento (BPM):**
   - Alterna entre 7 timbres MIDI (`0` Piano Acústico, `24` Violão/Guitarra, `33` Baixo, `80` Synth 8-bit Square, `40` Violino/Cordas, `21` Sanfona/Acordeão, `56` Trompete/Metais) e 3 andamentos base (`180 ms` Calmo, `140 ms` Normal/Fluido, `115 ms` Rápido).
6. **`[5]` Efeitos de Estúdio sobre o Vetor Dinâmico (`N` notas):**
   - **Transpor Tom (`+2` ou `-2` semitons):** Soma/subtrai semitons nas notas ativas (`> 0`), preserva pausas (`0`) e passos de sustentação (`-2`, `~~~`) intactos e aplica saturação (*clamping*) nos limites `36..96`.
   - **Inverter Melodia (*Reverse*):** Inverte *in-place* as `N` notas na *Heap* (`heap_seq[i] <-> heap_seq[N - 1 - i]`).
7. **`[6]` Carregar Música Demonstrativa Completa (5 Clássicos de 104–144 Passos com Sustentação):**
   - Carrega músicas completas (104–144 passos, sem limite fixo) na *Heap* via `syscall 9`, ajustando automaticamente o **instrumento** e a **duração base (`duracao_ms`)** ideais de cada obra e oferecendo reprodução imediata:
     - **Demo 1 — Ode à Alegria (Beethoven) Completa:** 136 passos | Piano Acústico (`0`) | `140 ms`
     - **Demo 2 — Super Mario Bros (Overworld Completo: Intro + A1 + A2):** 144 passos | Synth 8-bit (`80`) | `125 ms`
     - **Demo 3 — Marcha Imperial / Star Wars Completa (Tema + Ponte Aguda + Final):** 120 passos | Trompete / Metais (`56`) | `135 ms`
     - **Demo 4 — Asa Branca (Luiz Gonzaga) Completa:** 136 passos | Sanfona / Acordeão (`21`) | `140 ms`
     - **Demo 5 — Brilha, Brilha Estrelinha Completa (Forma A-B-A):** 104 passos | Violão (`24`) | `135 ms`
8. **`[0]` Sair:** Finaliza o programa de forma limpa via `syscall 10`.

---

## Teclado Musical Expandido (2 Oitavas + Sustenidos = 21 Teclas)

O sistema aceita letras maiúsculas ou minúsculas distribuídas em 3 fileiras ergonômicas do teclado QWERTY (espaços em branco `' '` são ignorados para facilitar a digitação agrupada):

### 1. Fileira Central — Oitava Central + Aguda (`Dó4` a `Ré5`)
| Tecla | `A` | `S` | `D` | `F` | `G` | `H` | `J` | `K` | `L` |
| :---: | :---: | :---: | :---: | :---: | :---: | :---: | :---: | :---: | :---: |
| **Nota (Cifra)** | `DO4` | `RE4` | `MI4` | `FA4` | `SOL4` | `LA4` | `SI4` | `DO5` | `RE5` |
| **Valor MIDI** | `60` | `62` | `64` | `65` | `67` | `69` | `71` | `72` | `74` |

### 2. Fileira Superior — Sustenidos / Bemóis (`Dó#4` a `Lá#4`)
| Tecla | `W` | `E` | `T` | `Y` | `U` |
| :---: | :---: | :---: | :---: | :---: | :---: |
| **Nota (Cifra)** | `DO#4` | `RE#4` | `FA#4` | `SOL#4` | `LA#4` |
| **Valor MIDI** | `61` | `63` | `66` | `68` | `70` |

### 3. Fileira Inferior — Oitava Grave (`Dó3` a `Si3`), Sustentação e Pausa
| Tecla | `Z` | `X` | `C` | `V` | `B` | `N` | `M` | `~`, `+` ou `=` | `-` ou `.` |
| :---: | :---: | :---: | :---: | :---: | :---: | :---: | :---: | :---: | :---: |
| **Nota (Cifra)** | `DO3` | `RE3` | `MI3` | `FA3` | `SOL3` | `LA3` | `SI3` | `~~~` (Sustentar) | `---` (Pausa) |
| **Valor na Heap** | `48` | `50` | `52` | `53` | `55` | `57` | `59` | `-2` | `0` |

---

## Como Executar no MARS

1. **Pré-requisitos:** Simulador **MARS 4.5+** com Java Runtime Environment (JRE) instalado e saída de áudio habilitada no sistema operacional.
2. **Abrir o arquivo principal:** No MARS, clique em `File` $\rightarrow$ `Open...` e selecione [`src/synthmips.asm`](src/synthmips.asm).
3. **Configurações do simulador:** Utilizar as opções padrão do MARS 4.5. Não são necessárias ferramentas externas (*Bitmap Display* ou *Keyboard MMIO*), pois toda a interação ocorre na aba **Run I/O** com síntese MIDI nativa.
4. **Montar e Executar:**
   - Pressione **`F3`** (*Assemble*) para montar o programa.
   - Pressione **`F5`** (*Go*) para iniciar a execução e interagir pelo console **Run I/O**.

---

## Estrutura do Repositório

| Caminho | Descrição |
| :--- | :--- |
| [`README.md`](README.md) | Apresentação geral, arquitetura da Heap, mapeamento de 2 oitavas + sustenidos, 4 Demos e instruções. |
| [`src/synthmips.asm`](src/synthmips.asm) | Código-fonte completo em Assembly MIPS (~590 instruções úteis), modularizado e comentado. |
| [`docs/proposta-fase1.md`](docs/proposta-fase1.md) | Proposta detalhada da Fase 1, escopo e divisão em 5 frentes funcionais. |
| [`docs/ficha-tecnica.md`](docs/ficha-tecnica.md) | Ficha técnica completa (Heap `0x10040000`, procedimentos, pilha `$sp` e requisitos MIPS). |
| [`docs/testes.md`](docs/testes.md) | Casos de teste reproduzíveis (Demos, edição/inserção/remoção na Heap, entradas inválidas e limites). |
| [`docs/uso-ia.md`](docs/uso-ia.md) | Registro transparente do uso de IA, adaptações de código e rastreamento manual (*trace*). |

---

## Divisão de Trabalho em 5 Frentes Funcionais

- **Frente 1 — Gerenciador da Heap, Leitura Segura e Painel Numerado:** Modelagem do vetor na *Heap* (`syscall 9`), `ler_inteiro_seguro`, `exibir_painel`, `exibir_grade_notas`, `imprimir_nome_instrumento` e `imprimir_nome_nota` (cálculo cromático `nota % 12` e oitava).
- **Frente 2 — Motor MIDI Síncrono, Modo Loop e Equalizador Visual:** Implementação de `tocar_sequencia` (laços aninhados de repetições `K` e notas `N`), `tocar_nota_unica` e `desenhar_barra_nota` com salvamento na pilha (`$sp`).
- **Frente 3 — Teclado de 2 Oitavas + Sustenidos e Estúdio Completo de Edição:** Procedimentos `traduzir_tecla` (21 teclas + pausa), `compor_faixa` (adição contínua, edição, inserção no meio `inserir_nota_posicao_heap`, remoção `remover_nota_posicao_heap`, Undo, substituir e PLAY rápido) e `modo_teclado_livre`.
- **Frente 4 — Efeitos de Estúdio e 4 Músicas Demonstrativas Completas:** Algoritmos `aplicar_transposicao` (*clamping* `36..96`), `inverter_sequencia` (*swap in-place*), `configurar_estudio` e `carregar_demo` (4 clássicos completos com ajuste automático de timbre e BPM).
- **Frente 5 — Testes Reproduzíveis, Documentação Técnica e Roteiro de Demonstração:** Elaboração e verificação dos casos de teste determinísticos no MARS, rastreamento de registradores e consolidação da documentação.

---

## Limitações Conhecidas

- A reprodução MIDI (`syscall 33`) é monofônica e síncrona passo a passo, dependendo do sintetizador Java Sound disponibilizado pelo sistema operacional.
- O tamanho máximo da faixa musical é limitado unicamente pelo espaço de memória disponível no segmento *Heap* do simulador MARS.

---

## Link do Vídeo de Demonstração

- **Vídeo Final (até 4 min):** *(link será adicionado na entrega da Fase 3)*
