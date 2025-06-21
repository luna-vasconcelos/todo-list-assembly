# Main To-Do List Application
.eqv MAX_TASKS 10
.eqv TASK_DESC_SIZE 128
.eqv TASK_PRIO_OFFSET 128
.eqv TASK_STATUS_OFFSET 132
.eqv TASK_STRUCT_SIZE 136

.data
# Task storage
taskList:   .space 1360
taskCount:  .word 0

# Menu strings
menuHdr: .asciiz "\nMenu - To-do list:\n"
optTxt:  .asciiz "  1) Adicionar tarefa\n  2) Listar tarefas\n  3) Marcar tarefa como concluída\n  4) Ordenar tarefas por prioridade\n  5) Mostrar tarefas concluídas\n  6) Sair\n"
prompt:  .asciiz "Sua escolha (1-6): "
badOpt:  .asciiz "\nOpção inválida — tente de novo.\n"
newline: .asciiz "\n"

# Task input
promptDesc: .asciiz "Digite a descrição da tarefa: "
promptPrio: .asciiz "Digite a prioridade da tarefa (1-5): "
msgSuccess: .asciiz "\nTarefa adicionada com sucesso!\n"
msgListFull:.asciiz "\nERRO: A lista de tarefas está cheia!\n"

# Option messages
msg1: .asciiz "\nOpção 1 (Adicionar) selecionada...\n"
msg2: .asciiz "\nOpção 2 (Listar) selecionada...\n"
msg3: .asciiz "\nOpção 3 (Marcar) selecionada...\n"
msg4: .asciiz "\nOpção 4 (Ordenar) selecionada...\n"
msg5: .asciiz "\nOpção 5 (Concluídas) selecionada...\n"
msg6: .asciiz "\nEncerrando programa...\n"

# List display
_list_header: .asciiz "\nLista ordenada por prioridade:\nPrioridade | Descrição\n"
_separator: .asciiz " | "
_empty_msg: .asciiz "Nenhuma tarefa para mostrar.\n"

# Jump table
jumpTable: .word do_add, do_list, do_mark, do_sort, do_done, do_exit

.text
.globl main

main:
menu_loop:
    # Print menu
    li $v0, 4
    la $a0, menuHdr
    syscall
    la $a0, optTxt
    syscall
    la $a0, prompt
    syscall

    # Read choice
    li $v0, 5
    syscall
    move $t0, $v0

    # Validate
    blt $t0, 1, invalid
    bgt $t0, 6, invalid

    # Call function
    addi $t1, $t0, -1
    sll $t1, $t1, 2
    la $t2, jumpTable
    add $t2, $t2, $t1
    lw $t3, 0($t2)
    jalr $t3
    
    beq $v0, $zero, menu_loop
    li $v0, 10
    syscall

invalid:
    li $v0, 4
    la $a0, badOpt
    syscall
    j menu_loop

# ============ FUNÇÕES ============

do_add:
    addi $sp, $sp, -8
    sw $ra, 4($sp)
    sw $s0, 0($sp)

    lw $t0, taskCount
    li $t1, MAX_TASKS
    bge $t0, $t1, _add_full

    la $s0, taskList
    lw $t0, taskCount
    li $t1, TASK_STRUCT_SIZE
    mul $t1, $t0, $t1
    add $s0, $s0, $t1

    li $v0, 4
    la $a0, promptDesc
    syscall
    li $v0, 8
    move $a0, $s0
    li $a1, TASK_DESC_SIZE
    syscall

    li $v0, 4
    la $a0, promptPrio
    syscall
    li $v0, 5
    syscall

    sw $v0, TASK_PRIO_OFFSET($s0)
    sw $zero, TASK_STATUS_OFFSET($s0)

    lw $t0, taskCount
    addi $t0, $t0, 1
    sw $t0, taskCount

    li $v0, 4
    la $a0, msgSuccess
    syscall
    j _add_exit

_add_full:
    li $v0, 4
    la $a0, msgListFull
    syscall

_add_exit:
    lw $s0, 0($sp)
    lw $ra, 4($sp)
    addi $sp, $sp, 8
    li $v0, 0
    jr $ra

do_list:
    li $v0, 4
    la $a0, msg2
    syscall
    
    # Implementação básica - pode ser melhorada
    lw $t0, taskCount
    beqz $t0, _list_empty
    
    la $t1, taskList
    li $v0, 4
    la $a0, _list_header
    syscall

_list_loop:
    li $v0, 1
    lw $a0, TASK_PRIO_OFFSET($t1)
    syscall
    
    li $v0, 4
    la $a0, _separator
    syscall
    
    li $v0, 4
    move $a0, $t1
    syscall
    
    li $v0, 4
    la $a0, newline
    syscall
    
    addi $t1, $t1, TASK_STRUCT_SIZE
    addi $t0, $t0, -1
    bgtz $t0, _list_loop
    j _list_exit

_list_empty:
    li $v0, 4
    la $a0, _empty_msg
    syscall

_list_exit:
    li $v0, 0
    jr $ra

do_mark:
    li $v0, 4
    la $a0, msg3
    syscall
    li $v0, 0
    jr $ra

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

do_done:
    li $v0, 4
    la $a0, msg5
    syscall
    li $v0, 0
    jr $ra

do_exit:
    li $v0, 4
    la $a0, msg6
    syscall
    li $v0, 1
    jr $ra
