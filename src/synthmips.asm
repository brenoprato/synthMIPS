# ==============================================================================
# PROJETO: SynthMIPS — Mini-Estudio Musical e Sequenciador Dinamico na Heap em MIPS
# DISCIPLINA: Arquitetura e Organizacao de Computadores (ICT Unifesp)
# DOCENTE: Profa. Denise Stringhini
# INTEGRANTES DO GRUPO:
#   - Breno Porto Pinheiro do Prado
#   - Felipe Pereira Silva
#   - Guilherme Bento Ramos
#   - Jose Rubens Freitas Pinheiro
#   - Luis Fernando Giaquinto Zolio
# SIMULADOR: MARS 4.5+ (Configuracao padrao, caixa de som/fone habilitado)
# ==============================================================================

.data
    # --------------------------------------------------------------------------
    # ESTRUTURAS DE DADOS PRINCIPAIS (Alinhadas em palavras de 32 bits)
    # --------------------------------------------------------------------------
    .align 2
    ptr_sequencia:      .word 0         # Endereco base do vetor na Heap (0x10040000 apos 1a alocacao)
    tam_sequencia:      .word 0         # Quantidade atual N de passos na faixa musical
    cap_alocada:        .word 0         # Capacidade fisica alocada na Heap via syscall 9 (sbrk)

    instrumento:        .word 0         # Codigo MIDI (0=Piano, 24=Violao, 21=Sanfona, 56=Trompete, 80=Synth, 40=Violino, 33=Baixo)
    duracao_ms:         .word 140       # Duracao base de 1 passo (colcheia) em milissegundos
    volume:             .word 115       # Volume MIDI (0..127)

    # --------------------------------------------------------------------------
    # 5 MUSICAS DEMONSTRATIVAS COMPLETAS COM SUSTENTACAO CONTINUA (-2 = ~~~)
    # Convencao de valores na Heap:
    #   > 0 : Nota MIDI ativa (ex: 60 = DO4)
    #    -2 : Sustentacao / Prolongamento da nota anterior (~~~ : soma +duracao_ms sem corte!)
    #     0 : Pausa / Silencio real (---)
    # --------------------------------------------------------------------------

    # Demo 1: Ode a Alegria (Beethoven - 9a Sinfonia) Completa - 136 passos (Piano 0, 140 ms)
    demo1_notas:
        .word 64, -2, 64, -2, 65, -2, 67, -2, 67, -2, 65, -2, 64, -2, 62, -2
        .word 60, -2, 60, -2, 62, -2, 64, -2, 64, -2, -2, 62, 62, -2, -2,  0
        .word 64, -2, 64, -2, 65, -2, 67, -2, 67, -2, 65, -2, 64, -2, 62, -2
        .word 60, -2, 60, -2, 62, -2, 64, -2, 62, -2, -2, 60, 60, -2, -2,  0
        .word 62, -2, 62, -2, 64, -2, 60, -2, 62, -2, 64, 65, 64, -2, 60, -2
        .word 62, -2, 64, 65, 64, -2, 62, -2, 60, -2, 62, -2, 55, -2, -2,  0
        .word 64, -2, 64, -2, 65, -2, 67, -2, 67, -2, 65, -2, 64, -2, 62, -2
        .word 60, -2, 60, -2, 62, -2, 64, -2, 62, -2, -2, 60, 60, -2, -2, -2
        .word -2, -2, -2, -2, -2, -2, -2, -2
    tam_demo1:          .word 136
    inst_demo1:         .word 0
    ms_demo1:           .word 140

    # Demo 2: Super Mario Bros (Overworld Completo: Intro + Parte A1 + A2) - 144 passos (Synth 80, 125 ms)
    demo2_notas:
        .word 64, 64,  0, 64,  0, 60, 64, -2, 67, -2, -2,  0, 55, -2, -2,  0
        .word 60, -2,  0, 55, -2,  0, 52, -2,  0, 57, -2, 59, -2, 58, 57, -2
        .word 55, 64, 67, 69, -2, 65, 67,  0, 64, -2, 60, 62, 59, -2, -2,  0
        .word 60, -2,  0, 55, -2,  0, 52, -2,  0, 57, -2, 59, -2, 58, 57, -2
        .word 55, 64, 67, 69, -2, 65, 67,  0, 64, -2, 60, 62, 59, -2, -2,  0
        .word 67, 66, 65, 63, -2, 64,  0, 56, 57, 60,  0, 57, 60, 62, -2,  0
        .word 67, 66, 65, 63, -2, 64,  0, 72, -2, 72, 72, -2, -2, -2, -2,  0
        .word 67, 66, 65, 63, -2, 64,  0, 56, 57, 60,  0, 57, 60, 62, -2,  0
        .word 63, -2, -2,  0, 62, -2, -2,  0, 60, -2, -2, -2, -2, -2, -2, -2
    tam_demo2:          .word 144
    inst_demo2:         .word 80
    ms_demo2:           .word 125

    # Demo 3: Marcha Imperial / Star Wars Completa (Tema + Ponte Aguda + Final) - 120 passos (Metais/Trompete 56, 135 ms)
    demo3_notas:
        .word 55, -2, 55, -2, 55, -2, 51, -2, 58, 55, -2, 51, -2, 58, 55, -2
        .word -2,  0, 62, -2, 62, -2, 62, -2, 63, -2, 58, 54, -2, 51, -2, 58
        .word 55, -2, -2,  0, 67, -2, 55, 55, 67, -2, 66, -2, 65, 64, 63, 64
        .word  0, 56, 61, -2, 60, -2, 59, 58, 57, 58,  0, 51, 54, -2, 58, 55
        .word 55, -2, -2,  0, 67, -2, 55, 55, 67, -2, 66, -2, 65, 64, 63, 64
        .word  0, 56, 61, -2, 60, -2, 59, 58, 57, 58,  0, 51, 54, -2, 58, 55
        .word -2, -2, 51, -2, 58, 55, -2, 51, -2, 58, 55, -2, -2, -2, -2, -2
        .word -2, -2, -2, -2, -2, -2, -2, -2
    tam_demo3:          .word 120
    inst_demo3:         .word 56
    ms_demo3:           .word 135

    # Demo 4: Asa Branca (Luiz Gonzaga) Completa - 136 passos (Sanfona/Acordeao 21, 140 ms)
    demo4_notas:
        .word 60, 62, 64, -2, 67, -2, 67, -2, 64, -2, 65, -2, 65, -2, -2,  0
        .word 60, 62, 64, -2, 67, -2, 67, -2, 65, -2, 64, -2, -2, -2, -2,  0
        .word 60, 60, 62, 64, -2, 67, -2, -2, 67, 65, 64, 60, 65, -2, -2,  0
        .word 65, 64, 62, -2, 62, -2, 64, -2, 62, -2, 60, -2, -2, -2, -2,  0
        .word 60, 62, 64, -2, 67, -2, 67, -2, 64, -2, 65, -2, 65, -2, -2,  0
        .word 60, 62, 64, -2, 67, -2, 67, -2, 65, -2, 64, -2, -2, -2, -2,  0
        .word 60, 60, 62, 64, -2, 67, -2, -2, 67, 65, 64, 60, 65, -2, -2,  0
        .word 65, 64, 62, -2, 62, -2, 64, -2, 62, -2, 60, -2, -2, -2, -2, -2
        .word -2, -2, -2, -2, -2, -2, -2, -2
    tam_demo4:          .word 136
    inst_demo4:         .word 21
    ms_demo4:           .word 140

    # Demo 5: Brilha, Brilha Estrelinha Completa (Forma A-B-A) - 104 passos (Violao 24, 135 ms)
    demo5_notas:
        .word 60, -2, 60, -2, 67, -2, 67, -2, 69, -2, 69, -2, 67, -2, -2,  0
        .word 65, -2, 65, -2, 64, -2, 64, -2, 62, -2, 62, -2, 60, -2, -2,  0
        .word 67, -2, 67, -2, 65, -2, 65, -2, 64, -2, 64, -2, 62, -2, -2,  0
        .word 67, -2, 67, -2, 65, -2, 65, -2, 64, -2, 64, -2, 62, -2, -2,  0
        .word 60, -2, 60, -2, 67, -2, 67, -2, 69, -2, 69, -2, 67, -2, -2,  0
        .word 65, -2, 65, -2, 64, -2, 64, -2, 62, -2, 62, -2, 60, -2, -2, -2
        .word -2, -2, -2, -2, -2, -2, -2, -2
    tam_demo5:          .word 104
    inst_demo5:         .word 24
    ms_demo5:           .word 135

    # --------------------------------------------------------------------------
    # TABELA DE MAPEAMENTO MUSICAL EXPANDIDO (2 Oitavas + Sustenidos = 21 teclas)
    #   Linha central (Oitava 4/5): A S D F G H J K L -> 60, 62, 64, 65, 67, 69, 71, 72, 74
    #   Sustenidos (Fileira sup.):  W E T Y U         -> 61, 63, 66, 68, 70
    #   Oitava grave (Oitava 3):    Z X C V B N M     -> 48, 50, 52, 53, 55, 57, 59
    #   Sustentacao (Prolongar):    '~', '+' ou '='   -> -2
    #   Pausa (Silencio):           '-' ou '.'        -> 0
    # --------------------------------------------------------------------------
    notas_teclas:
        .word 60, 62, 64, 65, 67, 69, 71, 72, 74
        .word 61, 63, 66, 68, 70
        .word 48, 50, 52, 53, 55, 57, 59
    teclas_validas:
        .byte 'A', 'S', 'D', 'F', 'G', 'H', 'J', 'K', 'L'
        .byte 'W', 'E', 'T', 'Y', 'U'
        .byte 'Z', 'X', 'C', 'V', 'B', 'N', 'M'

    # --------------------------------------------------------------------------
    # TABELA CROMATICA PARA EXIBICAO DE QUALQUER NOTA MIDI (nota % 12)
    # --------------------------------------------------------------------------
    .align 2
    tab_nomes_crom:
        .word str_c_0, str_c_1, str_c_2, str_c_3, str_c_4, str_c_5
        .word str_c_6, str_c_7, str_c_8, str_c_9, str_c_10, str_c_11
    tab_tam_crom:
        .word 2, 3, 2, 3, 2, 2, 3, 3, 4, 2, 3, 2

    str_c_0:            .asciiz "DO"
    str_c_1:            .asciiz "DO#"
    str_c_2:            .asciiz "RE"
    str_c_3:            .asciiz "RE#"
    str_c_4:            .asciiz "MI"
    str_c_5:            .asciiz "FA"
    str_c_6:            .asciiz "FA#"
    str_c_7:            .asciiz "SOL"
    str_c_8:            .asciiz "SOL#"
    str_c_9:            .asciiz "LA"
    str_c_10:           .asciiz "LA#"
    str_c_11:           .asciiz "SI"
    str_n_pausa:        .asciiz "---  "
    str_n_sustain:      .asciiz "~~~  "
    str_esp_1:          .asciiz " "
    str_esp_2:          .asciiz "  "

    # Buffers para leitura segura via syscall 8 e buffer de equalizador em 1 syscall
    buffer_linha:       .space 64
    buffer_teclas:      .space 128
    buf_linha_eq:       .space 96

    # --------------------------------------------------------------------------
    # STRINGS DE INTERFACE E MENSAGENS DO CONSOLE
    # --------------------------------------------------------------------------
    str_banner:         .asciiz "\n==============================================================================\n       SYNTHMIPS - MINI-ESTUDIO MUSICAL E SEQUENCIADOR DINAMICO NA HEAP\n==============================================================================\n"
    str_cfg_inst:       .asciiz " [Timbre] "
    str_inst_0:         .asciiz "Piano Acustico (0)"
    str_inst_24:        .asciiz "Violao / Guitarra (24)"
    str_inst_33:        .asciiz "Baixo Acustico/Elet. (33)"
    str_inst_80:        .asciiz "Synth 8-bit Square (80)"
    str_inst_40:        .asciiz "Violino / Cordas (40)"
    str_inst_21:        .asciiz "Sanfona / Acordeao (21)"
    str_inst_56:        .asciiz "Trompete / Metais (56)"
    str_inst_outro:     .asciiz "MIDI Custom"
    str_cfg_bpm:        .asciiz " | Base: "
    str_cfg_ms:         .asciiz " ms | Passos na Heap (N): "
    str_div_grade:      .asciiz "------------------------------------------------------------------------------\n"
    str_painel_vazio:   .asciiz " [!] Faixa vazia (0 notas na Heap). Use [2] Estudio ou [6] Demos para comecar.\n"
    str_painel_lbl:     .asciiz " Faixa: "
    str_painel_indent:  .asciiz "\n        "
    str_abre_col:       .asciiz "["
    str_zero_dig:       .asciiz "0"
    str_dois_pts_simples:.asciiz ":"
    str_fecha_passo:    .asciiz "] "

    # Menu principal
    str_menu:           .asciiz "\n [1] Tocar Faixa (PLAY / Modo Loop Fluido com Equalizador ASCII)\n [2] Estudio de Composicao e Edicao na Heap (Inserir, Editar, Remover, Undo)\n [3] Modo Teclado Livre (Improvisar em 2 Oitavas + Sustenidos + Sustain)\n [4] Configurar Instrumento MIDI e Andamento (BPM)\n [5] Efeitos de Estudio (Transpor +2/-2 Semitons ou Reverse)\n [6] Carregar Musica Demonstrativa Completa (5 Classicos Completos)\n [0] Sair\nEscolha uma opcao: "
    str_err_menu:       .asciiz "\n[!] Opcao invalida! Digite um numero valido do menu.\n"
    str_sair:           .asciiz "\nEncerrando o SynthMIPS. Obrigado por compor em Assembly MIPS!\n"

    # PLAY e Modo Loop
    str_play_vazia:     .asciiz "\n[!] A faixa esta vazia (0 notas)! Adicione notas ou carregue uma Demo primeiro.\n"
    str_ask_loop:       .asciiz "\nQuantas vezes deseja tocar a musica? (1 = tocar 1x, 2..20 = Modo Loop): "
    str_err_loop:       .asciiz "\n[!] Quantidade de repeticoes invalida! Escolha um valor entre 1 e 20.\n"
    str_play_ini:       .asciiz "\n>>> Reproduzindo musica da Heap (Sustentacao continua ativa)...\n"
    str_play_ciclo_ini: .asciiz "\n>>> [Modo Loop: Ciclo "
    str_play_ciclo_meio:.asciiz " de "
    str_play_ciclo_fim: .asciiz "] <<<\n"
    str_nl:             .asciiz "\n"

    # Estudio de Composicao e Edicao (Menu [2])
    str_comp_guia_teclas: .asciiz " Teclado: [Z..M]=DO3..SI3 | [A..L]=DO4..RE5 | [W E T Y U]=Sust. | [~ ou +]=Sustentar(~~~) | [- ou .]=Pausa\n"
    str_comp_menu:      .asciiz "\n--- ESTUDIO DE COMPOSICAO E EDICAO NA HEAP ---\n [1] Adicionar notas ao final (Modo Continuo na Heap)\n [2] Editar / Substituir nota de um passo (1..N)\n [3] Inserir nota no meio da faixa (em qualquer posicao 1..N)\n [4] Remover nota de um passo especifico (1..N)\n [5] Desfazer ultima nota (Undo rapido)\n [6] Substituir faixa inteira (Comecar nova musica do zero)\n [7] Ouvir faixa atual (PLAY rapido 1x)\n [8] Limpar / Zerar faixa (N = 0)\n [0] Voltar ao Menu Principal\nEscolha uma acao: "
    str_comp_cont_banner:.asciiz "\n--- MODO ADICAO CONTINUA (Alocacao na Heap via syscall 9) ---\nDigite teclas (ex: a~s~d~f~, wetyu, zxcvbnm, ~ ou + para prolongar nota, - para pausa).\nEspacos sao ignorados. Digite 0 ou linha vazia (ENTER) para concluir:\n"
    str_prompt:         .asciiz "Notas > "
    str_comp_ok:        .asciiz "\n[+] Modo de adicao concluido!\n"
    str_faixa_vazia:    .asciiz "\n[!] A faixa esta vazia (0 notas)! Adicione notas primeiro.\n"
    str_ask_pos_edit:   .asciiz "Digite o numero do passo que deseja editar (1 a N): "
    str_ask_pos_ins:    .asciiz "Digite a posicao onde deseja inserir a nova nota (1 a N): "
    str_ask_pos_rem:    .asciiz "Digite o numero do passo que deseja remover (1 a N): "
    str_err_pos:        .asciiz "\n[!] Passo invalido! Digite um numero entre 1 e o total N de notas.\n"
    str_passo_atual_1:  .asciiz " -> Passo "
    str_passo_atual_2:  .asciiz " contem atualmente: ["
    str_passo_atual_3:  .asciiz "]\n"
    str_ask_tecla:      .asciiz "Digite a tecla (A..L, W E T Y U, Z..M, ~ para Sustentar, - para Pausa): "
    str_err_tecla:      .asciiz "\n[!] Tecla invalida! Use A..L, W/E/T/Y/U, Z..M, ~/+ (sustain) ou -/. (pausa).\n"
    str_err_tecla_ign:  .asciiz " [!] Caractere ignorado (nao mapeado no teclado musical).\n"
    str_ok_edit:        .asciiz "\n[+] Passo atualizado com sucesso na Heap!\n"
    str_ok_ins:         .asciiz "\n[+] Nota inserida no meio da faixa (passos seguintes deslocados)!\n"
    str_ok_rem:         .asciiz "\n[+] Passo removido com sucesso! Novo total N = "
    str_undo_vazia:     .asciiz "\n[!] A faixa ja esta vazia (nada para desfazer).\n"
    str_undo_ok:        .asciiz "\n[+] Ultima nota desfeita (Undo)! Novo tamanho N = "
    str_limpar_ok:      .asciiz "\n[+] Faixa zerada! Iniciando gravacao da nova musica do zero...\n"
    str_zerar_ok:       .asciiz "\n[+] Faixa limpa com sucesso (N = 0 notas na Heap)!\n"

    # Modo Teclado Livre
    str_livre_ini:      .asciiz "\n--- MODO TECLADO LIVRE (2 OITAVAS + SUSTENIDOS + SUSTAIN) ---\nGrave: Z..M (DO3..SI3) | Central: A..L (DO4..RE5) | Sustenidos: W E T Y U\nSustentar/Prolongar nota: ~ ou + | Pausa: - ou .\nDigite as notas para tocar agora (ex: d~d~f~g~) e pressione ENTER: "
    str_livre_save:     .asciiz "\nDeseja anexar as notas tocadas ao final da musica na Heap? (1=Sim, 0=Nao): "
    str_livre_ok:       .asciiz "\n[+] Notas anexadas a Heap com sucesso!\n"

    # Configuracao
    str_cfg_menu_i:     .asciiz "\n--- ESCOLHA O INSTRUMENTO MIDI ---\n [1] Piano Acustico (0)\n [2] Violao / Guitarra (24)\n [3] Baixo (33)\n [4] Synth 8-bit Square (80)\n [5] Violino / Cordas (40)\n [6] Sanfona / Acordeao (21)\n [7] Trompete / Metais (56)\nOpcao: "
    str_cfg_menu_b:     .asciiz "\n--- ESCOLHA O ANDAMENTO BASE (DURACAO DA COLCHEIA) ---\n [1] Calmo / Expressivo (180 ms)\n [2] Normal / Fluido (140 ms)\n [3] Rapido / Energetico (115 ms)\nOpcao: "
    str_err_cfg:        .asciiz "\n[!] Opcao de configuracao invalida! Mantendo valor anterior.\n"
    str_ok_cfg:         .asciiz "\n[+] Configuracao de timbre e andamento atualizada!\n"

    # Efeitos de Estudio
    str_fx_vazia:       .asciiz "\n[!] A faixa esta vazia (0 notas)! Nao ha notas para aplicar efeitos.\n"
    str_fx_menu:        .asciiz "\n--- EFEITOS DE ESTUDIO ---\n [1] Transpor +2 semitons (Mais agudo)\n [2] Transpor -2 semitons (Mais grave)\n [3] Inverter Melodia (Reverse in-place na Heap)\n [0] Cancelar / Voltar\nEscolha: "
    str_fx_ok_tr:       .asciiz "\n[+] Transposicao aplicada (respeitando limites 36..96 e preservando pausas/sustain)!\n"
    str_fx_ok_rev:      .asciiz "\n[+] Melodia invertida (Reverse) com sucesso!\n"

    # Demos Completas
    str_demo_menu:      .asciiz "\n--- CARREGAR MUSICA DEMONSTRATIVA COMPLETA (100+ PASSOS COM SUSTAIN E FINAL) ---\n [1] Demo 1: Ode a Alegria - Beethoven (136 passos | Piano | 140 ms)\n [2] Demo 2: Super Mario Bros - Overworld Completo (144 passos | Synth 8-bit | 125 ms)\n [3] Demo 3: Marcha Imperial - Star Wars Completa (120 passos | Metais | 135 ms)\n [4] Demo 4: Asa Branca - Luiz Gonzaga Completa (136 passos | Sanfona | 140 ms)\n [5] Demo 5: Brilha, Brilha Estrelinha Completa (104 passos | Violao | 135 ms)\n [0] Voltar\nEscolha uma musica: "
    str_demo_ok:        .asciiz "\n[+] Musica demonstrativa completa carregada na Heap (timbre e BPM ajustados)!\n"
    str_demo_ask_play:  .asciiz "Deseja ouvir a musica carregada agora? (1=Tocar agora, 0=Voltar ao menu): "

