;-----------------------------------------------------------------------------
; Paul Wasson - 2025
;-----------------------------------------------------------------------------
; Pickman
;   Mining game

;------------------------------------------------
; Constants
;------------------------------------------------

.include "defines.asm"
.include "macros.asm"

;------------------------------------------------
; Constants
;------------------------------------------------

DELTA_H                 = 4
DELTA_V                 = 2

WINDOW_LEFT             = DELTA_H                       ; 1 space left
THRESHOLD_LEFT          = WINDOW_LEFT + DELTA_H*2       ; 2 space buffer
WINDOW_RIGHT            = 40-DELTA_H                    ; 1 space right
THRESHOLD_RIGHT         = WINDOW_RIGHT - DELTA_H*2      ; 2 space buffer
WINDOW_TOP              = DELTA_V*2                     ; 2 spaces top
THRESHOLD_TOP           = WINDOW_TOP + DELTA_V*2        ; 2 space buffer
WINDOW_BOTTOM           = 24 - DELTA_V                  ; 1 space bottom
THRESHOLD_BOTTOM        = WINDOW_BOTTOM - DELTA_V*2     ; 2 space buffer

MAP_WINDOW_WIDTH        = (WINDOW_RIGHT - WINDOW_LEFT) / DELTA_H
MAP_WINDOW_HEIGHT       = (WINDOW_BOTTOM - WINDOW_TOP) / DELTA_V

MAP_WIDTH               = 16
MAP_HEIGHT              = 128
MAP_SIZE                = MAP_WIDTH * MAP_HEIGHT

MAP_LEFT                = 0
MAP_RIGHT               = MAP_WIDTH - MAP_WINDOW_WIDTH
MAP_TOP                 = 0
MAP_BOTTOM              = MAP_WIDTH * (MAP_HEIGHT - MAP_WINDOW_HEIGHT)  ; 16 bit value
MAP_BOTTOM0             = <MAP_BOTTOM
MAP_BOTTOM1             = >MAP_BOTTOM
TILE_EMPTY              = 0
TILE_GRASS              = 1
TILE_DIRT               = 2
TILE_ROCK               = 4
TILE_GOLD               = 6
TILE_DIAMOND            = 8
TILE_PICKMAN_RIGHT1     = 11
TILE_PICKMAN_RIGHT2     = 12
TILE_PICKMAN_LEFT1      = 13
TILE_PICKMAN_LEFT2      = 14
TILE_SHOP_LEFT          = 15
TILE_SHOP_RIGHT         = 16
TILE_BRICK              = 17
TILE_DOOR               = 18

SEED0                   = $ab
SEED1                   = $cd
SEED2                   = $ef

; BCD numbers
BCD_MONEY               = 8*1-1
BCD_ROCK_VALUE          = 8*2-1
BCD_GOLD_VALUE          = 8*3-1
BCD_DIAMOND_VALUE       = 8*4-1

BCD_MONEY_INIT          = $00
BCD_ROCK_VALUE_INIT     = $01
BCD_GOLD_VALUE_INIT     = $05
BCD_DIAMOND_VALUE_INIT  = $20

;------------------------------------------------

.segment "CODE"
.org    $6000

;=============================================================================
; Main program
;=============================================================================

; Main
;------------------------------------------------
.proc main

    ; set seed (must not be 0)
    lda         #SEED0
    sta         seed
    lda         #SEED1
    sta         seed+1
    lda         #SEED2
    sta         seed+2

    jsr         genMap          ; generate map
    jsr         clearMapCache   ; must be called after generating a map

    lda         #$00            ; Clear both pages
    sta         drawPage
    jsr         clearScreen

    lda         #$20            ; Clear both pages
    sta         drawPage
    jsr         clearScreen

    jsr         dhgrInit        ; Turn on dhgr

    lda         #2
    sta         updateInfo      ; Update info (both pages)

gameLoop:

    ;-----------------------
    ; Page Flip
    ;-----------------------
    jsr         flipPage        ; display final drawing from last iteration of game loop

    ;-----------------------
    ; update screen
    ;-----------------------
    jsr         drawScreen

    ;-----------------------
    ; check for falling
    ;-----------------------
    ;jsr         checkBelow
    ;cmp         #TILE_EMPTY
    ;bne         playerInput
    ;jsr         moveDown
    ;jmp         gameLoop

