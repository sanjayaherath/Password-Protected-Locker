


#include "p16f873.inc"

    
;Variables
;ports
    LCDPORT	equ	PORTB	    ; lcd port
    LCDTRIS	equ	TRISB
    KEYPORTC	equ	PORTC	    ; keypad,motor,alarm port(INPUTS)
    KEYTRISC	equ	TRISC
    KEYPORTA	equ	PORTA	    ; keypad port(OUTPUTS)
    KEYTRISA	equ	TRISA
;password check
    PwordTemp	equ	0x26	    ; to store each character at comparision
    PwordCheck	equ	0x27	    ; to check number of loops in Password_check
    Pword1	equ	0x30	    ; password is retrieved to 0x30 to 0x33
    Usercode	equ	0x40	    ; users code is stored temporarily at 0x40 to 0x43
;LCD and Keypad
    LCDTemp	equ	0x22	    ; Yo keep LCD data tempararily
    button_pressed equ	0x25	    ; to store the pressed button
;delays
    c1		equ	0x20	    ; for delays
    c2		equ	0x21	    ; for delays
;eeprom
    eeval	equ	0x50	    ; temp store eeprom write data
    eead	equ	0x51	    ; store the address of eeprom
;program status register	    ; check whether status bits are set/reset 
    statusreg	equ	0x28	    ; 0 -to check whether program in reset mode
;interrupt	
     tmrctr     equ	0x52	    ; count number of timer1 interrupts to go to sleep
 

 
;Program

org 0x00
goto Main
	
org 0x04
goto ISR
   
Main:
        	
    call	Key_Init	    ; Keypad Initialization
    call	LCD_Init	    ; LCD initilaization
    call	DoorAlarm_Init	    ; motor and alarm intialization
    call	Check_PwordChange   ; check whether passwordis changed by the user
    call	Tmr1_Init	    ; timer 1 initialization
        
Menu_Select:			    ; select one option from available menu
    call	LCD_clear
    call	Msg0		    ;'Welcome'
    
    call	 Key_Check
    
    movlw	'A'		    ;Door open and close
    subwf	button_pressed,0	
    btfsc	STATUS,Z		
    call	Door_OpenClose
    
    movlw	'B'		    ;reset password
    subwf	button_pressed,0	
    btfsc	STATUS,Z		
    call	Pword_Reset
    
    movlw	'C'		    ;reset password
    subwf	button_pressed,0	
    btfsc	STATUS,Z
    call	About
    
    goto	Menu_Select
    
 ISR:				    ; Interrupt service routine
    btfsc	PIR1,0		    ;check whether interrupt from timer1 overflow
    goto	ISR_Time
    retfie
    
 ISR_Time:			    ; ISR for timer overflow   
    decfsz	tmrctr		    ; check the time of inactivity
    goto	ISR1
    goto	ISRsleep
    
    ISR1
    bcf		PIR1,0		    ; clear the tmr1 interrupt flag bit
    retfie
    
    ISRsleep			    ; send device to sleep
    bsf		INTCON,0	    ;enable RBO interrupt 
    bcf		PORTC,0		    ; backlight
    sleep
    bcf		INTCON,0	    ;disable RBO interrupt
    bcf		PIR1,0
    bsf		PORTC,0		    ; backlight
    retfie   

;Menus....
    
Door_OpenClose:			    ; subroutine for loop of opening and closing the door
    
    bcf		T1CON,0		    ;off tmr1
    call	LCD_clear	    ;clear display
    call	Msg1		    ;"Enter Password"
    call	LCD_Enter	    ;input mode
    goto	Password_Check	    ; check the password
    closedoor
    call	Key_Check
    movlw	'D'
    subwf	button_pressed,0    ; close door when D is pressed
    btfsc	STATUS,Z
    goto	Door_Close
    goto	closedoor
    
