SECTION "MemCpy", ROM0

MemCpy:
    ld a, [de]
    ld [hli], a
    inc de
    dec bc
    ld a, b
    or a, c
    jp nz, MemCpy
    ret
