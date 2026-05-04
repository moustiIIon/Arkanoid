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

; le main entre guillemet
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

; transition comme pokemon red gameboy, pour transitionner vers les jeux chacun, petit a petit ecran noir
; bon je penses ne pas faire comme pour un combat mais plus comme lorsque l'on rentre dans une grotte ou en passant par une porte donc
; blanc, gris clairn, gris foncé et noir pour ensuite jump au jeu comme ca plus pratique et bonne transition gameboy visuelle c'est cool

LaunchArkanoid:
    ; ici transition
    call TransitionScreenToBlack
    ld a, 0
    ld [rLCDC], a
    jp BrickInit

LaunchReact:
    ; ici transition
    call TransitionScreenToBlack
    ld a, 0
    ld [rLCDC], a
    jp ReactionInit

; efface le curseur et dessine sur le bon jeu seclectionné

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

SECTION "Menu Variables", WRAM0
wSelectedGame: db