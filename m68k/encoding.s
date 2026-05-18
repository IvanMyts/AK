.data
.org 0x00
buffer:     .word '\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0'
.text
.org 0x100
_start:
    movea.l 0x1000, A7     ; Инициализация стека

    link A6, -32             ; Выделение памяти в стеке
    move.l D0, -4(A6)
    move.l D1, -8(A6)
    move.l D2, -12(A6)
    move.l D3, -16(A6)
    move.l D4, -20(A6)
    move.l D5, -24(A6)
    move.l D6, -28(A6)
    move.l D7, -32(A6)

    movea.l 0, A0          ; A0 - адрес буфера
    movea.l 0x80, A1       ; A1 - адрес ввода
    movea.l 0x84, A2       ; A2 - адрес вывода
    clr.l D2               ; D2 - счетчик считанных символов
    clr.l D3               ; D3 - счетчик записанных байтов

main_loop:
    jsr read_and_decode    ; чтение 1 символа
    cmp.l -2, D0           ; если \n - конец ввода
    beq finish
    cmp.l 0, D0
    blt invalid_err        ; проверка на ошибку
    move.l D0, D4

    jsr read_and_decode    ; чтение 2 символа
    cmp.l 0, D0
    blt invalid_err        ; проверка на ошибку
    move.l D0, D5

    jsr read_and_decode    ; чтение 2 символа
    cmp.l -3, D0           ; проверка на =
    beq ok_c3
    cmp.l 0, D0
    blt invalid_err        ; проверка на ошибку
ok_c3:
    move.l D0, D6

    jsr read_and_decode    ; чтение 4 символа
    cmp.l -3, D0
    beq ok_c4              ; проверка на =
    cmp.l 0, D0
    blt invalid_err
ok_c4:
    move.l D0, D7

    
    move.l D4, D0          ; запись 1 байта
    lsl.l 2, D0
    move.l D5, D1
    lsr.l 4, D1
    or.l D1, D0
    move.b D0, (A0)+       ; Сохраняем с пост-инкрементом
    add.l 1, D3

    cmp.l -3, D6
    bne decode_b2          
    cmp.l -3, D7           ; если 3 символ это =, то 4 тоже должен быть =
    bne invalid_err
    jmp wait_nl

decode_b2:
    move.l D5, D0          ; запись 2 байта
    and.l 15, D0
    lsl.l 4, D0
    move.l D6, D1
    lsr.l 2, D1
    or.l D1, D0
    move.b D0, (A0)+
    add.l 1, D3

    cmp.l -3, D7
    beq wait_nl

    move.l D6, D0          ; запись 3 байта
    and.l 3, D0
    lsl.l 6, D0
    or.l D7, D0
    move.b D0, (A0)+
    add.l 1, D3

    jmp main_loop

wait_nl:                   ; если был встречен символ =, то после него обязан быть \n или =\n
    jsr read_and_decode
    cmp.l -2, D0
    beq finish
    jmp invalid_err


read_and_decode:
    cmp.l 64, D2           ; проверка на переполнение
    beq read_overflow
    move.l (A1), D0        ; чтение символа
    add.l 1, D2
    cmp.l 10, D0
    bne do_decode
    move.l -2, D0          ; -2 код для перевода строки
    rts

do_decode:
    cmp.l 65, D0
    blt check_num_sym
    cmp.l 90, D0
    bgt check_lower
    sub.l 65, D0           ; A-Z (0-25)
    rts
check_lower:
    cmp.l 97, D0
    blt err_ret
    cmp.l 122, D0
    bgt err_ret
    sub.l 71, D0           ; a-z (26-51)
    rts
check_num_sym:
    cmp.l 61, D0
    bne try_num
    move.l -3, D0          ; = (-3)
    rts
try_num:
    cmp.l 48, D0
    blt check_sym
    cmp.l 57, D0
    bgt err_ret
    add.l 4, D0            ; 0-9 (52-61)
    rts
check_sym:
    cmp.l 43, D0
    bne try_slash
    move.l 62, D0          ; + (62)
    rts
try_slash:
    cmp.l 47, D0
    bne err_ret
    move.l 63, D0          ; / (63)
    rts
err_ret:
    move.l -1, D0          ; ошибка
    rts

read_overflow:             
    move.l -858993460, D0
    move.l D0, (A2)
    jmp exit_program       ; переход к завершению программы

invalid_err:
    cmp.l 64, D2
    beq err_out
    move.l (A1), D0
    add.l 1, D2
    cmp.l 10, D0           ; дочитывание до \n
    bne invalid_err
err_out:
    move.l -1, D0
    move.l D0, (A2)
    jmp exit_program       ; переход к завершению программы

finish:
    clr.b D0
    move.b D0, (A0)        ; ставим \0 символ в конец строки
    
    movea.l 0, A0
    move.l D3, D1
    cmp.l 0, D1
    beq finish_end
output_loop:
    clr.l D0
    move.b (A0)+, D0
    move.l D0, (A2)
    sub.l 1, D1
    bne output_loop
finish_end:
    jmp exit_program

exit_program:              ; точка выхода
    move.l -4(A6), D0
    move.l -8(A6), D1
    move.l -12(A6), D2
    move.l -16(A6), D3
    move.l -20(A6), D4
    move.l -24(A6), D5
    move.l -28(A6), D6
    move.l -32(A6), D7
    unlk A6
    halt