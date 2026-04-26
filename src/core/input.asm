SECTION "Input", ROM0

UpdateKeys:
    ld a, JOYP_GET_BUTTONS
    call .onenibble
    ld b, a

    ld a, JOYP_GET_CTRL_PAD
    call .onenibble
    swap a
    xor a, b
    ld b, a

    ld a, JOYP_GET_NONE
    ldh [rJOYP], a

    ld a, [wCurKeys]
    xor a, b
    and a, b
    ld [wNewKeys], a
    ld a, b
    ld [wCurKeys], a
    ret

.onenibble
    ldh [rJOYP], a
    call .knownret
    ldh a, [rJOYP]
    ldh a, [rJOYP]
    ldh a, [rJOYP]
    or a, $F0
.knownret
    ret


SECTION "Input Variables", WRAM0
wCurKeys: db
wNewKeys: db
