SECTION "My WaitVBlank", ROM0

MyWaitVBlank:
.waitOut: ;while LY >= 144 wait
    ld a, [rLY] ;rLY dit en permanence ql ligne est entrain d'être dessiné
    cp 144 ;a - 144, derniere ligne dessinée
    jp nc, .waitOut ;jump si a >= 144 <=> not carry

.waitIn ;while LY < 144 wait
    ld a, [rLY]
    cp 144
    jp c, .waitIn ;jump si a < 144 <=> carry
    ret
