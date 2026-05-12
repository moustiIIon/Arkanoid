SECTION "Touhou Game Screen", ROM0

DEF PLAYER_SPEED EQU 2
DEF PLAYER_X_MIN EQU 0
DEF PLAYER_X_MAX EQU 144
DEF PLAYER_Y_MIN EQU 0
DEF PLAYER_Y_MAX EQU 112
DEF BULLET_SPEED EQU 4
DEF BULLET_FRAMES EQU 10
DEF BULLET_TILE EQU 8

TouhouGameScreen:
    ld a, [wCurKeys]
    and PAD_LEFT
    jr z, .checkRight
    ld a, [wPlayerX]
    sub PLAYER_SPEED
    jr c, .clampLeft
    cp PLAYER_X_MIN
    jr nc, .applyLeft
.clampLeft:
    ld a, PLAYER_X_MIN
.applyLeft:
    ld [wPlayerX], a

.checkRight:
    ld a, [wCurKeys]
    and PAD_RIGHT
    jr z, .checkUp
    ld a, [wPlayerX]
    add a, PLAYER_SPEED
    jr c, .clampRight
    cp PLAYER_X_MAX
    jr c, .applyRight
.clampRight:
    ld a, PLAYER_X_MAX
.applyRight:
    ld [wPlayerX], a

.checkUp:
    ld a, [wCurKeys]
    and PAD_UP
    jr z, .checkDown
    ld a, [wPlayerY]
    sub PLAYER_SPEED
    jr c, .clampUp
    cp PLAYER_Y_MIN
    jr nc, .applyUp
.clampUp:
    ld a, PLAYER_Y_MIN
.applyUp:
    ld [wPlayerY], a

.checkDown:
    ld a, [wCurKeys]
    and PAD_DOWN
    jr z, .checkFire
    ld a, [wPlayerY]
    add a, PLAYER_SPEED
    jr c, .clampDown
    cp PLAYER_Y_MAX
    jr c, .applyDown
.clampDown:
    ld a, PLAYER_Y_MAX
.applyDown:
    ld [wPlayerY], a

.checkFire:
    ; decrementer cooldown chaque frame
    ld a, [wFireCooldown]
    cp 0
    jr z, .cooldownDone
    dec a
    ld [wFireCooldown], a
    jr .updateBullets
.cooldownDone:
    ld a, [wCurKeys]
    and PAD_A
    jr z, .updateBullets
    ; reset cooldown (10 frames entre chaque bullet)
    ld a, BULLET_FRAMES
    ld [wFireCooldown], a

    ; round-robin : ecrire dans le slot courant et avancer
    ld a, [wPlayerX]
    add a, 4
    ld b, a
    ld a, [wPlayerY]
    ld c, a

    ld a, [wFireSlot]
    cp 1
    jr z, .fireSlot1
    cp 2
    jr z, .fireSlot2

.fireSlot0:
    ld a, 1
    ld [wPBullet0Active], a
    ld a, b
    ld [wPBullet0X], a
    ld a, c
    ld [wPBullet0Y], a
    ld a, 1
    ld [wFireSlot], a
    jr .updateBullets

.fireSlot1:
    ld a, 1
    ld [wPBullet1Active], a
    ld a, b
    ld [wPBullet1X], a
    ld a, c
    ld [wPBullet1Y], a
    ld a, 2
    ld [wFireSlot], a
    jr .updateBullets

.fireSlot2:
    ld a, 1
    ld [wPBullet2Active], a
    ld a, b
    ld [wPBullet2X], a
    ld a, c
    ld [wPBullet2Y], a
    xor a
    ld [wFireSlot], a

.updateBullets:
    ld a, [wPBullet0Active]
    cp 0
    jr z, .upd1
    ld a, [wPBullet0Y]
    sub BULLET_SPEED
    jr c, .deact0 ; sorti par le haut
    ld [wPBullet0Y], a
    jr .upd1
.deact0:
    xor a
    ld [wPBullet0Active], a

.upd1:
    ld a, [wPBullet1Active]
    cp 0
    jr z, .upd2
    ld a, [wPBullet1Y]
    sub BULLET_SPEED
    jr c, .deact1
    ld [wPBullet1Y], a
    jr .upd2
.deact1:
    xor a
    ld [wPBullet1Active], a

.upd2:
    ld a, [wPBullet2Active]
    cp 0
    jr z, .updateOAM
    ld a, [wPBullet2Y]
    sub BULLET_SPEED
    jr c, .deact2
    ld [wPBullet2Y], a
    jr .updateOAM
.deact2:
    xor a
    ld [wPBullet2Active], a

.updateOAM:
    ; sprites 0-3 : Reimu (16x32, 4 entrees 8x16)
    ld a, [wPlayerY]
    add a, 16
    ld [$FE00], a
    ld a, [wPlayerX]
    add a, 8
    ld [$FE01], a
    xor a
    ld [$FE02], a
    ld [$FE03], a

    ld a, [wPlayerY]
    add a, 16
    ld [$FE04], a
    ld a, [wPlayerX]
    add a, 16
    ld [$FE05], a
    ld a, 2
    ld [$FE06], a
    xor a
    ld [$FE07], a

    ld a, [wPlayerY]
    add a, 32
    ld [$FE08], a
    ld a, [wPlayerX]
    add a, 8
    ld [$FE09], a
    ld a, 4
    ld [$FE0A], a
    xor a
    ld [$FE0B], a

    ld a, [wPlayerY]
    add a, 32
    ld [$FE0C], a
    ld a, [wPlayerX]
    add a, 16
    ld [$FE0D], a
    ld a, 6
    ld [$FE0E], a
    xor a
    ld [$FE0F], a

    ; sprite 4 : bullet 0
    ld a, [wPBullet0Active]
    cp 0
    jr z, .hideBullet0
    ld a, [wPBullet0Y]
    add a, 16
    ld [$FE10], a
    ld a, [wPBullet0X]
    add a, 8
    ld [$FE11], a
    ld a, BULLET_TILE
    ld [$FE12], a
    xor a
    ld [$FE13], a
    jr .oamBullet1
.hideBullet0:
    xor a
    ld [$FE10], a

    ; sprite 5 : bullet 1
.oamBullet1:
    ld a, [wPBullet1Active]
    cp 0
    jr z, .hideBullet1
    ld a, [wPBullet1Y]
    add a, 16
    ld [$FE14], a
    ld a, [wPBullet1X]
    add a, 8
    ld [$FE15], a
    ld a, BULLET_TILE
    ld [$FE16], a
    xor a
    ld [$FE17], a
    jr .oamBullet2
.hideBullet1:
    xor a
    ld [$FE14], a

    ; sprite 6 : bullet 2
.oamBullet2:
    ld a, [wPBullet2Active]
    cp 0
    jr z, .hideBullet2
    ld a, [wPBullet2Y]
    add a, 16
    ld [$FE18], a
    ld a, [wPBullet2X]
    add a, 8
    ld [$FE19], a
    ld a, BULLET_TILE
    ld [$FE1A], a
    xor a
    ld [$FE1B], a
    jp TouhouLoop
.hideBullet2:
    xor a
    ld [$FE18], a

    jp TouhouLoop

TouhouGameOver:
    ld a, [wNewKeys]
    and PAD_START
    jp z, TouhouLoop
    call TransitionScreenToBlack
    xor a
    ld [rLCDC], a
    jp GlobalMenuInit
