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
TILE_STORE_ROCK         = 3
TILE_ROCK               = 4
TILE_STORE_GOLD         = 5
TILE_GOLD               = 6
TILE_STORE_DIAMOND      = 7
TILE_DIAMOND            = 8
TILE_STORE_DYNAMITE     = 9
TILE_DYNAMITE           = 10
TILE_PICKMAN_RIGHT1     = 11
TILE_PICKMAN_RIGHT2     = 12
TILE_PICKMAN_LEFT1      = 13
TILE_PICKMAN_LEFT2      = 14
TILE_SHOP_LEFT          = 15
TILE_SHOP_RIGHT         = 16
TILE_BRICK              = 17
TILE_DOOR               = 18
TILE_PICKMAN_SHOP_RIGHT = 23
TILE_PICKMAN_SHOP_LEFT  = 24
TILE_STORE_DRINK        = 25
TILE_DRINK              = 26
TILE_STORE_REROLL       = 27
TILE_STORE_SOLD_OUT     = 28


SEED0                   = $ab
SEED1                   = $cd
SEED2                   = $ef

PLAYER_INIT_X           = DELTA_H * 4
PLAYER_INIT_Y           = DELTA_V * 3
MAX_ENERGY_INIT         = $10

DRINK_ENERGY_INIT       = $05

; BCD numbers
BCD_MONEY               = 8*1-1
BCD_ROCK_VALUE          = 8*2-1
BCD_GOLD_VALUE          = 8*3-1
BCD_DIAMOND_VALUE       = 8*4-1
BCD_REROLL_COST         = 8*5-1
BCD_ITEM_COST           = 8*6-1
BCD_ARG                 = 8*7-1
BCD_TEMP                = 8*14-1
BCD_ZERO                = 8*15-1
BCD_INVALID             = 8*16-1

BCD_MONEY_INIT          = $00
BCD_ROCK_VALUE_INIT     = $05
BCD_GOLD_VALUE_INIT     = $20
BCD_DIAMOND_VALUE_INIT  = $50
BCD_REROLL_COST_INIT    = $03

STRING_BCD_BYTE         = 9
STRING_BCD_NUMBER0      = 10
STRING_BCD_NUMBER1      = 11
STRING_BCD_NUMBER2      = 12
STRING_NEWLINE          = 13
STRING_END              = 0

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

    ;----------------------------
    ; Title
    ;----------------------------
    jsr         dhgrInit        ; Turn on dhgr
    sta         CLR80COL
    sta         HISCR
    jsr         waitForKey

    ;----------------------------
    ; Init game
    ;----------------------------

    ldx         #BCD_ZERO
    ldy         #0
    lda         #0
    jsr         bcdSet

    ldx         #BCD_MONEY
;    ldy         #0
;   lda         #BCD_MONEY_INIT
    ldy         #5
    lda         #1
    jsr         bcdSet

    ldx         #BCD_ROCK_VALUE
    ldy         #0
    lda         #BCD_ROCK_VALUE_INIT
    jsr         bcdSet

    ldx         #BCD_GOLD_VALUE
    ldy         #0
    lda         #BCD_GOLD_VALUE_INIT
    jsr         bcdSet

    ldx         #BCD_DIAMOND_VALUE
    ldy         #0
    lda         #BCD_DIAMOND_VALUE_INIT
    jsr         bcdSet

    ldx         #BCD_REROLL_COST
    ldy         #0
    lda         #BCD_REROLL_COST_INIT
    jsr         bcdSet

    lda         #MAX_ENERGY_INIT
    sta         maxEnergy

    lda         #DRINK_ENERGY_INIT
    sta         drinkEnergy

