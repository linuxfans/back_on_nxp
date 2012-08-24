VARIABLE myvar1

VARIABLE I2CADR
VARIABLE I2CLEN
VARIABLE I2CBUF  DHERE @ 0x08 + DHERE !	\ Array, size 0x04+0x08

VARIABLE I2C_XFER_END
VARIABLE I2C_STO_FLG

0x1F CONSTANT F_LENMASK


0xE002C000 CONSTANT PINSEL0
0xE002C004 CONSTANT PINSEL1
0xE002C008 CONSTANT PINSEL2

0xE0028010 CONSTANT IOPIN1
0xE0028014 CONSTANT IOSET1
0xE0028018 CONSTANT IODIR1
0xE002801C CONSTANT IOCLR1



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
0xfffff110 CONSTANT VICVectAddr4
0xfffff210 CONSTANT VICVectCntl4
0xfffff118 CONSTANT VICVectAddr6
0xfffff218 CONSTANT VICVectCntl6
0xfffff124 CONSTANT VICVectAddr9
0xfffff224 CONSTANT VICVectCntl9



0xfffff030 CONSTANT VICVectAddr
0xE001C000 CONSTANT I2C0CONSET
0xE001C004 CONSTANT I2C0STAT
0xE001C008 CONSTANT I2C0DAT       
0xE001C00C CONSTANT I2C0ADR       
0xE001C010 CONSTANT I2C0SCLH      
0xE001C014 CONSTANT I2C0SCLL      
0xE001C018 CONSTANT I2C0CONCLR
0x0A000000 CONSTANT BEQ
0xEA000000 CONSTANT BAL
0xEB000000 CONSTANT ARM_BL


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
    HERE @
    BEQ ,
;
: RESOLVE
    HERE @				\ new PC
    SWAP
    BOFFSET
    OVER
    @
    +
    SWAP !
;

: ELSE IMMEDIATE
    THERE @
    ROT
    HERE @
    ROT    
    BAL ,
    
    RESOLVE
;

: THEN IMMEDIATE
    RESOLVE
;

: BEGIN IMMEDIATE
    HERE @
;

: WHILE IMMEDIATE
    [COMPILE] IF
;

: REPEAT IMMEDIATE
    -ROT
    HERE @
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
    ENTER_INTERRUPT
    BEGIN    
	U0IIR @ DUP 0x01 AND NOT
    WHILE
	    0x0E AND
	    CASE
		0x04 OF
		    U0DATA @
		ENDOF
		0x0C OF
		    U0DATA @
		ENDOF
	    ENDCASE
    REPEAT
    DROP
    0xFF VICVectAddr !
    LEAVE_INTERRUPT
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


: i2c-set-clr
    SWAP
    I2C0CONSET !		\ set
    I2C0CONCLR !		\ clr 
;
: i2c-send-addr
    I2CADR C@ I2C0DAT C!
;    
: i2c-send-data
    I2CLEN C@ I2CBUF + C@ I2C0DAT C!
;
: i2c-dec-cnt
    I2CLEN C@ ?DUP IF 0x01 - I2CLEN C! THEN    
;

: i2c-xfer-end
    0x0 I2C_XFER_END !	        
;    

: i2c-clr-sta
    0x04 0x28			\ set "AA", clr "SI" and "STA"
    i2c-set-clr
;

: i2c-clr-si-nack
    0x00 0x08 i2c-set-clr	\ set "AA", clr "SI"
;

: i2c-clr-si
    0x04 0x08 i2c-set-clr	\ set "AA", clr "SI"
;
: i2c-set-sto
    0x10 0x08 i2c-set-clr	\ set "AA" and "STO",  clr "SI"
;
: i2c-set-sta
    0x20 0x08 i2c-set-clr	\ set "AA" and "STO",  clr "SI"
;