playerInput:
    ;-------------------
    ; Input
    ;-------------------

    ; check user input
    lda         KBD
    bpl         gameLoop
    sta         KBDSTRB

    ; Movement
    ;----------------------
    cmp         #KEY_RIGHT
    bne         :+
    jsr         moveRight
    jmp         gameLoop
:
    cmp         #KEY_LEFT
    bne         :+
    jsr         moveLeft
    jmp         gameLoop
:
    cmp         #KEY_UP
    bne         :+
    jsr         moveUp
    jmp         gameLoop
:
    cmp         #KEY_DOWN
    bne         :+
    jsr         moveDown
    jmp         gameLoop
:

    cmp         #KEY_D
    bne         :+
    jsr         scrollRight
    jmp         gameLoop
:

    cmp         #KEY_A
    bne         :+
    jsr         scrollLeft
    jmp         gameLoop
:

    cmp         #KEY_S
    bne         :+
    jsr         scrollDown
    jmp         gameLoop
:

    cmp         #KEY_W
    bne         :+
    jsr         scrollUp
    jmp         gameLoop
:

    ;
    ; Exit
    ;

    cmp         #KEY_ESC
    bne         :+

    jsr    inline_print
    StringCR "Press CTRL-Y for ProDOS program launcher"

    ; Set ctrl-y vector
    lda         #$4c        ; JMP
    sta         $3f8
    lda         #<quit
    sta         $3f9
    lda         #>quit
    sta         $3fa

    bit         TXTSET
    jmp         MONZ        ; enter monitor
:

    ;
    ; Default
    ;
    jmp     gameLoop

 .endproc


;-----------------------------------------------------------------------------
; Player Movement
;   If before threshold
;       move on screen
;   else if can scroll
;       scroll
;   else if not on the edge
;       move on screen
;   else
;       can't move
;-----------------------------------------------------------------------------

.proc moveRight
    ; set direction
    lda         #TILE_PICKMAN_RIGHT1
    sta         playerTile

    ; check if move on screen
    lda         playerX
    clc
    adc         #DELTA_H
    cmp         #THRESHOLD_RIGHT
    bcc         setX

    ; check if scroll
    lda         mapOffsetX0
    cmp         #MAP_RIGHT
    beq         checkEdge
    inc         mapOffsetX0
    rts                         ; okay - scroll

checkEdge:
    ; check if on edge
    lda         playerX
    clc
    adc         #DELTA_H
    cmp         #WINDOW_RIGHT
    bcc         setX
    rts                         ; failed!

setX:
    sta         playerX
    rts                         ; okay - move on screen
.endproc

.proc moveLeft
    ; set direction
    lda         #TILE_PICKMAN_LEFT1
    sta         playerTile

    ; check if move on screen
    lda         playerX
    sec
    sbc         #DELTA_H
    cmp         #THRESHOLD_LEFT
    bcs         setX

    ; check if scroll
    lda         mapOffsetX0
    beq         checkEdge
    dec         mapOffsetX0
    rts                         ; okay - scroll

checkEdge:
    ; check if on edge
    lda         playerX
    sec
    sbc         #DELTA_H
    cmp         #WINDOW_LEFT
    bcs         setX
    rts                         ; failed
setX:
    sta         playerX         ; okay - move on screen
    rts
.endproc

.proc moveUp
    lda         playerY
    sec
    sbc         #DELTA_V
    cmp         #WINDOW_TOP
    bcs         :+
    rts
:
    sta         playerY
    rts
.endproc

.proc moveDown
    lda         playerY
    clc
    adc         #DELTA_V
    cmp         #WINDOW_BOTTOM
    bcc         :+
    rts
:
    sta         playerY
    rts
.endproc


;-----------------------------------------------------------------------------
; Scrolling (map movement)
;   offsetX0 increments by 1
;       range: MAP_LEFT <= offsetX0 < MAP_RIGHT
;   (offsetX1,offsetX0) increments by MAP_WIDTH
;       range: WINDOW_TOP  <= playerY < WINDOW_BOTTOM
;   ignore movements out of range
;-----------------------------------------------------------------------------

.proc scrollRight
    lda         mapOffsetX0
    cmp         #MAP_RIGHT
    bne         okay
    rts                         ; z set
okay:
    inc         mapOffsetX0
    lda         #1              ; z clear
    rts
.endproc

.proc scrollLeft
    lda         mapOffsetX0
    bne         okay
    rts                         ; z set
okay:
    dec         mapOffsetX0
    lda         #1              ; z clear
    rts