resetLevel:

    ; Reset map
    lda         #0
    sta         mapOffsetX0
    sta         mapOffsetY0
    sta         mapOffsetY1

    ; Set player location
    lda         #PLAYER_INIT_X
    sta         playerX
    lda         #PLAYER_INIT_Y
    sta         playerY
    lda         #TILE_PICKMAN_RIGHT1
    sta         playerTile

    ; Set energy
    lda         maxEnergy
    sta         currentEnergy

    jsr         genMap          ; generate map

resetDisplay:
    jsr         clearMapCache   ; must be called after generating a map or clearing screen

    lda         #2
    sta         updateInfo      ; Update info (both pages)

    lda         #$00            ; Clear both pages
    sta         drawPage
    jsr         clearScreen

    lda         #$20            ; Clear both pages
    sta         drawPage
    jsr         clearScreen



gameLoop:

    ;-----------------------
    ; Increment time
    ;-----------------------
    inc         timer0
    bne         :+
    inc         timer1
:

    ;-----------------------
    ; Enter Store
    ;-----------------------
    lda         destroyedTile
    cmp         #TILE_DOOR
    bne         :+
    lda         #0
    sta         destroyedTile
    jsr         enterStore
    lda         #TILE_PICKMAN_RIGHT1    ; exit to the right
    sta         playerTile
    jmp         resetDisplay
:

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
    lda         timer0
    and         #%11            ; every 4th frame
    bne         :+
    jsr         checkBelow
    cmp         #TILE_EMPTY
    bne         playerInput
    jsr         moveDown
    jmp         gameLoop
:

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
    cmp         #KEY_DOWN
    bne         :+
    jsr         moveDown
    jmp         gameLoop
:

; Note: can't dig up!

    cmp         #KEY_RETURN
    bne         :+
    jmp         resetLevel
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
; Wait for key
;-----------------------------------------------------------------------------

.proc waitForKey

    ; Randomize seed when waiting for keypress
;    inc         seed
;    bne         :+
;    inc         seed+1
;    bne         :+
;    inc         seed+2
;    bne         :+
;    inc         seed            ; can't be all zeroes, so add one more
;:

    lda         KBD
    bpl         waitForKey
    sta         KBDSTRB
    rts
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

    ; check if tile empty
    jsr         checkRight
    cmp         #TILE_EMPTY
    beq         move

    ; check if on edge (assume not on edge if able to scroll)
    lda         playerX
    clc
    adc         #DELTA_H
    cmp         #WINDOW_RIGHT
    bcc         :+
    rts                         ; Can't dig (or move)
:
    jmp         digTile

move:
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

    ; check if tile empty
    jsr         checkLeft
    cmp         #TILE_EMPTY
    beq         move

    ; check if on edge (assume not on edge if able to scroll)
    lda         playerX
    sec
    sbc         #DELTA_H
    cmp         #WINDOW_LEFT
    bcs         :+
    rts                         ; Can't dig (or move)
:
    jmp         digTile

move:
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
    ; check if move on screen
    lda         playerY
    sec
    sbc         #DELTA_V
    cmp         #THRESHOLD_TOP
    bcs         setY

    ; check if scroll
    lda         mapOffsetY1
    bne         scroll
    lda         mapOffsetY0
    beq         checkEdge       ; no scrolling

scroll:
    lda         mapOffsetY0
    sec
    sbc         #MAP_WIDTH
    sta         mapOffsetY0
    lda         mapOffsetY1
    sbc         #0
    sta         mapOffsetY1
    rts                         ; okay - scroll

checkEdge:
    ; check if on edge
    lda         playerY
    sec
    sbc         #DELTA_V
    cmp         #WINDOW_TOP
    bcs         setY
    rts                         ; failed
setY:
    sta         playerY
    rts                         ; okay - move on screen
.endproc

.proc moveDown

    ; check if tile empty
    jsr         checkBelow
    cmp         #TILE_EMPTY
    beq         :+
    jmp         digTile