.text
.globl main

# ==============================================================================
# PROCEDIMENTO PRINCIPAL: main
# Responsabilidade: Inicializa faixa com Demo 1 completa na Heap e gerencia o menu
# ==============================================================================
main:
    # Inicializa carregando a Demo 1 completa na Heap (136 passos com sustentacao)
    li   $a0, 1
    jal  carregar_demo

main_loop:
    # Exibe painel principal com estado atual da Heap e passos numerados
    lw   $a0, ptr_sequencia
    lw   $a1, tam_sequencia
    lw   $a2, instrumento
    lw   $a3, duracao_ms
    jal  exibir_painel

    # Exibe menu principal e le opcao com leitura segura (syscall 8)
    li   $v0, 4
    la   $a0, str_menu
    syscall

    jal  ler_inteiro_seguro
    move $t0, $v0                   # $t0 = opcao escolhida (-1 se invalida)

    # Despacho por opcao (0 a 6)
    beq  $t0, $zero, main_sair
    li   $t1, 1
    beq  $t0, $t1, opt_tocar
    li   $t1, 2
    beq  $t0, $t1, opt_compor
    li   $t1, 3
    beq  $t0, $t1, opt_teclado_livre
    li   $t1, 4
    beq  $t0, $t1, opt_configurar
    li   $t1, 5
    beq  $t0, $t1, opt_efeitos
    li   $t1, 6
    beq  $t0, $t1, opt_demos

    # Tratamento de opcao invalida no menu principal
    li   $v0, 4
    la   $a0, str_err_menu
    syscall
    j    main_loop

