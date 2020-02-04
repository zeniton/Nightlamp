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

    ;Read ADC output & determine Dark/Light
    in al,ADCL
    in ah,ADCH
    cp lo,al            ;Compare measurement to lower threshold
    brge IsDark         ;Lower threshold >= mesaurement
    cp al,hi            ;Compare measurement to higher threshold
    brge IsNotDark      ;Measurement >= higher threshold
    IsDark: sbr system,DARK
    rjmp StopADC
    IsNotDark: cbr system,DARK
    StopADC:
        in tmp,ADCSRA
        sbr tmp,ADIF
        out ADCSRA,tmp      ;Clear ADC flag
    ret
