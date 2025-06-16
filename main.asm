# Main-Menu          

.eqv MAX_TASKS 10            # Máximo de 10 tarefas na lista
.eqv TASK_DESC_SIZE 128      # Espaço para a descrição da tarefa
.eqv TASK_PRIO_OFFSET 128    # Deslocamento para o campo 'prioridade'
.eqv TASK_STATUS_OFFSET 132 # Deslocamento para o campo 'status'
.eqv TASK_STRUCT_SIZE 136    # Tamanho total da struct da tarefa

# (1.2. Variáveis simples)
.data

taskList:   .space 1360     # Aloca espaço para 10 tarefas
taskCount:  .word 0         # Contador de tarefas, inicia em 0

menuHdr: .asciiz "\nMenu - To-do list:\n"
optTxt:  .asciiz "  1) Adicionar tarefa\n  2) Listar tarefas\n  3) Marcar tarefa como concluída\n  4) Ordenar tarefas por prioridade\n  5) Mostrar tarefas concluídas\n  6) Sair\n"
prompt:  .asciiz "Sua escolha (1-6): "
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
msg5: .asciiz "\nVocê escolheu a opção 5 (Concluídas)…\n"
msg6: .asciiz "\nEncerrando o programa…\n"

# casos da jump table
# (1.3. Variável tipo array)
jumpTable:
    .word do_add, do_list, do_mark, do_sort, do_done, do_exit

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
    # TODO: checar com o Camilo se isso é válido ou se ele só quer if-else
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


# FUNÇÕES PRINCIPAIS DO PROGRAMA:
# Imprime msg1 e devolve 0 em $v0 para continuar no menu.
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
do_list:
    li  $v0, 4
    la $a0, msg2
    syscall
    li  $v0, 0
    jr  $ra

do_mark:
    li  $v0, 4 
    la $a0, msg3 
    syscall
    li  $v0, 0
    jr  $ra

do_sort:
    li  $v0, 4 
    la $a0, msg4 
    syscall
    li  $v0, 0
    jr  $ra

do_done:
    li  $v0, 4 
    la $a0, msg5 
    syscall
    li  $v0, 0
    jr  $ra

do_exit:
    li  $v0, 4 
    la $a0, msg6 
    syscall
    li  $v0, 1             # devolve ≠0 = main encerra
    jr  $ra