opt_tocar:
    lw   $t0, tam_sequencia
    bgtz $t0, opt_tocar_pedir_loop

    # Aviso de faixa vazia (N == 0)
    li   $v0, 4
    la   $a0, str_play_vazia
    syscall
    j    main_loop

opt_tocar_pedir_loop:
    li   $v0, 4
    la   $a0, str_ask_loop
    syscall

    jal  ler_inteiro_seguro
    move $t1, $v0                   # $t1 = repeticoes K

    # Valida 1 <= K <= 20
    blt  $t1, 1, opt_tocar_err_loop
    li   $t2, 20
    bgt  $t1, $t2, opt_tocar_err_loop

    lw   $a0, ptr_sequencia
    lw   $a1, tam_sequencia
    move $a2, $t1
    jal  tocar_sequencia
    j    main_loop

opt_tocar_err_loop:
    li   $v0, 4
    la   $a0, str_err_loop
    syscall
    j    main_loop

opt_compor:
    jal  compor_faixa
    j    main_loop

opt_teclado_livre:
    jal  modo_teclado_livre
    j    main_loop

opt_configurar:
    jal  configurar_estudio
    j    main_loop

opt_efeitos:
    jal  menu_efeitos
    j    main_loop

opt_demos:
    li   $v0, 4
    la   $a0, str_demo_menu
    syscall

    jal  ler_inteiro_seguro
    move $t0, $v0

    beq  $t0, $zero, main_loop
    blt  $t0, 1, opt_demos_err
    li   $t1, 5
    bgt  $t0, $t1, opt_demos_err

    move $a0, $t0
    jal  carregar_demo

    li   $v0, 4
    la   $a0, str_demo_ok
    syscall

    # Oferece tocar imediatamente a demo carregada
    li   $v0, 4
    la   $a0, str_demo_ask_play
    syscall

    jal  ler_inteiro_seguro
    li   $t0, 1
    bne  $v0, $t0, main_loop

    lw   $a0, ptr_sequencia
    lw   $a1, tam_sequencia
    li   $a2, 1
    jal  tocar_sequencia
    j    main_loop

opt_demos_err:
    li   $v0, 4
    la   $a0, str_err_menu
    syscall
    j    main_loop

main_sair:
    li   $v0, 4
    la   $a0, str_sair
    syscall

    li   $v0, 10                    # Encerramento limpo do programa
    syscall

# ==============================================================================
# PROCEDIMENTO: ler_inteiro_seguro (Folha)
# Responsabilidade: Le uma linha via syscall 8 em buffer_linha, ignora espacos
#                   iniciais e converte digitos '0'..'9' em inteiro nao-negativo.
#                   Evita excecoes fatais do MARS quando o usuario digita letras
#                   ou pressiona ENTER vazio.
# Saida: $v0 = inteiro >= 0 lido, ou -1 se entrada vazia ou invalida.
# Pilha ($sp): Sem pilha (folha)
# ==============================================================================
ler_inteiro_seguro:
    li   $v0, 8
    la   $a0, buffer_linha
    li   $a1, 60
    syscall

    la   $t0, buffer_linha

lis_pular_esp:
    lb   $t1, 0($t0)
    li   $t2, 32                    # ' '
    beq  $t1, $t2, lis_avancar_esp
    li   $t2, 9                     # '\t'
    beq  $t1, $t2, lis_avancar_esp
    j    lis_verificar_fim_vazio

lis_avancar_esp:
    addi $t0, $t0, 1
    j    lis_pular_esp

lis_verificar_fim_vazio:
    beq  $t1, $zero, lis_invalido
    li   $t2, 10                    # '\n'
    beq  $t1, $t2, lis_invalido
    li   $t2, 13                    # '\r'
    beq  $t1, $t2, lis_invalido

    li   $v0, 0                     # acumulador = 0
    li   $t3, 0                     # contador de digitos = 0

lis_loop_digitos:
    lb   $t1, 0($t0)
    beq  $t1, $zero, lis_concluir
    li   $t2, 10                    # '\n'
    beq  $t1, $t2, lis_concluir
    li   $t2, 13                    # '\r'
    beq  $t1, $t2, lis_concluir
    li   $t2, 32                    # espaco no final
    beq  $t1, $t2, lis_verificar_resto
    li   $t2, 9                     # tab no final
    beq  $t1, $t2, lis_verificar_resto

    # Verifica se '0' <= $t1 <= '9'
    li   $t2, 48                    # '0'
    blt  $t1, $t2, lis_invalido
    li   $t2, 57                    # '9'
    bgt  $t1, $t2, lis_invalido

    addi $t1, $t1, -48              # digito numerico
    mul  $v0, $v0, 10
    add  $v0, $v0, $t1
    addi $t3, $t3, 1
    addi $t0, $t0, 1
    j    lis_loop_digitos

lis_verificar_resto:
    addi $t0, $t0, 1
    lb   $t1, 0($t0)
    beq  $t1, $zero, lis_concluir
    li   $t2, 10
    beq  $t1, $t2, lis_concluir
    li   $t2, 13
    beq  $t1, $t2, lis_concluir
    li   $t2, 32
    beq  $t1, $t2, lis_verificar_resto
    li   $t2, 9
    beq  $t1, $t2, lis_verificar_resto
    j    lis_invalido

lis_concluir:
    blez $t3, lis_invalido
    jr   $ra

lis_invalido:
    li   $v0, -1
    jr   $ra

# ==============================================================================
# PROCEDIMENTO: exibir_painel (Nao-folha)
# Entrada: $a0 = ptr_sequencia, $a1 = tam_sequencia (N), $a2 = instrumento, $a3 = duracao_ms
# Responsabilidade: Exibe cabecalho com nome do instrumento, BPM e grade numerada
#                   no formato [01:MI4  ] [02:~~~  ] ... (8 passos por linha).
# Pilha ($sp): 20 bytes ($s0..$s3, $ra)
# ==============================================================================
exibir_painel:
    addi $sp, $sp, -20
    sw   $s0, 0($sp)
    sw   $s1, 4($sp)
    sw   $s2, 8($sp)
    sw   $s3, 12($sp)
    sw   $ra, 16($sp)

    move $s0, $a0                   # $s0 = ptr_sequencia (Heap)
    move $s1, $a1                   # $s1 = tam_sequencia (N)
    move $s2, $a2                   # $s2 = instrumento
    move $s3, $a3                   # $s3 = duracao_ms

    # Banner principal
    li   $v0, 4
    la   $a0, str_banner
    syscall

    # Linha de configuracao com nome descritivo do instrumento
    li   $v0, 4
    la   $a0, str_cfg_inst
    syscall

    move $a0, $s2
    jal  imprimir_nome_instrumento

    li   $v0, 4
    la   $a0, str_cfg_bpm
    syscall
    li   $v0, 1
    move $a0, $s3
    syscall
    li   $v0, 4
    la   $a0, str_cfg_ms
    syscall
    li   $v0, 1
    move $a0, $s1
    syscall
    li   $v0, 4
    la   $a0, str_nl
    syscall

    li   $v0, 4
    la   $a0, str_div_grade
    syscall

    # Exibe a grade numerada da faixa
    move $a0, $s0
    move $a1, $s1
    jal  exibir_grade_notas

    li   $v0, 4
    la   $a0, str_div_grade
    syscall

    lw   $s0, 0($sp)
    lw   $s1, 4($sp)
    lw   $s2, 8($sp)
    lw   $s3, 12($sp)
    lw   $ra, 16($sp)
    addi $sp, $sp, 20
    jr   $ra

# ==============================================================================
# PROCEDIMENTO: imprimir_nome_instrumento (Folha)
# Entrada: $a0 = codigo MIDI do instrumento
# Pilha ($sp): Sem pilha (folha)
# ==============================================================================
imprimir_nome_instrumento:
    move $t0, $a0
    beq  $t0, $zero, ini_piano
    li   $t1, 24
    beq  $t0, $t1, ini_violao
    li   $t1, 33
    beq  $t0, $t1, ini_baixo
    li   $t1, 80
    beq  $t0, $t1, ini_synth
    li   $t1, 40
    beq  $t0, $t1, ini_violino
    li   $t1, 21
    beq  $t0, $t1, ini_sanfona
    li   $t1, 56
    beq  $t0, $t1, ini_trompete

    la   $a0, str_inst_outro
    j    ini_print
ini_piano:
    la   $a0, str_inst_0
    j    ini_print
ini_violao:
    la   $a0, str_inst_24
    j    ini_print
ini_baixo:
    la   $a0, str_inst_33
    j    ini_print
ini_synth:
    la   $a0, str_inst_80
    j    ini_print
ini_violino:
    la   $a0, str_inst_40
    j    ini_print
ini_sanfona:
    la   $a0, str_inst_21
    j    ini_print
ini_trompete:
    la   $a0, str_inst_56
ini_print:
    li   $v0, 4
    syscall
    jr   $ra

# ==============================================================================
# PROCEDIMENTO: exibir_grade_notas (Nao-folha)
# Entrada: $a0 = ptr_sequencia, $a1 = tam_sequencia (N)
# Responsabilidade: Imprime cada nota numerada [01:MI4  ] [02:~~~  ] ... (8/linha)
# Pilha ($sp): 16 bytes ($s0, $s1, $s2, $ra)
# ==============================================================================
exibir_grade_notas:
    addi $sp, $sp, -16
    sw   $s0, 0($sp)
    sw   $s1, 4($sp)
    sw   $s2, 8($sp)
    sw   $ra, 12($sp)

    move $s0, $a0                   # $s0 = ptr_sequencia
    move $s1, $a1                   # $s1 = N

    bgtz $s1, egn_tem_notas

    li   $v0, 4
    la   $a0, str_painel_vazio
    syscall
    j    egn_fim

egn_tem_notas:
    li   $v0, 4
    la   $a0, str_painel_lbl
    syscall

    li   $s2, 0                     # i = 0..N-1

egn_loop:
    bge  $s2, $s1, egn_fim_loop

    # Quebra de linha a cada 8 passos (se i > 0 e i % 8 == 0)
    beq  $s2, $zero, egn_print_item
    andi $t0, $s2, 7
    bnez $t0, egn_print_item

    li   $v0, 4
    la   $a0, str_painel_indent
    syscall

egn_print_item:
    # Imprime "["
    li   $v0, 4
    la   $a0, str_abre_col
    syscall

    # Passo = i + 1 (com zero a esquerda se < 10)
    addi $t1, $s2, 1
    li   $t2, 10
    bge  $t1, $t2, egn_num_passo
    li   $v0, 4
    la   $a0, str_zero_dig
    syscall

