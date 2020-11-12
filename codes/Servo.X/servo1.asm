#include "p16f873.inc"

    

 c1		equ	0x20	    ; for delays
 c2		equ	0x21	    ; for delays
 LCDTemp	equ	0x22	    ; Yo keep LCD data tempararily
 LCDPORT	equ	PORTB	    
 LCDTRIS	equ	TRISB
 button_pressed equ	0x25	    ; to store the pressed button
 KEYPORTC	equ	PORTC	    
 KEYTRISC	equ	TRISC
 KEYPORTA	equ	PORTA	    
 KEYTRISA	equ	TRISA
 

org 0x00
goto Main
   
Main:
    call    LCD_Init
    call    Key_Init
    
    movlw   'E'
    call    LCD_char
    movlw   'N'
    call    LCD_char
    movlw   'T'
    call    LCD_char
    movlw   'E'
    call    LCD_char
    movlw   'R'
    call    LCD_char
    movlw   ' '
    call    LCD_char
    movlw   'P'
    call    LCD_char
    movlw   'A'
    call    LCD_char
    movlw   'S'
    call    LCD_char
    movlw   'S'
    call    LCD_char
    movlw   'W'
    call    LCD_char
    movlw   'O'
    call    LCD_char
    movlw   'R'
    call    LCD_char
    movlw   'D'
    call    LCD_char
    movlw   b'11000000'	    ;Goto 2nd row
    call    LCD_Ins
    movlw   b'00001111'	    ; Turn on Display/Cursor
    call    LCD_Ins
    ;call    Delay
    ;movlw   b'00000001'	    ; Clear display
    ;call    LCD_Ins
    
    bsf	    STATUS,5
    movlw   d'255'
    movwf   PR2
    bcf	    TRISC,2
    bcf	    STATUS,5
    movlw   b'00001011'
    movwf   CCPR1L
    movlw   b'00101100'
    movwf   CCP1CON
    movlw   b'00000110'
    movwf   T2CON
    l
    call    Key_Check
    movf    button_pressed,0
    call    LCD_char
    call    Delay5
    goto l
    
    
    
    
 ;LCD routines...........   
LCD_Init:		    ; initialize LED to 4 bit mode
    bsf	    STATUS, 5	    ; select bank 1 
    movlw   b'00000000'	    ; LCDPORT Outputs
    movwf   LCDTRIS	    ; Change PortB to output
    bcf	    STATUS, 5	    ; select bank 0
    call    Delay5	    ; Wait 15 msecs
    call    Delay5	    
    call    Delay5	    
    movlw   b'00110000'	    ; Send the Reset Instruction
    movwf   LCDPORT	    
    call    Pulse_e	    ; Pulse LCD_E
    call    Delay5	    ; Delay 5ms
    call    Pulse_e	    ; Pulse LCD_E
    call    Delay2	    ; Delay of 2ms
    call    Pulse_e	    ; Pulse LCD_E
    call    Delay2	    ; Delay of 2ms
    movlw   0x020	    ; Send the Data Length Specification
    movwf   LCDPORT	    
    call    Pulse_e	    ; Pulse LCD_E
    call    Delay2	    ; Delay of 2ms
    movlw   b'00101000'	    ; Set Interface Length
    call    LCD_Ins	    
    movlw   b'00010000'	    ; Turn Off Display
    call    LCD_Ins	    
    movlw   b'00000001'	    ; Clear Display RAM
    call    LCD_Ins	    
    movlw   b'00000110'	    ; Set Cursor Movement
    call    LCD_Ins	    
    movlw   b'00001100'	    ; Turn on Display/Cursor
    call    LCD_Ins	    
    movlw   b'00000001'	    ; Clear LCD
    call    LCD_Ins	    
    return ;
    
LCD_Ins: 		    ;Send the Instruction to the LCD
    movwf   LCDTemp	    ; Save the Value
    andlw   b'11110000'	    ; High Nibble first
    movwf   LCDPORT	    
    bcf	    LCDPORT,2	    
    call    Pulse_e	    
    swapf   LCDTemp, 0	    ; Low Nibble Second
    andlw   b'11110000'	    
    movwf   LCDPORT	    
    bcf	    LCDPORT,2	    
    call    Pulse_e	    
    call    Delay2	    ; wait 2 ms
    
    return ;

