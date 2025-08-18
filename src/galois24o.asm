; Copied from https://github.com/bbbradsmith/prng_6502
;
; 6502 LFSR PRNG - 24-bit
; Brad Smith, 2019
; http://rainwarrior.ca
;

; A 24-bit Galois LFSR

; Possible feedback values that generate a full 16777215 step sequence:
; $1B = %00011011
; $87 = %10000111
; $B1 = %10110001
; $DB = %11011011
; $F5 = %11110101

; $1B is chosen

; overlapped
; 73 cycles
; 38 bytes

.proc galois24o

	; rotate the middle byte left
	ldy seed+1 ; will move to seed+2 at the end
	; compute seed+1 ($1B>>1 = %1101)
	lda seed+2
	lsr
	lsr
	lsr
	lsr
	sta seed+1 ; reverse: %1011
	lsr
	lsr
	eor seed+1
	lsr
	eor seed+1
	eor seed+0
	sta seed+1
	; compute seed+0 ($1B = %00011011)
	lda seed+2
	asl
	eor seed+2
	asl
	asl
	eor seed+2
	asl
	eor seed+2
	sty seed+2 ; finish rotating byte 1 into 2
	sta seed+0
	rts

.endproc