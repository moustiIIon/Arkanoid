INCLUDE "hardware.inc"

; Layout OAM (priorité max -> min, index bas = plus prioritaire)
DEF OAM_BOSS     EQU $FE00  ; sprites  0-5  ($FE00-$FE17) : Sakuya
DEF OAM_REIMU    EQU $FE18  ; sprites  6-11 ($FE18-$FE2F) : Reimu
DEF OAM_PBUL0    EQU $FE30  ; sprite  12    ($FE30-$FE33) : balle joueur 0
DEF OAM_PBUL1    EQU $FE34  ; sprite  13    ($FE34-$FE37) : balle joueur 1
DEF OAM_PBUL2    EQU $FE38  ; sprite  14    ($FE38-$FE3B) : balle joueur 2
DEF OAM_BOSS_BUL EQU $FE3C  ; sprites 15+   ($FE3C+)      : ennemis / balles boss

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
wBossDX: db
