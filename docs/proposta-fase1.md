# Proposta — Fase 1 (Submissão da Ideia)

> **Resumo Pronto para o Formulário (1 Parágrafo):**
> O **SynthMIPS** é um mini-estúdio musical interativo e sequenciador dinâmico desenvolvido em Assembly MIPS para o simulador MARS 4.5 pelo grupo composto por Breno Porto Pinheiro do Prado, Felipe Pereira Silva, Guilherme Bento Ramos, José Rubens Freitas Pinheiro e Luis Fernando Giaquinto Zólio. O diferencial central da arquitetura é que a composição não tem tamanho fixo nem limite pré-configurado: o vetor da melodia reside na memória *Heap* (`0x10040000`) e cresce nota a nota sob demanda via chamada de sistema `syscall 9` (*sbrk*), permitindo compor continuamente melodias de tamanho livre com suporte a edição pontual (`1..N`), desfazer (*Undo*) e limpeza (`N = 0`). O programa integra reprodução sonora em **Modo Loop** (`K` ciclos consecutivos) através do sintetizador MIDI nativo (`syscall 33` e `syscall 32`) com barras visuais de equalizador ASCII no console, além de um **Modo Teclado Livre ergonômico** mapeado na fileira central (`A S D F G H J K` para Dó a Dó agudo e `-` para pausa). Conta ainda com seleção de 5 timbres MIDI, 3 andamentos rítmicos (BPM), carregamento de demos prontas e efeitos algorítmicos aplicados sobre as `N` notas da *Heap* (transposição com saturação entre `36..96` e proteção de pausas, além de inversão *Reverse* *in-place*), cumprindo com rigor todos os requisitos de procedimentos modulares, convenções e uso justificado da pilha (`$sp`), alocação dinâmica e tratamento de exceções.

---

## 1. Identificação do Projeto e do Grupo

- **Nome provisório do produto:** **SynthMIPS** — Mini-Estúdio Musical e Sequenciador Dinâmico em Assembly MIPS
- **Disciplina:** Arquitetura e Organização de Computadores — Profa. Denise Stringhini (ICT Unifesp)
- **Integrantes do Grupo:**
  1. Breno Porto Pinheiro do Prado
  2. Felipe Pereira Silva
  3. Guilherme Bento Ramos
  4. José Rubens Freitas Pinheiro
  5. Luis Fernando Giaquinto Zólio
- **Link do Repositório no GitHub:** *(inserir URL do repositório GitHub do grupo antes do envio)*

---

## 2. Objetivo, Público Previsto e Interação Principal

- **Objetivo:** Demonstrar como conceitos avançados de arquitetura de computadores — como gerenciamento dinâmico de memória *Heap* (`syscall 9`), endereçamento indexado de vetores, laços aninhados de repetição, manipulação de strings, convenções de chamadas de procedimentos e preservação rigorosa da pilha (`$sp`) — viabilizam um estúdio musical dinâmico e funcional dentro do simulador MARS.
- **Público Previsto:** Estudantes de computação, entusiastas de música computacional e avaliadores acadêmicos que queiram experimentar composição interativa direta em Assembly sem exigir conhecimentos prévios de numeração MIDI.
- **Descrição da Interação Principal:**
  A cada ciclo do laço principal, o painel do **SynthMIPS** exibe o instrumento MIDI selecionado, o andamento (ms/BPM), a contagem atual de notas alocadas na *Heap* (`N = tam_sequencia`) e a sequência completa traduzida para cifras musicais (`DO, RE, MI, FA, SOL, LA, SI, DO+, ---` ou `#num` para notas transpostas). O usuário navega por um menu de opções (`1..6` e `0` para sair), podendo adicionar notas continuamente com crescimento sob demanda da *Heap*, tocar a faixa 1 vez ou em **Modo Loop** com equalizador ASCII visual, configurar timbres/andamentos e aplicar efeitos algorítmicos sobre a melodia.

---

## 3. Entradas, Processamento, Saídas e Exemplo de Uso