Pword_Reset:			    ; subroutine for changing the password
    call	LCD_clear	    ;clear display
    call	Msg4		    ;"Reset Password"
    call	Delay
    call	Reset_P
    return
    
About:				    ;Help and information
    bcf		T1CON,0		    ;off tmr1
    call	LCD_clear
    call	Msg8		    ;'TECH SOLUTIONS\n081-2227222'
    
    call	Delay
    call	Delay
    call	Delay
    call	Delay
    
    call	Tmr1_On
    
    return
    
    
    
 ;Password Check.......
 
Password_Check:			    ; check the password 
    bcf		T1CON,0		    ;off tmr1
    call	Get_Pword
    call	Store_UserCode
    movlw	3
    movwf	PwordCheck	    ; for 3 incorrect attempts
    ;goto	Check_IncorrectAttempts
    
 
Check_IncorrectAttempts:	    ; check the number of incorrect attempts and trigger and alarm
    
    decfsz	PwordCheck,1
    goto	Compare_Code
    goto	Attempts_Over
    
 
Get_Pword:			    ; to get the password stored in eeprom
    
    movlw	0x30		    ; passowrd is retrieved to 0x30 to 0x33
    movwf	FSR
    
    movlw	0x00		    ; pword stored at 0x00 to 0x03
    movwf	eead
    call	Read_EEPROM
    movwf	INDF
    
    incf	FSR,1
    incf	eead,1
    call	Read_EEPROM
    movwf	INDF
    
    incf	FSR,1
    incf	eead,1
    call	Read_EEPROM
    movwf	INDF
    
    incf	FSR,1
    incf	eead,1
    call	Read_EEPROM
    movwf	INDF
    return
  
 Store_UserCode:	    ; to store the code given by user
    
    movlw	0x40
    movwf	FSR
    
    loopinstore
    call	Key_Check
    movf	button_pressed,0
    movwf	INDF
    call	LCD_char
    call	Delay5
    incf	FSR,1
    btfss	FSR,2	    ;0x43=0100 0111 therefore checks the 3rd bit ti find weather 4 digits are entered
    goto	loopinstore
    return
    
