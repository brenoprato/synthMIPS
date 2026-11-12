# Registro de Uso de Inteligência Artificial e Fontes — SynthMIPS

## 1. Ferramentas Utilizadas e Finalidade

No processo de desenvolvimento do **SynthMIPS**, o grupo utilizou assistentes de Inteligência Artificial generativa como ferramenta de suporte técnico e validação arquitetural para o simulador MARS 4.5. As principais finalidades foram:

1. **Concepção do Sequenciador Dinâmico na Heap:** Discussão de alternativas para superar o limite de vetores estáticos em `.data`, optando pela alocação dinâmica contígua via `syscall 9` (*sbrk*) a partir de `0x10040000`.
2. **Ergonomia e Usabilidade Musical:** Mapeamento ergonômico da linha central do teclado QWERTY (`A S D F G H J K` $\rightarrow$ notas diatônicas `60..72` e `-` $\rightarrow$ pausa `0`), permitindo compor e improvisar sem a necessidade de memorizar códigos numéricos MIDI.
3. **Estruturação do Modo Loop e Quadros de Pilha:** Planejamento da hierarquia de procedimentos não-folha e dimensionamento de quadros de pilha (`$sp`) para laços aninhados de repetição sonora.
4. **Validação de Convenções MIPS:** Conferência da preservação de registradores callee-saved (`$s0..$s7`) e de retorno (`$ra`), além da elaboração dos casos de teste determinísticos.

---

## 2. Exemplo Relevante de Sugestão da IA, Adaptação pelo Grupo e Verificação

### Contexto do Problema: Modo Loop e Laços Aninhados em `tocar_sequencia`
No procedimento **`tocar_sequencia`**, o sistema precisa executar o **Modo Loop**: repetir a faixa musical por `K` ciclos consecutivos (`K >= 1`), percorrendo em cada ciclo as `N` notas dinâmicas da *Heap* (`ptr_sequencia + 4 * i`).

Para cada nota:
1. Chama `tocar_nota_unica(passo, nota)`;
2. Este, por sua vez, chama `desenhar_barra_nota` (que chama `imprimir_nome_nota` e executa `syscall 1` e `syscall 4`);
3. Em seguida, aciona a `syscall 33` (MIDI síncrono para notas ativas) ou `syscall 32` (Sleep para pausas `0`), que utilizam os registradores de argumento `$a0..$a3`.

### O que a sugestão inicial propunha vs. O que o grupo alterou
- **Falha da Abordagem Ingênua:** Uma primeira sugestão de código mantinha os contadores de ciclo (`K`), índice do passo (`i`), tamanho `N` e ponteiro da *Heap* em registradores temporários (`$t0..$t4`), salvando apenas `$ra` na pilha.
  - **Problema crítico:** Como as rotinas de desenho de barras e as chamadas de sistema utilizam registradores temporários e alteram `$a0..$a3`, os contadores dos laços eram corrompidos após a primeira nota, gerando desvios incorretos ou travamento do laço externo de repetições.
- **Adaptação Estruturada pelo Grupo em `src/synthmips.asm`:**
  1. Definimos uma política estrita de preservação: todos os registradores ativos durante os dois laços aninhados devem residir em registradores `$s*`, e esses registradores devem ser devidamente salvos no prólogo do procedimento.
  2. Alocamos um quadro de pilha de **28 bytes** em `tocar_sequencia` (`addi $sp, $sp, -28`), salvando:
     - `0($sp)`: `$s0` (ponteiro da Heap `ptr_sequencia`)
     - `4($sp)`: `$s1` (tamanho `N`)
     - `8($sp)`: `$s2` (número total de repetições `K`)
     - `12($sp)`: `$s3` (contador do ciclo atual `1..K`)
     - `16($sp)`: `$s4` (índice da nota `i` de `0..N-1`)
     - `20($sp)`: `$s5` (contador acumulado de notas tocadas)
     - `24($sp)`: `$ra` (endereço de retorno para o chamador)
  3. Adicionalmente, no gerenciador da *Heap* (`adicionar_nota_heap`), o grupo incorporou o reaproveitamento de palavras já alocadas fisicamente (`tam_sequencia < cap_alocada`), garantindo que após operações de **Desfazer (Undo)** ou **Limpar faixa** não haja expansão redundante da *Heap*.

---

## 3. Verificação Realizada (Rastreamento Manual vs. Execução no MARS)

Para assegurar a confiabilidade do código, o grupo realizou rastreamento manual (*single-step trace* com teclas `F7` e inspeção de registradores e memória) no MARS 4.5+:

### 1. Rastreamento da Pilha (`$sp`) durante o Modo Loop
- **Estado antes da chamada:** `$sp = 0x7fffeffc`.
- **Prólogo de `tocar_sequencia`:** `$sp` passa para `0x7fffefe0` (`-28` bytes). `$ra` original do `main` é armazenado em `24($sp)`.
- **Chamada aninhada `jal tocar_nota_unica`:** Aloca mais `12` bytes na pilha (`$sp = 0x7fffefd4`), salvando seu próprio `$ra` em `8($sp)`.
- **Chamada de 3º nível `jal desenhar_barra_nota`:** Aloca outros `12` bytes (`$sp = 0x7fffefc8`).
- **Desempilhamento:** Cada epílogo restaura exatamente seus registradores e avança o `$sp`. Ao retornar para `tocar_sequencia`, `$s3` (ciclo) e `$s4` (passo) permanecem completamente íntegros, permitindo iterar pelos `K` ciclos sem desvio de fluxo. Ao término do laço externo, o `$sp` retorna perfeitamente para `0x7fffeffc` (sem vazamento de memória de pilha).

### 2. Rastreamento da Alocação Dinâmica na Heap (`adicionar_nota_heap`)
- **Primeira nota adicionada:** `cap_alocada = 0`, `tam_sequencia = 0`.
  - Executa `syscall 9` com `$a0 = 4`.
  - O MARS retorna `$v0 = 0x10040000`.
  - `ptr_sequencia` recebe `0x10040000`, a nota é armazenada no endereço `0x10040000`, e ambas as variáveis `cap_alocada` e `tam_sequencia` passam para `1`.
- **Próximas inserções contínuas:** O MARS devolve endereços contíguos (`0x10040004`, `0x10040008`, ...), comprovando que os dados formam um vetor contíguo indexado via `sll $t*, $i, 2`.
- **Comportamento no Desfazer (Undo):** Ao decrementar `tam_sequencia` de `10` para `9`, `cap_alocada` permanece `10`. Ao adicionar uma nova nota, o sistema detecta `N < C`, grava no endereço `ptr_sequencia + 36` sem chamar `syscall 9` e incrementa `tam_sequencia` para `10`, validando a reutilização de slots.

---

## 4. Fontes e Referências Consultadas

1. **Documentação Oficial do MARS 4.5 (Missouri State University — Pete Sanderson e Kenneth Vollmar):**
   - Especificação de chamadas de sistema: `syscall 9` (*sbrk / Heap allocation*), `syscall 32` (*Sleep*), `syscall 33` (*MIDI Out Synchronous*) e E/S padrão (`syscall 1, 4, 5, 8, 10`).
   - Tabela de instrumentos da especificação General MIDI (GM).
2. **Material da Disciplina de Arquitetura e Organização de Computadores (ICT Unifesp — Profa. Denise Stringhini):**
   - Convenções de chamada de procedimentos MIPS, distinção entre registradores `$t*` e `$s*`, gerenciamento de quadros de pilha (`$sp`) e estratégias de endereçamento indexado em memória.