: i2c-irq-send
    I2CLEN C@ IF
	i2c-dec-cnt
	i2c-send-data
	i2c-clr-si
    ELSE
	i2c-xfer-end		
	I2C_STO_FLG @
	IF
	    i2c-set-sto		    
	ELSE
	    i2c-clr-si
	THEN
    THEN
;

: i2c-irq
    ENTER_INTERRUPT    
    I2C0STAT @
    CASE
	0x40 OF
	    I2CLEN C@ IF
		i2c-clr-si
	    ELSE
		0x00 0x2C i2c-set-clr	    
	    THEN
	ENDOF
	0x50 OF
	    I2C0DAT C@
	    I2CLEN C@ I2CBUF + C!
	    I2CLEN C@ ?DUP IF
		0x01 - I2CLEN C!
		i2c-clr-si	    
	    ELSE
		0x00 0x0C i2c-set-clr
		i2c-xfer-end		
	    THEN
	ENDOF
	0x58 OF
	    I2C0DAT C@
	    I2CLEN C@ I2CBUF + C!
	    i2c-set-sto
	    i2c-xfer-end
	ENDOF
	
	0x08 OF
	    i2c-send-addr
	    i2c-clr-sta	    
	ENDOF
	
	0x10 OF
	    i2c-send-addr
	    i2c-clr-sta	    
	ENDOF
	
	0x18 OF
	    i2c-send-data
	    i2c-clr-si	    
	ENDOF
	
	0x20 OF
	    i2c-set-sto	    
	    i2c-xfer-end
	ENDOF
	
	0x28 OF
	    i2c-irq-send
	ENDOF
	
	0x30 OF
	    i2c-set-sto		    	    
	    i2c-xfer-end		
	ENDOF
	
	0x48 OF
	    i2c-set-sto
	    i2c-xfer-end		
	ENDOF
    ENDCASE

    0xFF VICVectAddr !
    LEAVE_INTERRUPT
;

