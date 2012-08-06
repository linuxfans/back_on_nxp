0x10 CONSTANT ten
0x40000080 CONSTANT mycon1
0x400000A0 CONSTANT mycon2
VARIABLE myvar1
VARIABLE myvar2

0x1F CONSTANT F_LENMASK

0x0A000000 CONSTANT BEQ
0xEA000000 CONSTANT BAL


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
    BEQ ,
;
: RESOLVE
    DUP DUP
    THERE @				\ new PC
    SWAP
    0x8 +    				\ old PC + 8
    -
    0x02 LSR				
    0x00FFFFFF AND
    SWAP
    @
    +
    SWAP !
;

: ELSE IMMEDIATE
    THERE @
    BAL ,
    SWAP

    RESOLVE

;

: THEN IMMEDIATE
    RESOLVE
;

END

: test1
    ten myvar1 !
    myvar1 @ mycon1 !
;

: test2
    ten myvar2 !
    myvar2 @ mycon2 !
    0x10 mycon2 !
;

: init-uart1
    0x1
    IF
	test1
	test2
	0x10 mycon2 !	
    ELSE
	0x20 mycon2 !	
    THEN
;

: init-uart0
    init-uart1
;

: init
    init-uart1
;

END
init-uart1
