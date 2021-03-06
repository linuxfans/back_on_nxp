
	.equ    PLL_BASE,       0xE01FC080  /* PLL Base Address */
        .equ    PLLCON_OFS,     0x00        /* PLL Control Offset*/
        .equ    PLLCFG_OFS,     0x04        /* PLL Configuration Offset */
        .equ    PLLSTAT_OFS,    0x08        /* PLL Status Offset */
        .equ    PLLFEED_OFS,    0x0C        /* PLL Feed Offset */
        .equ    PLLCON_PLLE,    (1<<0)      /* PLL Enable */
        .equ    PLLCON_PLLC,    (1<<1)      /* PLL Connect */
        .equ    PLLCFG_MSEL,    (0x1F<<0)   /* PLL Multiplier */
        .equ    PLLCFG_PSEL,    (0x03<<5)   /* PLL Divider */
        .equ    PLLSTAT_PLOCK,  (1<<10)     /* PLL Lock Status */
        .equ    PLL_SETUP,      1
        .equ    PLLCFG_Val,     0x00000024



	.text
	.align 4
	.global _start

Vectors:        LDR     PC, Reset_Addr         
                LDR     PC, Undef_Addr
                LDR     PC, SWI_Addr
                LDR     PC, PAbt_Addr
                LDR     PC, DAbt_Addr
                NOP                            /* Reserved Vector */
