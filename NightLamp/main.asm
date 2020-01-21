;************************************
; written by: Stoffel van Aswegen 
; for AVR: ATTiny85
; clock frequency: 1 MHz
; Function: Night light controller with motion detection
;	Ambient light level measured with LDR
;	Switch lamp on for 2-3hrs at sunset
;	Switch lamp on for 10mins when dark & motion detected and lamp is off
;	LDR circuit only switched on during measuring
       
.nolist
.include "tn85def.inc"
.list

.include "defs.inc"
.include "isr.inc"


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
	ldi	tmp,(1<<DDB2) | (1<<DDB1)
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

	cbi	PORTB,LAMP_IO	;Lamp off
	clr	system
	sei                 ;Enable global interrupts

LOOP:
	sbrs system,MOTION
	rjmp LOOP
	sbi PORTB,LAMP_IO	;Lamp on
	ldi hours,3
	rcall Sub_TimerOn
	TMR_LOOP:
		tst secs        ;seconds decremented by ISR
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
	cbr system,MOTION   ;Clear system flag
	cbi PORTB,LAMP_IO	;Lamp off
	rcall Sub_TimerOff
	rjmp LOOP

