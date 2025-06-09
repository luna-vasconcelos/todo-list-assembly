# Main-Menu          

# (1.2. Variáveis simples)
.data
menuHdr: .asciiz "\nMenu - To-do list:\n"
optTxt:  .asciiz "  1) Adicionar tarefa\n  2) Listar tarefas\n  3) Marcar tarefa como concluída\n  4) Ordenar tarefas por prioridade\n  5) Mostrar tarefas concluídas\n  6) Sair\n"
prompt:  .asciiz "Sua escolha (1-6): "
badOpt:  .asciiz "\nOpção inválida — tente de novo.\n"
newline: .asciiz "\n"

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
    li  $v0, 4 
    la $a0, msg1
    syscall          # (1.9. Saída de valores inteiros para o usuário)
    li  $v0, 0       # continua laço
    jr  $ra

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