egn_num_passo:
    li   $v0, 1
    addi $a0, $s2, 1
    syscall

    # Imprime ":"
    li   $v0, 4
    la   $a0, str_dois_pts_simples
    syscall

    # Imprime nome da nota de 5 caracteres (ex: "DO4  ", "~~~  ", "---  ")
    sll  $t0, $s2, 2
    add  $t0, $s0, $t0
    lw   $a0, 0($t0)
    jal  imprimir_nome_nota

    # Imprime "] "
    li   $v0, 4
    la   $a0, str_fecha_passo
    syscall

    addi $s2, $s2, 1
    j    egn_loop

egn_fim_loop:
    li   $v0, 4
    la   $a0, str_nl
    syscall

egn_fim:
    lw   $s0, 0($sp)
    lw   $s1, 4($sp)
    lw   $s2, 8($sp)
    lw   $ra, 12($sp)
    addi $sp, $sp, 16
    jr   $ra

# ==============================================================================
# PROCEDIMENTO: imprimir_nome_nota (Folha)
# Entrada: $a0 = valor MIDI da nota (>0), 0 (pausa "---  ") ou -2 (sustain "~~~  ")
# Responsabilidade: Converte qualquer nota MIDI para cifra cromatica + oitava
#                   usando divisao por 12:
#                   - indice = nota % 12 (DO, DO#, RE, RE#, MI, FA, FA#, SOL, SOL#, LA, LA#, SI)
#                   - oitava = (nota / 12) - 1
#                   Alinha exatamente em 5 caracteres (ex: "DO4  ", "~~~  ", "---  ").
# Pilha ($sp): Sem pilha (folha)
# ==============================================================================
imprimir_nome_nota:
    move $t0, $a0
    li   $t1, -2
    beq  $t0, $t1, inn_sustain
    blez $t0, inn_pausa

    # Calcula quociente (nota / 12) e resto (nota % 12)
    li   $t1, 12
    div  $t0, $t1
    mflo $t2                        # $t2 = nota / 12
    mfhi $t3                        # $t3 = nota % 12 (0..11)

    addi $t2, $t2, -1               # $t2 = oitava = (nota / 12) - 1

    # Imprime o nome cromatico correspondente a nota % 12
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

    # Calcula espacos de preenchimento para largura fixa de 5 colunas
    la   $t5, tab_tam_crom
    add  $t5, $t5, $t4
    lw   $t6, 0($t5)                # $t6 = comprimento do nome (2, 3 ou 4)

    li   $t7, 2
    beq  $t6, $t7, inn_pad_2
    li   $t7, 3
    beq  $t6, $t7, inn_pad_1
    jr   $ra                        # Se tam_nome == 4 ("SOL#"), ja tem 5 chars com oitava

inn_pad_2:
    li   $v0, 4
    la   $a0, str_esp_2
    syscall
    jr   $ra

inn_pad_1:
    li   $v0, 4
    la   $a0, str_esp_1
    syscall
    jr   $ra

inn_sustain:
    li   $v0, 4
    la   $a0, str_n_sustain
    syscall
    jr   $ra

inn_pausa:
    li   $v0, 4
    la   $a0, str_n_pausa
    syscall
    jr   $ra

# ==============================================================================
# PROCEDIMENTO: escrever_nome_nota_buf (Folha)
# Entrada: $a0 = valor da nota (>0, 0 ou -2), $a1 = endereco de 5 bytes no buffer
# Responsabilidade: Escreve exatamente 5 caracteres ASCII (ex: "MI4  ", "~~~  ", "---  ")
#                   em $a1 sem realizar nenhuma syscall!
# Pilha ($sp): Sem pilha (folha)
# ==============================================================================
escrever_nome_nota_buf:
    move $t0, $a0
    move $t8, $a1                   # $t8 = ponteiro destino (5 chars)

    # Preenche inicialmente os 5 bytes com espacos ' ' (32)
    li   $t9, 32
    sb   $t9, 0($t8)
    sb   $t9, 1($t8)
    sb   $t9, 2($t8)
    sb   $t9, 3($t8)
    sb   $t9, 4($t8)

    li   $t1, -2
    beq  $t0, $t1, ennb_sustain
    blez $t0, ennb_pausa

    # Nota MIDI > 0: calcula oitava e nota % 12
    li   $t1, 12
    div  $t0, $t1
    mflo $t2                        # $t2 = nota / 12
    mfhi $t3                        # $t3 = nota % 12 (0..11)
    addi $t2, $t2, -1               # oitava = (nota / 12) - 1

    sll  $t4, $t3, 2
    la   $t5, tab_nomes_crom
    add  $t5, $t5, $t4
    lw   $t6, 0($t5)                # $t6 = ponteiro para string cromatica ("DO", "SOL#", etc.)

ennb_copy_loop:
    lb   $t7, 0($t6)
    beq  $t7, $zero, ennb_put_oct
    sb   $t7, 0($t8)
    addi $t6, $t6, 1
    addi $t8, $t8, 1
    j    ennb_copy_loop

ennb_put_oct:
    addi $t2, $t2, 48               # converte oitava para digito ASCII ('0'..'9')
    sb   $t2, 0($t8)
    jr   $ra

ennb_sustain:
    li   $t9, 126                   # '~'
    sb   $t9, 0($t8)
    sb   $t9, 1($t8)
    sb   $t9, 2($t8)
    jr   $ra

ennb_pausa:
    li   $t9, 45                    # '-'
    sb   $t9, 0($t8)
    sb   $t9, 1($t8)
    sb   $t9, 2($t8)
    jr   $ra

# ==============================================================================
# PROCEDIMENTO: adicionar_nota_heap (Folha)
# Entrada: $a0 = valor MIDI da nota a anexar (>0, 0 ou -2)
# Saida:   $v0 = novo tam_sequencia (N + 1), $v1 = endereco gravado na Heap
# Pilha ($sp): Sem pilha (folha)
# ==============================================================================
adicionar_nota_heap:
    move $t0, $a0                   # $t0 = nota MIDI a anexar
    lw   $t1, tam_sequencia         # $t1 = N
    lw   $t2, cap_alocada           # $t2 = C

    blt  $t1, $t2, adh_gravar       # Se N < C, reaproveita slot ja alocado na Heap!

    # N == C: aloca mais 4 bytes contiguos na Heap via syscall 9 (sbrk)
    li   $v0, 9
    li   $a0, 4
    syscall                         # $v0 = endereco do novo bloco na Heap

    # Se for a primeira alocacao (C == 0), inicializa ptr_sequencia
    bnez $t2, adh_inc_cap
    sw   $v0, ptr_sequencia

adh_inc_cap:
    addi $t2, $t2, 1
    sw   $t2, cap_alocada

adh_gravar:
    lw   $t3, ptr_sequencia         # $t3 = base do vetor na Heap
    sll  $t4, $t1, 2                # offset = N * 4
    add  $t4, $t3, $t4              # endereco destino na Heap
    sw   $t0, 0($t4)                # grava a nota de 32 bits

    addi $t1, $t1, 1                # N = N + 1
    sw   $t1, tam_sequencia

    move $v0, $t1                   # $v0 = novo tam_sequencia
    move $v1, $t4                   # $v1 = endereco gravado
    jr   $ra

# ==============================================================================
# PROCEDIMENTO: inserir_nota_posicao_heap (Nao-folha)
# Entrada: $a0 = posicao 1..N onde inserir, $a1 = valor MIDI da nota
# Responsabilidade: Expande a Heap em +1 elemento (via adicionar_nota_heap),
#                   desloca os elementos de (pos-1)..(N-1) uma posicao para a
#                   direita e grava a nova nota na posicao escolhida.
# Pilha ($sp): 12 bytes ($s0, $s1, $ra)
# ==============================================================================
inserir_nota_posicao_heap:
    addi $sp, $sp, -12
    sw   $s0, 0($sp)
    sw   $s1, 4($sp)
    sw   $ra, 8($sp)

    move $s0, $a0                   # $s0 = pos (1..N)
    move $s1, $a1                   # $s1 = nova nota MIDI

    # Garante espaco para N+1 anexando temporariamente ao final
    move $a0, $s1
    jal  adicionar_nota_heap        # Agora tam_sequencia = N_novo = N_antigo + 1

    lw   $t0, ptr_sequencia
    lw   $t1, tam_sequencia         # $t1 = N_novo
    addi $t2, $t1, -1               # $t2 = indice final k = N_novo - 1
    addi $t3, $s0, -1               # $t3 = indice alvo idx = pos - 1

inph_shift_loop:
    ble  $t2, $t3, inph_gravar
    addi $t4, $t2, -1               # k - 1
    sll  $t4, $t4, 2
    add  $t4, $t0, $t4              # &heap[k - 1]
    lw   $t5, 0($t4)                # heap[k - 1]

    sll  $t6, $t2, 2
    add  $t6, $t0, $t6              # &heap[k]
    sw   $t5, 0($t6)                # heap[k] = heap[k - 1]

    addi $t2, $t2, -1
    j    inph_shift_loop

inph_gravar:
    sll  $t4, $t3, 2
    add  $t4, $t0, $t4              # &heap[pos - 1]
    sw   $s1, 0($t4)                # heap[pos - 1] = nova nota

    lw   $s0, 0($sp)
    lw   $s1, 4($sp)
    lw   $ra, 8($sp)
    addi $sp, $sp, 12
    jr   $ra

# ==============================================================================
# PROCEDIMENTO: remover_nota_posicao_heap (Folha)
# Entrada: $a0 = posicao 1..N a remover
# Saida:   $v0 = novo tam_sequencia (N - 1)
# Responsabilidade: Desloca todos os passos seguintes uma casa para a esquerda
#                   e decrementa tam_sequencia.
# Pilha ($sp): Sem pilha (folha)
# ==============================================================================
remover_nota_posicao_heap:
    lw   $t0, ptr_sequencia
    lw   $t1, tam_sequencia         # $t1 = N
    addi $t2, $a0, -1               # $t2 = k = pos - 1
    addi $t3, $t1, -1               # $t3 = N - 1

rnph_shift_loop:
    bge  $t2, $t3, rnph_fim
    addi $t4, $t2, 1                # k + 1
    sll  $t4, $t4, 2
    add  $t4, $t0, $t4              # &heap[k + 1]
    lw   $t5, 0($t4)                # heap[k + 1]

    sll  $t6, $t2, 2
    add  $t6, $t0, $t6              # &heap[k]
    sw   $t5, 0($t6)                # heap[k] = heap[k + 1]

    addi $t2, $t2, 1
    j    rnph_shift_loop

rnph_fim:
    sw   $t3, tam_sequencia         # tam_sequencia = N - 1
    move $v0, $t3
    jr   $ra

