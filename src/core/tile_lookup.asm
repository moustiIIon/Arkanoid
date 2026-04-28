SECTION "Tile Lookup", ROM0

GetTileByPixel:
    ld a, c
    and a, %11111000
    ld l, a
    ld h, 0
    add hl, hl
    add hl, hl
    ld a, b
    srl a
    srl a
    srl a
    add a, l
    ld l, a
    adc a, h
    sub a, l
    ld h, a
    ld bc, $9800
    add hl, bc
    ret