LCD_char:		    ; Send the Character to the LCD
    movwf   LCDTemp	    ; Save the Value
    andlw   0xF0	    ; High Nibble first
    movwf   LCDPORT	    
    bsf	    LCDPORT,2	    
    call    Pulse_e ;
    swapf   LCDTemp, 0	    ; Low Nibble Second
    andlw   0xF0	    
    movwf   LCDPORT	    
    bsf	    LCDPORT,2	    
    call    Pulse_e	    
    call    Delay2	   
    nop 
    return 

Pulse_e:		    ;LCD Enable pulse to write data from LCDPORT into LCD module.
    bsf LCDPORT,3	     
    nop			     
    bcf LCDPORT,3		     
    nop			    
    return	
 
;Keypad routines.............
Key_Init:		    ;	initalize keypad
    bsf	    STATUS,5	    ;select bank 1
    movlw   b'11110000'	    ;0-4 outputs,5-7 inputs.
    movwf   KEYTRISC	    
    bcf	    STATUS,5	    ;select bank0
       
    
    clrf    KEYPORTA	    ; clear the port
    clrf    KEYPORTC	    ; clear the port
    bsf	    STATUS,5	    ;select bank 1
    movlw   0x06
    movwf   ADCON1	    ;configure all pins as digital inputs
    movlw   b'00000000'	    ; make portA output  
    movwf   KEYTRISA
    bcf	    STATUS,5	    ;select bank 0
    
    clrf    button_pressed  ;clear the button
    
    return
    
    
Key_Check:				;	check what button has been pressed
    movlw   'X'
    movwf   button_pressed
    bsf	    KEYPORTA, 0			;	scan the first column of keys 		
    btfsc   KEYPORTC, 4			;	
    movlw   '7'				;	7 is pressed.
    btfsc   KEYPORTC, 5			;	
    movlw   '4'				;	4 is pressed.
    btfsc   KEYPORTC, 6			;	
    movlw   '1'				;	1 is pressed.
    btfsc   KEYPORTC, 7			;	
    movlw   '*'				;	* is pressed.
    bcf	    KEYPORTA, 0			;	take first column low.

    bsf	    KEYPORTA, 1			;	scan the second column of keys
    btfsc   KEYPORTC, 4			;	
    movlw   '8'				;	8 is pressed.
    btfsc   KEYPORTC, 5			;	
    movlw   '5'				;	5 is pressed.
    btfsc   KEYPORTC, 6			;	
    movlw   '2'				;	2 is pressed.
    btfsc   KEYPORTC, 7			;	
    movlw   '0'				;	0 is pressed.
    bcf	    KEYPORTA, 1			;	take second column low.

    bsf	    KEYPORTA, 2			;	scan the third column of keys 
    btfsc   KEYPORTC, 4			;	
    movlw   '9'				;	9 is pressed.
    btfsc   KEYPORTC, 5			;	
    movlw   '6'				;	6 is pressed.
    btfsc   KEYPORTC, 6			;	
    movlw   '3'				;	3 is pressed.
    btfsc   KEYPORTC, 7			;	
    movlw   '#'				;	1 is pressed.
    bcf	    KEYPORTA, 2			;	take rhird column low.

    bsf	    KEYPORTA, 3			;	scan the last column of keys
    btfsc   KEYPORTC, 4			;	
    movlw   'A'				;	A is pressed.
    btfsc   KEYPORTC, 5			;	
    movlw   'B'				;	B is pressed.
    btfsc   KEYPORTC, 6			;	
    movlw   'C'				;	C is pressed.
    btfsc   KEYPORTC, 7			;	
    movlw   'D'				;	D is pressed.
    bcf	    KEYPORTA, 3			;	take last column low.
    
    movwf   button_pressed
    movlw   'X'
    subwf   button_pressed,0
    btfsc   STATUS,Z
    goto    Key_Check
    		;	
    return			
    
    
    
; Delay routines........
Delay5:				;5ms
    movlw	d'2'
    movwf	c1
    goto	Delay
    
Delay:				;0.7s
    decfsz	c1,1	
    goto	Delay
    decfsz	c2,1
    goto	Delay
    return
Delay2:				;2ms
    decfsz	c1,1	    
    goto	Delay2
    return
 
 end