# ==============================================================================
# PROCEDIMENTO: desenhar_barra_nota (Nao-folha)
# Entrada: $a0 = numero do passo (1..N), $a1 = valor MIDI da nota (>0, 0 ou -2)
#          $a2 = quantidade de passos sustentados (1 = normal, 2 = 2x, 3 = 3x...)
# Responsabilidade: Constroi a linha INTEIRA do equalizador em buf_linha_eq na
#                   memoria e executa UMA UNICA syscall 4!
#                   Isso elimina 100% do atraso/jitter do console Swing do MARS!
# Pilha ($sp): 16 bytes ($s0, $s1, $s2, $ra)
# ==============================================================================
desenhar_barra_nota:
    addi $sp, $sp, -16
    sw   $s0, 0($sp)
    sw   $s1, 4($sp)
    sw   $s2, 8($sp)
    sw   $ra, 12($sp)

    move $s0, $a0                   # $s0 = numero do passo (1..N)
    move $s1, $a1                   # $s1 = nota MIDI (>0, 0 ou -2)
    move $s2, $a2                   # $s2 = passos sustentados (>= 1)
    bgtz $s2, dbn_iniciar_buf
    li   $s2, 1

dbn_iniciar_buf:
    la   $t0, buf_linha_eq

    # Escreve prefixo " Passo "
    li   $t1, 32                    # ' '
    sb   $t1, 0($t0)
    li   $t1, 80                    # 'P'
    sb   $t1, 1($t0)
    li   $t1, 97                    # 'a'
    sb   $t1, 2($t0)
    li   $t1, 115                   # 's'
    sb   $t1, 3($t0)
    sb   $t1, 4($t0)
    li   $t1, 111                   # 'o'
    sb   $t1, 5($t0)
    li   $t1, 32                    # ' '
    sb   $t1, 6($t0)

    # Passo >= 100: desloca "Passo" 1 posicao a esquerda e escreve a centena
    move $t5, $s0
    li   $t2, 100
    blt  $t5, $t2, dbn_dois_dig
    div  $t5, $t2
    mflo $t6                        # centena
    mfhi $t5                        # resto (0..99)
    li   $t1, 80                    # 'P'
    sb   $t1, 0($t0)
    li   $t1, 97                    # 'a'
    sb   $t1, 1($t0)
    li   $t1, 115                   # 's'
    sb   $t1, 2($t0)
    sb   $t1, 3($t0)
    li   $t1, 111                   # 'o'
    sb   $t1, 4($t0)
    li   $t1, 32
    sb   $t1, 5($t0)
    addi $t6, $t6, 48
    sb   $t6, 6($t0)

dbn_dois_dig:
    # Escreve dezena e unidade
    li   $t2, 10
    div  $t5, $t2
    mflo $t3                        # dezena
    mfhi $t4                        # unidade
    addi $t3, $t3, 48
    addi $t4, $t4, 48
    sb   $t3, 7($t0)
    sb   $t4, 8($t0)

    # Escreve " ["
    li   $t1, 32                    # ' '
    sb   $t1, 9($t0)
    li   $t1, 91                    # '['
    sb   $t1, 10($t0)

    # Escreve os 5 caracteres da nota em buf_linha_eq + 11
    move $a0, $s1
    addi $a1, $t0, 11
    jal  escrever_nome_nota_buf

    # Recarrega base do buffer e escreve "] | " nas posicoes 16..19
    la   $t0, buf_linha_eq
    li   $t1, 93                    # ']'
    sb   $t1, 16($t0)
    li   $t1, 32                    # ' '
    sb   $t1, 17($t0)
    li   $t1, 124                   # '|'
    sb   $t1, 18($t0)
    li   $t1, 32                    # ' '
    sb   $t1, 19($t0)

    addi $t0, $t0, 20               # $t0 aponta para o inicio da barra grafica

    blez $s1, dbn_barra_silencio

    # Nota ativa (> 0): comprimento da barra = (nota - 34) / 2
    addi $t2, $s1, -34
    sra  $t2, $t2, 1
    bgtz $t2, dbn_loop_hash_init
    li   $t2, 1

dbn_loop_hash_init:
    li   $t3, 35                    # '#'

dbn_loop_hash:
    blez $t2, dbn_check_sustain_tag
    sb   $t3, 0($t0)
    addi $t0, $t0, 1
    addi $t2, $t2, -1
    j    dbn_loop_hash

dbn_check_sustain_tag:
    # Se a nota tem sustentacao ($s2 > 1), desenha '=' extras indicando a duracao!
    li   $t4, 1
    ble  $s2, $t4, dbn_finalizar_linha
    addi $t5, $s2, -1               # quantidade de passos extras sustentados
    li   $t3, 61                    # '='

dbn_loop_eq_sustain:
    blez $t5, dbn_finalizar_linha
    sb   $t3, 0($t0)
    sb   $t3, 1($t0)
    sb   $t3, 2($t0)
    addi $t0, $t0, 3
    addi $t5, $t5, -1
    j    dbn_loop_eq_sustain

dbn_barra_silencio:
    li   $t2, -2
    beq  $s1, $t2, dbn_barra_sustain_iso
    li   $t3, 46                    # '.' para pausa (0)
    sb   $t3, 0($t0)
    addi $t0, $t0, 1
    j    dbn_finalizar_linha

dbn_barra_sustain_iso:
    li   $t3, 126                   # '~' para sustain isolado (-2)
    sb   $t3, 0($t0)
    sb   $t3, 1($t0)
    sb   $t3, 2($t0)
    addi $t0, $t0, 3

dbn_finalizar_linha:
    li   $t3, 10                    # '\n'
    sb   $t3, 0($t0)
    sb   $zero, 1($t0)              # '\0'

    # Imprime a linha inteira com UMA UNICA syscall 4!
    li   $v0, 4
    la   $a0, buf_linha_eq
    syscall

    lw   $s0, 0($sp)
    lw   $s1, 4($sp)
    lw   $s2, 8($sp)
    lw   $ra, 12($sp)
    addi $sp, $sp, 16
    jr   $ra

# ==============================================================================
# PROCEDIMENTO: tocar_nota_com_duracao (Nao-folha)
# Entrada: $a0 = numero do passo (1..N), $a1 = valor MIDI da nota,
#          $a2 = quantidade de passos unidos (>= 1)
# Responsabilidade: Desenha a barra em 1 syscall e toca a nota (ou pausa) pela
#                   duracao total = $a2 * duracao_ms continuamente sem cortes!
# Pilha ($sp): 16 bytes ($s0, $s1, $s2, $ra)
# ==============================================================================
tocar_nota_com_duracao:
    addi $sp, $sp, -20
    sw   $s0, 0($sp)
    sw   $s1, 4($sp)
    sw   $s2, 8($sp)
    sw   $s3, 12($sp)
    sw   $ra, 16($sp)

    move $s0, $a0                   # $s0 = passo inicial (1..N)
    move $s1, $a1                   # $s1 = nota MIDI
    move $s2, $a2                   # $s2 = cont_passos (>= 1)
    bgtz $s2, tncd_som
    li   $s2, 1

tncd_som:
    # 1) Imprime TODAS as linhas do grupo (nota + passos sustentados/pausas)
    li   $s3, 0                     # k = 0..cont_passos-1
tncd_loop:
    bge  $s3, $s2, tncd_tocar
    add  $a0, $s0, $s3              # passo exibido = inicial + k (nunca pula)
    move $a1, $s1
    li   $a2, 1
    beqz $s3, tncd_desenha
    blez $s1, tncd_desenha          # pausas: cada passo mostra '.'
    li   $a1, -2                    # passos seguintes da nota: '~~~'
tncd_desenha:
    jal  desenhar_barra_nota
    addi $s3, $s3, 1
    j    tncd_loop

tncd_tocar:
    # 2) Toca de forma SINCRONA pela duracao total: o proximo texto so aparece
    #    quando o som termina, mantendo console e audio alinhados.
    lw   $t0, duracao_ms
    mul  $t1, $s2, $t0              # duracao total = cont_passos * duracao_ms
    blez $s1, tncd_pausa
    move $a0, $s1
    move $a1, $t1
    lw   $a2, instrumento
    lw   $a3, volume
    li   $v0, 33
    syscall
    j    tncd_fim

tncd_pausa:
    move $a0, $t1
    li   $v0, 32
    syscall

tncd_fim:
    lw   $s0, 0($sp)
    lw   $s1, 4($sp)
    lw   $s2, 8($sp)
    lw   $s3, 12($sp)
    lw   $ra, 16($sp)
    addi $sp, $sp, 20
    jr   $ra

# ==============================================================================
# PROCEDIMENTO: tocar_nota_unica (Nao-folha)
# Entrada: $a0 = numero do passo (1..N), $a1 = valor MIDI da nota
# Responsabilidade: Wrapper para tocar 1 passo individual durante edicao/composicao
# Pilha ($sp): 4 bytes ($ra)
# ==============================================================================
tocar_nota_unica:
    addi $sp, $sp, -4
    sw   $ra, 0($sp)

    li   $a2, 1
    jal  tocar_nota_com_duracao

    lw   $ra, 0($sp)
    addi $sp, $sp, 4
    jr   $ra

# ==============================================================================
# PROCEDIMENTO: tocar_sequencia (Nao-folha)
# Entrada: $a0 = ptr_sequencia, $a1 = tam_sequencia (N), $a2 = repeticoes K (>= 1)
# Saida:   $v0 = total de passos executados (N * K)
# Responsabilidade: Reproduz a sequencia com suporte a SUSTENTACAO CONTINUA (-2):
#                   Quando encontra uma nota > 0 (ou pausa 0), olha a frente
#                   agrupando passos consecutivos de sustentacao (-2) na mesma
#                   chamada MIDI, produzindo notas longas perfeitamente fluidas!
# Pilha ($sp): 28 bytes ($s0..$s5 e $ra)
# ==============================================================================
tocar_sequencia:
    addi $sp, $sp, -28
    sw   $s0, 0($sp)
    sw   $s1, 4($sp)
    sw   $s2, 8($sp)
    sw   $s3, 12($sp)
    sw   $s4, 16($sp)
    sw   $s5, 20($sp)
    sw   $ra, 24($sp)

    move $s0, $a0                   # $s0 = ptr_sequencia (Heap)
    move $s1, $a1                   # $s1 = tam_sequencia (N)
    move $s2, $a2                   # $s2 = repeticoes K
    li   $s5, 0                     # $s5 = total de passos executados

    # Se N == 0, avisa e retorna 0
    bgtz $s1, tseq_iniciar
    li   $v0, 4
    la   $a0, str_play_vazia
    syscall
    li   $v0, 0
    j    tseq_fim

tseq_iniciar:
    li   $s3, 1                     # ciclo = 1..K

tseq_ciclo_loop:
    bgt  $s3, $s2, tseq_concluido

    # Cabecalho do ciclo (se K > 1 exibe indicador de ciclo)
    li   $t0, 1
    beq  $s2, $t0, tseq_sem_cab_ciclo
    li   $v0, 4
    la   $a0, str_play_ciclo_ini
    syscall
    li   $v0, 1
    move $a0, $s3
    syscall
    li   $v0, 4
    la   $a0, str_play_ciclo_meio
    syscall
    li   $v0, 1
    move $a0, $s2
    syscall
    li   $v0, 4
    la   $a0, str_play_ciclo_fim
    syscall
    j    tseq_nota_ini

tseq_sem_cab_ciclo:
    li   $v0, 4
    la   $a0, str_play_ini
    syscall

tseq_nota_ini:
    li   $s4, 0                     # i = 0..N-1

