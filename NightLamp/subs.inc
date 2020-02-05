TimerOn:
	ldi tcint,4			;Reset interrupt counter
	ldi tmp,(1<<CS02)|(1<<CS00)
	out TCCR0B,tmp		;Prescale Clock/1024
	ret

TimerOff:
	clr tmp
	out TCCR0B,tmp		;Stop timer
	ret

Wait:
	rcall TimerOn
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
			breq END_TMR_LOOP
			dec hours
			ldi mins,59
			ldi secs,60
			rjmp TMR_LOOP
	END_TMR_LOOP:
    ret

MeasureLight:
    in tmp,ADCSRA
    sbr tmp,ADSC
    out ADCSRA,tmp      ;Start conversion
    WaitForConversion:
        in tmp,ADCSRA
        sbrs tmp,ADIF
        rjmp WaitForConversion
    in a,ADCL           ;Store the measurement
    in tmp,ADCH         ;Required to do, not used
    StopADC:            ;Perhaps an empty ISR can be used instead? #17.13.2 Bit 4 - ADIF
        in tmp,ADCSRA
        sbr tmp,ADIF    
        out ADCSRA,tmp  ;Clear ADC flag
    ret

IsItDarkYet:
    rcall MeasureLight
    ldi tmp,LO
    cp tmp,a            ;Compare measurement to lower threshold
    brge IsDark         ;Lower threshold >= mesaurement
    ldi tmp,HI
    cp a,tmp            ;Compare measurement to higher threshold
    brge IsNotDark      ;Measurement >= higher threshold
    IsDark: 
        sbr system,DARK
    rjmp Exit_IsItDarkYet
    IsNotDark: 
        cbr system,DARK
    Exit_IsItDarkYet: 
    ret
