SECTION "Games Common Init", ROM0

CommonInit:
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
    ld hl, $FE00
    ld b, 160
    xor a
.clearOam:
    ld [hli], a
    dec b
    jr nz, .clearOam
    ret
