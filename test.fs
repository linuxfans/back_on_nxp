0x10 CONSTANT ten
0x40000080 CONSTANT mycon1
0x400000A0 CONSTANT mycon2
VARIABLE myvar1
VARIABLE myvar2
VARIABLE myvar3

VARIABLE U0IIR_TMP

0x1F CONSTANT F_LENMASK

0x0A000000 CONSTANT BEQ
0xEA000000 CONSTANT BAL
0xEB000000 CONSTANT ARM_BL

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
0xfffff124 CONSTANT VICVectAddr9
0xfffff224 CONSTANT VICVectCntl9
0xfffff030 CONSTANT VICVectAddr

END

0xE001C000 CONSTANT I2C0CONSET
0xE001C004 CONSTANT I2C0STAT
0xE001C008 CONSTANT I2C0DAT       
0xE001C00C CONSTANT I2C0ADR       
0xE001C010 CONSTANT I2C0SCLH      
0xE001C014 CONSTANT I2C0SCLL      
0xE001C018 CONSTANT I2C0CONCLR    


END


: ' IMMEDIATE
    WORD FIND
    >CFA
;

: BOFFSET
    0x8 +    				\ old PC + 8
    -
    0x02 >>
    0x00FFFFFF AND
;

: BLTO					  \ Branch to
    HERE @
    BOFFSET
    ARM_BL +
;

: [COMPILE] IMMEDIATE
    WORD FIND
    >CFA
    BLTO
    ,
;


END

: IF IMMEDIATE
    LIT [ ' 0= @ , ] ,
    LIT [ ' DROP , ] BLTO ,
    THERE @
    BEQ ,
;
: RESOLVE
    DUP DUP
    THERE @				\ new PC
    SWAP
    BOFFSET
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

: BEGIN IMMEDIATE
    THERE @
;

: WHILE IMMEDIATE
    [COMPILE] IF
;

: REPEAT IMMEDIATE
    SWAP
    THERE @
    BOFFSET
    BAL +
    ,
    
    RESOLVE
    
;

: UNTIL IMMEDIATE
    [COMPILE] IF
    [COMPILE] REPEAT
;

END

: CASE IMMEDIATE
    0x0		\ push 0 to mark the bottom of the stack )
;

: OF IMMEDIATE
    LIT [ ' OVER , ] BLTO ,	\ compile OVER )
    LIT [ ' = , ] BLTO ,	\ compile = )
    [COMPILE] IF	\ compile IF )
;

: ENDOF IMMEDIATE
    [COMPILE] ELSE	\ ENDOF is the same as ELSE )
;

: ENDCASE IMMEDIATE
    \ keep compiling THEN until we get to our zero marker )
    BEGIN
	?DUP
    WHILE
	    [COMPILE] THEN
    REPEAT
    
    LIT [ ' DROP , ] BLTO ,    
;

END

: uart0-irq
    ENTER_CRITICAL
    SAVE_CONTEXT
    U0IIR @ U0IIR_TMP !
    BEGIN
	U0IIR_TMP @ DUP
	0x0E AND
	0x04 -
	SWAP
	0x0E AND
	0x0C -
	AND
	NOT IF
	    U0DATA @ U0DATA !	
	THEN
	U0IIR @ DUP U0IIR_TMP ! 0x01 AND NOT
    UNTIL
    0x00 VICVectAddr !
    RESTORE_CONTEXT
    LEAVE_CRITICAL
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

: i2c-irq
    ENTER_CRITICAL
    SAVE_CONTEXT
    I2C0STAT @
    CASE
	0x08 OF
	    0x74 I2C0DAT !
	    0x28 I2C0CONCLR !
	ENDOF
	0x18 OF
	    0x55 I2C0DAT !
	    0x08 I2C0CONCLR !
	ENDOF
	0x28 OF
	    0x10 I2C0CONSET !
	    0x08 I2C0CONCLR !
	ENDOF
    ENDCASE
    0xFF VICVectAddr !
    RESTORE_CONTEXT
    LEAVE_CRITICAL
    
;


: init-i2c
    \ Init Pin
    PINSEL0 @
    0x50 OR
    PINSEL0 !
    \ Init I2C
    0x6c I2C0CONCLR !
    0x40 I2C0CONSET !
    0x0C I2C0SCLH !
    0x0D I2C0SCLL !
    LIT [ ' i2c-irq , ] VICVectAddr9 !
    0x29 VICVectCntl9 !
    0x01 0x09 << VICIntEnable !
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
    init-i2c
    LEAVE_CRITICAL
;

: main_loop

    0x60 I2C0CONSET !
    0x0
    CASE
    	0x01 OF 0x01 0x40000B00  C! ENDOF
	0x02 OF 0x02 0x40000B00  C! ENDOF
	0x03 OF 0x03 0x40000B00  C! ENDOF
    	0x04 OF 0x04 0x40000B00  C! ENDOF	
    	0x05 0x40000B00  C!
    ENDCASE
;

: main
    init
    main_loop
;

END main


