 LIST p=16F628A ;tell assembler what chip we are using
 include "P16F628A.inc" ;include the defaults for the chip
 ERRORLEVEL 0, -302 ;suppress bank selection messages
 __config 0x3D18 ;sets the configuration settings (osc type etc.) 
 
 LCD_PORT Equ PORTB
 LCD_TRIS Equ TRISB
 LCD_RS Equ 0x02 ;LCD handshake lines
 LCD_E Equ 0x03
 
 CBLOCK 0x20
 count ; Counter used when switch pressed has stopped
 count1 ; 160us Counter variable
 counta ; variables for delay timers
 countb ; variables for delay timers
 LCDTemp ; 4 bit for LCD
 ENDC ;
 
 org 0x000 ; 
 goto Init ;
 
HEX_Table 
 addwf PCL, f
 retlw 0x30
 retlw 0x31
 retlw 0x32
 retlw 0x33
 retlw 0x34
 retlw 0x35
 retlw 0x36
 retlw 0x37
 retlw 0x38
 retlw 0x39
 retlw 0x41
 retlw 0x42
 retlw 0x43
 retlw 0x44
 retlw 0x45
 retlw 0x46
 
Text 
 addwf PCL, f
 retlw 'H'
 retlw 'e'
 retlw 'l'
 retlw 'l'
 retlw 'o'
 retlw ' '
 retlw 'W'
 retlw 'o'
 retlw 'r'
 retlw 'l'
 retlw 'd'
 retlw '!'
 retlw 0x00
 
Text2 
 addwf PCL, f
 retlw 'L'
 retlw 'C'
 retlw 'D'
 retlw ' '
 retlw 'i'
 retlw 's'
 retlw ' '
 retlw 'O'
 retlw 'N'
 retlw 'L'
 retlw 'I'
 retlw 'N'
 retlw 'E'
 retlw 0x00
 
; Initialize the PIC and the LCD
Init ;
 movlw 0x07 ; Turn comparators off and
 movwf CMCON ; enable pins for I/O functions
 bsf STATUS, RP0 ; select bank 1 
 clrf PORTA ; Initialize PORTA by setting output data latches
 movlw b'00000000' ; PortA Outputs
 movwf TRISA ; All portA pins are inputs
 movlw b'00000000' ; PortB Outputs
 movwf TRISB ; Change PortB I/O
 bcf STATUS, RP0 ; select bank 0
 
 call LCDInit ; Initialize the LCD Display 
 
; Main program...
Message 
 movf count, w ; put counter value in W
 call Text ; get a character from the text table
 xorlw 0x00 ; is it a zero?
 btfsc STATUS, Z
 goto NextMessage ; display next message if finished
 call LCD_Char
 incf count, f
 goto Message
 
NextMessage 
 call LCD_L2 ;move to 2nd row, first column
 clrf count ;set counter register to zero
 
Message2 
 movf count, w ;put counter value in W
 call Text2 ;get a character from the text table
 xorlw 0x00 ;is it a zero?
 btfsc STATUS, Z
 goto EndMessage
 call LCD_Char
 incf count, f
 goto Message2
 
EndMessage 
 
; Infinate loop 
Stop
 goto Stop ;endless loop
 
; LCD routines and subs
LCDInit ; 4 Bit Initialization...
 call Del05 ; Wait 15 msecs
 call Del05 ;
 call Del05 ;
 movlw 0x030 ; Send the Reset Instruction
 movwf LCD_PORT ;
 call Pulse_e ; Pulse LCD_E
 call Del05 ; Delay 5ms
 call Pulse_e ; Pulse LCD_E
 call D160us ; Delay of 160us
 call Pulse_e ; Pulse LCD_E
 call D160us ; Delay of 160us
 movlw 0x020 ; Send the Data Length Specification
 movwf LCD_PORT ;
 call Pulse_e ; Pulse LCD_E
 call D160us ; Delay of 160us
 movlw 0x028 ; Set Interface Length
 call LCDIns ;
 movlw 0x010 ; Turn Off Display
 call LCDIns ; 
 movlw 0x001 ; Clear Display RAM
 call LCDIns ;
 movlw 0x006 ; Set Cursor Movement
 call LCDIns ;
 movlw 0x00C ; Turn on Display/Cursor
 call LCDIns ;
 call LCD_Clr ; Clear the LCD
 return ;
 
LCDIns ; Send the Instruction to the LCD
 movwf LCDTemp ; Save the Value
 andlw 0xF0 ; Most Significant Nibble first
 movwf LCD_PORT ;
 bcf LCD_PORT, LCD_RS ;
 call Pulse_e ;
 swapf LCDTemp, w ; Least Significant Nibble Second
 andlw 0xF0 ;
 movwf LCD_PORT ;
 bcf LCD_PORT, LCD_RS ;
 call Pulse_e ;
 call Del01 ; wait 1 ms
 movf LCDTemp, w ;
 andlw 0xFC ; Have to Delay 5 msecs?
 btfsc STATUS, Z ;
 call Del01 ; 1ms
 return ;
 
LCD_CharD
 addlw 0x30 ; add 0x30 to convert to ASCII
LCD_Char ; Send the Character to the LCD
 movwf LCDTemp ; Save the Value
 andlw 0xF0 ; Most Significant Nibble first
 movwf LCD_PORT ;
 bsf LCD_PORT, LCD_RS ; 
 call Pulse_e ;
 swapf LCDTemp, w ; Least Significant Nibble Second
 andlw 0xF0 ;
 movwf LCD_PORT ;
 bsf LCD_PORT, LCD_RS ;
 call Pulse_e ;
 call Del05 ;
 nop ;
 return ;
 
 
LCD_L2: movlw 0xc0 ; move to 2nd row, first column
 call LCDIns ;
 retlw 0x00 ;
 
LCD_Clr movlw 0x01 ; Clear display
 call LCDIns ;
 retlw 0x00 ;
 
Pulse_e ;
 bsf LCD_PORT, LCD_E ; LCD Enable pulse to write data from PORTB
 nop ; into LCD module.
 bcf LCD_PORT, LCD_E ; 
 nop ;
 retlw 0x00 ;
 
 
; Delay routines...
D160us 
 clrf count1 ; 
 bsf count1, 5 ; Delay 160 usecs
 bsf count1, 4 ;
 decfsz count1, f ;
 goto $ - 1 ;
 return ;
 
Del255 movlw 0xff ; delay 255 mS
 goto d0 ;
Del200 movlw d'200' ; delay 200mS
 goto d0 ;
Del100 movlw d'100' ; delay 100mS
 goto d0 ;
Del50 movlw d'50' ; delay 50mS
 goto d0 ;
Del20 movlw d'20' ; delay 20mS
 goto d0 ;
Del05 movlw 0x05 ; delay 5.000 ms (4 MHz clock)
 goto d0 ;
Del01 movlw 0x01 ; delay 1.000 ms (4 MHz clock)
d0 movwf count1 ;
d1 movlw 0xC7 ; delay 1mS
 movwf counta ;
 movlw 0x01 ;
 movwf countb ;
Del_0 decfsz counta,f ;
 goto $+2 ;
 decfsz countb,f ;
 goto Del_0 ;
 decfsz count1,f ;
 goto d1 ;
 retlw 0x00 ;
 
 end 


