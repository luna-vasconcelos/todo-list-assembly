# Main-Menu          

.eqv MAX_TASKS 10            # Máximo de 10 tarefas na lista
.eqv TASK_DESC_SIZE 128      # Espaço para a descrição da tarefa
.eqv TASK_PRIO_OFFSET 128    # Deslocamento para o campo 'prioridade'
.eqv TASK_STATUS_OFFSET 132 # Deslocamento para o campo 'status'
.eqv TASK_STRUCT_SIZE 136    # Tamanho total da struct da tarefa

# (1.2. Variáveis simples)
.data
    # (1.3. Variável tipo array)
    taskList:   .space 1360     # Aloca espaço para 10 tarefas

    taskCount:  .word 0         # Contador de tarefas, inicia em 0

    menuHdr: .asciiz "\nMenu - To-do list:\n"
    optTxt:  .asciiz "  1) Adicionar tarefa\n  2) Listar tarefas\n  3) Marcar tarefa como concluída\n  4) Ordenar tarefas por prioridade\n  5) Sair\n"
    prompt:  .asciiz "Sua escolha (1-5): "
    badOpt:  .asciiz "\nOpção inválida — tente de novo.\n"
    newline: .asciiz "\n"

    promptDesc: .asciiz "Digite a descrição da tarefa: "
    promptPrio: .asciiz "Digite a prioridade da tarefa (ex: 1 a 5): "
    msgSuccess: .asciiz "\nTarefa adicionada com sucesso!\n"
    msgListFull:.asciiz "\nERRO: A lista de tarefas está cheia!\n"

    msg1: .asciiz "\nVocê escolheu a opção 1 (Adicionar)…\n"
    msg2: .asciiz "\nVocê escolheu a opção 2 (Listar)…\n"
    msg3: .asciiz "\nVocê escolheu a opção 3 (Marcar concluída)…\n"
    msg4: .asciiz "\nVocê escolheu a opção 4 (Ordenar)…\n"
    msg6: .asciiz "\nEncerrando o programa…\n"

    # List display
    _list_header: .asciiz "\nLista de tarefas:\nPrioridade | Status | Descrição\n"
    _separator: .asciiz " | "
    _empty_msg: .asciiz "Nenhuma tarefa para mostrar.\n"

    # Marcar como concluída
    _mark_prompt:       .asciiz "\nTarefas disponíveis para marcar como concluídas:\n"
    _mark_index_prompt: .asciiz "\nDigite o número da tarefa a marcar como concluída: "
    _mark_success:      .asciiz "\nTarefa marcada como concluída com sucesso!\n"
    _mark_invalid_msg:  .asciiz "\nÍndice inválido!\n"

    # casos da jump table
    jumpTable:
        .word do_add, do_list, do_mark, do_sort, do_exit

    # Definições de status da tarefa
    _status_done:    .asciiz "Concluída"
    _status_pending: .asciiz "Pendente"

.text
.globl main
main:
menu_loop:
    # imprime todo o menu de uma vez 
    li  $v0, 4               # syscall: print_string
    la  $a0, menuHdr         # cabeçalho
    syscall
    la  $a0, optTxt          # opções 1-6
    syscall
    la  $a0, prompt          # prompt para que o usuário digite a escolha
    syscall

    # lê opção digitada do usuário 
    # (1.1.)
    li  $v0, 5               # syscall: read_int
    syscall
    move $t0, $v0            # armazena em $t0 a opção

    # realiza validação do range do menu (1‒6)
    # (1.4.: if)
    blt  $t0, 1, invalid     # (branch less than) if (op < 1)  goto invalid
    bgt  $t0, 6, invalid     # (branch greater than) if (op > 6)  goto invalid

    # jump table: busca handler correspondente 
    addi $t1, $t0, -1        # (add immediate) converte 1-based em 0-based
    sll  $t1, $t1, 2         # (shift left logical) índice ×4 (byte offset)
    la   $t2, jumpTable       # (load address) base da tabela
    addu $t2, $t2, $t1       # (add unsigned) endereço da word desejada
    lw   $t3, 0($t2)         # $t3 = endereço da função
    jalr $t3                 # (jump and link register) chama a função
    beq  $v0, $zero, menu_loop   # enquanto retorno==0 = repete menu (loop: 1.5. Estrutura de repetição)
    li   $v0, 10             # retorno !=0 = sair
    syscall

invalid:
    li  $v0, 4
    la  $a0, badOpt
    syscall
    j   menu_loop


############### FUNÇÕES PRINCIPAIS DO PROGRAMA ###############