:

    ; check if move on screen
    lda         playerY
    clc
    adc         #DELTA_V
    cmp         #THRESHOLD_BOTTOM
    bcc         setY

    ; check if scroll
    lda         mapOffsetY1
    cmp         #MAP_BOTTOM1
    bne         scroll
    lda         mapOffsetY0
    cmp         #MAP_BOTTOM0
    beq         checkEdge       ; no scrolling

scroll:
    lda         mapOffsetY0
    clc
    adc         #MAP_WIDTH
    sta         mapOffsetY0
    lda         mapOffsetY1
    adc         #0
    sta         mapOffsetY1
    rts                         ; okay - scroll

checkEdge:
    ; check if on edge
    lda         playerY
    clc
    adc         #DELTA_V
    cmp         #WINDOW_BOTTOM
    bcc         setY
    rts                         ; failed
setY:
    sta         playerY
    rts                         ; okay - move on screen
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
; Dig tile
;-----------------------------------------------------------------------------

.proc digTile

    lda         currentEnergy
    bne         :+
    rts                             ; Too tired
:

    ldy         tileOffset
    lda         (mapPtr0),y         ; previous value
    sta         destroyedTile

    tay
    lda         tileProperties,y
    sta         destroyedProp
    and         #TILE_PROPERTY_INVULNERABLE
    beq         :+
    rts                             ; Can't destroy
:

    ; decrease energy (BCD)
    sed
    lda         currentEnergy
    sec
    sbc         #1
    sta         currentEnergy
    cld
    lda         #2
    sta         updateInfo


    lda         destroyedProp
    and         #TILE_PROPERTY_SCORED
    beq         :+
    ; Add to score
    lda         destroyedProp
    and         #TILE_PROPERTY_INDEX
    tax
    ldy         tileIndexToBCD,x
    ldx         #BCD_MONEY
    jsr         bcdAdd
:

    lda         destroyedProp
    and         #TILE_PROPERTY_GRAB
    beq         :+
    lda         destroyedProp
    and         #TILE_PROPERTY_INDEX

    cmp         #TILE_INDEX_DRINK
    bne         nextItem
    sed
    lda         currentEnergy
    clc
    adc         drinkEnergy
    adc         #1                      ; doesn't cost energy to drink!
    sta         currentEnergy
    cld
nextItem:
    ; TODO: add dynamite

:
    ; Set map to empty
    ldy         tileOffset
    lda         #TILE_EMPTY
    sta         bgTile
    sta         (mapPtr0),y
    rts

destroyedProp:  .byte       0

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
    lda         tileX
    sta         leftX
    ldy         #0
    sty         index
loop:
    lda         (stringPtr0),y
    ; end of string
    bne         :+
    rts
:
    ; next-line
    cmp         #13
    bne         :+
    lda         leftX
    sta         tileX
    inc         tileY
    jmp         continue
:
    ; BCD number
    cmp         #STRING_BCD_NUMBER0
    bne         :+
    lda         bcdIndex0
    jsr         drawArrayNum
    jmp         continue
:
    cmp         #STRING_BCD_NUMBER1
    bne         :+
    lda         bcdIndex1
    jsr         drawArrayNum
    jmp         continue
:
    cmp         #STRING_BCD_NUMBER2
    bne         :+
    lda         bcdIndex2
    jsr         drawArrayNum
    jmp         continue
:
    ; BCD byte
    cmp         #STRING_BCD_BYTE
    bne         :+
    jsr         drawBCDByte
    jmp         continue
:
    and         #$3f
    sta         bgTile
    jsr         DHGR_DRAW_7X8
    inc         tileX
    inc         tileX
continue:
    inc         index
    ldy         index
    bne         loop
    rts

index:      .byte   0
leftX:      .byte   0
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

    ;---------------
    ; info
    ;---------------
