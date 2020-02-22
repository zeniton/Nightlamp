;************************************
; written by: Stoffel van Aswegen 
; for AVR: ATTiny85
; clock frequency: 1 MHz
; Function: Night light controller with motion detection
;   Ambient light level measured with LDR
;   Switch lamp on for 2-3hrs at sunset
;   Switch lamp on for 10mins when dark & motion detected and lamp is off
       
.nolist
.include "tn85def.inc"
.list

.include "defs.inc"
.include "isr.inc"
.include "subs.inc"


SETUP:
    ;Setup Timer0
    ;   With the 1MHz clock prescaled by 1024, the effective rate is 976kHz
    ;   976 = 244 * 4
    ;   Setting the Output Compare Register to 244, the TIMER0_COMPA interrupt will fire every 250ms
    ;   Count 4 interrupts to measure 1s
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

    ;Setup INT0 external interrupt (Motion Detector)
    clr	tmp
    out	MCUCR,tmp       ;Trigger INT0 interrupt on low level

    cbi	PORTB,LAMP      ;Lamp off
    clr	system          ;Clear flags
    sei                 ;Enable global interrupts

LOOP:
    sbrc system,MOTION
    rcall Movement

    rcall IsItDark
    sbrs system,DARK
    rjmp NOT_DARK

IS_DARK:
    sbrs system,NIGHT
    rcall Sunset
    rjmp LOOP

NOT_DARK:
    sbrc system,NIGHT   
    rjmp Sunrise
    rjmp LOOP
    
