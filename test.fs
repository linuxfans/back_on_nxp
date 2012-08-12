0x10 CONSTANT ten
0x40000080 CONSTANT mycon1
0x400000A0 CONSTANT mycon2
VARIABLE myvar1
VARIABLE myvar2
VARIABLE myvar3

0x1F CONSTANT F_LENMASK

0x0A000000 CONSTANT BEQ
0xEA000000 CONSTANT BAL

0xE002C000 CONSTANT PINSEL0
0xE002C004 CONSTANT PINSEL1
0xE002C008 CONSTANT PINSEL2

0xE0028010 CONSTANT IOPIN1
0xE0028014 CONSTANT IOSET1
0xE0028018 CONSTANT IODIR1
0xE002801C CONSTANT IOCLR1

END

0xe000c000 CONSTANT  U0DATA
0xe000c000 CONSTANT  U0DLL
0xe000c004 CONSTANT  U0DLM
0xe000c004 CONSTANT  U0IER
0xe000c008 CONSTANT  U0IIR
0xe000c008 CONSTANT  U0FCR
0xe000c00c CONSTANT  U0LCR
0xe000c014 CONSTANT  U0LSR
0xe000c020 CONSTANT  U0ACR
0xe000c028 CONSTANT  U0FDR
0xe000c030 CONSTANT  U0TER


0xfffff010 CONSTANT VICIntEnable
0xfffff118 CONSTANT VICVectAddr6
0xfffff218 CONSTANT VICVectCntl6
0xfffff030 CONSTANT VICVectAddr	
END


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
    0x02 >>
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

: DO IMMEDIATE
    THERE @
;

: UNTIL IMMEDIATE
    LIT [ ' 0= @ , ] ,
    THERE @
    BEQ ,

    SWAP
    THERE @
    0x08 +
    -
    0x02 >>
    0x00FFFFFF AND
    BAL +
    ,

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

: uart0-irq
    SAVE_CONTEXT
    U0IIR @ myvar1 !
    myvar1 @
    0x0E AND
    0x04 - IF
	DROP
    ELSE
	DROP
	U0DATA @ U0DATA !	
    THEN
    myvar1 @    
    0x0E AND
    0x0C - IF
	DROP
    ELSE
	DROP
	U0DATA @ U0DATA !	
    THEN

    0x00 VICVectAddr !
    RESTORE_CONTEXT
;


: init-uart0
    \ Init Pin
    PINSEL0 @
    0x05 OR
    PINSEL0 !
    \ Init Uart0
    0x00 U0IER !	\ Disable uart0 irq
    0x83 U0LCR !	\ 8bits, 1 stop, no parity
    0x5a U0DLL !	\ 9600bps, 18.384MHz * 3 / 4 / (16 * BAUD)
    0x00 U0DLM !	\ 9600bps, 18.384MHz * 3 / 4 / (16 * BAUD)    
    0x03 U0LCR !	\ Latch DLL
    0x01 U0FCR !
    LIT [ ' uart0-irq , ] VICVectAddr6 !
    0x26 VICVectCntl6 !
    0x01 0x06 << VICIntEnable !
    0x03 U0IER ! 		
;

: init-led
    IODIR1 @
    0x1 0x14 << OR
    IODIR1 !
    IODIR1 @
    0x1 0x15 << OR
    IODIR1 !
    0x1 0x14 << IOSET1 !
    0x1 0x15 << IOCLR1 !
;

: init
    init-led
    init-uart0
    LEAVE_CRITICAL
;

: main_loop
    0x10 DUP
    DO
	DROP				\ 0x10
	DUP				\ 0x10 0x10 
	DUP				\ 0x10 0x10 0x10
	DUP				\ 0x10 0x10 0x10 0x10 
	0x40000B00 + C!			\ 0x10 0x10 0x10
	0x01 -				\ 0x10 0x0f
	SWAP				\ 0x0f 0x10
    UNTIL
    DROP
    0x10 0x40000B00 !
    IF THEN
;

: main
    main_loop
;

END main


