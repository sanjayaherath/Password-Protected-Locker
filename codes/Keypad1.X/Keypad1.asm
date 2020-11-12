#include "p16f873.inc"
    
button_pressed equ 0x25
KEYPORT	       equ PORTC
KEYTRIS	       equ TRISC
 
org 0x00
goto Main
	      
Main:
    call    Key_Init	    ; intialize keypad
    call    Key_Check	    ; check the button pressed
    
    
    
Key_Init:		    ;	initalize keypad
    bsf	    STATUS,5	    ;select bank 1
    movlw   b'11110000'	    ;0-4 outputs,5-7 inputs.
    bcf	    STATUS,5	    ;select bank0
    clrf    button_pressed  ;clear the button
    return
    
    
Key_Check:				;	check what button has been pressed
    
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
    movlw   '1'				;	1 is pressed.
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
    bcf	    KEYPORT, 2			;	take last column low.

    movwf button_pressed		;	
    return						
    
    
    end


