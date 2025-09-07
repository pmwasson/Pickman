;-----------------------------------------------------------------------------
; Paul Wasson - 2025
;-----------------------------------------------------------------------------
; Store for Pickman
;-----------------------------------------------------------------------------

STORE_ACTION_NONE           = 0
STORE_ACTION_REROLL         = 1
STORE_ACTION_ADD_VALUE      = 2
STORE_ACTION_ADD_ENERGY     = 3
STORE_ACTION_ADD_DYNAMITE   = 4

STORE_X_LEFT                = 4
STORE_X_RIGHT               = 40-8
STORE_X_INIT                = STORE_X_RIGHT
STORE_Y_INIT                = 24-4

STORE_X_CASH                = 22
STORE_Y_CASH                = 6

STORE_X_ENERGY              = 22
STORE_Y_ENERGY              = 7

STORE_X_DESCRIPTION         = 4
STORE_Y_DESCRIPTION         = 12

STORE_X_COST                = 22
STORE_Y_COST                = 8

ITEM_X_1                    = 4
ITEM_X_2                    = 10
ITEM_X_3                    = 18
ITEM_X_4                    = 26

itemPtr0 = fgPtr0
itemPtr1 = fgPtr1


.proc enterStore

    ; init player
    lda         #STORE_X_INIT
    sta         playerX
    lda         #STORE_Y_INIT
    sta         playerY
    lda         #TILE_PICKMAN_SHOP_LEFT
    sta         playerTile

refresh:

    ; load items for display
    lda         #0
    sta         lastItem
loadItemLoop:
    jsr         loadItem
    inc         lastItem
    lda         lastItem
    cmp         #5
    bne         loadItemLoop

    jsr         drawStoreMap
    jsr         flipPage        ; display final drawing from last iteration of game loop
    jsr         drawStoreMap

storeLoop:

    ; erase then draw player
    lda         #TILE_EMPTY
    sta         bgTile
    lda         playerY
    sta         tileY
    lda         #4
    sta         tileX
eraseLoop:
    jsr         DHGR_DRAW_14X16
    lda         tileX
    clc
    adc         #DELTA_H
    sta         tileX
    cmp         #36
    bne         eraseLoop

    lda         playerX
    sta         tileX
    lda         playerY
    sta         tileY
    lda         playerTile
    sta         bgTile
    jsr         DHGR_DRAW_14X16

    ; draw values
    lda         #STORE_X_CASH
    sta         tileX
    lda         #STORE_Y_CASH
    sta         tileY
    lda         #BCD_MONEY
    jsr         drawArrayNum

    lda         #STORE_X_ENERGY
    sta         tileX
    lda         #STORE_Y_ENERGY
    sta         tileY
    lda         maxEnergy
    sta         bcdValue
    jsr         drawBCDByte

    jsr         flipPage        ; display final drawing from last iteration of game loop

    jsr         waitForKey

    cmp         #KEY_LEFT
    bne         :+

    lda         playerX
    cmp         #STORE_X_LEFT
    beq         noLeft
    dec         playerX
    dec         playerX
    lda         #TILE_PICKMAN_SHOP_LEFT
    sta         playerTile
noLeft:
    jmp         updateDisplay
:

    cmp         #KEY_RIGHT
    bne         :+
    lda         playerX
    cmp         #STORE_X_RIGHT
    beq         exit
    inc         playerX
    inc         playerX
    lda         #TILE_PICKMAN_SHOP_RIGHT
    sta         playerTile
    jmp         updateDisplay

exit:
    rts
:

    cmp         #KEY_UP
    beq         :+
    jmp         storeLoop
:
    lda         lastItem
    bne         :+
    jmp         storeLoop
:
    ; Buy item
    ; Check if can afford
    ldx         #BCD_TEMP
    ldy         #BCD_MONEY
    jsr         bcdCopy

    ldx         #BCD_TEMP
    ldy         #BCD_ITEM_COST
    jsr         bcdSub
    bcs         :+

    jmp         updateDisplay       ; can't afford
:

    ; subtract cost
    ldx         #BCD_MONEY
    ldy         #BCD_ITEM_COST
    jsr         bcdSub

    ldy         #INVENTORY_ACTION
    lda         (itemPtr0),y

    cmp         #STORE_ACTION_NONE
    bne         :+
    jmp         updateDisplay
:

    cmp         #STORE_ACTION_ADD_VALUE
    bne         :+
    ldx         bcdIndex0           ; value
    ldy         bcdIndex1           ; arg
    jsr         bcdAdd
    jmp         removeItemDisplay
:

    cmp         #STORE_ACTION_ADD_ENERGY
    bne         :+

    sed
    clc
    lda         maxEnergy
    adc         itemArg
    sta         maxEnergy
    cld
    bcc         energyOkay
    lda         #$99
    sta         maxEnergy
energyOkay:
    sta         currentEnergy
    jmp         removeItemDisplay
