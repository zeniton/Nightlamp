.def status	= r15	;Copy of Status Register
.def tmp	= r16	;General register
.def tcint	= r17	;Timer Compare Interrupt counter
.def hours	= r18	;Hours counter
.def mins	= r19	;Minutes counter
.def secs   = r20	;Seconds counter
.def system	= r21	;System flags
.def al     = r22   ;ADC L
.def ah     = r23   ;ADC H
.def lo     = r24   ;Low threshold
.def hi     = r25   ;High threshold

;System flag bits
.equ DARK   = 0     ;Outcome of light measurement
.equ NIGHT  = 1     ;Night/Day
.equ MOTION = 2     ;Movement detected

;I/O
.equ LAMP       = PB0	;Lamp (output)