tseq_nota_loop:
    bge  $s4, $s1, tseq_prox_ciclo

    sll  $t0, $s4, 2
    add  $t0, $s0, $t0
    lw   $a1, 0($t0)                # $a1 = nota atual em heap_seq[i]

    # Conta quantos passos de sustentacao (-2) vem imediatamente apos i
    li   $t1, 1                     # cont_passos = 1
    blez $a1, tseq_check_pausa_run  # se for pausa (0), pode agrupar pausas ou tocar 1x

tseq_lookahead_sustain:
    add  $t2, $s4, $t1              # proximo indice = i + cont_passos
    bge  $t2, $s1, tseq_disparar_nota
    sll  $t3, $t2, 2
    add  $t3, $s0, $t3
    lw   $t4, 0($t3)                # heap_seq[i + cont_passos]
    li   $t5, -2                    # codigo de sustentacao (~~~)
    bne  $t4, $t5, tseq_disparar_nota
    addi $t1, $t1, 1                # mais 1 passo sustentado!
    j    tseq_lookahead_sustain

tseq_check_pausa_run:
    # Para pausas (0), tambem agrupa pausas consecutivas (0) para nao atrasar no console!
    bne  $a1, $zero, tseq_disparar_nota
tseq_lookahead_pausa:
    add  $t2, $s4, $t1
    bge  $t2, $s1, tseq_disparar_nota
    sll  $t3, $t2, 2
    add  $t3, $s0, $t3
    lw   $t4, 0($t3)
    bne  $t4, $zero, tseq_disparar_nota
    addi $t1, $t1, 1
    j    tseq_lookahead_pausa

tseq_disparar_nota:
    addi $a0, $s4, 1                # $a0 = passo inicial (1..N)
    move $a2, $t1                   # $a2 = cont_passos unidos
    # Salva $t1 temporariamente em $s5 somando ao total e avanca $s4
    add  $s5, $s5, $t1
    add  $s4, $s4, $t1
    jal  tocar_nota_com_duracao
    j    tseq_nota_loop

tseq_prox_ciclo:
    addi $s3, $s3, 1
    j    tseq_ciclo_loop

tseq_concluido:
    move $v0, $s5                   # retorna total de passos executados

tseq_fim:
    lw   $s0, 0($sp)
    lw   $s1, 4($sp)
    lw   $s2, 8($sp)
    lw   $s3, 12($sp)
    lw   $s4, 16($sp)
    lw   $s5, 20($sp)
    lw   $ra, 24($sp)
    addi $sp, $sp, 28
    jr   $ra

# ==============================================================================
# PROCEDIMENTO: traduzir_tecla (Folha)
# Entrada: $a0 = caractere ASCII
# Saida:   $v0 = nota MIDI (48..74), 0 para pausa ('-' ou '.'),
#                -2 para sustentacao ('~', '+' ou '='), ou -1 se invalida
# Pilha ($sp): Sem pilha (folha)
# ==============================================================================
traduzir_tecla:
    move $t0, $a0

    # Verifica sustentacao ('~' = 126, '+' = 43, '=' = 61)
    li   $t1, 126
    beq  $t0, $t1, trad_sustain
    li   $t1, 43
    beq  $t0, $t1, trad_sustain
    li   $t1, 61
    beq  $t0, $t1, trad_sustain

    # Verifica pausa ('-' = 45 ou '.' = 46)
    li   $t1, 45
    beq  $t0, $t1, trad_pausa
    li   $t1, 46
    beq  $t0, $t1, trad_pausa

    # Converte minuscula ('a'..'z' -> 97..122) para maiuscula (-32)
    li   $t1, 97
    blt  $t0, $t1, trad_busca
    li   $t1, 122
    bgt  $t0, $t1, trad_busca
    addi $t0, $t0, -32

trad_busca:
    la   $t1, teclas_validas
    la   $t2, notas_teclas
    li   $t3, 0                     # indice k = 0..20 (21 teclas musicais)

trad_loop:
    bge  $t3, 21, trad_invalida
    add  $t4, $t1, $t3
    lb   $t5, 0($t4)                # teclas_validas[k]
    beq  $t0, $t5, trad_encontrou
    addi $t3, $t3, 1
    j    trad_loop

trad_encontrou:
    sll  $t4, $t3, 2
    add  $t4, $t2, $t4
    lw   $v0, 0($t4)                # notas_teclas[k]
    jr   $ra

trad_sustain:
    li   $v0, -2
    jr   $ra

trad_pausa:
    li   $v0, 0
    jr   $ra

trad_invalida:
    li   $v0, -1
    jr   $ra

# ==============================================================================
# PROCEDIMENTO: ler_tecla_musical (Nao-folha)
# Responsabilidade: Le uma linha via syscall 8, ignora espacos iniciais e traduz
#                   o primeiro caractere para nota MIDI (>0, 0, -2) ou -1.
# Saida: $v0 = nota MIDI (0, -2 ou 48..74) ou -1 se invalida
# Pilha ($sp): 4 bytes ($ra)
# ==============================================================================
ler_tecla_musical:
    addi $sp, $sp, -4
    sw   $ra, 0($sp)

    li   $v0, 8
    la   $a0, buffer_teclas
    li   $a1, 32
    syscall

    la   $t0, buffer_teclas

ltm_pular_esp:
    lb   $a0, 0($t0)
    li   $t1, 32                    # ' '
    beq  $a0, $t1, ltm_avancar
    li   $t1, 9                     # '\t'
    beq  $a0, $t1, ltm_avancar
    j    ltm_traduzir

ltm_avancar:
    addi $t0, $t0, 1
    j    ltm_pular_esp

ltm_traduzir:
    jal  traduzir_tecla

    lw   $ra, 0($sp)
    addi $sp, $sp, 4
    jr   $ra

# ==============================================================================
# PROCEDIMENTO: compor_faixa (Nao-folha)
# Responsabilidade: Estudio completo de composicao e edicao na Heap com laco
#                   proprio, reexibindo a grade numerada apos cada acao.
# Pilha ($sp): 20 bytes ($s0..$s3, $ra)
# ==============================================================================
compor_faixa:
    addi $sp, $sp, -20
    sw   $s0, 0($sp)
    sw   $s1, 4($sp)
    sw   $s2, 8($sp)
    sw   $s3, 12($sp)
    sw   $ra, 16($sp)

comp_loop_estudio:
    # Mostra divisoria, grade numerada atual e guia de teclas
    li   $v0, 4
    la   $a0, str_nl
    syscall
    li   $v0, 4
    la   $a0, str_div_grade
    syscall

    lw   $a0, ptr_sequencia
    lw   $a1, tam_sequencia
    jal  exibir_grade_notas

    li   $v0, 4
    la   $a0, str_div_grade
    syscall
    li   $v0, 4
    la   $a0, str_comp_guia_teclas
    syscall

    # Menu do Estudio de Composicao
    li   $v0, 4
    la   $a0, str_comp_menu
    syscall

    jal  ler_inteiro_seguro
    move $t0, $v0

    beq  $t0, $zero, comp_fim
    li   $t1, 1
    beq  $t0, $t1, comp_continua
    li   $t1, 2
    beq  $t0, $t1, comp_editar_pos
    li   $t1, 3
    beq  $t0, $t1, comp_inserir_pos
    li   $t1, 4
    beq  $t0, $t1, comp_remover_pos
    li   $t1, 5
    beq  $t0, $t1, comp_undo
    li   $t1, 6
    beq  $t0, $t1, comp_substituir_tudo
    li   $t1, 7
    beq  $t0, $t1, comp_ouvir_agora
    li   $t1, 8
    beq  $t0, $t1, comp_zerar_faixa

    li   $v0, 4
    la   $a0, str_err_menu
    syscall
    j    comp_loop_estudio

# ------------------------------------------------------------------------------
# Submodo [1]: Adicionar notas ao final (Modo Continuo na Heap)
# ------------------------------------------------------------------------------
comp_continua:
    li   $v0, 4
    la   $a0, str_comp_cont_banner
    syscall

comp_cont_linha:
    li   $v0, 4
    la   $a0, str_prompt
    syscall

    li   $v0, 8
    la   $a0, buffer_teclas
    li   $a1, 120
    syscall

    la   $s0, buffer_teclas

    # Se o usuario apenas apertou ENTER (linha vazia), encerra modo continuo
    lb   $t0, 0($s0)
    beq  $t0, $zero, comp_cont_encerrar
    li   $t1, 10                    # '\n'
    beq  $t0, $t1, comp_cont_encerrar
    li   $t1, 13                    # '\r'
    beq  $t0, $t1, comp_cont_encerrar

comp_cont_char_loop:
    lb   $a0, 0($s0)
    beq  $a0, $zero, comp_cont_linha
    li   $t0, 10                    # '\n'
    beq  $a0, $t0, comp_cont_linha
    li   $t0, 13                    # '\r'
    beq  $a0, $t0, comp_cont_linha
    li   $t0, 48                    # '0' (encerrar modo continuo)
    beq  $a0, $t0, comp_cont_encerrar

    # Ignora espacos em branco (' ' ou '\t') para permitir digitar "a s d f"
    li   $t0, 32
    beq  $a0, $t0, comp_cont_prox
    li   $t0, 9
    beq  $a0, $t0, comp_cont_prox

    jal  traduzir_tecla
    li   $t0, -1
    beq  $v0, $t0, comp_cont_invalida

    # Tecla valida! Olha a frente no buffer se ha '~' ou '+' para sustentar na hora
    move $s1, $v0                   # $s1 = nota MIDI (ou 0 / -2)
    move $a0, $s1
    jal  adicionar_nota_heap        # $v0 = novo tam_sequencia (passo inicial)
    move $s2, $v0                   # $s2 = passo inicial da nota
    li   $s3, 1                     # $s3 = cont_passos unidos = 1
    addi $s0, $s0, 1
    blez $s1, comp_cont_tocar_nota

comp_cont_lookahead:
    lb   $t7, 0($s0)
    # Pula espacos entre a nota e o '~' (ex: "d ~")
    li   $t8, 32
    beq  $t7, $t8, comp_cont_skip_sp_la
    li   $t8, 9
    beq  $t7, $t8, comp_cont_skip_sp_la
    li   $t8, 126                   # '~'
    beq  $t7, $t8, comp_cont_add_sus
    li   $t8, 43                    # '+'
    beq  $t7, $t8, comp_cont_add_sus
    li   $t8, 61                    # '='
    beq  $t7, $t8, comp_cont_add_sus
    j    comp_cont_tocar_nota

comp_cont_skip_sp_la:
    addi $s0, $s0, 1
    j    comp_cont_lookahead

comp_cont_add_sus:
    li   $a0, -2
    jal  adicionar_nota_heap        # grava passo de sustain (-2) na Heap
    addi $s3, $s3, 1
    addi $s0, $s0, 1
    j    comp_cont_lookahead

comp_cont_tocar_nota:
    move $a0, $s2                   # passo inicial
    move $a1, $s1                   # nota
    move $a2, $s3                   # cont_passos unidos
    jal  tocar_nota_com_duracao
    j    comp_cont_char_loop

comp_cont_invalida:
    li   $v0, 4
    la   $a0, str_err_tecla_ign
    syscall

comp_cont_prox:
    addi $s0, $s0, 1
    j    comp_cont_char_loop

