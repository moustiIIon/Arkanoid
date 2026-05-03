SECTION "Menu", ROM0

GlobalMenuInit:
    ld de, Menu_Tileset_Begin
    ld hl, $9000
    ld bc, Menu_Tileset_End - Menu_Tileset_Begin
    call MemCpy

    ld de, Menu_Map_Begin
    ld hl, $9800
    ld bc, Menu_Map_End - Menu_Map_Begin
    call MemCpy

    ld a, 0
    ld [wSelectedGame], a

    ld a, LCDC_ON | LCDC_BG_ON
    ld [rLCDC], a
    ld a, %11100100
    ld [rBGP], a

    ld a, 0
    ld [wCurKeys], a
    ld [wNewKeys], a
GlobalMenuLoop:
.waitNotVBlank:
    ld a, [rLY]
    cp 144
    jp nc, .waitNotVBlank

.waitVBlank:
    ld a, [rLY]
    cp 144
    jp c, .waitVBlank

    call UpdateKeys

    ; Vérifier UP
    ld a, [wNewKeys]
    and PAD_UP
    jr nz, MenuMoveUp

    ; Vérifier DOWN
    ld a, [wNewKeys]
    and PAD_DOWN
    jr nz, MenuMoveDown

    ; Vérifier START
    ld a, [wNewKeys]
    and PAD_START
    jr nz, MenuGameSelect

    jp GlobalMenuLoop

MenuMoveUp:
    ld a, [wSelectedGame]
    cp a, 0
    jp z, GlobalMenuLoop

    ld a, 0
    ld [wSelectedGame], a
    call UpdateCursor
    jp GlobalMenuLoop

MenuMoveDown:
    ld a, [wSelectedGame]
    cp a, 1
    jp z, GlobalMenuLoop

    ld a, 1
    ld [wSelectedGame], a
    call UpdateCursor
    jp GlobalMenuLoop

MenuGameSelect:
    ld a, [wSelectedGame]
    cp a, 0
    jp z, LaunchArkanoid
    jp LaunchReact

LaunchArkanoid:
    ld a, 0
    ld [rLCDC], a
    jp BrickInit

LaunchReact:
    ld a, 0
    ld [rLCDC], a
    jp GlobalMenuInit 
    ; ici mettre le init de reatc quand il sera implementé

; ============================================================================================================
; efface le curseur et dessine sur le bon jeu seclectionné
; ============================================================================================================

UpdateCursor:
    ld hl, $9884
    ld a, $00
    ld [hl], a
    ld hl, $98C4
    ld a, $00
    ld [hl], a

    ld a, [wSelectedGame]
    cp a, 0
    jr z, .cursorArkanoid
.cursorReact:
    ld hl, $98C4
    ld a, $0B
    ld [hl], a
    ret
.cursorArkanoid:
    ld hl, $9884
    ld a, $0B
    ld [hl], a
    ret

; ============================================================================================================
; les variables
; ============================================================================================================
SECTION "Menu Variables", WRAM0
wSelectedGame: db