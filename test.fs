0x13 CONSTANT ten
0x40000080 CONSTANT test

: init-uart
    HERE test !   
;
: init-uart1
    init-uart
    ten 0x400000A0 !    
;

END  init-uart1