comp_cont_encerrar:
    li   $v0, 4
    la   $a0, str_comp_ok
    syscall
    j    comp_loop_estudio

# ------------------------------------------------------------------------------
# Submodo [2]: Editar / Substituir nota de um passo especifico (1..N)
# ------------------------------------------------------------------------------
comp_editar_pos:
    lw   $s1, tam_sequencia
    bgtz $s1, comp_edit_ok_faixa

    li   $v0, 4
    la   $a0, str_faixa_vazia
    syscall
    j    comp_loop_estudio

comp_edit_ok_faixa:
    li   $v0, 4
    la   $a0, str_ask_pos_edit
    syscall

    jal  ler_inteiro_seguro
    move $s2, $v0                   # $s2 = pos (1..N)

    blt  $s2, 1, comp_edit_err_pos
    bgt  $s2, $s1, comp_edit_err_pos

    # Mostra qual nota esta atualmente no passo escolhido
    li   $v0, 4
    la   $a0, str_passo_atual_1
    syscall
    li   $v0, 1
    move $a0, $s2
    syscall
    li   $v0, 4
    la   $a0, str_passo_atual_2
    syscall

    lw   $t1, ptr_sequencia
    addi $t2, $s2, -1
    sll  $t2, $t2, 2
    add  $t1, $t1, $t2
    lw   $a0, 0($t1)
    jal  imprimir_nome_nota

    li   $v0, 4
    la   $a0, str_passo_atual_3
    syscall

    # Pede a nova tecla
    li   $v0, 4
    la   $a0, str_ask_tecla
    syscall

    jal  ler_tecla_musical
    li   $t0, -1
    beq  $v0, $t0, comp_edit_err_tecla
    move $s3, $v0                   # $s3 = nova nota MIDI (ou 0 / -2)

    # Salva nova nota em ptr_sequencia + 4 * (pos - 1)
    lw   $t1, ptr_sequencia
    addi $t2, $s2, -1
    sll  $t2, $t2, 2
    add  $t1, $t1, $t2
    sw   $s3, 0($t1)

    # Toca a nota editada para feedback auditivo imediato
    move $a0, $s2
    move $a1, $s3
    jal  tocar_nota_unica

    li   $v0, 4
    la   $a0, str_ok_edit
    syscall
    j    comp_loop_estudio

comp_edit_err_pos:
    li   $v0, 4
    la   $a0, str_err_pos
    syscall
    j    comp_loop_estudio

comp_edit_err_tecla:
    li   $v0, 4
    la   $a0, str_err_tecla
    syscall
    j    comp_loop_estudio

# ------------------------------------------------------------------------------
# Submodo [3]: Inserir nota no meio da faixa (em qualquer posicao 1..N)
# ------------------------------------------------------------------------------
comp_inserir_pos:
    lw   $s1, tam_sequencia
    bgtz $s1, comp_ins_ok_faixa

    li   $v0, 4
    la   $a0, str_faixa_vazia
    syscall
    j    comp_loop_estudio

comp_ins_ok_faixa:
    li   $v0, 4
    la   $a0, str_ask_pos_ins
    syscall

    jal  ler_inteiro_seguro
    move $s2, $v0                   # $s2 = pos (1..N)

    blt  $s2, 1, comp_edit_err_pos
    bgt  $s2, $s1, comp_edit_err_pos

    li   $v0, 4
    la   $a0, str_ask_tecla
    syscall

    jal  ler_tecla_musical
    li   $t0, -1
    beq  $v0, $t0, comp_edit_err_tecla
    move $s3, $v0                   # $s3 = nova nota MIDI

    move $a0, $s2
    move $a1, $s3
    jal  inserir_nota_posicao_heap

    # Toca a nota inserida
    move $a0, $s2
    move $a1, $s3
    jal  tocar_nota_unica

    li   $v0, 4
    la   $a0, str_ok_ins
    syscall
    j    comp_loop_estudio

# ------------------------------------------------------------------------------
# Submodo [4]: Remover nota de um passo especifico (1..N)
# ------------------------------------------------------------------------------
comp_remover_pos:
    lw   $s1, tam_sequencia
    bgtz $s1, comp_rem_ok_faixa

    li   $v0, 4
    la   $a0, str_faixa_vazia
    syscall
    j    comp_loop_estudio

comp_rem_ok_faixa:
    li   $v0, 4
    la   $a0, str_ask_pos_rem
    syscall

    jal  ler_inteiro_seguro
    move $s2, $v0                   # $s2 = pos (1..N)

    blt  $s2, 1, comp_edit_err_pos
    bgt  $s2, $s1, comp_edit_err_pos

    move $a0, $s2
    jal  remover_nota_posicao_heap
    move $s1, $v0                   # novo N

    li   $v0, 4
    la   $a0, str_ok_rem
    syscall
    li   $v0, 1
    move $a0, $s1
    syscall
    li   $v0, 4
    la   $a0, str_nl
    syscall
    j    comp_loop_estudio

# ------------------------------------------------------------------------------
# Submodo [5]: Desfazer ultima nota (Undo)
# ------------------------------------------------------------------------------
comp_undo:
    lw   $s1, tam_sequencia
    bgtz $s1, comp_undo_exec

    li   $v0, 4
    la   $a0, str_undo_vazia
    syscall
    j    comp_loop_estudio

comp_undo_exec:
    addi $s1, $s1, -1
    sw   $s1, tam_sequencia

    li   $v0, 4
    la   $a0, str_undo_ok
    syscall
    li   $v0, 1
    move $a0, $s1
    syscall
    li   $v0, 4
    la   $a0, str_nl
    syscall
    j    comp_loop_estudio

# ------------------------------------------------------------------------------
# Submodo [6]: Substituir faixa inteira (Comecar nova musica do zero)
# ------------------------------------------------------------------------------
comp_substituir_tudo:
    sw   $zero, tam_sequencia
    li   $v0, 4
    la   $a0, str_limpar_ok
    syscall
    j    comp_continua

# ------------------------------------------------------------------------------
# Submodo [7]: Ouvir faixa atual (PLAY rapido 1x sem sair do estudio)
# ------------------------------------------------------------------------------
comp_ouvir_agora:
    lw   $a0, ptr_sequencia
    lw   $a1, tam_sequencia
    li   $a2, 1
    jal  tocar_sequencia
    j    comp_loop_estudio

# ------------------------------------------------------------------------------
# Submodo [8]: Limpar / Zerar faixa (N = 0)
# ------------------------------------------------------------------------------
comp_zerar_faixa:
    sw   $zero, tam_sequencia
    li   $v0, 4
    la   $a0, str_zerar_ok
    syscall
    j    comp_loop_estudio

comp_fim:
    lw   $s0, 0($sp)
    lw   $s1, 4($sp)
    lw   $s2, 8($sp)
    lw   $s3, 12($sp)
    lw   $ra, 16($sp)
    addi $sp, $sp, 20
    jr   $ra

# ==============================================================================
# PROCEDIMENTO: modo_teclado_livre (Nao-folha)
# Responsabilidade: Le sequencia de teclas, toca em tempo real (com suporte a
#                   sustentacao '~' / '+') e oferece anexar a Heap.
# Pilha ($sp): 20 bytes ($s0..$s3, $ra)
# ==============================================================================
modo_teclado_livre:
    addi $sp, $sp, -20
    sw   $s0, 0($sp)
    sw   $s1, 4($sp)
    sw   $s2, 8($sp)
    sw   $s3, 12($sp)
    sw   $ra, 16($sp)

    li   $v0, 4
    la   $a0, str_livre_ini
    syscall

    li   $v0, 8
    la   $a0, buffer_teclas
    li   $a1, 120
    syscall

    la   $s0, buffer_teclas
    li   $s2, 1                     # passo temporario (1..)
    li   $s3, 0                     # contador de notas validas tocadas

livre_loop:
    lb   $a0, 0($s0)
    beq  $a0, $zero, livre_fim_input
    li   $t0, 10                    # '\n'
    beq  $a0, $t0, livre_fim_input
    li   $t0, 13                    # '\r'
    beq  $a0, $t0, livre_fim_input

    # Ignora espacos em branco
    li   $t0, 32
    beq  $a0, $t0, livre_prox
    li   $t0, 9
    beq  $a0, $t0, livre_prox

    jal  traduzir_tecla
    li   $t0, -1
    beq  $v0, $t0, livre_invalida

    # Tecla valida! Olha a frente no buffer se ha '~' ou '+' para sustentar
    move $s1, $v0                   # $s1 = nota traduzida
    addi $s0, $s0, 1
    addi $s3, $s3, 1
    li   $t6, 1                     # cont_passos = 1
    blez $s1, livre_tocar_passo

livre_lookahead_sustain:
    lb   $t7, 0($s0)
    li   $t8, 32
    beq  $t7, $t8, livre_skip_sp_la
    li   $t8, 9
    beq  $t7, $t8, livre_skip_sp_la
    li   $t8, 126                   # '~'
    beq  $t7, $t8, livre_mais_sustain
    li   $t8, 43                    # '+'
    beq  $t7, $t8, livre_mais_sustain
    li   $t8, 61                    # '='
    beq  $t7, $t8, livre_mais_sustain
    j    livre_tocar_passo

livre_skip_sp_la:
    addi $s0, $s0, 1
    j    livre_lookahead_sustain

livre_mais_sustain:
    addi $t6, $t6, 1
    addi $s0, $s0, 1
    addi $s3, $s3, 1
    j    livre_lookahead_sustain

livre_tocar_passo:
    move $a0, $s2                   # passo temporario
    move $a1, $s1                   # nota
    move $a2, $t6                   # cont_passos
    add  $s2, $s2, $t6
    jal  tocar_nota_com_duracao
    j    livre_loop

livre_invalida:
    li   $v0, 4
    la   $a0, str_err_tecla_ign
    syscall

livre_prox:
    addi $s0, $s0, 1
    j    livre_loop

livre_fim_input:
    # Se nenhuma nota valida foi tocada, retorna sem perguntar
    blez $s3, livre_retornar

    li   $v0, 4
    la   $a0, str_livre_save
    syscall

    jal  ler_inteiro_seguro
    li   $t0, 1
    bne  $v0, $t0, livre_retornar

    # Anexa as notas validas do buffer ao vetor dinamico da Heap
    la   $s0, buffer_teclas
livre_save_loop:
    lb   $a0, 0($s0)
    beq  $a0, $zero, livre_save_done
    li   $t0, 10
    beq  $a0, $t0, livre_save_done
    li   $t0, 13
    beq  $a0, $t0, livre_save_done

    li   $t0, 32
    beq  $a0, $t0, livre_save_skip
    li   $t0, 9
    beq  $a0, $t0, livre_save_skip

    jal  traduzir_tecla
    li   $t0, -1
    beq  $v0, $t0, livre_save_skip

    move $a0, $v0                   # $a0 = nota (>0, 0 ou -2)
    jal  adicionar_nota_heap

livre_save_skip:
    addi $s0, $s0, 1
    j    livre_save_loop

livre_save_done:
    li   $v0, 4
    la   $a0, str_livre_ok
    syscall

livre_retornar:
    lw   $s0, 0($sp)
    lw   $s1, 4($sp)
    lw   $s2, 8($sp)
    lw   $s3, 12($sp)
    lw   $ra, 16($sp)
    addi $sp, $sp, 20
    jr   $ra

