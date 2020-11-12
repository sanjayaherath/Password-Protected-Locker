#include "p16f873.inc"
    
org 0x00
c1  equ 0x20
c2  equ	0x21
temp equ 0x22
a   equ	0x22
goto Main
    
Main:
    call    LCD_Init
    movlw   'A'
    movwf   temp
    call    LCD_Char
    
    
    
    
    
    
    
LCD_Init:
    bsf	    STATUS,5	;select bank 1
    movlw   0x06	;make them digital pins.else cannot send 1/0
    movwf   ADCON1
    movlw   b'000000'	;make portA outputs
    movwf   TRISA
    bcf	    STATUS,5	;select bank 0
    
    call    Delay	;delay until voltage increases
    movlw   b'100010'	;4 bit initialization+enable high
    movwf   PORTA
    nop
    nop
    nop
    nop
    nop
    bcf	    PORTA,5	;set enable low
    
    movlw   b'00101000'	;4 bit 2 line 5x7 dots
    movwf   temp
    call    LCD_Command	;to send a command to lcd
    
    movlw   b'00001111'	;display on cursor on blinking
    movwf   temp
    call    LCD_Command	;to send a command to lcd
    
    movlw   b'00000001'	;clear display
    movwf   temp
    call    LCD_Command	;to send a command to lcd
    
    movlw   b'00000110'	;auto inc cursor
    movwf   temp
    call    LCD_Command	;to send a command to lcd
    return
    
    
LCD_Command:
    swapf   temp,0	;swap nibbles in temp and store in w
    andlw   b'00001111'	;keep only upper nibble
    movwf   PORTA	;output
    bsf	    PORTA,5	;set enable high
    nop
    nop
    nop
    nop
    nop
    bcf	    PORTA,5	;set enable low
    call    Delay1
    movf    temp,0	;move temp to w
    andlw   b'00001111'	;keep lower nibble only
    movwf   PORTA	;output
    bsf	    PORTA,5	;set enable high
    nop
    nop
    nop
    nop
    nop
    bcf	    PORTA,5	;set enable low
    call    Delay1
    return
    
LCD_Char:
    swapf   temp,0	;swap nibbles in temp and store in w
    andlw   b'00001111'	;keep only upper nibble
    movwf   PORTA	;output
    bsf	    PORTA,4	;set RS high
    bsf	    PORTA,5	;set enable high
    nop
    nop
    nop
    nop
    nop
    bcf	    PORTA,5	;set enable low
    call    Delay1
    movf    temp,0	;move temp to w
    andlw   b'00001111'	;keep lower nibble only
    movwf   PORTA	;output
    bsf	    PORTA,4	;set RS high
    bsf	    PORTA,5	;set enable high
    nop
    nop
    nop
    nop
    nop
    bcf	    PORTA,5	;set enable low
    bcf	    PORTA,4	;set RS low
    call    Delay1
    return
    
    
    
    


Delay:
    decfsz	c1,1	
    goto	Delay
    decfsz	c2,1
    goto	Delay
    return
Delay1:
    decfsz	c1,1	
    goto	Delay1
    return
  
    
end    
    
    
    


