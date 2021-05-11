.def status = r0    ;Copy of Status Register
.def level  = r1    ;ADC(L) measurement

.def tmp	= r16   ;General register
.def tcint	= r17   ;Timer Compare Interrupt counter
.def tchi   = r18   ;Timer Counter Hi byte
.def tclo   = r19   ;Timer Counter Lo byte
.def system	= r20   ;System flags

;System flag bits
.equ DARK   = 0     ;Dark/Light
.equ NIGHT  = 1     ;Night/Day
.equ MOTION = 2     ;Movement detected

;Hi/Lo thresholds
.equ LO     = 42    ;Low threshold
.equ HI     = 84    ;High threshold

;I/O
.equ LAMP   = PB0   ;Lamp (output)
