    .data

input_adr:       .word  0x80
input:           .word  0x0
output:          .word  0x0
output_adr:      .word  0x84
const_1:         .word  0xFF
const_2:         .word  0xFF00
const_3:         .word  0xFF0000
const_4:         .word  0xFF000000

const_5:         .word  0x8
const_6:         .word  0x18

    .text
    .org 0x100

_start:

    load_addr    input_adr
    load_acc
    store        input
    shiftl       const_6
    and          const_4
    store        output

    load_addr    input
    shiftl       const_5
    and          const_3
    add          output
    store        output

    load_addr    input
    shiftr       const_5
    and          const_2
    add          output
    store        output

    load_addr    input
    shiftr       const_6
    and          const_1
    add          output
    store_ind    output_adr
    halt