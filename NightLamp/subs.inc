TimerOn:
    ldi tcint,4			;Reset interrupt counter
    ldi tmp,(1<<CS02)|(1<<CS00)
    out TCCR0B,tmp		;Prescale Clock by 1024
    ret

TimerOff:
    clr tmp
    out TCCR0B,tmp		;Stop timer
    ret

Wait:
    rcall TimerOn
    TMR_LOOP:
        tst tclo            ;tclo decremented by ISR every second
        brne TMR_LOOP       ;Wait more...
        tst tchi
        breq END_TMR_LOOP   ;Timer run out
        dec tchi            ;Transfer 1 from HI byte to LO byte
        ldi tclo,0xFF
        rjmp TMR_LOOP
    END_TMR_LOOP:
        rcall TimerOff
        ret

MotDetOn:
    in tmp,GIMSK
    sbr tmp,(1<<INT0)
    out	GIMSK,tmp       ;Enable motion detector ISR
    ret

MotDetOff:
    in tmp,GIMSK
    cbr tmp,(1<<INT0)
    out GIMSK,tmp       ;Disable motion detector ISR
    ret

MeasureLight:
    sbi ADMUX,MUX1      ;Select ADC2
    sbi ADCSRA,ADSC     ;Start conversion
    WaitForConversion:
        in tmp,ADCSRA
        sbrs tmp,ADIF
        rjmp WaitForConversion
    sbi ADCSRA,ADIF     ;Clear ADC flag to stop conversion
    in level,ADCL       ;Store the measurement
    in tmp,ADCH         ;Required to do, not used
    ret

IsItDark:
    rcall MeasureLight
    ldi tmp,LO
    cp tmp,level        ;Compare measurement to lower threshold
    brge IsDark         ;Lower threshold >= measurement
    ldi tmp,HI
    cp level,tmp        ;Compare measurement to higher threshold
    brge NotDark        ;Measurement >= higher threshold
    IsDark: 
        sbr system,(1<<DARK)
        rjmp Exit_IsItDark
    NotDark: 
        cbr system,(1<<DARK)
    Exit_IsItDark: 
    ret

Movement:
    sbi PORTB,LAMP          ;Lamp on
    ldi tchi,0x02
    ldi tclo,0x58           ;10min * 60sec/min = 600sec = 0x0258
    rcall Wait              ;Wait 10 minutes
    cbi PORTB,LAMP          ;Lamp off
    cbr system,(1<<MOTION)  ;Clear Motion flag
    ret

Sunrise:
    rcall MotDetOff         ;Disable motion detection
    cbi	PORTB,LAMP          ;Lamp off
    clr	system              ;Clear flags
    ret

Sunset:
    sbr system,(1<<NIGHT)   ;Set Night flag
    sbi PORTB,LAMP          ;Lamp on
    ldi tchi,0x2A
    ldi tclo,0x30           ;3hr * 60min/hr * 60sec/min = 10800sec = 0x2A30
    rcall Wait              ;Wait 3 hours
    cbi PORTB,LAMP          ;Lamp off
    rcall MotDetOn          ;Enable motion detection
    ret
