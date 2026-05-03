.data
.org 0x00
buffer:     .word '\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0'

.text
.org 0x100
_start:
    movea.l 0x1000, A7     ; Инициализация указателя стека
    movea.l 0, A0          ; A0 = указатель на буфер декодирования
    movea.l 0x80, A1       ; A1 = порт ввода
    movea.l 0x84, A2       ; A2 = порт вывода
    clr.l D2               ; D2 = счетчик прочитанных символов (макс 64 символа)
    clr.l D3               ; D3 = счетчик записанных байтов

main_loop:
    jsr process_chunk      ; Вызов вложенной процедуры (использует стек и фрейм)
    cmp.l 0, D0
    bgt main_loop          ; D0 > 0  -> продолжаем чтение
    beq finish             ; D0 == 0 -> конец файла (\n)
    halt                   ; D0 < 0  -> ошибка (остановка уже произошла внутри, но здесь fallback)

; --- Вложенная процедура: читает и декодирует блок из 4 символов ---
process_chunk:
    link A6, 0             ; Инициализируем фрейм стека (требование по использованию стека)
    
    ; Чтение Символа 1 (C1)
    cmp.l 64, D2
    beq read_overflow
    move.l (A1), D0
    add.l 1, D2
    cmp.l 10, D0
    beq chunk_end_line     ; Если сразу \n - конец ввода
    jsr decode_char
    cmp.l 0, D0
    blt invalid_err
    move.l D0, D4

    ; Чтение Символа 2 (C2)
    cmp.l 64, D2
    beq read_overflow
    move.l (A1), D0
    add.l 1, D2
    cmp.l 10, D0
    beq invalid_err        ; Ошибка формата (оборванный блок)
    jsr decode_char
    cmp.l 0, D0
    blt invalid_err
    move.l D0, D5

    ; Чтение Символа 3 (C3)
    cmp.l 64, D2
    beq read_overflow
    move.l (A1), D0
    add.l 1, D2
    cmp.l 10, D0
    beq invalid_err
    jsr decode_char
    cmp.l -3, D0
    beq ok_c3
    cmp.l 0, D0
    blt invalid_err
ok_c3:
    move.l D0, D6

    ; Чтение Символа 4 (C4)
    cmp.l 64, D2
    beq read_overflow
    move.l (A1), D0
    add.l 1, D2
    cmp.l 10, D0
    beq invalid_err
    jsr decode_char
    cmp.l -3, D0
    beq ok_c4
    cmp.l 0, D0
    blt invalid_err
ok_c4:
    move.l D0, D7

    ; Декодирование Байта 1
    move.l D4, D0
    lsl.l 2, D0
    move.l D5, D1
    lsr.l 4, D1
    or.l D1, D0
    move.b D0, (A0)+       ; Сохраняем с пост-инкрементом
    add.l 1, D3

    cmp.l -3, D6
    beq check_pad_1        ; Если C3 - это паддинг '='

    ; Декодирование Байта 2
    move.l D5, D0
    and.l 15, D0
    lsl.l 4, D0
    move.l D6, D1
    lsr.l 2, D1
    or.l D1, D0
    move.b D0, (A0)+
    add.l 1, D3

    cmp.l -3, D7
    beq check_pad_2        ; Если C4 - это паддинг '='

    ; Декодирование Байта 3
    move.l D6, D0
    and.l 3, D0
    lsl.l 6, D0
    or.l D7, D0
    move.b D0, (A0)+
    add.l 1, D3

    move.l 1, D0           ; 1 = Статус "Продолжать"
    unlk A6
    rts

chunk_end_line:
    move.l 0, D0           ; 0 = Статус "Завершить"
    unlk A6
    rts

check_pad_1:
    cmp.l -3, D7
    bne invalid_err        ; Если C3 '=', C4 тоже обязан быть '='
    jmp wait_nl

check_pad_2:
wait_nl:
    cmp.l 64, D2
    beq read_overflow
    move.l (A1), D0
    add.l 1, D2
    cmp.l 10, D0           ; После паддинга ожидается исключительно \n
    beq chunk_end_line
    jmp invalid_err

; --- Блоки ошибок ---
read_overflow:
    unlk A6
    move.l -858993460, D0  ; Спец значение переполнения [overflow_error_value]
    move.l D0, (A2)
    halt                   ; Немедленно останавливаемся, не читая остаток!

invalid_err:
    unlk A6
invalid_flush:
    cmp.l 64, D2
    beq err_out
    move.l (A1), D0
    add.l 1, D2
    cmp.l 10, D0           ; Читаем мусор до \n
    beq err_out
    jmp invalid_flush
err_out:
    move.l -1, D0
    move.l D0, (A2)        ; Отправляем ошибку формата
    halt


; --- Процедура декодирования (максимально оптимизирована, без фреймов) ---
; Принимает D0 = ASCII. Возвращает D0 = Base64 (0..63) или ошибки (-3 = паддинг, -1 = формат)
decode_char:
    cmp.l 65, D0
    blt c_below_A
    cmp.l 90, D0
    bgt c_lower
    sub.l 65, D0           ; 'A'-'Z' (0-25)
    rts
c_lower:
    cmp.l 97, D0
    blt c_err
    cmp.l 122, D0
    bgt c_err
    sub.l 71, D0           ; 'a'-'z' (26-51)
    rts
c_below_A:
    cmp.l 61, D0
    beq c_pad              ; '=' (-3)
    cmp.l 48, D0
    blt c_sym
    cmp.l 57, D0
    bgt c_err
    add.l 4, D0            ; '0'-'9' (52-61)
    rts
c_sym:
    cmp.l 43, D0
    beq c_plus             ; '+' (62)
    cmp.l 47, D0
    beq c_slash            ; '/' (63)
    jmp c_err
c_plus:
    move.l 62, D0
    rts
c_slash:
    move.l 63, D0
    rts
c_pad:
    move.l -3, D0
    rts
c_err:
    move.l -1, D0
    rts


; --- Успешное завершение ---
finish:
    clr.b D0
    move.b D0, (A0)        ; Устанавливаем нуль-терминатор для C-строки в памяти (по правилам!)
    
    movea.l 0, A0
    move.l D3, D1          ; D1 = сколько байт выдаем в порт (без \0)
    cmp.l 0, D1
    beq finish_end
output_loop:
    clr.l D0
    move.b (A0)+, D0
    move.l D0, (A2)
    sub.l 1, D1
    bne output_loop
finish_end:
    halt