Compare_Code:			    ; compare the user submited code with the correct password
    
    movlw	0x30
    movwf	 FSR		    ; point to 0x30-0x33
    
    loopinCompare
    movf	INDF,0	
    movwf	PwordTemp	    ;store the value in current pointed register
    movlw	0x10
    addwf	FSR,1		    ;point to 0x40-0x43
    movf	INDF,0
    subwf	PwordTemp,0	    ;check weather 0x30=0x40 and ....
    btfss	STATUS,Z	    ;check 0 flag
    goto	Compared_IncorrectPword ;subroutine for wrong password
    movlw	0x10		    
    subwf	FSR,1		    ;point back to 30
    incf	FSR,1
    btfss	FSR,2
    goto	loopinCompare
    goto	Compared_CorrectPword;subroutine for right password
    
    
    
 Compared_IncorrectPword:	    ;subroutine for wrong password
    
    call	LCD_clear
    call	Msg2		    ;'Incprrect. Retry'
    call	LCD_Enter
    call	Store_UserCode
    goto	Check_IncorrectAttempts
    
    
 Compared_CorrectPword:		    ;subroutine for right password
    
    bcf		KEYPORTC,1	    ; off the alarm if its triggered
    call	LCD_clear
    btfsc	statusreg,0	    ; go back to password reset
    goto	reset1		    
    
    
    call	Msg3		    ; 'Correct;    
    call	Door_Open
    goto	closedoor
    
    
 Attempts_Over:			    ; trigger the alarm
    
    call	LCD_clear
    call	Alarm_On
    goto	Compare_Code
    
    
 ;Password Reset
 
 Reset_P:			    ;reset the password
    call	LCD_clear
    call	Msg5		    ;'old password'
    call	LCD_Enter
    bsf		statusreg,0		
    goto	Password_Check
    reset1
    bcf		statusreg,0
    call	Msg6		    ;'new password'
    call	LCD_Enter
    call	Store_UserCodetoEEPROM
    call	LCD_clear
    call	Msg7		    ;reset complete
    call	Delay
    
    call	Tmr1_On
    
    return
    
 Store_UserCodetoEEPROM:	    ; store the new password on eeprom
    call	Store_UserCode
    
    movlw	0x00		    ; stored from 0x00 to 0x03
    movwf	eead    
    
    movf	0x40,0		    ;'1'
    call	Write_EEPROM
    incf	eead,1
    
    movf	0x41,0		    ;'2'
    call	Write_EEPROM
    incf	eead,1
    
     movf	0x42,0		    ;'3'
    call	Write_EEPROM
    incf	eead,1
    
    movf	0x43,0		    ;'4'
    call	Write_EEPROM
    incf	eead,1
    
    movlw	0x01		    ;to note that user had changed the password.
    call	Write_EEPROM
    return
    
 Store_Pword:			    ; store the fisrt password. from 0x00 to 0x03
    
    movlw	0x00
    movwf	eead    
    
    movlw	'1'
    call	Write_EEPROM
    incf	eead,1
    
    movlw	'2'
    call	Write_EEPROM
    incf	eead,1
    
    movlw	'3'
    call	Write_EEPROM
    incf	eead,1
    
    movlw	'4'
    call	Write_EEPROM
    return
    
 Check_PwordChange:		    ; check whether the password is changed by the user at begining.else write eeprom with default password
    
    movlw	0x04
    movwf	eead
    call	Read_EEPROM
    btfsc	W,0
    call	Store_Pword
    return
    
     
 ; Door & Alarm Control
 
 DoorAlarm_Init:		    ; initialize the motor
    
    bsf		    STATUS,5	    ;select bank1
    movlw	    d'255'
    movwf	    PR2		    ; set the period of PWM signal to 16ms
    bcf		    KEYTRISC,2	    ; motor
    bcf		    KEYTRISC,1	    ; alarm
    bcf		    STATUS,5	    ;select bank 0
    return
 
 Door_Open:			    ;open the door when password is correct
    
    
    movlw	    b'00011111'	    ;make pwm duty cycle to 2ms.(d125)
    movwf	    CCPR1L	    ;higher 8 bits
    movlw	    b'00011100'
    movwf	    CCP1CON	    ;lower 2 bits in 4-5.11xx in 0-4 for PWM mode.
    movlw	    b'00000110'
    movwf	    T2CON	    ;on timer2 and set the prescaler to x16.
    
    return
    
 Door_Close:			    ;close the door 
    
    
    movlw	    b'00001011'	    ;make pwm duty cycle to 1ms.(d62)
    movwf	    CCPR1L
    movlw	    b'00101100'
    movwf	    CCP1CON
    movlw	    b'00000110'
    movwf	    T2CON
    call	    Delay
    call	    Delay
    call	    Delay
    bcf		    T2CON,2	    ;off timer2
    bcf		    CCP1CON,2	    ;
    bcf		    CCP1CON,3	    ;off CCP1
    call	    Tmr1_On
    
   
    ;bsf		    statusreg,1
    return
    
 Alarm_On:
    
    bsf		KEYPORTC,1	    ;Alarm on
    ;call	Delay
    return
 
 ;Timer1
 
 Tmr1_Init:			    ; configure timer 1
    
    bsf		STATUS,5	    ; bank1
    bsf		PIE1,0		    ; enable timer1 overflow bit
    bcf		STATUS,5	    ; bank 0
    bsf		INTCON,6	    ; enable peripheral interrupt enable bit
    bsf		INTCON,7	    ; enable global interrupt bit
    
    movlw	b'00110000'	    ; 8:1 prescale
    movwf	T1CON
 
 Tmr1_On:			    ; on the timer 1
    
    movlw	    d'10'	    ; check for 10s of inactivity
    movwf	    tmrctr
    bsf		    T1CON,0	    ; on timer 1 (sleep mode init)
    return
    
    
 ;EEPROM
 
 Read_EEPROM:
    
    bsf		STATUS, 6	    
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
    bsf		STATUS, 6	    
    movf	eead, 0		    ;Address to
    movwf	EEADR		    ;write to
    movf	eeval, 0	    ;Data to
    movwf	EEDATA		    ;write
    bsf		STATUS, 5	    ;Bank 3
    bcf		EECON1, 7	    ;Point to Data memory
    bsf		EECON1, 2	    ;Enable writes
				    ;Only disable interrupts
    bcf		INTCON, GIE	    ;if already enabled,
				    ;otherwise discard
    movlw	0x55		    ;Write 55h to
    movwf	EECON2		    ;EECON2
    movlw	 0xAA		    ;Write AAh to
    movwf	EECON2		    ;EECON2
    bsf		EECON1, 1	    ;Start write operation
				    ;Only enable interrupts
    bsf		INTCON, GIE	    ;if using interrupts,
				    ;otherwise discard
    bcf		EECON1, 2	    ;Disable writes
    btfsc	EECON1, 1	    ;Wait for write to finish
    goto	$-1
    bcf		STATUS,5	    
    bcf		STATUS,6	    ;select bank 0
    
    
    return
    
 ;LCD routines...........   
 
