.def status	= r15   ;Copy of Status Register
.def tmp	= r16   ;General register
.def tcint	= r17   ;Timer Compare Interrupt counter
.def hours	= r18   ;Hours counter
.def mins	= r19   ;Minutes counter
.def secs   = r20   ;Seconds counter
.def system	= r21   ;System flags
.def a      = r22   ;ADC(L) measurement

;System flag bits
.equ DARK   = 0     ;Dark/Light
.equ NIGHT  = 1     ;Night/Day
.equ MOTION = 2     ;Movement detected

;Hi/Lo thresholds
.equ LO     = 42    ;Low threshold
.equ HI     = 84    ;High threshold

;I/O
.equ LAMP   = PB0   ;Lamp (output)
