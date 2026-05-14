INCLUDE "hardware.inc"
SECTION "Touhou Game", ROM0

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

    xor a
    ld [wTouhouState], a
    ld [wCurKeys], a
    ld [wNewKeys], a
    ld [wPBullet0Active], a
    ld [wPBullet1Active], a
    ld [wPBullet2Active], a
    ld [wFireCooldown], a
    ld [wFireSlot], a
    ld [wTouhouFrame], a
    ld [wInvincTimer], a
    ld [wWaveIndex], a
    ld [wBossActive], a
    ld [wBossHP], a
    ld a, 5
    ld [wPlayerLives], a

    call TouhouWaveInit

    ld a, LCDC_ON | LCDC_BG_ON | LCDC_OBJ_ON
    ld [rLCDC], a
    ld a, %11100100
    ld [rBGP], a
    ld a, %11100100
    ld [rOBP0], a

TouhouLoop:
    call MyWaitVBlank
    call TouhouRenderOAM
    call UpdateKeys

    ld a, [wTouhouFrame]
    inc a
    ld [wTouhouFrame], a

    ld a, [wTouhouState]
    cp TOUHOU_STATE_WAVE
    jp z, TouhouGameScreen
    cp TOUHOU_STATE_BOSS
    jp z, TouhouGameScreen
    cp TOUHOU_STATE_WIN
    jp z, TouhouWinScreen
    cp TOUHOU_STATE_OVER
    jp z, TouhouGameOver
    jp TouhouLoop

SECTION "Touhou Vars", WRAM0
wTouhouState: db
wTouhouFrame: db
wPlayerX: db
wPlayerY: db
wPlayerLives: db
wInvincTimer: db
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
wFireSlot: db

wBossActive: db
wBossHP: db
wBossX: db
wBossY: db
wBossPhase: db
wBossDX: db
wBossShootTimer: db

; boss qui tire des balles
wBossBulX: ds 24
wBossBulY: ds 24
wBossBulActive: ds 24
wBossBulDX: ds 24
wBossBulDY: ds 24

; submoids boss phase 2 
wSub0X: db
wSub0Y: db
wSub0HP: db
wSub0Active: db
wSub0BulX: db
wSub0BulY: db
wSub0BulActive: db
wSub0ShootTimer: db

wSub1X: db
wSub1Y: db
wSub1HP: db
wSub1Active: db
wSub1BulX: db
wSub1BulY: db
wSub1BulActive: db
wSub1ShootTimer: db