LCD_Init:			     ; initialize LED to 4 bit mode
    
    bsf		STATUS, 5	    ; select bank 1 
    movlw	b'00000001'	    ; LCDPORT Outputs. RB0 as an input fot interrupt
    movwf	LCDTRIS		    ; Change PortB to output
    bcf		STATUS, 5	    ; select bank 0
    call	Delay5		    ; Wait 15 msecs
    call	Delay5	    
    call	Delay5	    
    movlw	b'00110000'	    ; Send the Reset Instruction
    movwf	LCDPORT	    
    call	Pulse_e		    ; Pulse LCD_E
    call	Delay5		    ; Delay 5ms
    call	Pulse_e		    ; Pulse LCD_E
    call	Delay2		    ; Delay of 2ms
    call	Pulse_e		    ; Pulse LCD_E
    call	Delay2		    ; Delay of 2ms
    movlw	b'00100000'	    ; Send the Data Length Specification
    movwf	LCDPORT	    
    call	Pulse_e		    ; Pulse LCD_E
    call	Delay2		    ; Delay of 2ms
    movlw	b'00101000'	    ; Set Interface Length
    call	LCD_Ins	    
    movlw	b'00001000'	    ; Turn Off Display
    call	LCD_Ins	    
    movlw	b'00000001'	    ; Clear Display RAM
    call	LCD_Ins	    
    movlw	b'00000110'	    ; Set Cursor Movement
    call	LCD_Ins	    
    movlw	b'00001100'	    ; Turn on Display
    call	LCD_Ins	    
    movlw	b'00000001'	    ; Clear LCD
    call	LCD_Ins	    
    bsf		PORTC,0		    ; on backlight
    return 
    
LCD_Ins:			    ;Send the Instruction to the LCD
    
    movwf	LCDTemp		    ; Save the Value
    andlw	b'11110000'	    ; High Nibble first
    movwf	LCDPORT	    
    bcf		LCDPORT,2	    
    call	Pulse_e	    
    swapf	LCDTemp, 0	    ; Low Nibble Second
    andlw	b'11110000'	    
    movwf	LCDPORT	    
    bcf		LCDPORT,2	    
    call	Pulse_e	    
    call	Delay2		    ; wait 2 ms
    
    return 

