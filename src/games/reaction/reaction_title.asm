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

SECTION "React Title Vars", WRAM0
wAnimFrame: db
wAnimTimer: db
