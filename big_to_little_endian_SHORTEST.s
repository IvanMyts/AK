    .data
input:           .word  0x0
output:          .word  0x0
const_1:         .word  0xFF
const_2:         .word  0xFF00
const_3:         .word  0xFF0000
const_4:         .word  0xFF000000
const_5:         .word  0x8
const_6:         .word  0x18

    .text
_start:

    load_addr    0x80
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
    store_addr   0x84
    halt