# do_add: Função para adicionar novas tarefas
do_add:
    # Prólogo: Salva registradores que serão modificados
    addi $sp, $sp, -8       # Aloca 8 bytes na pilha
    sw   $ra, 4($sp)        # Salva o endereço de retorno ($ra)
    sw   $s0, 0($sp)        # Salva $s0 (usaremos para o endereço da tarefa)

    # Verifica se a lista de tarefas está cheia
    lw   $t0, taskCount     # $t0 = taskCount
    li   $t1, MAX_TASKS     # $t1 = 10
    bge  $t0, $t1, _add_full # Se (taskCount >= MAX_TASKS), pula para _add_full

    # Calcula o endereço da nova tarefa na memória
    # Endereço = EndereçoBase + (índice * tamanho_da_struct)
    la   $s0, taskList      # $s0 = endereço base de taskList
    lw   $t0, taskCount     # $t0 = índice da nova tarefa (0, 1, 2...)
    li   $t1, TASK_STRUCT_SIZE
    mul  $t1, $t0, $t1      # offset = índice * 136
    add  $s0, $s0, $t1      # $s0 agora aponta para o início da struct da nova tarefa

    # Pede e lê a descrição da tarefa
    li   $v0, 4
    la   $a0, promptDesc
    syscall
    li   $v0, 8             # Syscall para ler string
    la   $a0, 0($s0)        # Argumento 1: Endereço do buffer (início da struct)
    li   $a1, TASK_DESC_SIZE# Argumento 2: Tamanho máximo do buffer
    syscall

    # Pede e lê a prioridade da tarefa
    li   $v0, 4
    la   $a0, promptPrio
    syscall
    li   $v0, 5             # Syscall para ler um inteiro
    syscall                 # O inteiro lido está em $v0

    # Salva a prioridade e o status inicial (0 = ativa) na struct
    sw   $v0, TASK_PRIO_OFFSET($s0)   # Salva prioridade no campo correto
    sw   $zero, TASK_STATUS_OFFSET($s0) # Salva status 0

    # Incrementa o contador de tarefas
    lw   $t0, taskCount
    addi $t0, $t0, 1
    sw   $t0, taskCount

    # Imprime mensagem de sucesso e vai para o final
    li   $v0, 4
    la   $a0, msgSuccess
    syscall
    j    _add_exit

_add_full:
    # Bloco executado apenas se a lista estiver cheia
    li   $v0, 4
    la   $a0, msgListFull
    syscall

_add_exit:
    # Epílogo: Restaura os registradores da pilha
    lw   $s0, 0($sp)
    lw   $ra, 4($sp)
    addi $sp, $sp, 8        # Libera o espaço alocado na pilha

    li   $v0, 0             # Retorna 0 para que o menu continue
    jr   $ra                # Retorna para o loop principal


# do_list: lista as tarefas sem ordem pre determinada
do_list:
    addi $sp, $sp, -8        # prólogo: reserva espaço
    sw   $ra, 4($sp)         # salva endereço de retorno do menu
    sw   $s0, 0($sp)         # (opcional) se precisar de um saved-reg

    li   $v0, 4
    la   $a0, msg2
    syscall

    lw   $t0, taskCount
    beqz $t0, _list_empty

    li   $v0, 4
    la   $a0, _list_header
    syscall

    la   $a0, taskList       # primeiro item
    move $a1, $t0            # nº de tarefas
    jal  print_task_rec      # $ra é alterado aqui

    j    _list_exit

_list_empty:
    li   $v0, 4
    la   $a0, _empty_msg
    syscall

_list_exit:
    li   $v0, 0              # devolve 0 p/ continuar no menu
    lw   $s0, 0($sp)         # restaura registradores salvos
    lw   $ra, 4($sp)
    addi $sp, $sp, 8
    jr   $ra                 # volta ao menu
# print_task_rec  —  imprime tarefas de forma recursiva
# Entradas:
#   $a0 = endereço da tarefa atual
#   $a1 = número de tarefas restantes a exibir
print_task_rec:
    beqz $a1, _print_base      # se não há tarefas, sai limpo
    # ---------- PRÓLOGO ----------
    addi $sp, $sp, -12
    sw   $ra, 8($sp)
    sw   $t0, 4($sp)
    sw   $t1, 0($sp)
    # ---------- CORPO ----------
    move $t0, $a0                   # ponteiro para a struct atual
    
    # ---- imprimir prioridade ----
    lw   $t1, TASK_PRIO_OFFSET($t0)
    li   $v0, 1
    move $a0, $t1
    syscall

    # separador " | "
    li   $v0, 4
    la   $a0, _separator
    syscall

    # ---- imprimir status ----
    lw   $t2, TASK_STATUS_OFFSET($t0)  # 0 = pendente, 1 = concluído
    beq  $t2, $zero, _print_stat_pending
    la   $a0, _status_done             # status = 1 → concluída
    j    _print_stat_print
    _print_stat_pending:
    la   $a0, _status_pending          # status = 0 → pendente
    _print_stat_print:
    li   $v0, 4
    syscall

    # separador " | "
    li   $v0, 4
    la   $a0, _separator
    syscall

    # ---- imprimir descrição ----
    li   $v0, 4
    move $a0, $t0
    syscall

    # chamada recursiva
    li   $t1, TASK_STRUCT_SIZE
    add  $a0, $t0, $t1              # próximo endereço
    addi $a1, $a1, -1               # tarefas_restantes--
    jal  print_task_rec

    # ---------- EPÍLOGO ----------
    lw   $t1, 0($sp)
    lw   $t0, 4($sp)
    lw   $ra, 8($sp)
    addi $sp, $sp, 12
    jr   $ra
