0x10 CONSTANT ten
0x40000080 CONSTANT mycon1
0x400000A0 CONSTANT mycon2
VARIABLE myvar1
VARIABLE myvar2

0x1F CONSTANT F_LENMASK

0x0A000000 CONSTANT BEQ


: >CFA
    DUP
    0x4 + C@				\ TOP = flag
    F_LENMASK AND			\ TOP = len
    + 0x8 +				\ TOP = CFA + x
    0xFFFFFFFC AND			\ Boundary
;

: ' IMMEDIATE
    WORD FIND
    >CFA
;

END
    
: IF IMMEDIATE
    LIT [ ' 0= @ , ] ,
    THERE @ 
;

: THEN IMMEDIATE
    DUP
    0x8 +    
    THERE @
    -
    0x02 LSR
    0x00FFFFFF AND
    BEQ +
    SWAP !
;

END

: test1
    ten myvar1 !
    myvar1 @ mycon1 !
;

: test2
    ten myvar2 !
    myvar2 @ mycon2 !
;

: init-uart1
    0x0
    IF
	DROP
	test1
	
    THEN
    0x1
    IF
	DROP
	test2
    THEN
;

END  init-uart1
