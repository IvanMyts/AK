    .data

input_adr:       .word  0x80
output_adr:      .word  0x84
var:             .word  0x3230
comand:          .word  0x00

    .text
_start:
    lit         var 
    halt