# ==============================================================================
# PROCEDIMENTO: configurar_estudio (Nao-folha)
# Responsabilidade: Altera instrumento MIDI e andamento (duracao_ms) com validacao
# Pilha ($sp): 4 bytes ($ra)
# ==============================================================================
configurar_estudio:
    addi $sp, $sp, -4
    sw   $ra, 0($sp)

    li   $v0, 4
    la   $a0, str_cfg_menu_i
    syscall

    jal  ler_inteiro_seguro
    move $t0, $v0

    li   $t1, 1
    beq  $t0, $t1, cfg_inst_piano
    li   $t1, 2
    beq  $t0, $t1, cfg_inst_violao
    li   $t1, 3
    beq  $t0, $t1, cfg_inst_baixo
    li   $t1, 4
    beq  $t0, $t1, cfg_inst_synth
    li   $t1, 5
    beq  $t0, $t1, cfg_inst_violino
    li   $t1, 6
    beq  $t0, $t1, cfg_inst_sanfona
    li   $t1, 7
    beq  $t0, $t1, cfg_inst_trompete

    li   $v0, 4
    la   $a0, str_err_cfg
    syscall
    j    cfg_bpm_step

cfg_inst_piano:
    li   $t2, 0
    sw   $t2, instrumento
    j    cfg_bpm_step
cfg_inst_violao:
    li   $t2, 24
    sw   $t2, instrumento
    j    cfg_bpm_step
cfg_inst_baixo:
    li   $t2, 33
    sw   $t2, instrumento
    j    cfg_bpm_step
cfg_inst_synth:
    li   $t2, 80
    sw   $t2, instrumento
    j    cfg_bpm_step
cfg_inst_violino:
    li   $t2, 40
    sw   $t2, instrumento
    j    cfg_bpm_step
cfg_inst_sanfona:
    li   $t2, 21
    sw   $t2, instrumento
    j    cfg_bpm_step
cfg_inst_trompete:
    li   $t2, 56
    sw   $t2, instrumento

cfg_bpm_step:
    li   $v0, 4
    la   $a0, str_cfg_menu_b
    syscall

    jal  ler_inteiro_seguro
    move $t0, $v0

    li   $t1, 1
    beq  $t0, $t1, cfg_bpm_lento
    li   $t1, 2
    beq  $t0, $t1, cfg_bpm_normal
    li   $t1, 3
    beq  $t0, $t1, cfg_bpm_rapido

    li   $v0, 4
    la   $a0, str_err_cfg
    syscall
    j    cfg_fim

cfg_bpm_lento:
    li   $t2, 180
    sw   $t2, duracao_ms
    j    cfg_ok
cfg_bpm_normal:
    li   $t2, 140
    sw   $t2, duracao_ms
    j    cfg_ok
cfg_bpm_rapido:
    li   $t2, 115
    sw   $t2, duracao_ms

cfg_ok:
    li   $v0, 4
    la   $a0, str_ok_cfg
    syscall

cfg_fim:
    lw   $ra, 0($sp)
    addi $sp, $sp, 4
    jr   $ra

# ==============================================================================
# PROCEDIMENTO: menu_efeitos (Nao-folha)
# Responsabilidade: Submenu de efeitos de estudio (transposicao e reverse)
# Pilha ($sp): 4 bytes ($ra)
# ==============================================================================
menu_efeitos:
    addi $sp, $sp, -4
    sw   $ra, 0($sp)

    lw   $t0, tam_sequencia
    bgtz $t0, fx_mostrar_menu

    li   $v0, 4
    la   $a0, str_fx_vazia
    syscall
    j    fx_fim

fx_mostrar_menu:
    li   $v0, 4
    la   $a0, str_fx_menu
    syscall

    jal  ler_inteiro_seguro
    move $t0, $v0

    beq  $t0, $zero, fx_fim
    li   $t1, 1
    beq  $t0, $t1, fx_up
    li   $t1, 2
    beq  $t0, $t1, fx_down
    li   $t1, 3
    beq  $t0, $t1, fx_rev

    li   $v0, 4
    la   $a0, str_err_menu
    syscall
    j    fx_fim

fx_up:
    lw   $a0, ptr_sequencia
    lw   $a1, tam_sequencia
    li   $a2, 2
    jal  aplicar_transposicao
    li   $v0, 4
    la   $a0, str_fx_ok_tr
    syscall
    j    fx_fim

fx_down:
    lw   $a0, ptr_sequencia
    lw   $a1, tam_sequencia
    li   $a2, -2
    jal  aplicar_transposicao
    li   $v0, 4
    la   $a0, str_fx_ok_tr
    syscall
    j    fx_fim

fx_rev:
    lw   $a0, ptr_sequencia
    lw   $a1, tam_sequencia
    jal  inverter_sequencia
    li   $v0, 4
    la   $a0, str_fx_ok_rev
    syscall

fx_fim:
    lw   $ra, 0($sp)
    addi $sp, $sp, 4
    jr   $ra

# ==============================================================================
# PROCEDIMENTO: aplicar_transposicao (Folha)
# Entrada: $a0 = ptr_sequencia, $a1 = tam_sequencia (N), $a2 = delta (+2 ou -2)
# Saida:   $v0 = quantidade de notas ativas efetivamente transpostas
# Responsabilidade: Transpoe apenas notas ativas (> 0), preservando intactos
#                   tanto os passos de pausa (0) quanto os de sustentacao (-2)!
# Pilha ($sp): 8 bytes ($s0, $s1)
# ==============================================================================
aplicar_transposicao:
    addi $sp, $sp, -8
    sw   $s0, 0($sp)
    sw   $s1, 4($sp)

    move $s0, $a0                   # $s0 = base do vetor na Heap
    li   $s1, 0                     # $s1 = contador de notas transpostas
    li   $t0, 0                     # $t0 = indice i = 0

transp_loop:
    bge  $t0, $a1, transp_fim
    sll  $t1, $t0, 2                # deslocamento = i * 4
    add  $t1, $s0, $t1              # endereco de heap_seq[i]
    lw   $t2, 0($t1)                # $t2 = nota atual

    blez $t2, transp_proximo        # Pausa (0) e Sustentacao (-2) permanecem intactas!

    add  $t2, $t2, $a2              # Soma delta (+2 ou -2 semitons)

    # Clamping no limite inferior seguro (36 = DO2)
    li   $t3, 36
    bge  $t2, $t3, transp_check_max
    move $t2, $t3
    j    transp_salvar

transp_check_max:
    # Clamping no limite superior seguro (96 = DO7)
    li   $t3, 96
    ble  $t2, $t3, transp_salvar
    move $t2, $t3

transp_salvar:
    sw   $t2, 0($t1)                # Grava nota transposta na Heap
    addi $s1, $s1, 1

transp_proximo:
    addi $t0, $t0, 1
    j    transp_loop

transp_fim:
    move $v0, $s1
    lw   $s0, 0($sp)
    lw   $s1, 4($sp)
    addi $sp, $sp, 8
    jr   $ra

# ==============================================================================
# PROCEDIMENTO: inverter_sequencia (Folha)
# Entrada: $a0 = ptr_sequencia, $a1 = tam_sequencia (N)
# Pilha ($sp): Sem pilha (folha - usa $t0..$t5)
# ==============================================================================
inverter_sequencia:
    li   $t0, 0                     # i = 0 (inicio)
    addi $t1, $a1, -1               # j = N - 1 (fim)

rev_loop:
    bge  $t0, $t1, rev_fim
    sll  $t2, $t0, 2
    add  $t2, $a0, $t2              # end heap_seq[i]
    sll  $t3, $t1, 2
    add  $t3, $a0, $t3              # end heap_seq[j]

    lw   $t4, 0($t2)                # temp1 = heap_seq[i]
    lw   $t5, 0($t3)                # temp2 = heap_seq[j]
    sw   $t5, 0($t2)                # heap_seq[i] = temp2
    sw   $t4, 0($t3)                # heap_seq[j] = temp1

    addi $t0, $t0, 1
    addi $t1, $t1, -1
    j    rev_loop

rev_fim:
    jr   $ra

# ==============================================================================
# PROCEDIMENTO: carregar_demo (Nao-folha)
# Entrada: $a0 = opcao de demo (1..5)
# Saida:   $v0 = 1 se carregou com sucesso, 0 se opcao invalida
# Responsabilidade: Carrega uma das 5 musicas completas (100+ passos com sustain)
#                   na Heap e configura automaticamente o instrumento e BPM.
# Pilha ($sp): 16 bytes ($s0, $s1, $s2, $ra)
# ==============================================================================
carregar_demo:
    addi $sp, $sp, -16
    sw   $s0, 0($sp)
    sw   $s1, 4($sp)
    sw   $s2, 8($sp)
    sw   $ra, 12($sp)

    li   $t0, 1
    beq  $a0, $t0, demo_sel_1
    li   $t0, 2
    beq  $a0, $t0, demo_sel_2
    li   $t0, 3
    beq  $a0, $t0, demo_sel_3
    li   $t0, 4
    beq  $a0, $t0, demo_sel_4
    li   $t0, 5
    beq  $a0, $t0, demo_sel_5

    # Opcao invalida
    li   $v0, 0
    j    demo_fim

demo_sel_1:
    la   $s0, demo1_notas
    lw   $s2, tam_demo1
    lw   $t1, inst_demo1
    sw   $t1, instrumento
    lw   $t2, ms_demo1
    sw   $t2, duracao_ms
    j    demo_copiar

demo_sel_2:
    la   $s0, demo2_notas
    lw   $s2, tam_demo2
    lw   $t1, inst_demo2
    sw   $t1, instrumento
    lw   $t2, ms_demo2
    sw   $t2, duracao_ms
    j    demo_copiar

demo_sel_3:
    la   $s0, demo3_notas
    lw   $s2, tam_demo3
    lw   $t1, inst_demo3
    sw   $t1, instrumento
    lw   $t2, ms_demo3
    sw   $t2, duracao_ms
    j    demo_copiar

demo_sel_4:
    la   $s0, demo4_notas
    lw   $s2, tam_demo4
    lw   $t1, inst_demo4
    sw   $t1, instrumento
    lw   $t2, ms_demo4
    sw   $t2, duracao_ms
    j    demo_copiar

demo_sel_5:
    la   $s0, demo5_notas
    lw   $s2, tam_demo5
    lw   $t1, inst_demo5
    sw   $t1, instrumento
    lw   $t2, ms_demo5
    sw   $t2, duracao_ms

demo_copiar:
    # Redefine tam_sequencia = 0 para recomecar a faixa com as notas da demo
    sw   $zero, tam_sequencia

    li   $s1, 0                     # i = 0

demo_loop:
    bge  $s1, $s2, demo_sucesso
    sll  $t0, $s1, 2
    add  $t0, $s0, $t0
    lw   $a0, 0($t0)                # $a0 = demo_notas[i]
    jal  adicionar_nota_heap
    addi $s1, $s1, 1
    j    demo_loop

demo_sucesso:
    li   $v0, 1

demo_fim:
    lw   $s0, 0($sp)
    lw   $s1, 4($sp)
    lw   $s2, 8($sp)
    lw   $ra, 12($sp)
    addi $sp, $sp, 16
    jr   $ra
