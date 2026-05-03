    .data

input_adr:       .word  0x80
output_adr:      .word  0x84
input1:          .word  0x0
output1:         .word  0x0
output2:         .word  0x0
const_1:         .word  0x1
const_n1:        .word  0xFFFFFFFF

    .text
    .org 0x100

_start:
    load_addr    input_adr
    load_acc
    beqz         stop           ;проверка конца потока

    bgt          next           ;блок расширения знака до 64-битов для отрицательных чисел
    beqz         next
    store        input1
    load         output2
    add          const_n1
    store        output2
    load         input1

next:
    add          output1
    store        output1

    bcc          next2          ;переброс керри в старшие байты
    clc
    load         output2
    add          const_1
    store        output2

next2:
    jmp          _start
stop:
    load         output2
    store_ind    output_adr
    load         output1
    store_ind    output_adr
    halt