#               LDR     PC, IRQ_Addr
                LDR     PC, [PC, #-0x0FF0]     /* Vector from VicVectAddr */
                LDR     PC, FIQ_Addr

Reset_Addr:     .word   Reset_Handler
Undef_Addr:     .word   Undef_Handler
SWI_Addr:       .word   0
PAbt_Addr:      .word   PAbt_Handler
DAbt_Addr:      .word   PAbt_Handler
                .word   0                      /* Reserved Address */
IRQ_Addr:       .word   IRQ_Handler
FIQ_Addr:       .word   FIQ_Handler	

Undef_Handler:
	B       Undef_Handler
#SWI_Handler:    B       SWI_Handler
PAbt_Handler:
	B       PAbt_Handler
#DAbt_Handler:   B       DAbt_Handler
IRQ_Handler:
	B       IRQ_Handler
FIQ_Handler:
	B       FIQ_Handler	
	
	top	.req	r11
	rsp	.req	sp
	psp	.req	r12
	
Reset_Handler:	
	b	_reset
	
	.text
	.set link,0
	
	.macro defcode name, namelen, flags=0, label
	.section .text
	.align 2
	.globl name_\label
name_\label :
	.int link
	.set link,name_\label
	.byte \flags+\namelen
	.ascii "\name"	
	.align 2	
	.globl code_\label

	 code_\label :
	.endm

	.macro defword name, namelen, flags=0, label
	.section .text
	.align 2
	.globl name_\label
name_\label :
	.int link
	.set link,name_\label
	.byte \flags+\namelen
	.ascii "\name"	
	.align 2	
	.globl code_\label
code_\label :
	DOCOL
	.endm
	
	.macro defvar name, namelen, flags=0, label, initial=0
	defcode \name,\namelen,\flags,\label
	PUSH	top
	ldr	top, =var_\name
	NEXT
	.data
	.align 2
var_\name :
	.word \initial
	.endm
	
	.macro NEXT
	mov	pc, lr
	.endm
	
	.macro	DOCOL
	PUSHRSP	lr
	.endm
	
 	.macro PUSHRSP reg
	stmfd	rsp!, {\reg}
	.endm

	.macro POPRSP reg
	ldmfd	rsp!, {\reg}
	.endm
	
	.macro PUSH reg
	stmfd	psp!, {\reg}
	.endm
	
	.macro POP reg
	ldmfd	psp!, {\reg}
	.endm

_reset:
	@@ set the cpu to IRQ32 mode 
	mrs	r0,cpsr
	bic	r0,r0,#0x1f
	orr	r0,r0,#0xd2
	msr	cpsr,r0

	mov	r0, #0x40000000
	mov	r1, #0x1E00
	add	r0, r1, r0
	mov	rsp, r0
	
	
	@@ set the cpu to SVC32 mode 
	mrs	r0,cpsr
	bic	r0,r0,#0x1f
	orr	r0,r0,#0xd3
	msr	cpsr,r0

	@@ Init PLL
	LDR     R0, =PLL_BASE
	MOV     R1, #0xAA
	MOV     R2, #0x55

	MOV     R3, #PLLCFG_Val
	STR     R3, [R0, #PLLCFG_OFS] 
	MOV     R3, #PLLCON_PLLE
	STR     R3, [R0, #PLLCON_OFS]
	STR     R1, [R0, #PLLFEED_OFS]
	STR     R2, [R0, #PLLFEED_OFS]


PLL_Loop:
	LDR     R3, [R0, #PLLSTAT_OFS]
	ANDS    R3, R3, #PLLSTAT_PLOCK
	BEQ     PLL_Loop

	MOV     R3, #(PLLCON_PLLE | PLLCON_PLLC)
	STR     R3, [R0, #PLLCON_OFS]
	STR     R1, [R0, #PLLFEED_OFS]
	STR     R2, [R0, #PLLFEED_OFS]


	
	@@ Init State
	ldr	r0, =var_STATE
	mov	r1, #1
	str	r1, [r0]

	@@ Init RSP & PSP
	ldr	rsp, =return_stack_top
	ldr	psp, =parameter_stack_top

	@@ Init latest
	ldr	r0, =var_LATEST
	ldr	r1, =name_OVER
	str	r1, [r0]

	@@ Init here
	ldr	r0, =var_HERE
	mov	r1, #0x00001000
	str	r1, [r0]
	
	@@ Init blk_here
	ldr	r0, =var_BLK_HERE
	mov	r1, #0x00001000
	str	r1, [r0]
	
	@@ Init there
	ldr	r0, =var_THERE
	mov	r1, #0x40000000
	mov	r2, #0x00000c00
	add	r1, r1, r2
	str	r1, [r0]
	
	@@ Init blk_there
	ldr	r0, =var_BLK_THERE
	mov	r1, #0x40000000
	mov	r2, #0x00000c00
	add	r1, r1, r2
	str	r1, [r0]

	@@ Init tib
	ldr	r0, =FORTH_FILE
	ldr	r1, =var_TIB
	str	r0, [r1]

	@@ Init data here
	ldr	r0, =var_DHERE
	ldr	r1, =data_here
	str	r1, [r0]

	@@ Erase 4kB~28kB

	STMFD SP!,{R0-R12, R14}
	
	ldr	r0, =iap_para
	mov	r2, #50
	str	r2, [r0], #4
	mov	r2, #1
	str	r2, [r0], #4
	mov	r2, #6
	str	r2, [r0], #4
	ldr	r0, =iap_para
	ldr	r1, =iap_result
	
	bl	iap

	ldr	r0, =iap_para
	mov	r2, #52
	str	r2, [r0], #4
	mov	r2, #1
	str	r2, [r0], #4
	mov	r2, #6
	str	r2, [r0], #4
	mov	r2, #0xD800
	str	r2, [r0], #4
	ldr	r0, =iap_para
	ldr	r1, =iap_result
	
	bl	iap
	LDMFD SP!,{R0-R12, R14}
	
	

	
MAIN_LOOP:
	bl	code_INTERPRET
	b	MAIN_LOOP	


	defword "INTERPRET",9,,INTERPRET
	bl	code_WORD
	bl	_FIND
	cmp	top, #0		@ top = link address
	beq	2f		@ Not Found
	ldrb	r0, [top, #4]
	and	r1, r0, #F_IMMED
	ldr	r3, =var_STATE
	ldr	r3, [r3]
	add	r1, r1, r3
	cmp	r1, #0	
	bne	1f		@ Immediate word, jmp to 1f
	and	r0, r0, #F_LENMASK
	add	r0, r0, top	@ r0+4(link filed)+4(flag_len+3)-8(bl offset)
	and	r0, r0, #~3     @ r0: CFA of the word is being compiled
	cmp	r0, #0x40000000
	blt	10f
	ldr	r2, =var_BLK_THERE
	ldr	r2, [r2]
	ldr	r3, =var_BLK_HERE
	ldr	r3, [r3]
	sub	r2, r2, r3	@ r2 = BLK_THERE - BLK_HERE
	sub	r0, r0, r2
10:	
	ldr	r1, =var_HERE
	ldr	r1, [r1]	@ r1: HERE
	sub	r2, r0, r1	@ r2: offset
	mov	r2, r2, LSR #2
	and	r2, r2, #0x00FFFFFF
	add	top, r2, #0xEB000000
	bl	code_COMMA
	bl	code_EXIT	
1:
	and	r0, r0, #F_LENMASK
	add	r0, r0, #1	
	add	r0, r0, top
	add	r0, r0, #7
	and	r0, r0, #~3
	POP	top
	mov	lr, pc
	mov	pc, r0
	bl	code_EXIT
2:
	
	@@ Is it a number?
	mov	r2, #0
	POP	r0
	ldrb	r1, [r0], #1
	cmp	r1, $'0'
	bhi	nothex		@ Higher than '0', not hex
	ldrb	r1, [r0], #1
	cmp	r1, $'x'
	bne	error		@ Not start with "0x", error
	mov	r2, #0	
3:
	ldrb	r1, [r0], #1
	cmp	r1, $' '
	bls	over
	mov	r2, r2, lsl #4
	cmp	r1, $'0'
	blt	error		@ Less than '0', error
	cmp	r1, $'9'
	bhi	4f
	sub	r1, r1, $'0'
	add	r2, r2, r1
	b	3b
4:
	cmp	r1, $'A'
	blt	error
	cmp	r1, $'F'
	bhi	5f
	sub	r1, r1, $'7'	@ 'A'-10 = 65-10 = 55 = '7'
	add	r2, r2, r1
	b	3b
5:	
	cmp	r1, $'a'
	blt	error
	cmp	r1, $'f'
	bhi	error
	sub	r1, r1, $'W'	@ 'a'-10 = 97-10 = 87 = 'W'
	add	r2, r2, r1
	b	3b
over:
	mov	top, r2
	ldr	r3, =var_STATE
	ldr	r3, [r3]
	cmp	r3, #0
	bne	6f		@ Immediat mode
	ldr	r3, =code_LIT
	sub	r3, r3, #8
	ldr	r1, =var_HERE
	ldr	r1, [r1]	@ r1: HERE
	sub	r2, r3, r1	@ r2: offset
	mov	r2, r2, LSR #2
	and	r2, r2, #0x00FFFFFF
	PUSH	top
	add	top, r2, #0xEB000000
	bl	code_COMMA
	bl	code_COMMA
6:
	bl	code_EXIT	
nothex:
error:
	ldr	r0, =var_S0
	mov	r1, #0x55
	str	r1, [r0]
	b	END_LOOP

	defvar "STATE",5,,STATE
	defvar "HERE",4,,HERE
	defvar "BLK_HERE",8,,BLK_HERE	
	defvar "THERE",5,,THERE
	defvar "BLK_THERE",9,,BLK_THERE	
	defvar "LATEST",6,,LATEST
	defvar "S0",2,,SZ
	defvar "TIB",3,,TIB
	defvar "DHERE", 5,, DHERE


	@@ Create New Word
	defcode "CREATE",6,,CREATE
_CREATE:
	ldr	r0, =var_HERE
	ldr	r0, [r0]	@ r0 = HERE
	ldr	r1, =var_THERE
	ldr	r1, [r1]	@ r1 = THERE
	mov	r3, r0
	mov	r4, #BLK_SIZE
	sub	r4, r4, #1
	and	r3, r3, r4
	cmp	r3, #(BLK_SIZE - 36) @4 link, 32 name
	addge	r0, #36
	mov	r3, #BLK_SIZE
	sub	r3, r3, #1
	mvn	r4, r3
	andge	r0, r4
	addge	r1, #36
	andge	r1, r4
	mov	r4, #0x40000000
	add	r4, r4, #THERE_BUF_END
	cmp	r1, r4
	subge	r1, r1, #THERE_BUF_SIZE
	ldr	r2, =var_LATEST	@ r2 = &LATEST
	ldr	r3, [r2]	@ r3 = LATEST
	str	r0, [r2]	@ LATEST = HERE
	str	r3, [r1]	@ *THERE = LINK

	add	r0, r0, #4	@ Move HERE
	add	r1, r1, #4	@ Move THERE
	mov	r5, #0x40000000
	add	r5, #THERE_BUF_END
	cmp	r1, r5
	subge	r1, #THERE_BUF_SIZE

	strb	top, [r1]	@ Store len & flg
	add	r0, r0, #1
	add	r1, r1, #1	@ Move HERE and THERE
	mov	r5, #0x40000000
	add	r5, #THERE_BUF_END
	cmp	r1, r5
	subge	r1, #THERE_BUF_SIZE
	add	top, r0, top	@
	POP	r2

1:
	ldrb	r3, [r2], #1
	strb	r3, [r1], #1
	mov	r5, #0x40000000
	add	r5, #THERE_BUF_END
	cmp	r1, r5
	subge	r1, #THERE_BUF_SIZE
	add	r0, r0, #1
	cmp	top, r0
	bne	1b
	add	r0, r0, #3	@ Move HERE and THERE to 4B boundary
	and	r0, r0, #~3
	add	r1, r1, #3
	and	r1, r1, #~3
	mov	r5, #0x40000000
	add	r5, #THERE_BUF_END
	cmp	r1, r5
	subge	r1, #THERE_BUF_SIZE
	ldr	r2, =var_HERE	@ Save HERE and THERE
	str	r0, [r2]
	ldr	r2, =var_THERE
	str	r1, [r2]
	POP	top
	NEXT
	

	@@ Enter interpret mode
	defcode "[",1,F_IMMED,LBRAC
	ldr	r0, =var_STATE
	mov	r1, #1
	str	r1, [r0]
	NEXT
	
	@@ Enter compile mode
	defcode "]",1,,RBRAC
	ldr	r0, =var_STATE
	mov	r1, #0
	str	r1, [r0]	
	NEXT

	@@ Lit
	defcode "LIT",3,,LIT
	PUSH	top
	ldr	top, [lr]
	add	lr, lr, #4
	NEXT
	
	@@ 
	defcode "EXIT",4,,EXIT
	POPRSP 	lr
	NEXT
	
	@@ 
	defcode ",",1,,COMMA
	ldr	r0, =var_HERE
	ldr	r1, [r0]
	add	r1, r1, #4
	ldr	r2, =var_THERE
	ldr	r3, [r2]
	str	top, [r3]
	add	r3, r3, #4
	mov	r4, #0x40000000
	mov	r5, #THERE_BUF_END
	add	r4, r4, r5
	cmp	r3, r4
	subge	r3, #THERE_BUF_SIZE
	POP	top
	str	r1, [r0]	@ Update HERE
	str	r3, [r2]	@ Update THERE
	NEXT
	
	@@ 
	defcode "!",1,,STORE
	POP	r0
	str	r0, [top]
	POP	top
	NEXT
	
	@@ 
	defcode "C!",2,,CSTORE
	POP	r0
	strb	r0, [top]
	POP	top
	NEXT

	@@ 
	defcode "@",1,,FETCH
	ldr	top, [top]
	NEXT

	@@ 
	defcode "C@",2,,CFETCH
	ldrb	top, [top]
	NEXT

	@@ 
	defcode "+",1,,PLUS
	POP	r0
	add	top, top , r0
	NEXT
	
	@@ 
	defcode "-",1,,MINUS
	POP	r0
	sub	top, r0, top 
	NEXT

	@@ 
	defcode "AND",3,,AND
	POP	r0
	and	top, top , r0
	NEXT
	@@
	
	defcode "OR",2,,OR
	POP	r0
	orr	top, top , r0
	NEXT
	
	defcode "NOT",3,,NOT
	cmp	top, #0
	moveq	top, #0xFFFFFFFF
	movne	top, #0
	NEXT

	defcode "BNOT",4,,BNOT
	mvn	top, top
	NEXT

	
	@@ 
	defcode ">>",2,,ASR
	POP	r0
	mov	top, r0, ASR top
	NEXT
	
	@@ 
	defcode "<<",2,,LSL
	POP	r0
	mov	top, r0, LSL top
	NEXT
	@@
	
	defcode "ENTER_CRITICAL",14,,ENTER_CRITICAL
	mrs	r0, cpsr
	orr	r0, r0, #0x80
	msr	cpsr, r0
	NEXT
	
	defcode "LEAVE_CRITICAL",14,,LEAVE_CRITICAL
	mrs	r0, cpsr
	bic	r0, r0, #0x80
	msr	cpsr, r0
	NEXT
	
	defcode "SAVE_CONTEXT",12,,SAVE_CONTEXT
	stmfd	SP!,{R0-R12}
	NEXT
	
	defcode "RESTORE_CONTEXT",15,,RESTORE_CONTEXT
	LDMFD SP!,{R0-R12}
	NEXT
	
	defcode "ENTER_INTERRUPT",15,,ENTER_INTERRUPT
	stmfd	sp!, {r0-r12}
	NEXT	
	
	defcode "LEAVE_INTERRUPT",15,,LEAVE_INTERRUPT
	ldmfd	sp!, {r0-r12}
	POPRSP	lr
	subs	pc, lr, #4
	

	
	@@
	defword "END",3,F_IMMED,END
1:
	ldr	r0, =var_THERE	
	ldr	r0, [r0]	@ r0 = THERE
	ldr	r1, =var_BLK_THERE
	ldr	r1, [r1]	@ r1 = BLK_THERE
	add	r0, r0, #THERE_BUF_SIZE
	sub	r2, r0, r1	@ r2 = THERE - BLK_THERE + SIZE
	cmp	r2, #THERE_BUF_SIZE
	subge	r2, r2, #THERE_BUF_SIZE
	cmp	r2, #0x0
	ble	2f
	
	@@ Prepare the flash
	STMFD SP!,{R0-R12, R14}
	ldr	r1, =var_BLK_HERE
	ldr	r1, [r1]	@ r1 = BLK_HERE
	mov	r3, r1, LSR #12	@ BLK_HERE / 4k
	and	r3, r3, #0xFF
	ldr	r0, =iap_para
	mov	r2, #50
	str	r2, [r0], #4
	mov	r2, r3
	str	r2, [r0], #4
	mov	r2, r3
	str	r2, [r0], #4
	ldr	r0, =iap_para
	ldr	r1, =iap_result
	bl	iap
	
	@@ Write the flash
	ldr	r0, =iap_para
	mov	r2, #51
	str	r2, [r0], #4
	ldr	r2, =var_BLK_HERE	
	ldr	r2, [r2]	@ r0 = BLK_HERE
	str	r2, [r0], #4
	ldr	r2, =var_BLK_THERE	
	ldr	r2, [r2]	@ r0 = BLK_THERE
	str	r2, [r0], #4
	mov	r2, #BLK_SIZE
	str	r2, [r0], #4
	mov	r2, #0xD800	
	str	r2, [r0], #4
	ldr	r0, =iap_para
	ldr	r1, =iap_result
	bl	iap

	LDMFD SP!,{R0-R12, R14}


	@@ Update BLK_HERE and BLK_THERE
	ldr	r0, =var_BLK_HERE
	ldr	r1, [r0]
	add	r1, r1, #BLK_SIZE
	str	r1, [r0]
	ldr	r0, =var_HERE
	ldr	r2, [r0]
	cmp	r1, r2		@new BLK_HERE, HERE
	strge	r1, [r0]
	
	ldr	r0, =var_BLK_THERE
	ldr	r1, [r0]
	add	r1, r1, #BLK_SIZE
	mov	r4, #0x40000000
	mov	r5, #THERE_BUF_END
	add	r4, r4, r5
	cmp	r1, r4
	subge	r1, #THERE_BUF_SIZE
	str	r1, [r0]
	
	ldr	r0, =var_THERE
	ldr	r3, =var_BLK_HERE
	ldr	r3, [r3]
	ldr	r4, =var_HERE
	ldr	r4, [r4]
	cmp	r3, r4
	strge	r1, [r0]
	b	1b
2:	
	bl	code_EXIT

	@@
	defword ";",1,F_IMMED,SEMICOLON
	bl	code_LIT
	POPRSP 	lr	
	bl	code_COMMA
	bl	code_LIT
	NEXT
	bl	code_COMMA
	bl	code_LBRAC
1:
	ldr	r0, =var_THERE	
	ldr	r0, [r0]	@ r0 = THERE
	ldr	r1, =var_BLK_THERE
	ldr	r1, [r1]	@ r1 = BLK_THERE
	add	r0, r0, #THERE_BUF_SIZE
	sub	r2, r0, r1	@ r2 = THERE - BLK_THERE + SIZE
	cmp	r2, #THERE_BUF_SIZE
	subge	r2, r2, #THERE_BUF_SIZE
	cmp	r2, #BLK_SIZE
	ble	2f
	
	@@ ldr	r0, =var_LATEST	@ If the word's defination is cross
	@@ ldr	r0, [r0]	@ the boundary, may cause problem
	@@ ldr	r1, =var_BLK_HERE
	@@ ldr	r1, [r1]
	@@ add	r1, r1, #BLK_SIZE
	@@ cmp	r0, r1
	@@ ble	2f
	
	@@ Prepare the flash
	STMFD SP!,{R0-R12, R14}
	ldr	r1, =var_BLK_HERE
	ldr	r1, [r1]	@ r1 = BLK_HERE
	mov	r3, r1, LSR #12	@ BLK_HERE / 4k
	and	r3, r3, #0xFF
	ldr	r0, =iap_para
	mov	r2, #50
	str	r2, [r0], #4
	mov	r2, r3
	str	r2, [r0], #4
	mov	r2, r3
	str	r2, [r0], #4
	ldr	r0, =iap_para
	ldr	r1, =iap_result
	bl	iap
	
	@@ Write the flash
	ldr	r0, =iap_para
	mov	r2, #51
	str	r2, [r0], #4
	ldr	r2, =var_BLK_HERE	
	ldr	r2, [r2]	@ r0 = BLK_HERE
	str	r2, [r0], #4
	ldr	r2, =var_BLK_THERE	
	ldr	r2, [r2]	@ r0 = BLK_THERE
	str	r2, [r0], #4
	mov	r2, #BLK_SIZE
	str	r2, [r0], #4
	mov	r2, #0xD800
	str	r2, [r0], #4
	ldr	r0, =iap_para
	ldr	r1, =iap_result
	bl	iap
	LDMFD SP!,{R0-R12, R14}
	@@ Update BLK_HERE and BLK_THERE
	ldr	r0, =var_BLK_HERE
	ldr	r1, [r0]
	add	r1, r1, #BLK_SIZE
	str	r1, [r0]
	ldr	r0, =var_BLK_THERE
	ldr	r1, [r0]
	add	r1, r1, #BLK_SIZE
	mov	r4, #0x40000000
	mov	r5, #THERE_BUF_END
	add	r4, r4, r5
	cmp	r1, r4
	subge	r1, #THERE_BUF_SIZE
	str	r1, [r0]
	b	1b
2:	
	bl	code_EXIT

	@@ 
	defword ":",1,F_IMMED,COLON
	bl	_WORD
	bl	_CREATE
	bl	code_LIT
	DOCOL
	bl	code_COMMA
	bl	code_RBRAC
	bl	code_EXIT
	
	@@ ( -- addr length )
	defword "WORD", 4, , WORD
	bl	_WORD
	bl	code_EXIT	
_WORD:
	ldr	r0, =var_TIB
	ldr	r0, [r0]

1:
	ldrb	r1, [r0], #1
	
	
	cmp	r1, #0
	beq	END_LOOP	
	cmp	r1, $'\\'
	beq	3f
	cmp	r1, $' '
	bls	1b
	sub	r2, r0, #1
	PUSH	top
	PUSH	r2
	mov	top, #0		@ top = word's length
2:
	add	top, top, #1
	ldrb	r1, [r0], #1
	cmp	r1, #0
	beq	END_LOOP	
	cmp	r1, $' '	
	bhi	2b
@	add	r1, top, #0x30
	ldr	r1, =var_TIB
	str	r0, [r1]
	NEXT
3:
	ldrb	r1, [r0], #1
	cmp	r1, $'\n'
	bne	3b
	b	1b
	
	.set F_IMMED,0x80
	.set F_HIDDEN,0x20
	.set F_LENMASK,0x1f

	.set THERE_BUF_SIZE, 4096
	.set THERE_BUF_END, 0x1C00
	.set BLK_SIZE, 512

	defword "FIND", 4, , FIND
	bl	_FIND
	bl	code_EXIT
_FIND:
	
	ldr	r0, =var_LATEST
	ldr	r1, [r0]
	ldr	r1, [r1]
	cmp	r1, #0xffffffff
	ldreq	r0, [r0]
	beq	5f
1:
	ldr	r1, [r0]	@ r1 = link
	cmp	r1, #0		
	beq	4f
	cmp	r1, #0xffffffff	@ There's no link, should be in RAM
	bne	2f
5:	
	ldr	r2, =var_BLK_THERE
	ldr	r2, [r2]
	ldr	r3, =var_BLK_HERE
	ldr	r3, [r3]
	sub	r2, r2, r3	@ r2 = BLK_THERE - BLK_HERE
	add	r0, r0, r2	@ link = THERE
	mov	r2, #THERE_BUF_END
	add	r2, #0x40000000
	cmp	r0, r2
	subge	r0, r0, #THERE_BUF_SIZE
	mov	r1, r0
2:	
	ldrb	r3, [r1, #4]
	and	r3, r3, #F_LENMASK
	cmp	r3, top
	mov	r0, r1
	bne	1b
3:
	sub	r3, r3, #1
	add	r4, r3, #5
	ldrb	r2, [r1, r4]
	ldr	r5, [psp]
	ldrb	r4, [r5, r3]
	cmp	r2, r4
	bne	1b		@ Different character, move to next word in dict
	cmp	r3, #0
	bne	3b		@ Continue to compare
	POP	top
	mov	top, r0
	NEXT
4:
	mov	top, #0
	NEXT
	
	defword ">CFA", 4,, TCFA
	bl 	_TCFA
	bl	code_EXIT
_TCFA:
	ldrb	r0, [top, #4]
	and	r0, r0, #F_LENMASK
	add	r0, r0, top	@ r0+4(link filed)+4(flag_len+3)-8(bl offset)
	add	r0, #8
	and	r0, r0, #~3   @ top: CFA of the word is being compiled
	cmp	r0, #0x40000000
	blt	10f
	ldr	r2, =var_BLK_THERE
	ldr	r2, [r2]
	ldr	r3, =var_BLK_HERE
	ldr	r3, [r3]
	sub	r2, r2, r3	@ r2 = BLK_THERE - BLK_HERE
	sub	r0, r0, r2
10:
	mov	top, r0
	NEXT

	defcode "IMMEDIATE",9,F_IMMED,IMMEDIATE
	ldr	r0, =var_LATEST
	ldr	r1, [r0]	@ r0 = link
	ldr	r1, [r1]
	cmp	r1, #0xffffffff	@ There's no link, should be in RAM
	bne	1f
	ldr	r2, =var_BLK_THERE
	ldr	r2, [r2]
	ldr	r3, =var_BLK_HERE
	ldr	r3, [r3]
	sub	r2, r2, r3	@ r2 = BLK_THERE - BLK_HERE
	ldr	r1, [r0]	@ r0 = link	
	add	r0, r1, r2	@ link = THERE
	b	2f
1:
	ldr	r0, [r0]
2:	
	add	r0, r0, #4
	ldrb	r1, [r0]
	orr	r1, r1, #F_IMMED
	strb	r1, [r0]
	NEXT
	

	defcode "DROP",4,,DROP
	POP	top
	NEXT

	defcode "SWAP",4,,SWAP
	POP	r0
	PUSH	top
	mov	top, r0
	NEXT

	defcode "DUP",3,,DUP
	PUSH	top
	NEXT
	
	defcode "?DUP",4,,NZ_DUP
	cmp	top, #0
	stmnefd	psp!, {top}
	NEXT
	
	defcode "ROT",3,,ROT
	POP	r0
	POP	r1
	PUSH	top
	mov	top, r0
	PUSH	r1
	NEXT
	
	defcode "-ROT",4,,NROT
	POP	r0
	POP	r1
	PUSH	r0
	PUSH	top
	mov	top, r1
	NEXT
	
	cmp	top, #0
	stmnefd	psp!, {top}
	NEXT
	
	defcode "0=",2,,ZEQ
	cmp	top, #0
	NEXT
	
	defcode "=",1,,EQ
	POP	r0
	cmp	r0, top
	moveq	top, #0xFFFFFFFF
	movne	top, #0
	NEXT
	
	defword "CONSTANT",8,F_IMMED,CONSTANT
	bl	_WORD
	bl	_CREATE
	bl	code_LIT
	PUSH	top
	bl	code_COMMA
	bl	code_LIT
	ldr	top, [pc, #0]
	bl	code_COMMA
	bl	code_LIT
	NEXT
	bl	code_COMMA
	bl	code_COMMA
	bl	code_EXIT
	
	defword "VARIABLE",8,F_IMMED,VARIABLE
	bl	_WORD
	bl	_CREATE
	bl	code_LIT
	PUSH	top
	bl	code_COMMA
	bl	code_LIT
	ldr	top, [pc, #0]
	bl	code_COMMA
	bl	code_LIT
	NEXT
	bl	code_COMMA

	ldr	r0, =var_DHERE
	PUSH	top	
	ldr	r1, [r0]
	mov	top, r1
	add	r1, r1, #4
	str	r1, [r0]
	bl	code_COMMA
	bl	code_EXIT
	
	defcode "OVER",4,,OVER
	ldr	r0, [psp]
	PUSH	top
	mov	top, r0
	NEXT

iap:	
	mov	r2, #0x7ffffff1
	bx	r2
	
	
FALSE_END_LOOP:
	b	FALSE_END_LOOP
END_LOOP:
TRUE_END_LOOP:
  	b	TRUE_END_LOOP
_code_end:	

	.section .rodata
_rodata_start:	
	.word name_OVER
	. = _rodata_start + 4096
FORTH_FILE:
	.incbin "test.fs"	
	.word	0x0
	.align 4

	.data			
	.set RETURN_STACK_SIZE,256
	.set PARAMETER_STACK_SIZE,256
	.set DICTIONARY_SIZE,4
	.data
	.align 4
	.space 512
return_stack:
	.space RETURN_STACK_SIZE
return_stack_top:
	.align 4
parameter_stack:
	.space PARAMETER_STACK_SIZE
parameter_stack_top:
	.align 4
iap_para:
	.space 20
iap_result:
	.space 40	
data_here:
	