### Entradas do Usuário
- Seleção de opções numéricas nos menus via console (`syscall 5`).
- Teclas musicais ergonômicas (`A S D F G H J K` maiúsculas/minúsculas e `-`/Espaço para pausa) lidas como strings (`syscall 8`) na Composição Contínua e no Modo Teclado Livre.
- Parâmetros numéricos de configuração: número de repetições `K` para o Modo Loop, posição `1..N` para edição, escolha de instrumento (`1..5`) e velocidade de andamento (`1..3`).

### Processamento em MIPS
- **Gerenciamento Dinâmico da Heap (`syscall 9`):** A cada nova nota inserida, se `tam_sequencia == cap_alocada`, o sistema invoca `syscall 9` com `$a0 = 4` para alocar uma nova palavra contígua na *Heap* (`0x10040000`), incrementa `cap_alocada`, grava o valor MIDI no deslocamento indexado `ptr_sequencia + 4 * N` e incrementa `tam_sequencia`.
- **Tradução ASCII $\rightarrow$ MIDI:** Normalização de caracteres para maiúsculas e busca linear na tabela de teclas válidas para obter a nota diatônica (`60..72`) ou pausa (`0`).
- **Reprodução Síncrona, Modo Loop e Equalizador Visual:**
  Dois laços aninhados (`ciclo = 1..K` e `passo = 0..N-1`) percorrem o vetor dinâmico na *Heap*. Para cada nota ativa (`> 0`), aciona a `syscall 33` e calcula o tamanho da barra ASCII (`(nota - 34) / 2`); para pausas (`0`), invoca `syscall 32` (*Sleep*) e imprime `--- | .`.
- **Transformações Algorítmicas sobre `N` Notas:**
  - *Transposição (`+2` / `-2` semitons):* Varredura do índice `0..N-1` na *Heap*, somando o deslocamento apenas nas notas ativas, mantendo pausas em `0` e aplicando saturação (*clamping*) entre `36` e `96`.
  - *Inversão (Reverse):* Troca *in-place* dos elementos simétricos (`heap_seq[i] <-> heap_seq[N - 1 - i]`).

### Saídas Esperadas
- Áudio MIDI real emitido pelo sintetizador do MARS.
- Console atualizado com o total de notas `N`, cifras legíveis e barras horizontais `#` sincronizadas no console.
- Mensagens explicativas de validação de dados em caso de entradas incorretas.

### Exemplo Rápido de Uso
1. O usuário seleciona `[6] Carregar Demo Pronta` $\rightarrow$ opção `2` (*Demo 2: Brilha Estrelinha / Riff Synth*, carregando 8 notas na *Heap* com pausa).
2. Seleciona `[2] Compor / Editar Faixa` $\rightarrow$ `[1] Composição Contínua`, digita `jk` e pressiona `ENTER`. O sistema aloca mais duas notas dinamicamente na *Heap* via `syscall 9`, expandindo a faixa para `N = 10` notas. Digita `0` para retornar ao menu.
3. Seleciona `[5] Efeitos de Estúdio` $\rightarrow$ `[3] Inverter Melodia (Reverse)`, revertendo a sequência de 10 notas *in-place*.
4. Seleciona `[1] Tocar faixa (PLAY / Loop)` $\rightarrow$ informa `2` repetições para o **Modo Loop**, ouvindo a música repetir duas vezes consecutivas acompanhada do equalizador visual no console.
5. Digita `0` para sair de forma limpa.

---

## 4. Como os Requisitos Técnicos de MIPS Serão Incorporados