_print_base:                         # caso-base sem frame
    jr   $ra

# do_mark: Marcar as tarefas disponíveis como concluídas, mostra as tarefas disponíveis não concluídas para marcar e dá a opção de escolha para marcação
do_mark:
    addi $sp, $sp, -12
    sw $ra, 8($sp)
    sw $s0, 4($sp)
    sw $s1, 0($sp)

    li $v0, 4
    la $a0, msg3
    syscall

    # Verificar se há tarefas
    lw $t0, taskCount
    beqz $t0, _mark_no_tasks

    # Mostrar lista de tarefas não concluídas
    li $v0, 4
    la $a0, _mark_prompt
    syscall

    la $s0, taskList        # Carregar início da lista de tarefas
    li $s1, 0               # Contador de tarefas

_mark_list_loop:
    lw $t1, TASK_STATUS_OFFSET($s0)
    bnez $t1, _mark_skip    # Pular tarefas já concluídas

    # Mostrar índice da tarefa
    li $v0, 1
    move $a0, $s1
    syscall

    # Mostrar separador
    li $v0, 4
    la $a0, _separator
    syscall

    # Mostrar descrição
    move $a0, $s0
    syscall

_mark_skip:
    addi $s0, $s0, TASK_STRUCT_SIZE
    addi $s1, $s1, 1
    blt $s1, $t0, _mark_list_loop

    # Pedir índice da tarefa a marcar
    li $v0, 4
    la $a0, _mark_index_prompt
    syscall
    li $v0, 5
    syscall

    # Validar índice
    bltz $v0, _mark_invalid
    lw $t0, taskCount
    bge $v0, $t0, _mark_invalid

    # Marcar tarefa como concluída
    li $t1, TASK_STRUCT_SIZE
    mul $t1, $v0, $t1
    la $t0, taskList
    add $t0, $t0, $t1
    li $t1, 1
    sw $t1, TASK_STATUS_OFFSET($t0)

    li $v0, 4
    la $a0, _mark_success
    syscall
    j _mark_exit

_mark_invalid:
    li $v0, 4
    la $a0, _mark_invalid_msg
    syscall
    j _mark_exit

_mark_no_tasks:
    li $v0, 4
    la $a0, _empty_msg
    syscall

_mark_exit:
    lw $s1, 0($sp)
    lw $s0, 4($sp)
    lw $ra, 8($sp)
    addi $sp, $sp, 12
    li $v0, 0
    jr $ra

# do_sort: Função para ordenar as tarefas que já foram adicionadas por ordem de prioridade
do_sort:
    addi $sp, $sp, -24
    sw $ra, 20($sp)
    sw $s0, 16($sp)
    sw $s1, 12($sp)
    sw $s2, 8($sp)
    sw $s3, 4($sp)
    sw $s4, 0($sp)

    li $v0, 4
    la $a0, msg4
    syscall

    lw $t0, taskCount
    ble $t0, 1, _sort_end

    li $s0, 0
    addi $s1, $t0, -1
    la $s2, taskList

_sort_outer:
    bge $s0, $s1, _sort_end

    li $s3, 0
    sub $s4, $s1, $s0

_sort_inner:
    bge $s3, $s4, _sort_next_outer

    mul $t1, $s3, TASK_STRUCT_SIZE
    add $t2, $s2, $t1
    addi $t3, $t1, TASK_STRUCT_SIZE
    add $t3, $s2, $t3

    lw $t4, TASK_PRIO_OFFSET($t2)
    lw $t5, TASK_PRIO_OFFSET($t3)
    ble $t4, $t5, _sort_no_swap

    move $a0, $t2
    addi $a1, $sp, 24
    li $a2, TASK_STRUCT_SIZE
    jal _copy_memory

    move $a0, $t3
    move $a1, $t2
    li $a2, TASK_STRUCT_SIZE
    jal _copy_memory

    addi $a0, $sp, 24
    move $a1, $t3
    li $a2, TASK_STRUCT_SIZE
    jal _copy_memory

_sort_no_swap:
    addi $s3, $s3, 1
    j _sort_inner

_sort_next_outer:
    addi $s0, $s0, 1
    j _sort_outer

_sort_end:
    # Mostra lista ordenada
    jal do_list

    lw $s4, 0($sp)
    lw $s3, 4($sp)
    lw $s2, 8($sp)
    lw $s1, 12($sp)
    lw $s0, 16($sp)
    lw $ra, 20($sp)
    addi $sp, $sp, 24
    li $v0, 0
    jr $ra

_copy_memory:
    li $t9, 0
_copy_loop:
    bge $t9, $a2, _copy_end
    lb $t8, 0($a0)
    sb $t8, 0($a1)
    addi $a0, $a0, 1
    addi $a1, $a1, 1
    addi $t9, $t9, 1
    j _copy_loop
_copy_end:
    jr $ra

do_exit:
    li  $v0, 4 
    la $a0, msg6 
    syscall
    li  $v0, 1             # devolve ≠0 = main encerra
    jr  $ra