:

    cmp         #STORE_ACTION_REROLL
    bne         :+

    jsr         restockItems
    jmp         refresh

:
    brk

removeItemDisplay:
    ; remove item from inventory
    jsr         removeItem

    ; mark as sold-out
    ldx         lastItem
    lda         #0
    sta         itemList,x
    jsr         loadItem
    ; jmp       updateDisplay

updateDisplay:
    ldx         playerX
    lda         itemIndex,x
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
    ldx         lastItem
    bne         :+                      ; none
    jmp         storeLoop
:

    jsr         loadItem

    ; Display description
    lda         itemValue
    sta         bcdIndex0

    lda         itemArg
    sta         bcdValue

    lda         #STORE_X_DESCRIPTION
    sta         tileX
    lda         #STORE_Y_DESCRIPTION
    sta         tileY
    jsr         drawString

    ; Display cost
    ;-------------
    lda         #STORE_X_COST
    sta         tileX
    lda         #STORE_Y_COST
    sta         tileY
    lda         #BCD_ITEM_COST
    jsr         drawArrayNum

    jsr         drawItems

    jmp         storeLoop

; reusing name in local scope
playerX:            .byte   0
playerY:            .byte   0
playerTile:         .byte   0

.endproc

;------------------------------
; Draw Store
;------------------------------

.proc drawStoreMap
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

    lda         #<storeStringWelcome
    sta         stringPtr0
    lda         #>storeStringWelcome
    sta         stringPtr1
    jsr         drawString

    jsr         drawItems

    rts

index:              .byte   0

.endproc

.proc drawItems
    lda         #ITEM_X_1
    sta         tileX
    lda         #18
    sta         tileY
    lda         itemTile+1
    sta         bgTile
    jsr         DHGR_DRAW_14X16

    lda         #ITEM_X_2
    sta         tileX
    lda         #18
    sta         tileY
    lda         itemTile+2
    sta         bgTile
    jsr         DHGR_DRAW_14X16

    lda         #ITEM_X_3
    sta         tileX
    lda         itemTile+3
    sta         bgTile
    jsr         DHGR_DRAW_14X16

    lda         #ITEM_X_4
    sta         tileX
    lda         itemTile+4
    sta         bgTile
    jsr         DHGR_DRAW_14X16

    rts
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

;------------------------------
; Restock Items
;------------------------------

.proc restockItems

    ldx         #0
availableLoop:
    ldy         itemDepends,x       ; this item only available if dependency sold (or none)
    beq         available           ; no dependencies
    lda         itemAvailable,y     ; 0 = sold
    beq         available

    ; dependency not sold, unavailable
    lda         #0
    sta         itemActive,x
    jmp         next

available:
    lda         itemAvailable,x
    sta         itemActive,x
next:
    inx
    bne         availableLoop

    ; available items marked with there locations, shuffle list
    jsr         shuffleItems

    lda         #0
    sta         itemList
    lda         #1
    sta         itemList+1
    jsr         findFirstItem
    sta         itemList+2
    jsr         findNextItem
    sta         itemList+3
    jsr         findNextItem
    sta         itemList+4

    rts

findFirstItem:
    ldx         #1
    lda         itemActive          ; check if 0 is active
    beq         findNextItem
    rts

findNextItem:
    cpx         #0
    bne         :+
    lda         #0
    rts                             ; sold out
:
    lda         itemActive,x
    beq         :+
    inx
    rts
:
    inx
    jmp         findNextItem

.endproc

;------------------------------
; Load Item
;   Pass item in lastItem
;------------------------------

.proc loadItem
    ldx         lastItem
    lda         itemList,x
    asl
    asl
    asl
    asl                                 ; * 16
    clc
    adc         #<inventoryTable
    sta         itemPtr0
    lda         #>inventoryTable
    adc         #0
    sta         itemPtr1

    ; Set string pointer to description
    ldy         #INVENTORY_DESCRIPTION
    lda         (itemPtr0),y
    sta         stringPtr0
    iny
    lda         (itemPtr0),y
    sta         stringPtr1

    ; Store BCD value index
    ldy         #INVENTORY_VALUE
    lda         (itemPtr0),y
    sta         itemValue

    ; Store ARG as BCD_ITEM_ARG as well as itemArg byte
    ldy         #INVENTORY_ARG
    lda         (itemPtr0),y
    sta         itemArg
    sta         costBase
    iny
    lda         (itemPtr0),y
    tay
    ldx         #BCD_ITEM_ARG
    stx         bcdIndex1
    lda         costBase
    jsr         bcdSet

    ; Store cost in BCD_ITEM_COST (if 0, use value)
    ldy         #INVENTORY_COST
    lda         (itemPtr0),y
    bne         :+

    ; if cost is 0, use value
    ldx         #BCD_ITEM_COST
    ldy         itemValue
    jsr         bcdCopy
    jmp         setTile
