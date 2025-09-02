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

STORE_X_LEFT                = 4
STORE_X_RIGHT               = 40-8
STORE_X_INIT                = STORE_X_RIGHT
STORE_Y_INIT                = 24-4

STORE_X_DESCRIPTION         = 4
STORE_Y_DESCRIPTION         = 11

.proc enterStore

    ; Store doesn't use page flip, so put everything on the low screen
    sta         LOWSCR          ; diaplay page 1
    lda         #0
    sta         drawPage        ; draw on page 1

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

    lda         #4
    sta         tileX
    lda         #18
    sta         tileY
    lda         #TILE_STORE_REROLL
    sta         bgTile
    jsr         DHGR_DRAW_14X16

    lda         #10
    sta         tileX
    lda         #18
    sta         tileY
    lda         #TILE_STORE_ROCK
    sta         bgTile
    jsr         DHGR_DRAW_14X16

    lda         #18
    sta         tileX
    lda         #TILE_STORE_DYNAMITE
    sta         bgTile
    jsr         DHGR_DRAW_14X16

    lda         #26
    sta         tileX
    lda         #TILE_STORE_DRINK
    sta         bgTile
    jsr         DHGR_DRAW_14X16

    lda         #STORE_X_INIT
    sta         playerX
    sta         tileX
    lda         #STORE_Y_INIT
    sta         playerY
    sta         tileY
    lda         #TILE_PICKMAN_SHOP_LEFT
    sta         bgTile
    jsr         DHGR_DRAW_14X16

    lda         #0
    sta         lastDescription

storeLoop:
    jsr         waitForKey

    cmp         #KEY_LEFT
    bne         :+

    lda         playerX
    cmp         #STORE_X_LEFT
    beq         storeLoop
    lda         playerY
    sta         tileY
    lda         playerX
    sta         tileX
    lda         #TILE_EMPTY
    sta         bgTile
    jsr         DHGR_DRAW_14X16
    dec         playerX
    dec         playerX
    lda         playerX
    sta         tileX
    lda         #TILE_PICKMAN_SHOP_LEFT
    sta         bgTile
    jsr         DHGR_DRAW_14X16
    jmp         updateDisplay
:

    cmp         #KEY_RIGHT
    bne         :+
    lda         playerX
    cmp         #STORE_X_RIGHT
    beq         exit
    lda         playerY
    sta         tileY
    lda         playerX
    sta         tileX
    lda         #TILE_EMPTY
    sta         bgTile
    jsr         DHGR_DRAW_14X16
    inc         playerX
    inc         playerX
    lda         playerX
    sta         tileX
    lda         #TILE_PICKMAN_SHOP_RIGHT
    sta         bgTile
    jsr         DHGR_DRAW_14X16
    jmp         updateDisplay
:
    jmp         storeLoop

updateDisplay:
    ldx         playerX
    lda         descriptionIndex,x
    cmp         lastDescription
    bne         :+
    jmp         storeLoop
:
    sta         lastDescription

    lda         #STORE_X_DESCRIPTION
    sta         tileX
    lda         #STORE_Y_DESCRIPTION
    sta         tileY
    lda         #<descriptionBlank
    sta         stringPtr0
    lda         #>descriptionBlank
    sta         stringPtr1
    jsr         drawString

    lda         lastDescription
    asl
    tax
    lda         descriptionTable,x
    sta         stringPtr0
    lda         descriptionTable+1,x
    sta         stringPtr1
    lda         #STORE_X_DESCRIPTION
    sta         tileX
    lda         #STORE_Y_DESCRIPTION
    sta         tileY
    jsr         drawString
    jmp         storeLoop

exit:
    rts

index:              .byte   0
lastDescription:    .byte   0

; reusing name in local scope
playerX:            .byte   0
playerY:            .byte   0

storeMap:
    .byte       TILE_SHOP_LEFT, TILE_SHOP_RIGHT, TILE_BRICK, TILE_BRICK, TILE_BRICK, TILE_BRICK, TILE_BRICK, TILE_BRICK, TILE_BRICK, TILE_BRICK
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
    .byte   "TO SELECT, ^ TO",STRING_NEWLINE
    .byte   "BUY.",STRING_NEWLINE,STRING_NEWLINE
    .byte   "CASH:   $",STRING_BCD_NUMBER,STRING_NEWLINE
    .byte   "ENERGY: &",STRING_BCD_BYTE,STRING_NEWLINE,STRING_NEWLINE
    .byte   "COST:   $?",STRING_NEWLINE
    .byte   "DESCRIPTION:",STRING_END

descriptionIndex:               ; 0..39 (only evens matter)
    .byte   0,0,0,0             ; wall
    .byte   1,1                 ; reroll
    .byte   0,0                 ; space
    .byte   2,2,2,2,2,2         ; left item
    .byte   0,0                 ; space
    .byte   3,3,3,3,3,3         ; middle item
    .byte   0,0                 ; space
    .byte   4,4,4,4,4,4         ; right item
    .byte   0,0,0,0,0,0         ; space
    .byte   0,0,0,0             ; door

; Description, price, priceExp, quantity left, dependsOn, action, value0, value1, tile,
inventoryTable:
    .byte   <descriptionOut,   >descriptionOut,   0,  0, 0, 0,   STORE_ACTION_NONE,      BCD_ROCK_VALUE, 5,   TILE_EMPTY,      "???",      0,0,0,0
    .byte   <descriptionRe,    >descriptionRe,    0,  0, 0, 0,   STORE_ACTION_NONE,      BCD_ROCK_VALUE, 5,   TILE_EMPTY,      "???",      0,0,0,0
    .byte   <descriptionRockP, >descriptionRockP, 10, 0, 3, 0,   STORE_ACTION_ADD_VALUE, BCD_ROCK_VALUE, 5,   TILE_STORE_ROCK, "$",11,     0,0,0,0
    .byte   <descriptionRockP, >descriptionRockP, 20, 0, 3, 1,   STORE_ACTION_ADD_VALUE, BCD_ROCK_VALUE, 15,  TILE_STORE_ROCK, "$",11,     0,0,0,0


descriptionTable:
    .word       descriptionBlank
    .word       descriptionRe
    .word       descriptionRockP
    .word       descriptionDynamite
    .word       descriptionDrink
; Special charaters
; 0   = end of string
; 10  = Display BCD array value (value0)
; 11  = Display BCD byte (value1)

;                                    ----------------
;                                    $$$$$ $$$$$ $$$$$
;                                    ##  ##  ##
;                                    111 222 3333  4
descriptionBlank:       .byte       "                ",STRING_NEWLINE
                        .byte       "                ",STRING_NEWLINE
                        .byte       "                ",STRING_END
descriptionOut:         .byte       "OUT OF STOCK",STRING_END
descriptionRe:          .byte       "RESTOCK STORE",STRING_NEWLINE
                        .byte       "WITH NEW ITEMS",STRING_END
descriptionRockP:       .byte       "INCREASE ROCK",STRING_NEWLINE
                        .byte       "VALUE BY ",STRING_BCD_BYTE,".",STRING_NEWLINE
                        .byte       "CURRENT = ",STRING_BCD_NUMBER,STRING_END
descriptionDynamite:    .byte       "DYNAMITE! PRESS",STRING_NEWLINE
                        .byte       "SPACE TO THROW",STRING_END
descriptionDrink:       .byte       "ENERGY DRINK!",STRING_NEWLINE
                        .byte       "PRESS TAB TO USE",STRING_END

.endproc