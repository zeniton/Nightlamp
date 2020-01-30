.def status	= r15	;Copy of Status Register
.def tmp	= r16	;General register
.def tcint	= r17	;Timer Compare Interrupt counter
.def hours	= r18	;Hours counter
.def mins	= r19	;Minutes counter
.def secs   = r20	;Seconds counter
.def system	= r21	;System flags

;System flag bits
.equ DARK   = 0     ;Outcome of light measurement
.equ NIGHT  = 1
.equ MOTION = 2

;I/O
.equ LAMP       = PB0	;Lamp (output)
