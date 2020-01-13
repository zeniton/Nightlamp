;************************************
; written by: Stoffel van Aswegen 
; date: 2019-08-17
; version: 0.0
; for AVR: ATTiny85
; clock frequency: 1 MHz
; Function: Night light controller with motion detection
;	Ambient light level measured with LDR
;	Switch lamp on for 2-3hrs at sunset
;	Switch lamp on for 10mins when dark & motion detected and lamp is off
;	LDR circuit only switched on during measuring
;       
;   +5V ---+------+----------------------------+------+
;          |      |                            |      |
;          |     1k           ATTiny85         |      |
;          |      |         +----------+       |      |
;         LDR     +--RESET--| 1      8 |--Vcc--+     10k              +--------+
;          |                |          |              |               |Motion  |
;          |                | 2      7 |<-PB2---@1    |          @1---|detector|
;          |                |          |              |               +--------+
;          +------ADC2/PB4->| 3      6 |<-PB1---------+----+
;          |                |          |              |    |          +--------+
;          |      +----GND--| 4      5 |>-PB0---@2    |    |     @2---|  Lamp  |
;         100k    |         +----------+             1k    |          +--------+
;          |      |                                   |    O |
;          |      |                            100nF ---     |=O Level Set
;          |      |                                  ---   O |   Button
;          |      |                                   |    |
;   GND ---+------+-----------------------------------+----+
										     
.nolist
.include "tn85def.inc"
.list

.def status	= r15	;Copy of Status Register
.def tmp	= r16	;General register
.def tcint	= r17	;Timer Compare Interrupt counter
.def secs   = r18	;Seconds counter
.def mins	= r19	;Minutes counter
.def hours	= r20	;Hours counter
.def system	= r21	;System flags: bit0=1/0(movement/not)

;Flags
.equ TIMER      = 0
.equ MOVEMENT   = 1

;I/O
.equ LAMP       = PB0	;Lamp (output)
.equ MOTION     = PB2	;Motion detector (input)
.equ BUTTON     = PB1	;Level Set button (input)

.org 0x0000
rjmp RESET				;0x0000 RESET
rjmp INT0_ISR			;0x0001 INT0
reti					;0x0002 PCINT0
reti					;0x0003 TIMER1_COMPA
reti					;0x0004 TIMER1_OVF
reti					;0x0005 TIMER0_OVF
reti					;0x0006 EE_RDY
reti					;0x0007 ANA_COMP
reti					;0x0008 ADC
reti					;0x0009 TIMER1_COMPB
rjmp TIMER0_COMPA_ISR	;0x000A TIMER0_COMPA
reti					;0x000B TIMER0_COMPB
reti					;0x000C WDT
reti					;0x000D USI_START
reti					;0x000E USI_OVF

INT0_ISR: in 
    status,SREG                 ;Save status
	ori	system,(1<<MOVEMENT)	;Set system flag
	out	SREG,status             ;Restore status
	reti

TIMER0_COMPA_ISR:	
    in status,SREG      ;Save status
	dec tcint			;Interrupt counter
	brne EXIT_A
	ldi tcint,4			;Reset counter
	dec secs
EXIT_A:	
    out SREG,status	    ;Restore status
	reti


;===Subroutines===
Sub_TimerOn:
	ldi tcint,4			;Reset interrupt counter
	ldi tmp,(1<<CS02)|(1<<CS00)
	out TCCR0B,tmp		;Prescale Clock/1024
	ret

Sub_TimerOff:
	clr tmp
	out TCCR0B,tmp		;Stop timer
	ret

Sub_SampleLight:
    ret
;=================


RESET:
	;Setup Timer0
	;	With the 1MHz clock prescaled by 1024, the effective rate is 976kHz
	;	976 = 244 * 4
	;	Setting the Output Compare Register to 244, the TIMER0_COMPA interrupt will fire every 250ms
	;	Count 4 interrupts to measure 1s
	ldi tmp,(1<<WGM01)	;CTC mode
	out TCCR0A,tmp
	ldi tmp,244			;TIMER0 compare value
	out OCR0A,tmp
	ldi tmp,(1<<OCIE0A)
	out TIMSK,tmp		;Enable output compare interrupt

	;Setup PORTB
	ldi	tmp,(1<<DDB0)
	out DDRB,tmp		;Outputs: lamp
	ldi	tmp,(1<<DDB4) | (1<<DDB2) | (1<<DDB1)
	out	PORTB,tmp		;Enable input pull-ups

	;Setup ADC
	ldi	tmp,(1<<MUX1)	;ADC2 channel (MUX)
	out	ADMUX,tmp		;Vref = Vcc (REFSn)
	ldi	tmp,(1<<ADEN)   ;Enable ADC
	out	ADCSRA,tmp

	;Setup INT0 external interrupt (Motion Detector)
	clr	tmp 			;Trigger INT0 interrupt on low level
	out	MCUCR,tmp
	ldi	tmp,(1<<INT0)
	out	GIMSK,tmp		;Enable INT0 interrupt

	cbi	PORTB,LAMP		;Lamp off
	clr	system
	sei                 ;Enable global interrupts

LOOP:
	sbrs system,MOVEMENT
	rjmp LOOP
	sbi PORTB,LAMP		;Lamp on
	ldi hours,3
	rcall Sub_TimerOn
	TMR_LOOP:
		tst secs        ;seconds decremented in ISR
		brne TMR_LOOP
		tst mins
		breq TST_HOURS
		dec mins
		ldi	secs,60
		rjmp TMR_LOOP
		TST_HOURS:
			tst hours
			breq EXIT_TMR_LOOP
			dec hours
			ldi mins,59
			ldi secs,60
			rjmp TMR_LOOP
	EXIT_TMR_LOOP:
	andi system,(0<<MOVEMENT)	;Clear system flag
	cbi PORTB,LAMP		;Lamp off
	rcall Sub_TimerOff
	rjmp LOOP