: init-i2c
    \ Init Pin
    PINSEL0 @
    0x50 OR
    PINSEL0 !
    \ Init I2C
    0x6c I2C0CONCLR !
    0x40 I2C0CONSET !
    0x4C I2C0SCLH !
    0x4D I2C0SCLL !
    LIT [ ' i2c-irq , ] VICVectAddr9 !
    0x29 VICVectCntl9 !
    0x01 0x09 << VICIntEnable !
;

: uart-send
    BEGIN
	U0LSR @ 0x40 AND NOT
    WHILE
    REPEAT
    U0DATA !    
;

: i2c-xfer
    0x0 I2C_STO_FLG !			\ don't send STOP    
    0x20 I2C0CONSET !
;

: i2c-xfer-withend
    0xFFFFFFFF I2C_STO_FLG !		\ send STOP    
    0x20 I2C0CONSET !    
;


: mpu6050-read				  \ (reg addr --)
    0xD0 I2CADR C!
    0x00 I2CLEN C!
    I2CBUF C!
    0xFFFFFFFF I2C_XFER_END !		    
    i2c-xfer-withend
    BEGIN
	I2C_XFER_END @
    WHILE
    REPEAT
    0xD1 I2CADR C!
    0x00 I2CLEN C!
    0xFFFFFFFF I2C_XFER_END !		
    i2c-xfer-withend
    BEGIN
    	I2C_XFER_END @
    WHILE
    REPEAT

    BEGIN
	I2C0CONSET @
	0x10 AND 
    WHILE
    REPEAT
;

END

: mpu6050-write				  \ (reg addr --)
    0xD0 I2CADR C!
    0x01 I2CLEN C!
    I2CBUF 0x01 + C!
    I2CBUF C!
    0xFFFFFFFF I2C_XFER_END !		    
    i2c-xfer-withend
    BEGIN
	I2C_XFER_END @
    WHILE
    REPEAT
    BEGIN
	I2C0CONSET @
	0x10 AND 
    WHILE
    REPEAT
;


0x14 CONSTANT MCR
0x18 CONSTANT MR0
0x1C CONSTANT MR1
0x20 CONSTANT MR2
0x24 CONSTANT MR3
0x217A7 CONSTANT CYC

: timer-irq
    DUP
    @
    SWAP
    OVER 0x01 AND IF
	DUP MR0 + @
	CYC = IF
	    0x35D9 OVER MR0 + !
	    DUP MCR + @
	    0x02 BNOT AND
	    OVER MCR + !
	ELSE
	    CYC OVER MR0 + !
	    DUP MCR + @
	    0x02 OR
	    OVER MCR + !
	THEN
    THEN
    OVER 0x02 AND IF
	DUP MR1 + @
	CYC = IF
	    0x35D9 OVER MR1 + !
	    DUP MCR + @
	    0x10 BNOT AND
	    OVER MCR + !
	ELSE
	    CYC OVER MR1 + !
	    DUP MCR + @
	    0x10 OR
	    OVER MCR + !
	THEN
    THEN
    OVER 0x04 AND IF
	DUP MR2 + @
	CYC = IF
	    0x35D9 OVER MR2 + !
	    DUP MCR + @
	    0x80 BNOT AND
	    OVER MCR + !
	ELSE
	    CYC OVER MR2 + !
	    DUP MCR + @
	    0x80 OR
	    OVER MCR + !
	THEN
    THEN
    OVER 0x08 AND IF
	DUP MR3 + @
	CYC = IF
	    0x35D9 OVER MR3 + !
	    DUP MCR + @
	    0x400 BNOT AND
	    OVER MCR + !
	ELSE
	    CYC OVER MR3 + !
	    DUP MCR + @
	    0x400 OR
	    OVER MCR + !
	THEN
    THEN
    !				\ Clear the interrupt
    0xFF VICVectAddr !    
;

: timer0-irq
    ENTER_INTERRUPT
    0xe0004000
    timer-irq
    LEAVE_INTERRUPT
;    
    
;
: timer1-irq
    ENTER_INTERRUPT    
    0xe0008000
    timer-irq
    LEAVE_INTERRUPT    
;
: init-servo
    
    0x6db 0xe0004000 MCR + !
    0xfff0 0xe000403c !
    CYC 0xe0004000 MR0 + !
    CYC 0xe0004000 MR1 + !
    CYC 0xe0004000 MR2 + !
    CYC 0xe0004000 MR3 + !
    LIT [ ' timer0-irq , ] VICVectAddr4 !
    0x24 VICVectCntl4 !
    0x01 0x04 << VICIntEnable !
    0x02 0xe0004004 !
    0x01 0xe0004004 !
    
;


: init
    init-led
    init-uart0
    init-i2c
    init-servo    
    LEAVE_CRITICAL
;


: main_loop
    \ 0x0
    \ CASE
    \ 	0x01 OF 0x01 0x40000B00  C! ENDOF
    \ 	0x02 OF 0x02 0x40000B00  C! ENDOF
    \ 	0x03 OF 0x03 0x40000B00  C! ENDOF
    \ 	0x04 OF 0x04 0x40000B00  C! ENDOF	
    \ 	0x05 0x40000B00  C!
    \ ENDCASE
    I2CBUF C@ uart-send
    0x75 mpu6050-read
    I2CBUF C@ uart-send
    0x99 uart-send

    0x00 0x6b mpu6050-write
    
    0x1 0x15 << IOSET1 !
    0x1 0x14 << IOCLR1 !

    0x00 myvar1 !
    
    BEGIN
    	0x01
    WHILE
    	    0xea uart-send	    	    
    	    0x3b mpu6050-read
    	    I2CBUF C@ uart-send	    
    	    0x3c mpu6050-read
	    I2CBUF C@ uart-send

	    myvar1 @ IF
		0x00 myvar1 !
		0x1 0x15 << IOSET1 !		
	    ELSE
		0x01 myvar1 !
		0x1 0x15 << IOCLR1 !		
	    THEN
    REPEAT
    
;
: main
    init
    main_loop
;

END main