:
    ldy         #INVENTORY_COST
    lda         (itemPtr0),y
    sta         costBase
    iny
    lda         (itemPtr0),y
    tay
    ldx         #BCD_ITEM_COST
    lda         costBase
    jsr         bcdSet

setTile:
    ldy         #INVENTORY_TILE
    lda         (itemPtr0),y
    ldx         lastItem
    sta         itemTile,x

    ldy         #INVENTORY_ICON
    ldx         lastItem
    lda         (itemPtr0),y
    sta         itemIcon0,x
    iny
    lda         (itemPtr0),y
    sta         itemIcon1,x

    rts

costBase:           .byte   0

.endproc

;------------------------------
; Remove Item
;   Make item unavailable
;------------------------------

.proc removeItem

    ; find an occurence of item
    ldx         lastItem
    lda         itemList,x
    ldy         #0
removeLoop:
    cmp         itemAvailable,y
    beq         :+
    iny
    bne         removeLoop

    brk         ; how can we remove an item that isn't available?
:
    lda         #0
    sta         itemAvailable,y
    rts

.endproc

;-----------------------------------------------------
; Data
;-----------------------------------------------------

lastItem:           .byte   0

; current item

itemValue:          .byte       0
itemArg:            .byte       0
; also:
;   stringPtr0
;   BCD_ITEM_COST
;   BCD_ITEM_ARG

; displated items
itemIcon0:
    .byte   0
    .byte   0
    .byte   0
    .byte   0
    .byte   0

itemIcon1:
    .byte   0
    .byte   0
    .byte   0
    .byte   0
    .byte   0

itemList:           ; Points into inventory table
    .byte   0       ; item 0 doesn't exit
    .byte   1       ; item 1 always reroll
    .byte   0       ; item 2
    .byte   0       ; item 3
    .byte   0       ; item 4

itemTile:
    .byte   TILE_STORE_SOLD_OUT
    .byte   TILE_STORE_REROLL
    .byte   TILE_STORE_ROCK
    .byte   TILE_STORE_ROCK
    .byte   TILE_STORE_DRINK

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
    .byte   "CASH:   $",STRING_NEWLINE
    .byte   "ENERGY: &",STRING_NEWLINE
    .byte   "COST:   $0",STRING_NEWLINE
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

.define COMBINE_CHAR(ta,tb) (ta & $3f)+(tb & $3f)*256
STORE_ICON_NONE             = COMBINE_CHAR(' ',' ')
STORE_ICON_ADD_VALUE        = COMBINE_CHAR('+','$')
STORE_ICON_ADD_ENERGY       = COMBINE_CHAR('+','$')
STORE_ICON_INCREASE         = COMBINE_CHAR('+',' ')

INVENTORY_DESCRIPTION       = 0
INVENTORY_COST              = 2
INVENTORY_ACTION            = 4
INVENTORY_VALUE             = 6
INVENTORY_ARG               = 8
INVENTORY_TILE              = 10
INVENTORY_ICON              = 12

INVENTORY_ITEM_SOLD_OUT     = inventoryTable

;           Description,            cost,   action,                     value,            arg,   tile,                icon,                   reserved
inventoryTable:     ; 16 bytes per entry
    .word   descriptionOut,         $0000,  STORE_ACTION_NONE,          BCD_ZERO,         $0000, TILE_STORE_SOLD_OUT, STORE_ICON_NONE,        0
    .word   descriptionRe,          $0000,  STORE_ACTION_REROLL,        BCD_REROLL_COST,  $0000, TILE_STORE_REROLL,   STORE_ICON_NONE,        0
    .word   descriptionRockP,       $0020,  STORE_ACTION_ADD_VALUE,     BCD_ROCK_VALUE,   $0005, TILE_STORE_ROCK,     STORE_ICON_ADD_VALUE,   0
    .word   descriptionRockP,       $0040,  STORE_ACTION_ADD_VALUE,     BCD_ROCK_VALUE,   $0010, TILE_STORE_ROCK,     STORE_ICON_ADD_VALUE,   0
    .word   descriptionEnergy,      $0101,  STORE_ACTION_ADD_ENERGY,    BCD_INVALID,      $0004, TILE_STORE_DRINK,    STORE_ICON_ADD_ENERGY,  0
    .word   descriptionDynamite,    $0080,  STORE_ACTION_ADD_DYNAMITE,  BCD_INVALID,      $0001, TILE_STORE_DYNAMITE, STORE_ICON_INCREASE,    0

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
    .res        256

itemAvailable:              ; Inventory index.  Set to 0 if item is sold making it unavailable (except reroll)
    .byte       2           ; rock+5
    .byte       3           ; rock+10
    .byte       4           ; max energy + 4
    .byte       4           ; max energy + 4
    .byte       5           ; dynamite
    .res        256-4

itemActive:                 ; Shuffled list of active items
    .res        256