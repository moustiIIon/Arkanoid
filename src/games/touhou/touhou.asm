INCLUDE "hardware.inc"
SECTION "Touhou Game", ROM0

DEF TOUHOU_STATE_GAME EQU 0
DEF TOUHOU_STATE_OVER EQU 1

TouhouInit:
    call CommonInit

    ld de, Touhou_Sprite_Begin
    ld hl, $8000
    ld bc, Touhou_Sprite_End - Touhou_Sprite_Begin
    call MemCpy

    ld a, 72
    ld [wPlayerX], a
    ld a, 80
    ld [wPlayerY], a

    ;init WRAM
    xor a
    ld [wTouhouState], a
    ld [wCurKeys], a
    ld [wNewKeys], a
    ld [wPBullet0Active], a
    ld [wPBullet1Active], a
    ld [wPBullet2Active], a
    ld [wFireCooldown], a

    ld a, LCDC_ON | LCDC_BG_ON | LCDC_OBJ_ON | LCDC_OBJ_16
    ld [rLCDC], a
    ld a, %11100100
    ld [rBGP], a
    ld a, %11100100
    ld [rOBP0], a

TouhouLoop:
    call MyWaitVBlank
    call UpdateKeys

    ld a, [wTouhouState]
    cp TOUHOU_STATE_GAME
    jp z, TouhouGameScreen
    cp TOUHOU_STATE_OVER
    jp z, TouhouGameOver
    jp TouhouLoop

SECTION "Touhou Vars", WRAM0
wTouhouState: db
wPlayerX: db
wPlayerY: db
wPBullet0X: db
wPBullet0Y: db
wPBullet0Active: db
wPBullet1X: db
wPBullet1Y: db
wPBullet1Active: db
wPBullet2X: db
wPBullet2Y: db
wPBullet2Active: db
wFireCooldown: db
