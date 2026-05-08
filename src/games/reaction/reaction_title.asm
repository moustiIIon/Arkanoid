SECTION "Reaction Title", ROM0

ReactTitleScreen:
    xor a
    ld [rLCDC], a

    ld de, Shared_Tileset_Begin
    ld hl, $9000
    ld bc, Shared_Tileset_End - Shared_Tileset_Begin
    call MemCpy

    ld hl, $9800
    ld bc, 1024
.clearMap:
    xor a
    ld [hli], a
    dec bc
    ld a, b
    or a, c
    jp nz, .clearMap

    ; "REACT" row 4 col 8 = $9888
    ld hl, $9888
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

    ; "START" row 8 col 8 = $9908
    ld hl, $9908
    ld a, TILE_S
    ld [hli], a
    ld a, TILE_T
    ld [hli], a
    ld a, TILE_A
    ld [hli], a
    ld a, TILE_R
    ld [hli], a
    ld a, TILE_T
    ld [hl], a

    ; cadre : remplir les 16 positions avec TILE_BORDER
    ld c, 0
.initBorder:
    ld a, c
    call GetBorderAddr
    ld a, TILE_BORDER
    ld [hl], a
    inc c
    ld a, c
    cp 16
    jr nz, .initBorder

    xor a
    ld [wAnimFrame], a
    ld [wAnimTimer], a
    call DrawBorderHL

    ld a, LCDC_ON | LCDC_BG_ON
    ld [rLCDC], a
    ld a, %11100100
    ld [rBGP], a

    ; attendre que START soit relâché (évite de catcher le START du menu)
.waitNotStart:
    call UpdateKeys
    ld a, [wCurKeys]
    and PAD_START
    jr nz, .waitNotStart

.titleLoop:
    call MyWaitVBlank
    call UpdateKeys
    call UpdateTitleAnim
    ld a, [wNewKeys]
    and PAD_START
    jr z, .titleLoop

    call TransitionScreenToBlack
    xor a
    ld [rLCDC], a
    jp ReactionInit

UpdateTitleAnim:
    ld a, [wAnimTimer]
    inc a
    ld [wAnimTimer], a
    cp 4
    ret nz
    xor a
    ld [wAnimTimer], a

    ; effacer position courante
    ld a, [wAnimFrame]
    call GetBorderAddr
    ld a, TILE_BORDER
    ld [hl], a

    ; avancer le frame (0-15)
    ld a, [wAnimFrame]
    inc a
    cp 16
    jr nz, .noWrap
    xor a
.noWrap:
    ld [wAnimFrame], a
    call DrawBorderHL
    ret

DrawBorderHL:
    ld a, [wAnimFrame]
    call GetBorderAddr
    ld a, TILE_BORDER_HL
    ld [hl], a
    ret

GetBorderAddr:
    ; a = index (0-15) → hl = adresse tilemap
    ld hl, ReactBorderPositions
    ld b, 0
    ld c, a
    add hl, bc
    add hl, bc ; hl = base + index*2
    ld a, [hli] ; octet bas (little-endian)
    ld h, [hl] ; octet haut
    ld l, a
    ret

ReactBorderPositions:
    ; cadre horaire autour de "START" (row 8, cols 8-12)
    dw $98E7, $98E8, $98E9, $98EA, $98EB, $98EC, $98ED  ; haut (row 7, cols 7-13)
    dw $990D ; droite (row 8, col 13)
    dw $992D, $992C, $992B, $992A, $9929, $9928, $9927  ; bas (row 9, cols 13-7)
    dw $9907 ; gauche (row 8, col 7)

SECTION "React Title Vars", WRAM0
wAnimFrame: db
wAnimTimer: db
