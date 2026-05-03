    .data
buffer:          .byte  'Hello, \0________________________'
buffer_siz:      .word  23
buffer_end:      .word  7

start_str:       .byte  'What is your name?\n\0'

input_adr:       .word  0x80
output_adr:      .word  0x84

input_ended:     .word 0x0
end_sign:        .word '\n'

const_end:       .byte '!\0__'

    .text
.org 0xF0
_start:

    lit start_str
    write

    @p buffer_end
    read

    @p buffer_end
    a!
    @p const_end
    !

    lit buffer
    write

stop:
    halt


write: \пишет в output_adr. Адресс строки данных в T
    a!
    @p output_adr
    b!
loop:
    @
    lit 0xFF and
    if return_write
    @+
    lit 0xFF and
    !b
    loop ;

return_write:
    ;


read: \читает из input_adr и кладет строку по адресу T. Конец ввода \n
    a!
    @p input_adr
    b!
            \счетчик переполнения в стеке
    @p buffer_end
    @p buffer_siz
    minus
loop2:
    @b
    dup
    @p end_sign
    xor
    if return_read
    !+
            \увеличиваем счетчик и проверяем переполнение
    lit 1 +
    dup
    -if error
    loop2 ;

return_read:
    drop
    @p buffer_siz
    +
    !p buffer_end
    ;


minus:  \ вычитает S - T
    inv lit 1 + +
    ;

error: \выводит в output ошибку и завершает работу
    lit output_adr
    b!
    lit 0xCCCCCCCC
    !b

        \дочитывает поток ввода
loop4:
    @p input_adr
    if stop
    loop4 ;