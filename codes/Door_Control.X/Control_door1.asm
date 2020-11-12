


#include "p16f873.inc"

    

 c1		equ	0x20	    ; for delays
 c2		equ	0x21	    ; for delays
 LCDTemp	equ	0x22	    ; Yo keep LCD data tempararily
 LCDPORT	equ	PORTB	    
 LCDTRIS	equ	TRISB
 button_pressed equ	0x25	    ; to store the pressed button
 PwordTemp	equ	0x26	    ; to store each character at comparision
 PwordCheck	equ	0x27	    ; to check number of loops in Password_check
 KEYPORT	equ	PORTC	    
 KEYTRIS	equ	TRISC
 Pword1		equ	0x30	    ; password
 Pword2		equ	0x31	    ; password
 Pword3		equ	0x32	    ; password
 Pword4		equ	0x33	    ; password
 CONTROLPORT    equ     PORTA	    ; motor control
 CONTROLTRIS	equ     TRISA	
;eeprom
 eeval		equ	0x50	    ; temp store eeprom write data
 eead		equ	0x51	    ; store the address of eeprom
 

 
 

org 0x00
goto Main
   
Main:
    call    LCD_Init		
    call    Key_Init
    call    DoorAlarm_Init
    call    Door_OpenClose  
    
       
    
;Loops.....
    
Door_OpenClose:		    ; subroutine for loop of opening and closing the door
    l2Door_OpenClose
    call    LCD_clear	    ;clear display
    call    Msg1	    ;"Enter Password"
    call    LCD_Enter	    ;input mode
    call    Password_Check  ; check the password
   
    l1Door_OpenClose
    call    Key_Check
    movlw   'D'
    subwf   button_pressed,0	; close door when D is pressed
    btfsc   STATUS,Z
    goto    Door_Close
    goto    l1Door_OpenClose
    return
    
    
    
    
 ;Password Check.......
 
Password_Check:	    ; check the password 
    call    Store_Pword
    call    Get_Pword
    call    Store_UserCode
    movlw   3
    movwf   PwordCheck	    ; for 3 incorrect attempts
    call    Check_IncorrectAttempts
    
    return
 
Store_Pword:	    ; store the user password. from 0x00 to 0x04
    movlw   0x00
    movwf   eead    
    
    movlw   '1'
    call    Write_EEPROM
    incf    eead,1
    
    movlw   '2'
    call    Write_EEPROM
    incf    eead,1
    
    movlw   '3'
    call    Write_EEPROM
    incf    eead,1
    
    movlw   '4'
    call    Write_EEPROM
    return
    
    
    
Get_Pword:		    ; to get the password stored in eeprom
    movlw   0x30
    movwf   FSR
    
    movlw   0x00	    ; pword stored at 0x00 to 0x04
    movwf   eead
    call    Read_EEPROM
    movwf   INDF
    
    incf    FSR,1
    incf    eead,1
    call    Read_EEPROM
    movwf   INDF
    
    incf    FSR,1
    incf    eead,1
    call    Read_EEPROM
    movwf   INDF
    
    incf    FSR,1
    incf    eead,1
    call    Read_EEPROM
    movwf   INDF
    return
  
 Store_UserCode:	    ; to store the code given by user
    movlw   0x40
    movwf   FSR
    loopinstore
    call    Key_Check
    movf    button_pressed,0
    movwf   INDF
    call    LCD_char
    call    Delay5
    incf    FSR,1
    btfss   FSR,2
    goto    loopinstore
    return
    
  Show_UserCode:	   ; show the code submitted by user
    movlw   0x40
    movwf   FSR
    loopinshow
    movf    INDF,0
    call    LCD_char
    call    Delay5
    incf    FSR,1
    btfss   FSR,2
    goto    loopinshow
    return
 
 Check_IncorrectAttempts:	    ; check the number of incorrect attempts and trigger and alarm
    decfsz  PwordCheck,1
    goto    Compare_Code
    goto    Attempts_Over
    return
    
   
 Compare_Code:			    ; compare the user submited code with the correct password
    movlw   0x30
    movwf   FSR			    ; point to 0x30-0x33
    loopinCompare
    movf    INDF,0	
    movwf   PwordTemp		    ;store the value in current pointed register
    movlw   0x10
    addwf   FSR,1		    ;point to 0x40-0x43
    movf    INDF,0
    subwf   PwordTemp,0		    ;check weather 0x30=0x40 and ....
    btfss   STATUS,Z		    ;check 0 flag
    goto    Compared_IncorrectPword ;subroutine for wrong password
    movlw   0x10		    ;
    subwf   FSR,1		    ;point back to 30
    incf    FSR,1
    btfss   FSR,2
    goto    loopinCompare
    goto    Compared_CorrectPword   ;subroutine for right password
    return
    
    
 Compared_IncorrectPword:	    ;subroutine for wrong password
    call    LCD_clear
    call    Msg2
    call    LCD_Enter
    call    Store_UserCode
    call    Check_IncorrectAttempts
    return
    
 Compared_CorrectPword:		    ;subroutine for right password
    bcf	    CONTROLPORT,2	    ; off the alarm if its triggered
    call    LCD_clear
    call    Msg3
    call    Door_Open
    return
    
 Attempts_Over:			    ; trigger the alarm
    call    LCD_clear
    ;call    Msg4
    call    Alarm_On
    goto    Compare_Code
    return
    
    
 ; Door & Alarm Control
 
 DoorAlarm_Init:		    ; initialize the motor
    bcf	    STATUS,5	    ; select bank 0
    clrf    CONTROLPORT	    ; clear the port
    bsf	    STATUS,5	    ;select bank 1
    movlw   0x06
    movwf   ADCON1	    ;configure all pins as digital inputs
    bcf	    CONTROLTRIS,0   ;make 0 pin output
    bcf	    CONTROLTRIS,1    ;make 1 pin output
    bcf	    CONTROLTRIS,2    ;make 2 pin output for the alarm
    bcf	    STATUS,5	    ;select bank 0
    return
 
 Door_Open:
    bsf	    CONTROLPORT,0    ; motor forward direction
    call    Delay
    call    Delay
    
    bcf	    CONTROLPORT,0    ; motor off
    return
    
 Door_Close:
    bsf	    CONTROLPORT,1    ; motor reverse direction
    call    Delay
    call    Delay
    
    bcf	    CONTROLPORT,1    ; motor off
    goto    l2Door_OpenClose
    return
    
 Alarm_On:
    bsf	    CONTROLPORT,2    ;Alarm on
    ;call    Delay
    return
    
 ;EEPROM
 
 Read_EEPROM:
    bsf		STATUS, 6	    ;
    bcf		STATUS, 5	    ;Bank 2
    movf	eead, 0		    ;Write address
    movwf	EEADR		    ;to read from
    bsf		STATUS, 5	    ;Bank 3
    bcf		EECON1, 7	    ;Point to Data memory
    bsf		EECON1, 0	    ;Start read operation
    bcf		STATUS, 5	    ;Bank 2
    movf	EEDATA, 0	    ;W = EEDATA
    bcf		STATUS, 6	    ;select bank 0
    return

