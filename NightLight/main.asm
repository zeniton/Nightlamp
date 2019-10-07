;************************************
; written by: Stoffel van Aswegen 
; date: 2019-08-17
; version: 0.0
; for AVR: ATTiny85
; clock frequency: 1 MHz
; Function: Night light controller with motion detection
;
;                +5V       ATTiny85        +5V
;                 |       +---------+       |
;                 +--1k---| 1     8 |-------+
;                   Reset |         |
;                         | 2     7 |<-PB2/INT0--------> Motion detector
;                         |         |
;                         | 3     6 |
;                         |         |
;                 +-------| 4     5 |>-PB0--+----------> Lamp
;                 |       +---------+      _|_
;                 |                       _\_/_ LED
;                 |                         |
;                 |                        220R
;                _|_                       _|_
;                ///                       ///
										     
.nolist
.include "tn85def.inc"
.list

.def status	= r15	;Copy of Status Register
.def tmp	= r16	;General register
.def tcint	= r17	;Timer Compare Interrupt counter
.def seconds	= r18	;Seconds counter
.def minutes	= r19	;Minutes counter
.def hours	= r20	;Hours counter
.def system	= r21	;System flags: bit0=1/0(movement/not)

.equ LAMP	= PB0	;Lamp (output)
.equ MOTION	= PB2	;Motion detector (input)
.equ MOVEMENT	= 0	;System flag

.org 0x0000
rjmp START				;0x0000 RESET
rjmp ISR_1				;0x0001 INT0
reti					;0x0002 PCINT0
reti					;0x0003 TIMER1_COMPA
reti					;0x0004 TIMER1_OVF
reti					;0x0005 TIMER0_OVF
reti					;0x0006 EE_RDY
reti					;0x0007 ANA_COMP
reti					;0x0008 ADC
reti					;0x0009 TIMER1_COMPB
rjmp ISR_A				;0x000A TIMER0_COMPA
reti					;0x000B TIMER0_COMPB
reti					;0x000C WDT
reti					;0x000D USI_START
reti					;0x000E USI_OVF


ISR_1:	in	status,SREG		;Save status
	ori	system,(1<<MOVEMENT)	;Set system flag
	out	SREG,status		;Restore status
	reti


ISR_A:	in status,SREG			;Save status
	dec tcint			;Interrupt counter
	brne EXIT_A
	ldi tcint,4			;Reset counter
	dec seconds
EXIT_A:	out SREG,status			;Restore status
	reti


;===Subroutines===
Sub_TimerOn:
	ldi tcint,4			;Reset interrupt counter
	ldi tmp,(1<<CS02)|(1<<CS00)
	out TCCR0B,tmp			;Prescale Clock/1024
	ret

Sub_TimerOff:
	clr tmp
	out TCCR0B,tmp			;Stop timer
	ret
;=================


START:
	;Timer0 setup
	;	With the 1MHz clock prescaled by 1024, the effective rate is 976kHz
	;	976 = 244 * 4
	;	Setting the Output Compare Register to 244, the TIMER0_COMPA interrupt will fire every 250ms
	;	Count 4 interrupts to measure 1s
	ldi tmp,(1<<WGM01)		;CTC mode
	out TCCR0A,tmp
	ldi tmp,244			;TIMER0 compare value
	out OCR0A,tmp
	ldi tmp,(1<<OCIE0A)
	out TIMSK,tmp			;Enable output compare interrupt

	;Setup PORTB
	ldi	tmp,(1<<DDB0)
	out	DDRB,tmp		;Lamp output
	ldi	tmp,(1<<DDB4) | (1<<DDB3) | (1<<DDB2) | (1<<DDB1)
	out	PORTB,tmp		;Enable input pull-ups

	;Setup INT0 external interrupt
	clr	tmp 			;Trigger INT0 interrupt on low level
	out	MCUCR,tmp
	ldi	tmp,(1<<INT0)
	out	GIMSK,tmp		;Enable INT0 interrupt

	cbi	PORTB,LAMP		;Lamp off
	clr	system
	sei				;Enable global interrupts

LOOP:
	sbrs	system,MOVEMENT
	rjmp	LOOP
	sbi	PORTB,LAMP		;Lamp on
;	ldi	seconds,3
	ldi	minutes,1
	rcall	Sub_TimerOn
	TMR_LOOP:
		tst	seconds
		brne	TMR_LOOP
		tst	minutes
		breq	TST_HOURS
		dec	minutes
		ldi	seconds,60
		rjmp	TMR_LOOP
		TST_HOURS:
			tst	hours
			breq	EXIT_TMR_LOOP
			dec	hours
			ldi	minutes,59
			ldi	seconds,60
			rjmp	TMR_LOOP
	EXIT_TMR_LOOP:
	andi	system,(0<<MOVEMENT)	;Clear system flag
	cbi	PORTB,LAMP		;Lamp off
	rcall	Sub_TimerOff
	rjmp	LOOP