drawInfo:
    lda         updateInfo
    beq         drawDone
    dec         updateInfo

    ; display cash
    lda         #BCD_MONEY
    sta         bcdIndex0
    lda         #0
    sta         tileX
    sta         tileY
    lda         #<textStringCash
    sta         stringPtr0
    lda         #>textStringCash
    sta         stringPtr1
    jsr         drawString

    ; display energy
    lda         currentEnergy
    sta         bcdValue
    lda         #0
    sta         tileX
    lda         #1
    sta         tileY
    lda         #<textStringEnergy
    sta         stringPtr0
    lda         #>textStringEnergy
    sta         stringPtr1
    jsr         drawString

    ; display warning
    lda         currentEnergy
    bne         drawDone
    lda         #0
    sta         tileX
    lda         #22
    sta         tileY
    lda         #<textStringReturn
    sta         stringPtr0
    lda         #>textStringReturn
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
    sty         tileOffset      ; cache result to avoid re-calling
    rts

index:          .byte   0

.endProc


;-----------------------------------------------------------------------------
; checkRight
;   return tile to the right player
;   assumes not at edge of map
;-----------------------------------------------------------------------------

.proc checkRight

    lda         playerX
    clc
    adc         #DELTA_H
    sta         tileX
    lda         playerY
    sta         tileY
    jsr         setMapPtr
    jsr         tile2Offset
    lda         (mapPtr0),y
    rts

.endproc


;-----------------------------------------------------------------------------
; checkLeft
;   return tile to the right player
;   assumes not at edge of map/screen
;-----------------------------------------------------------------------------

.proc checkLeft

    lda         playerX
    sec
    sbc         #DELTA_H
    sta         tileX
    lda         playerY
    sta         tileY
    jsr         setMapPtr
    jsr         tile2Offset
    lda         (mapPtr0),y
    rts

.endproc

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
    .byte       TILE_DIAMOND,   10      ; 0.5%
    .byte       TILE_GOLD,      40      ; 2%
    .byte       TILE_ROCK,      160     ; 8%
    .byte       TILE_DYNAMITE,  2
    .byte       TILE_DRINK,     2

    ; fill remainder with dirt
    .byte       TILE_DIRT,      255
    .byte       TILE_DIRT,      255
    .byte       TILE_DIRT,      255
    .byte       TILE_DIRT,      255
    .byte       TILE_DIRT,      255
    .byte       TILE_DIRT,      255
    .byte       TILE_DIRT,      255
    .byte       TILE_DIRT,      255

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

.include "store.asm"
.include "galois24o.asm"
.include "inline_print.asm"
.include "bcd.asm"

;-----------------------------------------------------------------------------
; Global Variables

timer0:             .byte   0
timer1:             .byte   0

clearColor:         .byte   0
cacheOffset:        .byte   0

mapOffsetX0:        .byte   0
mapOffsetY0:        .byte   0
mapOffsetY1:        .byte   0

playerX:            .byte   0
playerY:            .byte   0
playerTile:         .byte   0
destroyedTile:      .byte   0
maxEnergy:          .byte   0
currentEnergy:      .byte   0
drinkEnergy:        .byte   0

tileOffset:         .byte   0

updateInfo:         .byte   0


textStringCash:     .byte       "CASH   $",STRING_BCD_NUMBER0,"   ",0
textStringEnergy:   .byte       "ENERGY &",STRING_BCD_BYTE," ",0
                                ;--------------------
textStringReturn:   StringCont  "&& OUT OF ENERGY  &&"
                    String      "&& PRESS <RETURN> &&"

; Lookup table of tile properties
; 7:    Invulnerable (negative)
; 6:    Scored      - increase score when destroyed
; 5:    Grab        - pick up if activitly dug
; 4:    Explosive   - explode when destroyed (grab has higher priority)
; 3-0:  Index       - score index
;
; Index: 0  - none (dirt, etc)
;        1  - rock
;        2  - gold
;        3  - diamond
;        4  - inventory item
;        5  - store door
;       ...
;        F  - invalid (error)

TILE_PROPERTY_INVALID       =   $FF

