#include "p16f873.inc"

    

 c1		equ	0x20	    ; for delays
 c2		equ	0x21	    ; for delays
 LCDTemp	equ	0x22	    ; Yo keep LCD data tempararily
 LCDPORT	equ	PORTB	    
 LCDTRIS	equ	TRISB
 button_pressed equ	0x25	    ; to store the pressed button
 KEYPORT	equ	PORTC	    
 KEYTRIS	equ	TRISC
 

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
    movwf   KEYTRIS	    
    bcf	    STATUS,5	    ;select bank0
    clrf    button_pressed  ;clear the button
    return
    
    
Key_Check:				;	check what button has been pressed
    movlw   'X'
    movwf   button_pressed
    bsf	    KEYPORT, 0			;	scan the first column of keys 		
    btfsc   KEYPORT, 4			;	
    movlw   '7'				;	7 is pressed.
    btfsc   KEYPORT, 5			;	
    movlw   '4'				;	4 is pressed.
    btfsc   KEYPORT, 6			;	
    movlw   '1'				;	1 is pressed.
    btfsc   KEYPORT, 7			;	
    movlw   '*'				;	* is pressed.
    bcf	    KEYPORT, 0			;	take first column low.

    bsf	    KEYPORT, 1			;	scan the second column of keys
    btfsc   KEYPORT, 4			;	
    movlw   '8'				;	8 is pressed.
    btfsc   KEYPORT, 5			;	
    movlw   '5'				;	5 is pressed.
    btfsc   KEYPORT, 6			;	
    movlw   '2'				;	2 is pressed.
    btfsc   KEYPORT, 7			;	
    movlw   '0'				;	0 is pressed.
    bcf	    KEYPORT, 1			;	take second column low.

    bsf	    KEYPORT, 2			;	scan the third column of keys 
    btfsc   KEYPORT, 4			;	
    movlw   '9'				;	9 is pressed.
    btfsc   KEYPORT, 5			;	
    movlw   '6'				;	6 is pressed.
    btfsc   KEYPORT, 6			;	
    movlw   '3'				;	3 is pressed.
    btfsc   KEYPORT, 7			;	
    movlw   '#'				;	1 is pressed.
    bcf	    KEYPORT, 2			;	take rhird column low.

    bsf	    KEYPORT, 3			;	scan the last column of keys
    btfsc   KEYPORT, 4			;	
    movlw   'A'				;	A is pressed.
    btfsc   KEYPORT, 5			;	
    movlw   'B'				;	B is pressed.
    btfsc   KEYPORT, 6			;	
    movlw   'C'				;	C is pressed.
    btfsc   KEYPORT, 7			;	
    movlw   'D'				;	D is pressed.
    bcf	    KEYPORT, 3			;	take last column low.
    
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