LCD_char:			    ; Send the Character to the LCD
    
    movwf	LCDTemp		    ; Save the Value
    andlw	0xF0		    ; High Nibble first
    movwf	LCDPORT	    
    bsf		LCDPORT,2	    
    call	Pulse_e ;
    swapf	LCDTemp, 0	    ; Low Nibble Second
    andlw	0xF0	    
    movwf	LCDPORT	    
    bsf		LCDPORT,2	    
    call	Pulse_e	    
    call	Delay2	   
    nop 
    return 

Pulse_e:			    ;LCD Enable pulse to write data from LCDPORT into LCD module.
    
    bsf		LCDPORT,3	     
    nop			     
    bcf		LCDPORT,3		     
    nop			    
    return

LCD_Enter:			    ;Input Mode
    
    movlw	b'11000000'	    ;Goto 2nd row
    call	LCD_Ins
    movlw	b'00001111'	    ; Turn on Display/Cursor
    call	LCD_Ins
    return

LCD_clear:
    
    movlw	 b'00000001'	    ; Clear display
    call	LCD_Ins
    call	Delay5
    movlw	b'00001100'	    ; Turn off Cursor
    call	LCD_Ins
    call	Delay2
    return
    
;Keypad routines.............
    
Key_Init:				 ;Initalize keypad
    
    bsf		STATUS,5		;select bank 1
    movlw	b'11110000'		;0-4 outputs,4-7 inputs in portc
    movwf	KEYTRISC
    movlw	0x06	
    movwf	ADCON1			;configure all pins as digital inputs
    movlw	b'00000000'		; make portA output  
    movwf	KEYTRISA
    bcf		STATUS,5		;select bank0
    clrf	KEYPORTA		; clear the port
    clrf	KEYPORTC		; clear the port
    clrf	button_pressed		;clear the button
    return
    
    
Key_Check:				;check what button has been pressed
    
    movlw	'X'			;X stored as buttonpressed
    movwf	button_pressed
    bsf		KEYPORTA, 0		;scan the first column of keys 		
    btfsc	KEYPORTC, 4				
    movlw	'7'			;7 is pressed.
    btfsc	KEYPORTC, 5				
    movlw	'4'			;4 is pressed.
    btfsc	KEYPORTC, 6				
    movlw	'1'			;1 is pressed.
    btfsc	KEYPORTC, 7				
    movlw	'*'			;* is pressed.
    bcf		KEYPORTA, 0		;take first column low.

    bsf		KEYPORTA, 1		;scan the second column of keys
    btfsc	KEYPORTC, 4			
    movlw	'8'			;8 is pressed.
    btfsc	KEYPORTC, 5			
    movlw	'5'			;5 is pressed.
    btfsc	KEYPORTC, 6			
    movlw	'2'			;2 is pressed.
    btfsc	KEYPORTC, 7			
    movlw	'0'			;0 is pressed.
    bcf		KEYPORTA, 1		;take second column low.

    bsf		KEYPORTA, 2		;scan the third column of keys 
    btfsc	KEYPORTC, 4			
    movlw	'9'			;9 is pressed.
    btfsc	KEYPORTC, 5			
    movlw	'6'			;6 is pressed.
    btfsc	KEYPORTC, 6			
    movlw	'3'			;3 is pressed.
    btfsc	KEYPORTC, 7			
    movlw	'#'			;1 is pressed.
    bcf		KEYPORTA, 2		;take rhird column low.

    bsf		KEYPORTA, 3		;scan the last column of keys
    btfsc	KEYPORTC, 4			
    movlw	'A'			;A is pressed.
    btfsc	KEYPORTC, 5			
    movlw	'B'			;B is pressed.
    btfsc	KEYPORTC, 6			
    movlw	'C'			;C is pressed.
    btfsc	KEYPORTC, 7			
    movlw	'D'			;D is pressed.
    bcf		KEYPORTA, 3		;take last column low.
    
    movwf	button_pressed
    movlw	'X'
    subwf	button_pressed,0	; Check whether the button pressed ='X'
    btfsc	STATUS,Z		; else a button has been pressed and stored
    goto	Key_Check
    			
    return
 

    
    