TILE_PROPERTY_INVULNERABLE  =   %10000000
TILE_PROPERTY_SCORED        =   %01000000
TILE_PROPERTY_GRAB          =   %00100000
TILE_PROPERTY_EXPLOSIVE     =   %00010000
TILE_PROPERTY_INDEX         =   %00001111

TILE_INDEX_NONE             =   0
TILE_INDEX_ROCK             =   1
TILE_INDEX_GOLD             =   2
TILE_INDEX_DIAMOND          =   3
TILE_INDEX_DYNAMITE         =   4
TILE_INDEX_DRINK            =   5
TILE_INDEX_DOOR             =   6

tileIndexToBCD:
    .byte       BCD_INVALID
    .byte       BCD_ROCK_VALUE
    .byte       BCD_GOLD_VALUE
    .byte       BCD_DIAMOND_VALUE
    .byte       BCD_INVALID
    .byte       BCD_INVALID
    .byte       BCD_INVALID
    .byte       BCD_INVALID
    .byte       BCD_INVALID
    .byte       BCD_INVALID
    .byte       BCD_INVALID
    .byte       BCD_INVALID
    .byte       BCD_INVALID
    .byte       BCD_INVALID
    .byte       BCD_INVALID
    .byte       BCD_INVALID

tileProperties:
    .byte       TILE_INDEX_NONE                                                      ; empty
    .byte       TILE_INDEX_NONE                                                      ; grass
    .byte       TILE_INDEX_NONE                                                      ; dirt
    .byte       TILE_INDEX_ROCK     + TILE_PROPERTY_SCORED                           ; rock
    .byte       TILE_INDEX_ROCK     + TILE_PROPERTY_SCORED                           ; rock
    .byte       TILE_INDEX_GOLD     + TILE_PROPERTY_SCORED                           ; gold
    .byte       TILE_INDEX_GOLD     + TILE_PROPERTY_SCORED                           ; gold
    .byte       TILE_INDEX_DIAMOND  + TILE_PROPERTY_SCORED                           ; diamond
    .byte       TILE_INDEX_DIAMOND  + TILE_PROPERTY_SCORED                           ; diamond
    .byte       TILE_INDEX_DYNAMITE + TILE_PROPERTY_GRAB + TILE_PROPERTY_EXPLOSIVE   ; dynamite
    .byte       TILE_INDEX_DYNAMITE + TILE_PROPERTY_GRAB + TILE_PROPERTY_EXPLOSIVE   ; dynamite
    .byte       TILE_PROPERTY_INVALID                                                ; player
    .byte       TILE_PROPERTY_INVALID                                                ; player
    .byte       TILE_PROPERTY_INVALID                                                ; player
    .byte       TILE_PROPERTY_INVALID                                                ; player
    .byte       TILE_PROPERTY_INVALID                                                ; store
    .byte       TILE_PROPERTY_INVALID                                                ; store
    .byte       TILE_INDEX_NONE     + TILE_PROPERTY_INVULNERABLE                     ; brick
    .byte       TILE_INDEX_DOOR     + TILE_PROPERTY_INVULNERABLE                     ; door
    .byte       TILE_PROPERTY_INVALID                                                ; Thrown dynamite
    .byte       TILE_PROPERTY_INVALID                                                ; Thrown dynamite
    .byte       TILE_PROPERTY_INVALID                                                ; Thrown dynamite
    .byte       TILE_PROPERTY_INVALID                                                ; Thrown dynamite
    .byte       TILE_PROPERTY_INVALID                                                ; player (store)
    .byte       TILE_PROPERTY_INVALID                                                ; player (store)
    .byte       TILE_INDEX_DRINK    + TILE_PROPERTY_GRAB                             ; drink
    .byte       TILE_INDEX_DRINK    + TILE_PROPERTY_GRAB                             ; drink

.align 256
map:
        .res    MAP_SIZE
mapEnd:

mapCache:
        .res    256         ; cache / map overflow