0x13 CONST ten
END
: init-uart
    ten ten !    
;
: init-uart1
    init-uart
    0x89 0x400000A0 !    
;

END  init-uart1
