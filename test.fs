[ 0x13 ] CONST ten
: init-uart
    ten 0x40000080 !    
;
: init-uart1
    init-uart
    0x89 0x400000A0 !    
;

END  init-uart1
