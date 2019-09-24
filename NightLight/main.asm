;************************************
; written by: Stoffel van Aswegen 
; date: 2019-08-17
; version: 0.0
; file saved as: NightLight.asm
; for AVR: attiny85
; clock frequency: 1 MHz
; Function: Night light controller 
;	with motion detection
;
;                                         Vcc
;                                          ^
;                          ATTiny85        |
;                         -----------      |
;                         | 1     8 |-------     ----------
;                         |         | INT0      | Motion   |
;                         | 2     7 |-----------|          |
;         (Day/night)     |         |           | Detector |
;         ----------------| 3     6 |           -----------
;         |               |         |      |\|
;         |       --------| 4     5 |------| |-----/\/\/---
;         |       |       -----------      |/|       R    |
;         |       |                        LED            |
;         |       |                                       |
;         |       |                                       |
;         V       V                                       V

.nolist
.include "tn85def.inc"
.list

;==============
; Declarations:
;.def	var = Rnn
;.equ	var = K
.def status		= r15		;Copy of Status Register
.def tmp		= r16		;General accumulator
.def tcint		= r17		;Timer Compare Interrupt counter
.def seconds	= r18		;Seconds counter
.def minutes	= r19		;Minutes counter
.def hours		= r20		;Hours counter

.equ LAMP		= PB0

.org 0x0000
rjmp START				;0x0000 RESET
reti					;0x0001 INT0
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


ISR_A:					;Timer Output Compare
	in status,SREG		;Save status
	dec tcint
	brne EXIT_ISR_A
	ldi tcint,4			;Reset counter
	dec seconds
EXIT_ISR_A:
	out SREG,status		;Restore status
	reti


START:
	;PORTB setup
	ldi tmp,(1<<LAMP)	;Lamp output
	out DDRB,tmp
	com tmp				;1's compliment to flip bits
	out PORTB,tmp		;Enable input pull-ups
	
	;Timer0 setup
	;	With the 1MHz clock prescaled by 1024, the effective rate is 976kHz
	;	976 = 244 * 4
	;	Setting the Output Compare Register to 244, the TIMER0_COMPA interrupt will fire every 250ms
	;	Count 4 interrupts to measure 1s
	ldi tmp,(1<<WGM01)	;CTC mode
	out TCCR0A,tmp
	ldi tmp,244			;TIMER0 compare value
	out OCR0A,tmp
	ldi tmp,(1<<OCIE0A)	;Enable output compare interrupt
	out TIMSK,tmp

	;Setup timing counters
	ldi tcint,4
	ldi seconds,1
	sei					;Enable global interrupts

	;Prescale clock (will also start it)
	ldi tmp,(1<<CS02)|(1<<CS00)
	out TCCR0B,tmp		;Clock/1024: CS0[2:0] = 101

LOOP:
	tst seconds			;=0?
	brne LOOP
	sbi PINB,LAMP		;Toggle LAMP
	ldi seconds,1		;Restart the counter
	rjmp LOOP
