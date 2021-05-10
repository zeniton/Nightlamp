;************************************
; written by: Stoffel van Aswegen 
; for AVR: ATTiny85
; clock frequency: 1 MHz
; Function: Night light controller with motion detection
;   Ambient light level measured with LDR
;   Switch lamp on for 3hrs at sunset
;   Switch lamp on for 10mins when dark & motion detected
       
.nolist
.include "tn85def.inc"
.list

.include "defs.inc"
.include "isr.inc"
.include "subs.inc"


SETUP:
    ;Initialize the stack
    ldi tmp,low(RAMEND)
    out spl,tmp
    ldi tmp,high(RAMEND)
    out sph,tmp

    ;Setup Timer0
    ;   With the 1MHz clock prescaled by 1024, the effective rate is 976Hz
    ;   976 = 244 * 4
    ;   Setting the Output Compare Register to 244, the TIMER0_COMPA interrupt will fire every 250ms
    ;   Count 4 interrupts to measure 1s
    ldi tmp,(1<<WGM01)
    out TCCR0A,tmp      ;CTC mode
    ldi tmp,244
    out OCR0A,tmp       ;TIMER0 compare value
    ldi tmp,(1<<OCIE0A)
    out TIMSK,tmp       ;Enable output compare interrupt

    ;Setup PORTB digital I/O
    sbi DDRB,DDB0       ;Outputs: lamp
    sbi PORTB,DDB2      ;Enable input pull-up on PB2 (motion detector)

    ;Setup INT0 external interrupt (Motion Detector)
    clr	tmp
    out	MCUCR,tmp       ;Trigger INT0 interrupt on low level

    cbi	PORTB,LAMP      ;Lamp off
    clr	system          ;Clear flags
    rcall MotDetOff     ;Disable Motion Detector

    sei                 ;Enable global interrupts

LOOP:
    sbrc system,MOTION  ;Did something move?
    rcall Movement

    rcall IsItDark
    sbrs system,DARK
    rjmp NOT_DARK

IS_DARK:
    sbrs system,NIGHT   ;Is it Night?
    rcall Sunset
    rjmp LOOP

NOT_DARK:
    sbrc system,NIGHT   ;Is it Day?
    rjmp Sunrise
    rjmp LOOP