.endproc

; FIXME: no bounds check
.proc scrollDown
    lda         mapOffsetY1
    cmp         #MAP_BOTTOM1
    bne         okay
    lda         mapOffsetY0
    cmp         #MAP_BOTTOM0
    bne         okay
    rts                         ; bottom of map (Z set)
okay:
    lda         mapOffsetY0
    clc
    adc         #MAP_WIDTH
    sta         mapOffsetY0
    lda         mapOffsetY1
    adc         #0
    sta         mapOffsetY1
    lda         #1              ; Z clear
    rts
.endproc

.proc scrollUp
    lda         mapOffsetY1
    bne         okay
    lda         mapOffsetY0
    bne         okay
    rts                         ; top of map
okay:
    lda         mapOffsetY0
    sec
    sbc         #MAP_WIDTH
    sta         mapOffsetY0
    lda         mapOffsetY1
    sbc         #0
    sta         mapOffsetY1
    lda         #1              ; Z clear
    rts
.endproc

;-----------------------------------------------------------------------------
; Init double hi-res
;-----------------------------------------------------------------------------

.proc dhgrInit
    sta         TXTCLR      ; Graphics
    sta         HIRES       ; Hi-res
    sta         MIXCLR      ; Full Screen
    sta         LOWSCR      ; Display page 1
    sta         DHIRESON    ; Annunciator 2 On
    sta         SET80VID    ; 80 column on
    rts
.endproc

;-----------------------------------------------------------------------------
; DHGR clear screen
;-----------------------------------------------------------------------------

.proc clearScreen
    lda         #$00
    sta         screenPtr0
    clc
    lda         #$20
    adc         drawPage
    sta         screenPtr1
    adc         #$20
    sta         nextPage

    sta         CLR80COL        ; Use RAMWRT for aux mem

loop:
    ldy         #0

    ; aux mem
    lda         clearColor
    sta         RAMWRTON

:
    sta         (screenPtr0),y
    iny
    bne         :-

    sta         RAMWRTOFF

    ; main mem
:
    sta         (screenPtr0),y
    iny
    bne         :-

    inc         screenPtr1
    lda         nextPage
    cmp         screenPtr1
    bne         loop
    rts

nextPage:   .byte   0

.endproc

;-----------------------------------------------------------------------------
; flipPage
;-----------------------------------------------------------------------------

.proc flipPage
    ; flip page
    ldx         PAGE2
    bmi         flipToPage1
    sta         HISCR           ; display page 2
    lda         #0
    sta         drawPage        ; draw on page 1
    sta         cacheOffset     ; 0
    rts

flipToPage1:
    sta         LOWSCR          ; diaplay page 1
    lda         #$20
    sta         drawPage        ; draw on page 2
    lda         #$80
    sta         cacheOffset     ; 128
    rts

.endproc

;-----------------------------------------------------------------------------
; drawString
;   Set tileX and tileY before calling
;   Pass string index in X
;-----------------------------------------------------------------------------
.proc drawString
    ldy         #0
    sty         index
loop:
    lda         (stringPtr0),y
    bne         :+
    rts
:
    and         #$3f
    sta         bgTile
    jsr         DHGR_DRAW_7X8
    inc         tileX
    inc         tileX
    inc         index
    ldy         index
    bne         loop
    rts

index:      .byte   0

.endproc

;-----------------------------------------------------------------------------
; drawScreen
;-----------------------------------------------------------------------------
.proc drawScreen

    ; set up cache
    lda         cacheOffset
    sta         cacheIndex

    ; set map pointer
    jsr         setMapPtr

    lda         #WINDOW_TOP
loopY1:
    sta         tileY

    lda         #0
    sta         index
    lda         #WINDOW_LEFT
loopX2:
    sta         tileX
    ldx         cacheIndex
    ldy         index
    lda         (mapPtr0),y
    cmp         mapCache,x
    beq         skip                ; if same as last time, skip drawing
    sta         mapCache,x
    sta         bgTile
    jsr         DHGR_DRAW_14X16
skip:
    inc         index
    inc         cacheIndex
    lda         tileX
    clc
    adc         #DELTA_H
    cmp         #WINDOW_RIGHT
    bne         loopX2

    lda         mapPtr0
    clc
    adc         #MAP_WIDTH
    sta         mapPtr0
    lda         mapPtr1
    adc         #0
    sta         mapPtr1

    lda         tileY
    clc
    adc         #DELTA_V
    cmp         #WINDOW_BOTTOM
    bne         loopY1

    ;---------------
    ; pickman
    ;---------------
