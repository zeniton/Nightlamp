.org 0x0000
rjmp SETUP                  ;0x0000 RESET
rjmp INT0_ISR               ;0x0001 INT0
reti                        ;0x0002 PCINT0
reti                        ;0x0003 TIMER1_COMPA
reti                        ;0x0004 TIMER1_OVF
reti                        ;0x0005 TIMER0_OVF
reti                        ;0x0006 EE_RDY
reti                        ;0x0007 ANA_COMP
reti                        ;0x0008 ADC
reti                        ;0x0009 TIMER1_COMPB
rjmp TIMER0_COMPA_ISR       ;0x000A TIMER0_COMPA
reti                        ;0x000B TIMER0_COMPB
reti                        ;0x000C WDT
reti                        ;0x000D USI_START
reti                        ;0x000E USI_OVF

INT0_ISR:                   ;Something moved
    in status,SREG          ;Save status
    sbr	system,(1<<MOTION)  ;Set Motion flag
    out SREG,status         ;Restore status
    reti

TIMER0_COMPA_ISR:	
    in status,SREG          ;Save status
    dec tcint               ;Interrupt counter
    brne EXIT_ISR
    ldi tcint,4             ;Reset counter
    dec secs
EXIT_ISR:
    out SREG,status         ;Restore status
    reti
