 : BRANCH
    HERE @ 
    -
    0x02 LSR
    0x00FFFFFF AND
    0xEB000000 +
    ,
;

: COMPILE
    WORD FIND
    >CFA
    BRANCH
;

: ' IMMEDIATE
    WORD FIND
    >CFA
;

: [COMPILE] IMMEDIATE
    COMPILE
;

: 0BRANCH IMMEDIATE
    LIT ' 0= [ , ]
    BRANCH
    
    LIT
    ' DROP [ , ]
    BRANCH
    
    HERE @ 
    DUP 0x0B000000 SWAP !		\ Save bleq to HERE
    DUP 0x04 +
    HERE !
;


: IF IMMEDIATE
    [COMPILE] 0BRANCH
;

: ELSE IMMEDIATE
    DUP DUP
    0x04 +				\ pc - 4 = top + 4 
    HERE @				\ get current HERE, tar = HERE + 4
    SWAP -				\ off = tar - pc 
    0x02 LSR
    0x00FFFFFF AND
    SWAP @				\ Get bleq or bl
    +					\ bleq or bl off
    SWAP !
    
    HERE @ 
    DUP 0xEB000000 SWAP !		\ Save bl to HERE
    DUP 0x04 +
    HERE !
;

: THEN IMMEDIATE
    DUP DUP
    0x08 +				\ pc = top + 8
    HERE @				\ get current HERE
    SWAP -				\ off = tar - pc
    0x02 LSR
    0x00FFFFFF AND
    SWAP @				\ Get bleq or bl
    +					\ bleq or bl off
    SWAP !
;

: init-uart
    0x55 0x40000060 !
    0x1 IF	
	0x22 0x40000060 !
    THEN
;

init-uart