drawPlayer:
    ldx         playerTile
    lda         drawPage
    beq         :+
    inx
:
    stx         bgTile
    lda         playerX
    sta         tileX
    lda         playerY
    sta         tileY
    jsr         DHGR_DRAW_14X16
    jsr         setMapCache

;     ;-----------
;     ; Dig test
;     ;-----------
;     jsr         setMapPtr
;     jsr         tile2Offset
;     lda         (mapPtr0),y
;     beq         :+
;     sta         digTile             ; remember overwritten tile (if not empty)
; :
;     lda         #TILE_EMPTY
;     sta         (mapPtr0),y
;
;     lda         #36
;     sta         tileX
;     lda         #22
;     sta         tileY
;     lda         digTile
;     sta         bgTile
;     jsr         DHGR_DRAW_14X16

    ;---------------
    ; info
    ;---------------
drawInfo:
    lda         updateInfo
    beq         drawDone
    dec         updateInfo
    lda         #0
    sta         tileX
    sta         tileY
    lda         #<textString0
    sta         stringPtr0
    lda         #>textString0
    sta         stringPtr1
    jsr         drawString

    ldx         #BCD_MONEY
    jsr         drawNum

    lda         #0
    sta         tileX
    lda         #1
    sta         tileY
    lda         #<textString1
    sta         stringPtr0
    lda         #>textString1
    sta         stringPtr1
    jsr         drawString

drawDone:
    rts


index:          .byte   0
cacheIndex:     .byte   0

.endproc

;-----------------------------------------------------------------------------
; Set map cache
;   Update map cache with the last thing drawn
;-----------------------------------------------------------------------------

.proc setMapCache

    ; set cache
    lda         tileY
    sec
    sbc         #WINDOW_TOP
    asl
    asl                         ; tileY increments by 2, so *4 for total of row*8
    sta         index
    lda         tileX
    sec
    sbc         #WINDOW_LEFT
    lsr
    lsr                         ; tileX increments by 4, so /4
    clc
    adc         index           ; + row
    adc         cacheOffset     ; + page
    tax
    lda         bgTile
    sta         mapCache,x

    rts

index:          .byte   0

.endproc


;-----------------------------------------------------------------------------
; Set Map Ptr
;   Set mapPtr based on mapOffset
;-----------------------------------------------------------------------------

.proc setMapPtr

    ; set up map
    lda         #<map
    clc
    adc         mapOffsetX0
    adc         mapOffsetY0     ; increments by MAP_WIDTH
    sta         mapPtr0
    lda         #>map
    adc         mapOffsetY1     ; no clc needed as row should never overflow
    sta         mapPtr1
    rts

.endProc

;-----------------------------------------------------------------------------
; tile2Offset
;   Get offet in Y to tileX, tileY
;-----------------------------------------------------------------------------

.proc tile2Offset

    lda         tileY
    sec
    sbc         #WINDOW_TOP
    asl
    asl
    asl                         ; tileY increments by 2, so *8 for total of row*16
    sta         index
    lda         tileX
    sec
    sbc         #WINDOW_LEFT
    lsr
    lsr                         ; tileX increments by 4, so /4
    clc
    adc         index           ; + row
    tay
    rts

index:          .byte   0

.endProc


;-----------------------------------------------------------------------------
; checkBelow
;   return tile below player
;-----------------------------------------------------------------------------

.proc checkBelow

    lda         playerX
    sta         tileX
    lda         playerY
    clc
    adc         #DELTA_V
    sta         tileY
    jsr         setMapPtr
    jsr         tile2Offset
    lda         (mapPtr0),y

    rts

.endproc


;-----------------------------------------------------------------------------
; genMap
;   Generate map
;-----------------------------------------------------------------------------
; map 2048 bytes = 16 * 128 tiles
; fill with frequence of items
; then randomly swap positions
; then overwrite fixed locations
; 1 instance = 1/2048 = 0.05 % chance, 20 is ~1%

.proc genMap

    ; Step 1: fill in map with frequence of object to appear
    ;-------------------------------------------------------
    lda         #<map
    sta         mapPtr0
    lda         #>map
    sta         mapPtr1
    lda         #0
    sta         index

freqTileLoop:
    ldy         index
    lda         tileFreq,y          ; tile
    ldx         tileFreq+1,y        ; count
    stx         count
    inc         index
    inc         index

    ldy         #0
