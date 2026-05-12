SECTION "Menu", ROM0

GlobalMenuInit:
    call InitAllSram
    ld de, Shared_Tileset_Begin
    ld hl, $9000
    ld bc, Shared_Tileset_End - Shared_Tileset_Begin
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

    dec a
    ld [wSelectedGame], a
    call UpdateCursor
    jp GlobalMenuLoop

MenuMoveDown:
    ld a, [wSelectedGame]
    cp a, 3
    jp z, GlobalMenuLoop

    inc a
    ld [wSelectedGame], a
    call UpdateCursor
    jp GlobalMenuLoop

MenuGameSelect:
    ld a, [wSelectedGame]
    cp a, 0
    jp z, LaunchArkanoid
    cp a, 1
    jp z, LaunchReact
    cp a, 2
    jp z, LaunchTouhou
    jp LeaderboardScreen

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
    call TransitionScreenToBlack
    ld a, 0
    ld [rLCDC], a
    jp ReactTitleScreen

LaunchTouhou:
    call TransitionScreenToBlack
    ld a, 0
    ld [rLCDC], a
    jp TouhouInit

; efface le curseur et dessine sur le bon jeu seclectionné

UpdateCursor:
    xor a
    ld hl, $9884
    ld [hl], a
    ld hl, $98C4
    ld [hl], a
    ld hl, $9904
    ld [hl], a
    ld hl, $9944
    ld [hl], a

    ld a, [wSelectedGame]
    cp a, 0
    jr z, .cursorArkanoid
    cp a, 1
    jr z, .cursorReact
    cp a, 2
    jr z, .cursorTouhou
.cursorScores:
    ld hl, $9944
    ld a, $0B
    ld [hl], a
    ret
.cursorTouhou:
    ld hl, $9904
    ld a, $0B
    ld [hl], a
    ret
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

LeaderboardScreen:
    xor a
    ld [rLCDC], a

    ; vider tilemap
    ld hl, $9800
    ld bc, 1024
.clearMap:
    xor a
    ld [hli], a
    dec bc
    ld a, b
    or a, c
    jp nz, .clearMap

    ; "ARK" row 2 col 5 = $9845
    ld hl, $9845
    ld a, TILE_A
    ld [hli], a
    ld a, TILE_R
    ld [hli], a
    ld a, TILE_K
    ld [hl], a

    ; "REACT" row 9 col 4 = $9924
    ld hl, $9924
    ld a, TILE_R
    ld [hli], a
    ld a, TILE_E
    ld [hli], a
    ld a, TILE_A
    ld [hli], a
    ld a, TILE_C
    ld [hli], a
    ld a, TILE_T
    ld [hl], a

    call EnableSRAM

    ; scores brick (BCD)- rows 4/5/6, col 5
    ld hl, $9885
    ld a, [SRAM_SCORE1]
    call DrawBCDScore

    ld hl, $98A5
    ld a, [SRAM_SCORE2]
    call DrawBCDScore

    ld hl, $98C5
    ld a, [SRAM_SCORE3]
    call DrawBCDScore

    ; scores react (binaire) - rows 11/12/13, col 5
    ld hl, $9965
    ld a, [SRAM_REACT_SCORE1]
    call DrawBinaryScore

    ld hl, $9985
    ld a, [SRAM_REACT_SCORE2]
    call DrawBinaryScore

    ld hl, $99A5
    ld a, [SRAM_REACT_SCORE3]
    call DrawBinaryScore

    call DisableSRAM

    ld a, LCDC_ON | LCDC_BG_ON
    ld [rLCDC], a
    ld a, %11100100
    ld [rBGP], a

.leaderboardLoop:
    call MyWaitVBlank
    call UpdateKeys
    ld a, [wNewKeys]
    and PAD_START
    jr z, .leaderboardLoop
    jp GlobalMenuInit

DrawBCDScore:
    ; a = score BCD, hl = destination tilemap (écrit 2 tiles)
    ld b, a
    and %11110000
    rrca
    rrca
    rrca
    rrca
    add a, TILE_0
    ld [hli], a
    ld a, b
    and %00001111
    add a, TILE_0
    ld [hl], a
    ret

DrawBinaryScore:
    ; a = score binaire (0-25), hl = destination tilemap (écrit 2 tiles)
    ld b, 0
.divLoop:
    cp 10
    jr c, .divDone
    sub 10
    inc b
    jr .divLoop
.divDone:
    ld c, a
    ld a, b
    add a, TILE_0
    ld [hli], a
    ld a, c
    add a, TILE_0
    ld [hl], a
    ret

SECTION "Menu Variables", WRAM0
wSelectedGame: db