SECTION "Transition", ROM0

; ecran de base jusqu'a la couleur noir
TransitionScreenToBlack:
    ld a, %11100100
    ldh [rBGP], a
    call TransitionWait
    ld a, %11111001
    ldh [rBGP], a
    call TransitionWait
    ld a, %11111110
    ldh [rBGP], a
    call TransitionWait
    ld a, %11111111
    ldh [rBGP], a
    call TransitionWait
    ret

GameTransitionToStartFaster:
    ld a, %11100100
    ldh [rBGP], a
    call GameTransitionWait
    ld a, %11111001
    ldh [rBGP], a
    call GameTransitionWait
    ld a, %11111110
    ldh [rBGP], a
    call GameTransitionWait
    ld a, %11111111
    ldh [rBGP], a
    call GameTransitionWait
    ret

TransitionWait:
    ; on attend "n" frame sinon trop rapide ou trop lent, on peut modifier ici comme par exemple 16 sera plus long
    ld b, 8
.loop:
.waitNotVBlank:
    ldh a, [rLY]
    cp 144
    jp nc, .waitNotVBlank
.waitVBlank:
    ldh a, [rLY]
    cp 144
    jp c, .waitVBlank
    dec b
    jr nz, .loop
    ret

GameTransitionWait:
    ld b, 3
.loop:
.GamewaitNotVBlank:
    ldh a, [rLY]
    cp 144
    jp nc, .GamewaitNotVBlank
.GamewaitVBlank:
    ldh a, [rLY]
    cp 144
    jp c, .GamewaitVBlank
    dec b
    jr nz, .loop
    ret

