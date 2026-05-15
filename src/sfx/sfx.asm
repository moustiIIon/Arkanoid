; started sfx

SECTION "SFX", ROM0

InitAndStartAPU:
    ld a, $80
    ldh [rNR52], a
    ld a, $77
    ldh [rNR50], a
    ld a, $FF
    ldh [rNR51], a
    ret


MusicSelectSfx:
    ld a, $16
    ldh [rNR10], a
    ld a, $C0
    ldh [rNR11], a
    ld a, $F2
    ldh [rNR12], a
    ld a, $A0
    ldh [rNR13], a
    ld a, $C6
    ldh [rNR14], a
    ret

BrickBreakSfx:
    ld a, $16
    ldh [rNR10], a
    ld a, $80
    ldh [rNR11], a
    ld a, $F1
    ldh [rNR12], a
    ld a, $D0
    ldh [rNR13], a
    ld a, $C4
    ldh [rNR14], a
    ret