freqLoop:
    sta         (mapPtr0),y
    iny
    dex
    bne         freqLoop

    lda         mapPtr0
    clc
    adc         count
    sta         mapPtr0
    lda         mapPtr1
    adc         #0
    sta         mapPtr1

    cmp         #>mapEnd
    bne         freqTileLoop

    ; Step 2: randomly swap entries
    ;-------------------------------------------------------

    lda         #<map
    sta         mapPtr0
    lda         #>map
    sta         mapPtr1

swapLoop:
    jsr         galois24o       ; generate 8-bit random number
    sta         stringPtr0
    jsr         galois24o
    and         #7              ; 0-7
    clc
    adc         #>map
    sta         stringPtr1

    ldy         #0
    lda         (mapPtr0),y
    sta         A1
    lda         (stringPtr0),y
    sta         (mapPtr0),y
    lda         A1
    sta         (stringPtr0),y

    inc         mapPtr0
    bne         swapLoop
    inc         mapPtr1
    lda         mapPtr1
    cmp         #>mapEnd
    bne         swapLoop

    ; Step 3: overwrite fixed objects
    ;-------------------------------------------------------
    ; <shop><sky...................>
    ; <shop><sky...................>
    ; <grass.......................>
    ; ....
    ; random map
    ; ....
    ; <bricks......................>

    ldx         #MAP_WIDTH-1

overwriteLoop:
    lda         #TILE_EMPTY
    sta         map,x                           ; row 0
    sta         map+MAP_WIDTH,x                 ; row 1
    lda         #TILE_GRASS
    sta         map+MAP_WIDTH*2,x               ; row 2
    lda         #TILE_BRICK
    sta         map+MAP_WIDTH*(MAP_HEIGHT-1),x  ; last row
    dex
    bpl         overwriteLoop

    ; shop
    lda         #TILE_SHOP_LEFT
    sta         map
    lda         #TILE_SHOP_RIGHT
    sta         map+1
    lda         #TILE_BRICK
    sta         map+MAP_WIDTH
    lda         #TILE_DOOR
    sta         map+MAP_WIDTH+1
    rts

index:      .byte       0
count:      .byte       0

tileFreq:
    .byte       TILE_DIAMOND, 10    ; 0.5%
    .byte       TILE_GOLD, 40       ; 2%
    .byte       TILE_ROCK, 160      ; 8%

    ; fill remainder with dirt
    .byte       TILE_DIRT, 255
    .byte       TILE_DIRT, 255
    .byte       TILE_DIRT, 255
    .byte       TILE_DIRT, 255
    .byte       TILE_DIRT, 255
    .byte       TILE_DIRT, 255
    .byte       TILE_DIRT, 255
    .byte       TILE_DIRT, 255

.endproc

;-----------------------------------------------------------------------------
; Clear Map Cache
;
;   Note genMap will corrupt, so must be cleared
;-----------------------------------------------------------------------------

.proc clearMapCache
    ldx         #0
    lda         #0
loop:
    sta         mapCache,x
    inx
    bne         loop
    rts
.endproc

;-----------------------------------------------------------------------------
; Quit
;
;   Exit to ProDos
;-----------------------------------------------------------------------------
.proc quit

    jsr     MLI
    .byte   CMD_QUIT
    .word   quit_params

quit_params:
    .byte   4               ; 4 parameters
    .byte   0               ; 0 is the only quit type
    .word   0               ; Reserved pointer for future use (what future?)
    .byte   0               ; Reserved byte for future use (what future?)
    .word   0               ; Reserved pointer for future use (what future?)

.endproc

;-----------------------------------------------------------------------------
; Utilies

.include "galois24o.asm"
.include "inline_print.asm"
.include "bcd.asm"

;-----------------------------------------------------------------------------
; Global Variables

clearColor:         .byte   0
cacheOffset:        .byte   0

mapOffsetX0:        .byte   0
mapOffsetY0:        .byte   0
mapOffsetY1:        .byte   0

playerX:            .byte   16
playerY:            .byte   6
playerTile:         .byte   TILE_PICKMAN_RIGHT1
digTile:            .byte   0

updateInfo:         .byte   0

;                           |--------||--------|
textString0:        String "MOVES:12345   $"
textString1:        String "DEPTH:0"

.align 256
map:
        .res    MAP_SIZE
mapEnd:

mapCache:
        .res    256         ; cache / map overflow