Write_EEPROM:
    movwf	eeval		    ; move the value to register
    bsf		STATUS, 6	    ;
    movf	eead, 0		    ;Address to
    movwf	EEADR		    ;write to
    movf	eeval, 0	    ;Data to
    movwf	EEDATA		    ;write
    bsf		STATUS, 5	    ;Bank 3
    bcf		EECON1, 7	    ;Point to Data memory
    bsf		EECON1, 2	    ;Enable writes
				    ;Only disable interrupts
    ;bcf	INTCON, GIE	    ;if already enabled,
				    ;otherwise discard
    movlw	0x55		    ;Write 55h to
    movwf	EECON2		    ;EECON2
    movlw	 0xAA		    ;Write AAh to
    movwf	EECON2		    ;EECON2
    bsf		EECON1, 1	    ;Start write operation
				    ;Only enable interrupts
    ;bsf	INTCON, GIE	    ;if using interrupts,
				    ;otherwise discard
    bcf		EECON1, 2	    ;Disable writes
    btfsc	EECON1, 1	    ;Wait for write to finish
    goto	$-1
    bcf		STATUS,5	    
    bcf		STATUS,6	    ;select bank 0
    
    
    return
    
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

LCD_Enter:		    ;Input Mode
    movlw   b'11000000'	    ;Goto 2nd row
    call    LCD_Ins
    movlw   b'00001111'	    ; Turn on Display/Cursor
    call    LCD_Ins
    return

LCD_clear:
    movlw   b'00000001'	    ; Clear display
    call    LCD_Ins
    call    Delay5
    movlw   b'00001100'	    ; Turn off Cursor
    call    LCD_Ins
    call    Delay2
    return
    
;Messages..........
Msg1:			    ; 'Enter Password'
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
    return
 
 Msg2:			    ; 'Incorrect Password'
    movlw   'I'
    call    LCD_char
    movlw   'N'
    call    LCD_char
    movlw   'C'
    call    LCD_char
    movlw   'O'
    call    LCD_char
    movlw   'R'
    call    LCD_char
    movlw   'R'
    call    LCD_char
    movlw   'E'
    call    LCD_char
    movlw   'C'
    call    LCD_char
    movlw   'T'
    call    LCD_char
    movlw   '.'
    call    LCD_char
    movlw   ' '
    call    LCD_char
    movlw   'R'
    call    LCD_char
    movlw   'E'
    call    LCD_char
    movlw   'T'
    call    LCD_char
    movlw   'R'
    call    LCD_char
    movlw   'Y'
    call    LCD_char
    
    return
    
 Msg3:			    ; 'Correct Password'
    movlw   'C'
    call    LCD_char
    movlw   'O'
    call    LCD_char
    movlw   'R'
    call    LCD_char
    movlw   'R'
    call    LCD_char
    movlw   'E'
    call    LCD_char
    movlw   'C'
    call    LCD_char
    movlw   'T'
    call    LCD_char
    return
    
 Msg4:			    ;'Alarm On'
    movlw   'A'
    call    LCD_char
    movlw   'L'
    call    LCD_char
    movlw   'A'
    call    LCD_char
    movlw   'R'
    call    LCD_char
    movlw   'M'
    call    LCD_char
    movlw   ' '
    call    LCD_char
    movlw   'O'
    call    LCD_char
    movlw   'N'
    call    LCD_char
    return
    
 
    
    
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
    movlw   'X'				;	X stored as buttonpressed
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
    subwf   button_pressed,0		; Check whether the button pressed ='X'
    btfsc   STATUS,Z			; else a button has been pressed and stored
    goto    Key_Check
    			
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


