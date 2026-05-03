    \ дочитываем поток ввода
    lit 0x80 b!
loop4:
    @b
    lit 0xA xor     \ 0xA это '\n', в дебаге 0x5C
    if stop
    loop4 ;