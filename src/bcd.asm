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
;   x <- A * 10^(Y*2)
;
;   Set number X to the BCD value passed in A for the Y-th byte and
;   zero out the rest of the number
;-----------------------------------------------------------------------------
.proc bcdSet

    sta         value       ; rember value
    sty         index       ; and index
    ldy         #0
    lda         #0

loop:
    cpy         index
    bne         continue
    lda         value
continue:
    sta         num_array,x
    lda         #0
    dex
    iny
    cpy         #8
    bne         loop

    rts

value:          .byte   0
index:          .byte   0

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
; BCD sub
;
;   x <- x-y
;
;-----------------------------------------------------------------------------
.proc bcdSub

    sed         ; set BCD mode
    sec

    lda         #BCD_NUM_SIZE
    sta         temp

loop:
    lda         num_array,x
    sbc         num_array,y
    sta         num_array,x
    dex
    dey
    dec         temp
    bne         loop

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
    lda         num_array,y
    sta         num_array,x
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
;              9,999,999,999,999,999 suffix | 1 byte? | skip last? | padding to 5
; MSB = 7   ->                    00        | yes     |            | skip_first+3
; MSB = 6   ->                 1 100        |         |            | skip_first+1
; MSB = 5   ->               221     K      |         | yes        | skip_first+1
; MSB = 4   ->            33         M      | yes     |            | skip_first+2
; MSB = 3   ->         4 433         M      |         |            | skip_first
; MSB = 2   ->       554             B      |         | yes        | skip_first+1
; MSB = 1   ->    66                 T      | yes     |            | skip_first+2
; MSB = 0   -> 7 766                 T      |         |            | skip_first
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

.proc drawArrayNum

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

    lda         #1
    sta         skipFirst       ; guess skip first digit, clear below if wrong
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
    lda         #0
    sta         skipFirst
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
    ldy         suffix
    lda         padding,y
    clc
    adc         skipFirst
    sta         index
    beq         done

    lda         #$20            ; space
    sta         bgTile
paddingLoop:
    jsr         DHGR_DRAW_7X8
    inc         tileX
    inc         tileX
    dec         index
    bne         paddingLoop

done:
    rts

startIndex:     .byte       0
index:          .byte       0
suffix:         .byte       0
skipFirst:      .byte       0

flagOneByte:    .byte       0,1,0,0,1,0,0,1
flagSkipLast:   .byte       0,0,1,0,0,1,0,0
;                             T   T   B   M   M   K
suffixTile:     .byte       $14,$14,$02,$0D,$0D,$0B,$00,$00
padding:        .byte       0,2,1,0,2,1,1,3
.endproc


;-----------------------------------------------------------------------------
; Draw BCD Byte
;   BCD number in bcdValue
;-----------------------------------------------------------------------------
.proc drawBCDByte
    lda         bcdValue
    and         #$f0
    beq         nextDigit
    lsr
    lsr
    lsr
    lsr
    ora         #TILE_FONT_0
    sta         bgTile
    jsr         DHGR_DRAW_7X8
    inc         tileX
    inc         tileX
nextDigit:
    lda         bcdValue
    and         #$0f
    ora         #TILE_FONT_0
    sta         bgTile
    jsr         DHGR_DRAW_7X8
    inc         tileX
    inc         tileX
    rts
.endproc

;-----------------------------------------------------------------------------
; Global
;-----------------------------------------------------------------------------

bcdValue:           .byte   0
bcdIndex0:          .byte   0
bcdIndex1:          .byte   0
bcdIndex2:          .byte   0

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
