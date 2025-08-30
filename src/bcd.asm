;-----------------------------------------------------------------------------
; Paul Wasson - 2025
;-----------------------------------------------------------------------------
; BCD numbers
;
;   A few functions for manipulating large BCD numbers
;
; Numbers stored MSB to LSB
; Numbered passed in using LSB.  So 7, 15, 23, etc
;

BCD_NUM_SIZE    =   8      ; 16 digit numbers
BCD_NUM_COUNT   =   16
TILE_FONT_0     =   $30
temp            :=  A1

;-----------------------------------------------------------------------------
; BCD set
;
;   x <- A
;
;   Set number X to the BCD value passed in A for the first byte and
;   zero out the rest of the number
;-----------------------------------------------------------------------------
.proc bcdSet

    ldy         #BCD_NUM_SIZE-1
    sta         num_array,x         ; LSB = last byte of array
    lda         #0
loop:
    dex
    sta         num_array,x
    dey
    bne         loop
    rts

.endproc


;-----------------------------------------------------------------------------
; BCD add
;
;   x <- x+y
;
;-----------------------------------------------------------------------------
.proc bcdAdd

    sed         ; set BCD mode
    clc

    lda         #BCD_NUM_SIZE
    sta         temp

loop:
    lda         num_array,x
    adc         num_array,y
    sta         num_array,x
    dex
    dey
    dec         temp
    bne         loop

    bcc         :+
    brk                         ; Overflow -- FIXME: set to all 9s
:

    cld                         ; clear BCD mode for normal operation
    rts

.endproc

;-----------------------------------------------------------------------------
; BCD copy
;
;   x <- y
;
;-----------------------------------------------------------------------------
.proc bcdCopy

    lda         #BCD_NUM_SIZE
    sta         temp

loop:
    lda         num_array,x
    sta         num_array,y
    dex
    dey
    dec         temp
    bne         loop
    rts

.endproc


;-----------------------------------------------------------------------------
; drawNum
;   Set tileX and tileY before calling
;   Pass offset into BCD array in A
;-----------------------------------------------------------------------------
;   Display in 4 or 5 characters
;                       0 ..                   9,999          : ____  (2 bytes = 4 digits)
;                  10,000 ..                 999,999          : ___K  (3 bytes = 6 digits)
;               1,000,000 ..           9,999,999,999          : ____M (5 bytes = 10 digits)
;          10,000,000,000 ..         999,999,999,999          : ___B  (6 bytes = 12 digits)
;       1,000,000,000,000 ..   9,999,999,999,999,999          : ____T (8 bytes = 16 digits)
;
;              9,999,999,999,999,999 suffix | 1 byte? | skip last? | max output size
; MSB = 7   ->                    00        | yes     |            | 2
; MSB = 6   ->                 1 100        |         |            | 4
; MSB = 5   ->               221     K      |         | yes        | 4
; MSB = 4   ->            33         M      | yes     |            | 3
; MSB = 3   ->         4 433         M      |         |            | 5
; MSB = 2   ->       554             B      |         | yes        | 4
; MSB = 1   ->    66                 T      | yes     |            | 3
; MSB = 0   -> 7 766                 T      |         |            | 5
;
; output size = max or max - 1 if leading zero
;
; algo:
;   find msb (first byte)
;   display upper nibble of first byte if not zero
;   display lower nibble of first byte
;   if 1 byte skip to display suffix
;   display upper nibble of second byte
;   display lower nibble of second byte if not half-byte (not 2 or 5)
;   display suffix if any (not 6 or 7)

.proc drawNum

    and         #$F8            ; -7 (assuming aligned)
    tax
    ; find msb
    stx         startIndex
    ldy         #BCD_NUM_SIZE-1
msbLoop:
    lda         num_array,x
    bne         :+
    inx
    dey
    bne         msbLoop
:
    stx         index
    txa
    sec
    sbc         startIndex
    sta         suffix

    ; first digit
    lda         num_array,x
    lsr
    lsr
    lsr
    lsr
    beq         doneDigit
    ora         #TILE_FONT_0
    sta         bgTile
    jsr         DHGR_DRAW_7X8
    inc         tileX
    inc         tileX
doneDigit:

    ; second digit
    ldx         index
    lda         num_array,x
    and         #$0f
    ora         #TILE_FONT_0
    sta         bgTile
    jsr         DHGR_DRAW_7X8
    inc         tileX
    inc         tileX

    ; third digit
    ldy         suffix
    lda         flagOneByte,y
    bne         drawSuffix
    inc         index
    ldx         index
    lda         num_array,x
    lsr
    lsr
    lsr
    lsr
    ora         #TILE_FONT_0
    sta         bgTile
    jsr         DHGR_DRAW_7X8
    inc         tileX
    inc         tileX

    ; fourth digit
    ldy         suffix
    lda         flagSkipLast,y
    bne         drawSuffix
    ldx         index
    lda         num_array,x
    and         #$0f
    ora         #TILE_FONT_0
    sta         bgTile
    jsr         DHGR_DRAW_7X8
    inc         tileX
    inc         tileX

drawSuffix:
    ldy         suffix
    lda         suffixTile,y
    beq         :+
    sta         bgTile
    jsr         DHGR_DRAW_7X8
    inc         tileX
    inc         tileX

:
    rts

startIndex:     .byte       0
index:          .byte       0
suffix:         .byte       0

flagOneByte:    .byte       0,1,0,0,1,0,0,1
flagSkipLast:   .byte       0,0,1,0,0,1,0,0
;                             T   T   B   M   M   K
suffixTile:     .byte       $14,$14,$02,$0D,$0D,$0B,$00,$00

.endproc


.align 256
num_array:
    .byte       $99,$99,$99,$99,$99,$99,$99,$99
    .byte       $99,$99,$99,$99,$99,$99,$99,$99
    .byte       $99,$99,$99,$99,$99,$99,$99,$99
    .byte       $99,$99,$99,$99,$99,$99,$99,$99
    .byte       $99,$99,$99,$99,$99,$99,$99,$99
    .byte       $99,$99,$99,$99,$99,$99,$99,$99
    .byte       $99,$99,$99,$99,$99,$99,$99,$99
    .byte       $99,$99,$99,$99,$99,$99,$99,$99
    .byte       $99,$99,$99,$99,$99,$99,$99,$99
    .byte       $99,$99,$99,$99,$99,$99,$99,$99
    .byte       $99,$99,$99,$99,$99,$99,$99,$99
    .byte       $99,$99,$99,$99,$99,$99,$99,$99
    .byte       $99,$99,$99,$99,$99,$99,$99,$99
    .byte       $99,$99,$99,$99,$99,$99,$99,$99
    .byte       $99,$99,$99,$99,$99,$99,$99,$99
    .byte       $99,$99,$99,$99,$99,$99,$99,$99
