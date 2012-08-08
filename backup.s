	
	PUSHRSP	lr
	mov	r7, #0x39
	mov	r0, lr
	bl	tx
	
	mov	r8, r0, LSR #0
	and	r8, r8, #0xF
	add	r8, #0x30
	mov	r7, r8
	bl	tx	

	mov	r8, r0, LSR #4
	and	r8, r8, #0xF
	add	r8, #0x30
	mov	r7, r8
	bl	tx	

	mov	r8, r0, LSR #8
	and	r8, r8, #0xF
	add	r8, #0x30
	mov	r7, r8
	bl	tx	

	mov	r8, r0, LSR #12
	and	r8, r8, #0xF
	add	r8, #0x30
	mov	r7, r8
	bl	tx	

	mov	r8, r0, LSR #16
	and	r8, r8, #0xF
	add	r8, #0x30
	mov	r7, r8
	bl	tx	

	mov	r8, r0, LSR #20
	and	r8, r8, #0xF
	add	r8, #0x30
	mov	r7, r8
	bl	tx	

	mov	r8, r0, LSR #24
	and	r8, r8, #0xF
	add	r8, #0x30
	mov	r7, r8
	bl	tx	

	mov	r8, r0, LSR #28
	and	r8, r8, #0xF
	add	r8, #0x30
	mov	r7, r8
	bl	tx
	
	POPRSP	lr

	        @@ UART0 Initialization
        @@ Transmit on P0.0 (TXD0), Receive on P0.1 (RXD0)
        @@ we do not need to set TXD0 as an output, right?  Right!
pin_init:    
        ldr r6, = PINSEL0
        ldr r0, [r6]
        orr r0, r0, #5       @ bits 3:2 control RXD0, bits 1:0 control TXD0
        str r0, [r6]
	
        .equ PLLCLKIN, 18384000  @  19660800  @  Main crystal clock frequency 
        .equ PLL_MULTIPLIER, 3   @  Multiplier must be 1 since we turn off PLL
        .equ CPUDIVISOR, 1       @  (does the 2294 have a cpu clock divisor?)
        .equ PCLKDIVISOR, 4      @ must be 1, 2, or 4
        .equ TIMER0_PRESCALE_DIVISOR, 1 @ (does the 2294 have a timer prescale divisor?)
        @.equ BAUDRATE, 115200
        .equ BAUDRATE, 9600
        .equ SPIDIVISOR, 128     @ slow it way down for testing -- fcs 31 July 2006
        .equ PLLCLK, (PLLCLKIN * PLL_MULTIPLIER)
        .equ CCLK, (PLLCLK / CPUDIVISOR)

        @@ Unlike the lpc2378, the lpc2294 has only a single PCLK.
        @@ The formula for the value to set the VPDIV register is
        @@            (PCLKDIVISOR % 4)  (see p. 52?? of manual)
        @@ We do not need to use the "case" statement@ we could simply
        @@ do     .equ PCLKVALUE, (PCLKVALUE % 4)   instead
        .if PCLKDIVISOR == 1
          .equ PCLKVALUE, 1             @ divide by 1
        .endif
        .if PCLKDIVISOR == 2
          .equ PCLKVALUE, 2             @ divide by 2
        .endif
        .if PCLKDIVISOR == 4
          .equ PCLKVALUE, 0             @ divide by 4
        .endif

        .equ  PCLK, CCLK / PCLKDIVISOR   @ most timing depends on PCLK

@ Memory Accelerator Module (MAM) definitions
	.equ MAM_BASE,        0xE01FC000      @ MAM Base Address
	.equ MAMCR_OFS,       0x00            @ MAM Control Offset
	.equ MAMTIM_OFS,      0x04            @ MAM Timing Offset

	.equ MAMCR_Val,            0x00000001
	.equ MAMTIM_Val,           0x00000004	

	ldr	r0, =MAM_BASE
	mov	r1, #MAMTIM_Val
	str	r1, [r0, #MAMTIM_OFS]
	mov	r1, #MAMCR_Val
	str	r1, [r0, #MAMCR_OFS]

	
	

setup_uarts:    
        ldr r6, = U0BASE 
        
        @ Write to U0LCR to set DLAB bit and then set baud rate, etc.
        mov r1, #0x83        @ access divisor latches, 8 bits, 1 stop, no parity
        strb r1, [r6, # ULCR]
        @ Now set divisor latches for 9600 bps with 14.745 Mhz xtal, no PLL,
        @    pclk 1/4 of cclk, so at 14.7456 MHz, pclk is 3,686,400, which, 
        @    divided by 16 is 230,400.  So, here is the table of divisor 
        @    latch values and baud rates:
        @        divisor        bps
        @              1        230,400
        @              2        115,200
        @              4         57,600
        @              6         38,400
        @             12         19,200
        @             24          9,600

        @ We would like to calculate the baud rate DIVISOR automatically
        @  based on CCLK, PCLK, and BAUDRATE set near beginning of
        @  this file.  Note, this works only for divisors less
        @  than 256.

        @ So, the formula (ignoring partials)
        @  baudrate = PCLK / (16 * DIVISOR)
        @  16 * DIVISOR * baudrate = PCLK
        @  DIVISOR = PCLK / (16 * baudrate)
        @ E.g. with a 12 MHz CCLK and a 3 MHz PCLK
        @    (/ 3000000.0 (* 16 115200))  1.6276041666666667
        @    (/ 3000000.0 (* 16  57600))  3.2552083333333335
        @    (/ 3000000.0 (* 16  38400))  4.8828125
        @    (/ 3000000.0 (* 16  19200))  9.765625
        @    (/ 3000000.0 (* 16   9600))  19.53125
        @    (/ 3000000.0 (* 16   4800))  39.0625
        @    (/ 3000000.0 (* 16   2400))  78.125
        @    (/ 3000000.0 (* 16   1200))  156.25
        @
        @ So, without partials, I guess 4800 bps or less will have the least error
        
        .equ  DIVISOR, PCLK / (16 * BAUDRATE)
        
        mov r1, # DIVISOR
        strb r1, [r6, # UDLL]
        mov r1, #0
        strb r1, [r6, # UDLM]

        mov r1, #03
        strb r1, [r6, # ULCR]   @ turn off access to divisor latches but
                                @   leave uart0 set to 8 bits, 1 stop, no parity

        mov r0, #1
        strb r0, [r6, # UFCR]   @  enable FIFOs (required)

