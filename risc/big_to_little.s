.data
input_addr:         .word 0x80
stack_top:          .word 0x1000
output_addr:        .word 0x84
    .text
    .org 0x90
_start:
    lui  a0, %hi(stack_top)         ; инициализация стека
    addi a0, a0, %lo(stack_top)
    lw   sp, 0(a0)

    lui  a0, %hi(input_addr)        ; загрузка числа в a0
    addi a0, a0, %lo(input_addr)
    lw   a0, 0(a0)
    lw   a0, 0(a0)

    jal  ra, reverse_word           ; запуск главной процедуры

    lui  a2, %hi(output_addr)
    addi a2, a2, %lo(output_addr)   ; запись результата
    lw   a2, 0(a2)
    sw   a0, 0(a2)

    halt


reverse_word:
    addi sp, sp, -4                 ; запись адреса возврата в стек
    sw   ra, 0(sp)

    jal  ra, swap_halves            ; меняет местами старшие и младшие байты

    lui  t2, 0x00FF0                ; 0x00FF00FF маска в t2
    addi t2, t2, 0xFF

    and  t0, a0, t2                 ; применение маски в t0
    slli t0, t0, 8                  ; сдвиг влево

    srli a0, a0, 8                  ; сдвиг справо исходного числа
    and  a0, a0, t2                 ; маска

    or   a0, a0, t0                 ; склейка результата

    lw   ra, 0(sp)                  ; загрузка адреса возврата
    addi sp, sp, 4                  ; освобождение памяти в стеке

    jr   ra                         ; возврат


swap_halves:                        ; меняет местами старшие и младшие
    
    slli t0, a0, 16
    srli t1, a0, 16
    or   a0, t0, t1

    jr   ra