; Delay routines........
    
Delay5:					;5ms @ 1MHz
    
    movlw	d'2'
    movwf	c1
    call	Delay
    return
    
Delay:					;0.7s
    
    decfsz	c1,1	
    goto	Delay
    decfsz	c2,1
    goto	Delay
    return
Delay2:					;2ms
    decfsz	c1,1	    
    goto	Delay2
    return
 
 


;Messages..........
 
 Msg0:					;'_**WELCOME**_'
    
    movlw   ' '
    call    LCD_char
    movlw   ' '
    call    LCD_char
    movlw   '*'
    call    LCD_char
    movlw   '*'
    call    LCD_char
    movlw   'W'
    call    LCD_char
    movlw   'E'
    call    LCD_char
    movlw   'L'
    call    LCD_char
    movlw   'C'
    call    LCD_char
    movlw   'O'
    call    LCD_char
    movlw   'M'
    call    LCD_char
    movlw   'E'
    call    LCD_char
    movlw   '*'
    call    LCD_char
    movlw   '*'
    call    LCD_char
    return
    
Msg1:				    ; 'Enter Password'
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
 
 Msg2:				     ; 'Incorrect Password'
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
    
 Msg3:					; 'Correct Password'
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
    
Msg4:				    ; 'Reset Password'
    movlw   'R'
    call    LCD_char
    movlw   'E'
    call    LCD_char
    movlw   'S'
    call    LCD_char
    movlw   'E'
    call    LCD_char
    movlw   'T'
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
    
Msg5:				    ; 'Old Password'
    movlw   'O'
    call    LCD_char
    movlw   'L'
    call    LCD_char
    movlw   'D'
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
    
Msg6:				    ; 'New Password'
    movlw   'N'
    call    LCD_char
    movlw   'E'
    call    LCD_char
    movlw   'W'
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
    
Msg7:				    ; 'Reset Complete'
    movlw   'R'
    call    LCD_char
    movlw   'E'
    call    LCD_char
    movlw   'S'
    call    LCD_char
    movlw   'E'
    call    LCD_char
    movlw   'T'
    call    LCD_char
    movlw   ' '
    call    LCD_char
    movlw   'C'
    call    LCD_char
    movlw   'O'
    call    LCD_char
    movlw   'M'
    call    LCD_char
    movlw   'P'
    call    LCD_char
    movlw   'L'
    call    LCD_char
    movlw   'E'
    call    LCD_char
    movlw   'T'
    call    LCD_char
    movlw   'E'
    call    LCD_char
    return

Msg8:				    ; 'TECH SOLUTIONS\n081-2227222'
    movlw   'T'
    call    LCD_char
    movlw   'E'
    call    LCD_char
    movlw   'C'
    call    LCD_char
    movlw   'H'
    call    LCD_char
    movlw   ' '
    call    LCD_char
    movlw   'S'
    call    LCD_char
    movlw   'O'
    call    LCD_char
    movlw   'L'
    call    LCD_char
    movlw   'U'
    call    LCD_char
    movlw   'T'
    call    LCD_char
    movlw   'I'
    call    LCD_char
    movlw   'O'
    call    LCD_char
    movlw   'N'
    call    LCD_char
    movlw   'S'
    call    LCD_char
    movlw   b'11000000'	    ;Goto 2nd row
    call    LCD_Ins
    movlw   '0'
    call    LCD_char
    movlw   '8'
    call    LCD_char
    movlw   '1'
    call    LCD_char
    movlw   '-'
    call    LCD_char
    movlw   '2'
    call    LCD_char
    movlw   '2'
    call    LCD_char
    movlw   '2'
    call    LCD_char
    movlw   '7'
    call    LCD_char
    movlw   '2'
    call    LCD_char
    movlw   '2'
    call    LCD_char
    movlw   '2'
    call    LCD_char
    
    
    
    return 



end


