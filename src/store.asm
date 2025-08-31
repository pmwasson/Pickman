;-----------------------------------------------------------------------------
; Paul Wasson - 2025
;-----------------------------------------------------------------------------
; Store for Pickman
;-----------------------------------------------------------------------------

STORE_ACTION_NONE           = 0
STORE_ACTION_BUY_ITEM       = 1
STORE_ACTION_ADD_VALUE      = 2
STORE_ACTION_DOUBLE_VALUE   = 3
STORE_ACTION_ADD_FREQ       = 4

.proc enterStore

    ; Store doesn't use page flip, so put everything on the low screen
    sta         LOWSCR          ; diaplay page 1
    lda         #0
    sta         drawPage        ; draw on page 1
    jsr         clearScreen

    lda         #0
    sta         index

loopY:
    sta         tileY
    lda         #0
loopX:
    sta         tileX
    ldy         index
    lda         storeMap,y
    sta         bgTile
    jsr         DHGR_DRAW_14X16
    inc         index

    lda         tileX
    clc
    adc         #DELTA_H
    cmp         #40
    bne         loopX

    lda         tileY
    clc
    adc         #DELTA_V
    cmp         #24
    bne         loopY

    lda         #4
    sta         tileX
    lda         #2
    sta         tileY

    lda         #BCD_MONEY
    sta         bcdIndex
    lda         maxEnergy
    sta         bcdValue
    lda         #<storeStringWelcome
    sta         stringPtr0
    lda         #>storeStringWelcome
    sta         stringPtr1
    jsr         drawString

    lda         #6
    sta         tileX
    lda         #18
    sta         tileY
    lda         #TILE_STORE_ROCK
    sta         bgTile
    jsr         DHGR_DRAW_14X16

    lda         #6+8
    sta         tileX
    lda         #TILE_STORE_GOLD
    sta         bgTile
    jsr         DHGR_DRAW_14X16

    lda         #6+16
    sta         tileX
    lda         #TILE_STORE_DIAMOND
    sta         bgTile
    jsr         DHGR_DRAW_14X16

    jsr         waitForKey
    rts

index:          .byte   0

storeMap:
    .byte       TILE_BRICK, TILE_SHOP_LEFT, TILE_SHOP_RIGHT, TILE_BRICK, TILE_BRICK, TILE_BRICK, TILE_BRICK, TILE_BRICK, TILE_BRICK, TILE_BRICK
    .byte       TILE_BRICK, TILE_EMPTY,     TILE_EMPTY,      TILE_EMPTY, TILE_EMPTY, TILE_EMPTY, TILE_EMPTY, TILE_EMPTY, TILE_EMPTY, TILE_BRICK
    .byte       TILE_BRICK, TILE_EMPTY,     TILE_EMPTY,      TILE_EMPTY, TILE_EMPTY, TILE_EMPTY, TILE_EMPTY, TILE_EMPTY, TILE_EMPTY, TILE_BRICK
    .byte       TILE_BRICK, TILE_EMPTY,     TILE_EMPTY,      TILE_EMPTY, TILE_EMPTY, TILE_EMPTY, TILE_EMPTY, TILE_EMPTY, TILE_EMPTY, TILE_BRICK
    .byte       TILE_BRICK, TILE_EMPTY,     TILE_EMPTY,      TILE_EMPTY, TILE_EMPTY, TILE_EMPTY, TILE_EMPTY, TILE_EMPTY, TILE_EMPTY, TILE_BRICK
    .byte       TILE_BRICK, TILE_EMPTY,     TILE_EMPTY,      TILE_EMPTY, TILE_EMPTY, TILE_EMPTY, TILE_EMPTY, TILE_EMPTY, TILE_EMPTY, TILE_BRICK
    .byte       TILE_BRICK, TILE_EMPTY,     TILE_EMPTY,      TILE_EMPTY, TILE_EMPTY, TILE_EMPTY, TILE_EMPTY, TILE_EMPTY, TILE_EMPTY, TILE_BRICK
    .byte       TILE_BRICK, TILE_EMPTY,     TILE_EMPTY,      TILE_EMPTY, TILE_EMPTY, TILE_EMPTY, TILE_EMPTY, TILE_EMPTY, TILE_EMPTY, TILE_BRICK
    .byte       TILE_BRICK, TILE_EMPTY,     TILE_EMPTY,      TILE_EMPTY, TILE_EMPTY, TILE_EMPTY, TILE_EMPTY, TILE_EMPTY, TILE_EMPTY, TILE_BRICK
    .byte       TILE_BRICK, TILE_EMPTY,     TILE_EMPTY,      TILE_EMPTY, TILE_EMPTY, TILE_EMPTY, TILE_EMPTY, TILE_EMPTY, TILE_EMPTY, TILE_BRICK
    .byte       TILE_BRICK, TILE_EMPTY,     TILE_EMPTY,      TILE_EMPTY, TILE_EMPTY, TILE_EMPTY, TILE_EMPTY, TILE_EMPTY, TILE_EMPTY, TILE_DOOR
    .byte       TILE_BRICK, TILE_BRICK,     TILE_BRICK,      TILE_BRICK, TILE_BRICK, TILE_BRICK, TILE_BRICK, TILE_BRICK, TILE_BRICK, TILE_BRICK

storeStringWelcome:
    ;        ----------------
    .byte   "STAND UNDER ITEM",STRING_NEWLINE
    .byte   "TO SELECT, UP TO",STRING_NEWLINE
    .byte   "BUY.",STRING_NEWLINE,STRING_NEWLINE
    .byte   "CASH:   $",STRING_BCD_NUMBER,STRING_NEWLINE
    .byte   "ENERGY: &",STRING_BCD_BYTE,STRING_NEWLINE,STRING_NEWLINE
    .byte   "COST:   $?",STRING_NEWLINE
    .byte   "DESCRIPTION:",STRING_END

; Description, price, quantity left, dependsOn, action, value0, value1, tile,
inventoryTable:
    .byte   <descriptionOut,   >descriptionOut,   0,  0, 0,   STORE_ACTION_NONE,      BCD_ROCK_VALUE, 5,   TILE_EMPTY,      "???",      0,0,0,0
    .byte   <descriptionRe,    >descriptionRe,    0,  0, 0,   STORE_ACTION_NONE,      BCD_ROCK_VALUE, 5,   TILE_EMPTY,      "???",      0,0,0,0
    .byte   <descriptionRockP, >descriptionRockP, 10, 3, 0,   STORE_ACTION_ADD_VALUE, BCD_ROCK_VALUE, 5,   TILE_STORE_ROCK, "$",11,     0,0,0,0
    .byte   <descriptionRockP, >descriptionRockP, 20, 3, 1,   STORE_ACTION_ADD_VALUE, BCD_ROCK_VALUE, 15,  TILE_STORE_ROCK, "$",11,     0,0,0,0

; Special charaters
; 0   = end of string
; 10  = Display BCD array value (value0)
; 11  = Display BCD byte (value1)

;                               ----------------
;                               $$$$$ $$$$$ $$$$$
;                               ##  ##  ##
;                               111 222 3333  4
descriptionOut:     .byte      "OUT OF STOCK",STRING_END
descriptionRe:      .byte      "RESTOCK",STRING_END
descriptionRockP:   .byte      "INCREASE ROCK",STRING_NEWLINE
                    .byte      "VALUE BY ",STRING_BCD_BYTE,".",STRING_NEWLINE
                    .byte      "CURRENT = ",STRING_BCD_NUMBER,STRING_END
.endproc