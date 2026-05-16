INCLUDE "hardware.inc"

DEF hDMAWait EQU $FF80  ; adresse HRAM de la routine d'attente DMA

; Offsets dans le tampon OAM fantôme (base = wShadowOAM, aligné sur 256 octets)
DEF OAM_BOSS EQU $00 ; sprites 0-5 : Sakuya
DEF OAM_REIMU EQU $18 ; sprites 6-11 : Reimu
DEF OAM_PBUL0 EQU $30 ; sprite 12 : balle joueur 0
DEF OAM_PBUL1 EQU $34 ; sprite 13 : balle joueur 1
DEF OAM_PBUL2 EQU $38 ; sprite 14 : balle joueur 2
DEF OAM_BOSS_BUL EQU $3C ; sprites 15+ : ennemis / balles boss

SECTION "Touhou Game", ROM0

; Routine copiée en HRAM - CPU limité à HRAM pendant le DMA (~160 cycles)
DMAWaitRoutine:
    ld a, 40
.loop:
    dec a
    jr nz, .loop
    ret
DMAWaitRoutine_End:

TouhouInit:
    call CommonInit

    ; copier la routine d'attente DMA en HRAM
    ld de, DMAWaitRoutine
    ld hl, hDMAWait
    ld bc, DMAWaitRoutine_End - DMAWaitRoutine
    call MemCpy

    ; initialiser le tampon OAM fantôme à zéro
    ld hl, wShadowOAM
    ld b, 160
    xor a
.clearShadow:
    ld [hli], a
    dec b
    jr nz, .clearShadow

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
    ld [wTouhouWinDrawn], a
    ld [wTouhouOverDrawn], a
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

SECTION "Shadow OAM", WRAM0, ALIGN[8]
wShadowOAM: ds 160

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
wBossShootTimer: db
wBossBulSlot: db
wBossPhase: db

wBossBulX: ds 12
wBossBulY: ds 12
wBossBulActive: ds 12
wBossBulDY: ds 12
wBossBulDX: ds 12

wTouhouWinDrawn: db
wTouhouOverDrawn: db
