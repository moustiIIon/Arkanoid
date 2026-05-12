SECTION "Touhou Game Screen", ROM0

DEF PLAYER_SPEED  EQU 2
DEF PLAYER_X_MIN  EQU 0
DEF PLAYER_X_MAX  EQU 144
DEF PLAYER_Y_MIN  EQU 0
DEF PLAYER_Y_MAX  EQU 112
DEF BULLET_SPEED  EQU 3
DEF BULLET_TILE   EQU 8

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

    jp TouhouLoop

TouhouGameOver:
    ld a, [wNewKeys]
    and PAD_START
    jp z, TouhouLoop
    call TransitionScreenToBlack
    xor a
    ld [rLCDC], a
    jp GlobalMenuInit
