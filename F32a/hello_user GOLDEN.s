    .data
buffer:          .byte  '_________________________________---'
buffer_siz:      .word  32
buffer_end:      .word  0

start_str:       .byte  'What is your name\n\0'
hello_str:       .byte  'Hello, \0'
end_str:         .byte  '!\0'

input_adr:       .word  0x80
output_adr:      .word  0x84

input_ended:     .word 0x0
end_sign:        .byte '\n\0\0\0'

extra_buf:       .word '\0\0'

    .text
.org 0xC0
_start:

    lit start_str
    write

    lit hello_str 
    lit buffer
    copy

    lit buffer
    read

    lit end_str
    copy

    lit buffer
    write

stop:
    halt


write: \пишет в output_adr. Адресс строки данных в T
    a!
    @p output_adr
    b!
loop:
    @ lit 0xFF and 
    if return_write
    @+ lit 0xFF and
    !b
    loop ;

return_write:
    ;


read: \читает из input_adr и кладет строку по адресу T. Конец ввода \n
    a!
    @p input_adr
    b!
loop2:
    @b
    dup
    @p end_sign
    xor
    if return_read
    write_byte
    loop2 ;

return_read:
    lit 1
    !p input_ended
    lit 0
    write_byte
    ;


write_byte: \записывает один байт по указаному адресу в А++. buffer_end++
    @ lit 0xFF inv and +
    !+
    @p buffer_end lit 1 +
    !p buffer_end
            \проверяем, что буфер не переполнен
    @p buffer_end @p buffer_siz minus
    if error
    ;

convert: \перемещает младший байт в старший
    a
    over
    !p extra_buf
    lit 24
    lit extra_buf
    +
    a!
    @
    a!
    ;


copy: \копирует строку mem[S] -> mem[T]
    a!  \\ сюда записываем 
    dup
    b!  \\ отсюда читаем (так же храним адрес в стеке в S)

loop3:
    @b lit 0xFF and
    if return_copy
    @b
    write_byte
    lit 1 + 
    dup
    b!
    loop3 ;

return_copy:
    lit 0
    write_byte
    ;


minus:  \ вычитает S - T
    inv lit 1 + +
    ;

error: \выводит в output ошибку и завершает работу
    lit output_adr
    b!
    lit 0xCCCCCCCC
    !b

        \дочитывает поток ввода если есть
    @p input_ended
    if stop
loop4:
    @p input_adr
    if stop
    loop4 ;