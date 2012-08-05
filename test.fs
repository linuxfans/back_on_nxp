0x13 CONSTANT ten
0x40000080 CONSTANT test1
0x400000A0 CONSTANT test2
VARIABLE myvar1
VARIABLE myvar2
: init-uart
    ten myvar1 !
    ten ten + myvar2 !
    myvar1 @ test1 !
    myvar2 @ test2 !    
;
: init-uart1
    init-uart
;

END  init-uart1
