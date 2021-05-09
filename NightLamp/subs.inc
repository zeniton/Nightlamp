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
        tst secs        ;secs == 0? (secs decremented by ISR)
        brne TMR_LOOP
        tst mins        ;mins == 0?
        breq TST_HOURS
        dec mins
        ldi	secs,60
        rjmp TMR_LOOP
        TST_HOURS:
            tst hours   ;hrs == 0?
            breq END_TMR_LOOP
            dec hours
            ldi mins,59
            ldi secs,60
            rjmp TMR_LOOP
    END_TMR_LOOP:
    ret

MotDetOn:
    in tmp,GIMSK
    sbr tmp,INT0
    out	GIMSK,tmp       ;Enable motion detector ISR
    ret

MotDetOff:
    in tmp,GIMSK
    cbr tmp,INT0
    out GIMSK,tmp       ;Disable motion detector ISR
    ret

MeasureLight:
    in tmp,ADMUX
    sbr tmp,MUX1
    out ADMUX,tmp       ;Select ADC2
    in tmp,ADCSRA
    sbr tmp,ADSC
    out ADCSRA,tmp      ;Start conversion
    WaitForConversion:
        in tmp,ADCSRA
        sbrs tmp,ADIF
        rjmp WaitForConversion
    StopConversion:     ;Perhaps an (empty?) ISR can be used instead? #17.13.2 Bit 4 - ADIF
        in tmp,ADCSRA
        sbr tmp,ADIF    
        out ADCSRA,tmp  ;Clear ADC flag
    in a,ADCL           ;Store the measurement
    in tmp,ADCH         ;Required to do, not used
    ret

IsItDark:
    rcall MeasureLight
    ldi tmp,LO
    cp tmp,a            ;Compare measurement to lower threshold
    brge IsDark         ;Lower threshold >= measurement
    ldi tmp,HI
    cp a,tmp            ;Compare measurement to higher threshold
    brge NotDark        ;Measurement >= higher threshold
    IsDark: 
        sbr system,DARK
        rjmp Exit_IsItDark
    NotDark: 
        cbr system,DARK
    Exit_IsItDark: 
    ret

Movement:
    sbi PORTB,LAMP      ;Lamp on
    ldi mins,10
    clr hours
    clr secs
    rcall Wait          ;Wait 10 minutes
    cbi PORTB,LAMP      ;Lamp off
    cbr system,MOTION   ;Clear Motion flag
    ret

Sunrise:
    rcall MotDetOff     ;Disable motion detection
    cbi	PORTB,LAMP      ;Lamp off
    clr	system          ;Clear flags
    ret

Sunset:
    sbr system,NIGHT    ;Set Night flag
    sbi PORTB,LAMP      ;Lamp on
    ldi hours,3
    clr mins
    clr secs
    rcall Wait          ;Wait 3 hours
    cbi PORTB,LAMP      ;Lamp off
    rcall MotDetOn      ;Enable motion detection
    ret
