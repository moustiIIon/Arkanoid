SECTION "My WaitVBlank", ROM0

MyWaitVBlank:
.waitOut:
    ld a, [rLY]
    cp 144
    jp nc .waitOut

.waitIn
    ld a, [rLY]
    cp 144
    jp c, .waitIn
    ret