| Requisito Técnico (Seção 3) | Incorporação no SynthMIPS |
| :--- | :--- |
| **Decisões e repetições com função real** | Laços aninhados no Modo Loop (`1..K` e `0..N-1`), laços de varredura dinâmica na *Heap*, geração de barras `#`, despacho de opções e validações de limites. |
| **Alocação dinâmica na Heap (`syscall 9`) e vetores** | Alocação contígua nota a nota na *Heap* (`0x10040000`) via `syscall 9` (*sbrk*), variáveis de controle `ptr_sequencia`, `tam_sequencia`, `cap_alocada`, demos estáticas em `.data`, tabelas de tradução e buffers de entrada. |
| **Modularização em procedimentos claros** | Mais de 10 procedimentos estruturados: `main`, `exibir_painel`, `imprimir_nome_nota`, `adicionar_nota_heap`, `tocar_nota_unica`, `tocar_sequencia`, `desenhar_barra_nota`, `traduzir_tecla`, `compor_faixa`, `modo_teclado_livre`, `configurar_estudio`, `aplicar_transposicao`, `inverter_sequencia`, `carregar_demo`. |
| **Parâmetros, retornos e preservação** | Passagem formal de argumentos via `$a0..$a3`, retornos em `$v0..$v1` e preservação consistente de `$s0..$s6` e `$ra`. |
| **Uso justificado da pilha (`$sp`)** | Todos os procedimentos não-folha salvam `$ra` e os registradores salvos `$s*` em quadros dedicados na pilha (`$sp`), suportando chamadas aninhadas profundas (`main` $\rightarrow$ `tocar_sequencia` $\rightarrow$ `tocar_nota_unica` $\rightarrow$ `desenhar_barra_nota` $\rightarrow$ `imprimir_nome_nota`). |
| **Tratamento de entradas inválidas e encerramento** | Validação de opções do menu (`0..6`), validação de repetições do loop (`K >= 1`), validação de índices de edição (`1..N`), proteção contra operações em faixa vazia (`N == 0`), rejeição de teclas inválidas e saída via `syscall 10`. |
| **Complexidade mínima ($\ge$ 100 linhas úteis)** | O código-fonte em `src/synthmips.asm` conta com mais de **330 instruções MIPS úteis** (desconsiderando comentários, rótulos e diretivas de montagem). |

---

## 5. Escopo Mínimo e Divisão Inicial de Tarefas (5 Frentes)

Para garantir distribuição equilibrada do trabalho entre os 5 integrantes e assegurar que todos dominem a totalidade da arquitetura para a prova individual, o desenvolvimento é organizado em **5 frentes funcionais independentes de nomes fixos**:

- **Frente 1 — Gerenciador da Heap, Estruturas de Dados e Painel Visual:**
  Modelagem do crescimento dinâmico na *Heap* (`syscall 9`), variáveis `ptr_sequencia`, `tam_sequencia`, `cap_alocada`, laço principal `main`, validação de menu e procedimentos `exibir_painel` e `imprimir_nome_nota`.
- **Frente 2 — Motor MIDI Síncrono, Modo Loop e Equalizador Visual:**
  Implementação de `tocar_sequencia` com suporte a Modo Loop (`K` repetições sobre `N` notas), `tocar_nota_unica` e `desenhar_barra_nota`, com gerenciamento rigoroso do quadro de pilha (`$sp`).
- **Frente 3 — Mapeamento Ergonômico, Composição Contínua e Teclado Livre:**
  Implementação de `traduzir_tecla` (mapeamento `A S D F G H J K` e `-`), `compor_faixa` (composição contínua que expande a Heap sob demanda, edição pontual `1..N`, Undo e Clear) e `modo_teclado_livre` com gravação opcional na Heap.
- **Frente 4 — Efeitos de Estúdio sobre Vetor Dinâmico e Configuração:**
  Implementação de `aplicar_transposicao` (preservação de pausas `0` e *clamping* `36..96`), `inverter_sequencia` (*swap in-place* sobre `N` notas), `configurar_estudio` e `carregar_demo`.
- **Frente 5 — Testes Reproduzíveis, Documentação Técnica e Roteiro de Demonstração:**
  Execução e validação dos 3 casos de teste determinísticos em `docs/testes.md`, rastreamento manual de registradores (*trace*), consolidação técnica de `docs/ficha-tecnica.md`, documentação de IA em `docs/uso-ia.md` e preparação para a avaliação individual.
