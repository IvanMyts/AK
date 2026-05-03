.data
buffer:          .byte  'Hello, \0__________________________'
buffer_end:      .word  7

start_str:       .byte  'What is your name?\n\0'
const_end:       .byte  '!\0__'

    .text
.org 0xF0
_start:
    lit start_str
    write

    @p buffer_end
    read

    find_end

    lit buffer
    write

stop:
    halt

find_end: \ находит конец строки и ставит туда '!\0__'
    lit 7
    a!
loop3:
    @
    lit 0xFF and
    if return_find
    @+
    drop
    loop3 ;

return_find:
    @p const_end
    !
    ;

write: \ Пишет в порт 0x84. Адрес строки в T
    a!
    lit 0x84
    b!
loop:
    @+
    lit 0xFF and
    dup
    if return_write
    !b
    loop ;

return_write:
    drop         
    ;


read: \ Читает из порта 0x80 по адресу в T. Конец ввода '\n'
    a!
    lit 0x80
    b!
    
    lit 30
    inv lit 1 + 
    @p buffer_end
    +   \ вычисляем buffer_end - buffer_siz
    
loop2:
    @b
    dup
    lit 0xA xor    \ 0xA это '\n', в дебаге 0x5C
    if return_read
    !+
                    \ Увеличиваем счетчик переполнения
    lit 1 +
    dup
    -if error
    loop2 ;

return_read:
    drop
    lit 30
    +
    dup
    !p buffer_end
    ;


error: \ Выводит в output ошибку и завершает работу
    lit 0x84 b!
    lit 0xCCCCCCCC
    !b

    stop ;