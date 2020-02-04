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
.include "subs.inc"


RESET:
	;Setup Timer0
	;	With the 1MHz clock prescaled by 1024, the effective rate is 976kHz
	;	976 = 244 * 4
	;	Setting the Output Compare Register to 244, the TIMER0_COMPA interrupt will fire every 250ms
	;	Count 4 interrupts to measure 1s
	ldi tmp,(1<<WGM01)
	out TCCR0A,tmp      ;CTC mode
	ldi tmp,244
	out OCR0A,tmp       ;TIMER0 compare value
	ldi tmp,(1<<OCIE0A)
	out TIMSK,tmp       ;Enable output compare interrupt

	;Setup PORTB I/O
	ldi	tmp,(1<<DDB0)
	out DDRB,tmp        ;Outputs: lamp
	ldi	tmp,(1<<DDB2)
	out	PORTB,tmp       ;Enable input pull-ups

	;Setup ADC
	ldi	tmp,(1<<MUX1)	;ADC2 channel (MUX)
	out	ADMUX,tmp		;Vref = Vcc (REFSn)
	ldi	tmp,(1<<ADEN)
	out	ADCSRA,tmp      ;Enable ADC

    ;Set ADC thresholds
    ldi lo,42
    ldi hi,84

	;Setup INT0 external interrupt (Motion Detector)
	clr	tmp
	out	MCUCR,tmp       ;Trigger INT0 interrupt on low level
	ldi	tmp,(1<<INT0)
	out	GIMSK,tmp       ;Enable INT0 interrupt

	cbi	PORTB,LAMP	    ;Lamp off
	clr	system          ;Clear flags
    sei                 ;Enable global interrupts

LOOP:
    rcall MeasureLight
    sbrc system,DARK
    rjmp IS_DARK

NOT_DARK:
    sbrs system,NIGHT
    rjmp LOOP
    
    ;Sunrise
    in tmp,GIMSK
    cbr tmp,INT0
    out GIMSK,tmp       ;Disable motion detector
    cbr system,MOTION   ;Unset Motion flag
    cbr system,NIGHT    ;Unset Night flag
	cbi	PORTB,LAMP	    ;Lamp off
    rjmp LOOP

IS_DARK:
    sbrs system,NIGHT
    rjmp IS_NIGHT
    
    ;Sunset
    sbr system,NIGHT    ;Set Night flag
	sbi PORTB,LAMP	    ;Lamp on
	ldi hours,3
    clr mins
    clr secs
    rcall Wait          ;Wait 3 hours
	cbi PORTB,LAMP	    ;Lamp off
    rjmp LOOP

IS_NIGHT:
    in tmp,GIMSK
    sbr tmp,INT0
	out	GIMSK,tmp       ;Enable motion detector
    sbrs system,MOTION  ;Set Motion flag
    rjmp LOOP

    ;Motion detected
	sbi PORTB,LAMP	    ;Lamp on
	ldi mins,10
    clr hours
    clr secs
    rcall Wait          ;Wait 10 minutes
	cbi PORTB,LAMP	    ;Lamp off
    cbr system,MOTION   ;Unset Motion flag
    rjmp LOOP
