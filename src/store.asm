;-----------------------------------------------------------------------------
; Paul Wasson - 2025
;-----------------------------------------------------------------------------
; Store for Pickman
;-----------------------------------------------------------------------------

STORE_ACTION_NONE           = 0
STORE_ACTION_REROLL         = 1
STORE_ACTION_ADD_VALUE      = 2
STORE_ACTION_ADD_ENERGY     = 3

STORE_X_LEFT                = 4
STORE_X_RIGHT               = 40-8
STORE_X_INIT                = STORE_X_RIGHT
STORE_Y_INIT                = 24-4

STORE_X_DESCRIPTION         = 4
STORE_Y_DESCRIPTION         = 12

STORE_X_COST                = 22
STORE_Y_COST                = 9

itemPtr0 = fgPtr0
itemPtr1 = fgPtr1


.proc enterStore

    jsr         shuffleItems

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
    sta         bcdIndex0
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
    sta         lastItem

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

exit:
    rts

updateDisplay:
    ldx         playerX
    lda         itemIndex,x
    cmp         lastItem
    bne         :+
    jmp         storeLoop
:
    sta         lastItem

    ; Clear previous item
    lda         #STORE_X_DESCRIPTION
    sta         tileX
    lda         #STORE_Y_DESCRIPTION
    sta         tileY
    lda         #<descriptionBlank
    sta         stringPtr0
    lda         #>descriptionBlank
    sta         stringPtr1
    jsr         drawString
    lda         #STORE_X_COST
    sta         tileX
    lda         #STORE_Y_COST
    sta         tileY
    lda         #BCD_ZERO
    jsr         drawArrayNum

    ; Read item
    lda         lastItem
    bne         :+
    jmp         storeLoop
:

    asl                                 ; *2
    tax
    lda         itemList,x
    sta         itemPtr0
    lda         itemList+1,x
    sta         itemPtr1

    ; Display description
    ldy         #0                      ; description
    lda         (itemPtr0),y
    sta         stringPtr0
    ldy         #1
    lda         (itemPtr0),y
    sta         stringPtr1

    ; TODO read values
    ldy         #6                      ; value
    lda         (itemPtr0),y
    sta         bcdIndex0

    ldy         #8                      ; arg
    lda         (itemPtr0),y
    sta         bcdValue                ; Store arg as BCD byte ...
    sta         costBase
    ldy         #9
    lda         (itemPtr0),y
    tay
    ldx         #BCD_ARG
    stx         bcdIndex1
    lda         costBase
    jsr         bcdSet                  ; ... and BCD number

    lda         #STORE_X_DESCRIPTION
    sta         tileX
    lda         #STORE_Y_DESCRIPTION
    sta         tileY
    jsr         drawString

    ; Display cost
    ;-------------
    ldy         #2                      ; cost
    lda         (itemPtr0),y
    sta         costBase
    ldy         #3
    lda         (itemPtr0),y
    tay
    ldx         #BCD_ITEM_COST
    lda         costBase
    jsr         bcdSet

    lda         #STORE_X_COST
    sta         tileX
    lda         #STORE_Y_COST
    sta         tileY
    lda         #BCD_ITEM_COST
    jsr         drawArrayNum

    ldy         #6
    lda         (itemPtr0),y
    sta         bcdIndex0               ; value

    jmp         storeLoop


index:              .byte   0
lastItem:           .byte   0
costBase:           .byte   0

; reusing name in local scope
playerX:            .byte   0
playerY:            .byte   0

.endproc

;------------------------------
; Shuffle Items randomly
;   Shuffle 256 bytes of data
;------------------------------

.proc shuffleItems

    lda         #0
    sta         index

loop:
    jsr         galois24o
    tay
    ldx         index

    ; swap x and y
    lda         itemActive,x
    sta         temp
    lda         itemActive,y
    sta         itemActive,x
    lda         temp
    sta         itemActive,y
    dec         index
    bne         loop
    rts

index:          .byte   0
temp:           .byte   0

.endproc


;-----------------------------------------------------
; Data
;-----------------------------------------------------

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
    .byte   "CASH:   $",STRING_BCD_NUMBER0,STRING_NEWLINE
    .byte   "ENERGY: &",STRING_BCD_BYTE,STRING_NEWLINE,STRING_NEWLINE
    .byte   "COST:   $?",STRING_NEWLINE
    .byte   "DESCRIPTION:",STRING_END

itemIndex:                      ; 0..39 (only evens matter)
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

itemList:
    .word   inventoryTable+16*0
    .word   inventoryTable+16*1
    .word   inventoryTable+16*2
    .word   inventoryTable+16*3
    .word   inventoryTable+16*4

.define COMBINE_CHAR(ta,tb) (ta & $3f)+(tb & $3f)*256
STORE_ICON_NONE             = COMBINE_CHAR(' ',' ')
STORE_ICON_ADD_VALUE        = COMBINE_CHAR('+','$')
STORE_ICON_ADD_ENERGY       = COMBINE_CHAR('+','$')

;           Description,       cost,   action,                  value,            arg,   tile,                icon,                   reserved
inventoryTable:     ; 16 bytes per entry
    .word   descriptionOut,    $0000,  STORE_ACTION_NONE,       BCD_INVALID,      $0000, TILE_STORE_SOLD_OUT, STORE_ICON_NONE,        0
    .word   descriptionRe,     $0000,  STORE_ACTION_REROLL,     BCD_REROLL_COST,  $0000, TILE_STORE_REROLL,   STORE_ICON_NONE,        0
    .word   descriptionRockP,  $0020,  STORE_ACTION_ADD_VALUE,  BCD_ROCK_VALUE,   $0005, TILE_STORE_ROCK,     STORE_ICON_ADD_VALUE,   0
    .word   descriptionRockP,  $0040,  STORE_ACTION_ADD_VALUE,  BCD_ROCK_VALUE,   $0010, TILE_STORE_ROCK,     STORE_ICON_ADD_VALUE,   0
    .word   descriptionEnergy, $0101,  STORE_ACTION_ADD_ENERGY, BCD_INVALID,      $0007, TILE_STORE_DRINK,    STORE_ICON_ADD_ENERGY,  0

;                                    ----------------
descriptionBlank:       .byte       "                ",STRING_NEWLINE
                        .byte       "                ",STRING_NEWLINE
                        .byte       "                ",STRING_END
descriptionOut:         .byte       "OUT OF STOCK",STRING_END
descriptionRe:          .byte       "RESTOCK STORE",STRING_NEWLINE
                        .byte       "WITH NEW ITEMS",STRING_END
descriptionRockP:       .byte       "INCREASE ROCK",STRING_NEWLINE
                        .byte       "VALUE BY ",STRING_BCD_NUMBER1,STRING_NEWLINE
                        .byte       "CURRENT = ",STRING_BCD_NUMBER0,STRING_END
descriptionDynamite:    .byte       "DYNAMITE! PRESS",STRING_NEWLINE
                        .byte       "SPACE TO THROW",STRING_END
descriptionEnergy:      .byte       "INCREASE",STRING_NEWLINE
                        .byte       "STARTING ENERGY",STRING_NEWLINE
                        .byte       "BY ",STRING_BCD_BYTE,STRING_END


.align 256

itemDepends:                ; Item only apears if dependent item sold (unavailable).  0=no dependencies
    .res        255

itemAvailable:              ; Set to 0 if item is sold making it unavailable (except reroll)
    .res        255

itemActive:                 ; Shuffled list of active items
    .res        256