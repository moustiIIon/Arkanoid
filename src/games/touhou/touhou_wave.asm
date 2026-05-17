SECTION "Touhou Wave", ROM0

DEF TOUHOU_STATE_WAVE EQU 0
DEF TOUHOU_STATE_BOSS EQU 1
DEF TOUHOU_STATE_WIN EQU 2
DEF TOUHOU_STATE_OVER EQU 3

DEF ENEMY_COUNT EQU 4
DEF ENEMY_HP_INIT EQU 2
DEF ENEMY_SPEED EQU 1
DEF ENEMY_BULLET_SPD EQU 3
DEF ENEMY_SHOOT_RATE EQU 20

DEF HITBOX_OFF_X EQU 6
DEF HITBOX_OFF_Y EQU 10
DEF HITBOX_SIZE EQU 4
DEF INVINC_FRAMES EQU 60

DEF ENEMY_TILE EQU 7
DEF ENBUL_TILE EQU 8
DEF BOSS_TILE  EQU 9 ; Sakuya 2x3 tiles (9-14), grille identique à Reimu

DEF WAVE_X0     EQU 8
DEF WAVE_X1     EQU 44
DEF WAVE_X2     EQU 80
DEF WAVE_X3     EQU 116
DEF WAVE_EDGE_L EQU 0
DEF WAVE_EDGE_R EQU 160
DEF WAVE2_Y0    EQU 20
DEF WAVE2_Y1    EQU 50

;remplis 4 octets consécutifs en WRAM avec une valeur immédiate
;usage : FILL4 adresse, valeur
MACRO FILL4
    ld hl, \1
    ld a, \2
    ld [hli], a
    ld [hli], a
    ld [hli], a
    ld [hl], a
ENDM

TouhouWaveInit:
    xor a
    ld [wWaveIndex], a
    call SpawnWave
    ret

SpawnWave:
    ld a, [wWaveIndex]
    cp 0
    jr z, .wave0
    cp 1
    jr z, .wave1
    cp 2
    jr z, .wave2
    ld a, TOUHOU_STATE_BOSS
    ld [wTouhouState], a
    call BossInit
    ret

.wave0:
    ; diagonale (haut gauche vers bas droite) : X=WAVE_X0-3  DX=+1 DY=+1
    ld hl, wEnemyX
    ld a, WAVE_X0
    ld [hli], a
    ld a, WAVE_X1
    ld [hli], a
    ld a, WAVE_X2
    ld [hli], a
    ld a, WAVE_X3
    ld [hl], a
    FILL4 wEnemyY,  0
    FILL4 wEnemyDX, ENEMY_SPEED
    FILL4 wEnemyDY, ENEMY_SPEED
    jr .initCommon

.wave1:
    ; diagonale (haut droite vers bas gauche) : X=WAVE_X3-0  DX=-1 DY=+1
    ld hl, wEnemyX
    ld a, WAVE_X3
    ld [hli], a
    ld a, WAVE_X2
    ld [hli], a
    ld a, WAVE_X1
    ld [hli], a
    ld a, WAVE_X0
    ld [hl], a
    FILL4 wEnemyY,  0
    FILL4 wEnemyDX, -ENEMY_SPEED & $FF
    FILL4 wEnemyDY, ENEMY_SPEED
    jr .initCommon

.wave2:
    ;horizontal : 2 depuis gauche (Y=WAVE2_Y0,WAVE2_Y1) + 2 depuis droite
    ld hl, wEnemyX
    ld a, WAVE_EDGE_L
    ld [hli], a
    ld [hli], a
    ld a, WAVE_EDGE_R
    ld [hli], a
    ld [hl], a

    ld hl, wEnemyY
    ld a, WAVE2_Y0
    ld [hli], a
    ld a, WAVE2_Y1
    ld [hli], a
    ld a, WAVE2_Y0
    ld [hli], a
    ld a, WAVE2_Y1
    ld [hl], a

    ld hl, wEnemyDX
    ld a, ENEMY_SPEED
    ld [hli], a
    ld [hli], a
    ld a, -ENEMY_SPEED & $FF
    ld [hli], a
    ld [hl], a

    FILL4 wEnemyDY, ENEMY_SPEED

.initCommon:
    FILL4 wEnemyActive, 1
    FILL4 wEnemyHP, ENEMY_HP_INIT
    FILL4 wEnemyBulActive, 0
    FILL4 wEnemyShootTimer, 0
    ret

UpdateWave:
    call UpdateEnemies
    call UpdateEnemyBullets
    call CheckEnemyBulletsVsReimu
    call CheckPlayerBulletsVsEnemies
    call CheckWaveDone
    ret

CheckWaveDone:
    ld a, [wEnemyActive]
    or a
    ret nz
    ld a, [wEnemyActive + 1]
    or a
    ret nz
    ld a, [wEnemyActive + 2]
    or a
    ret nz
    ld a, [wEnemyActive + 3]
    or a
    ret nz
    ld a, [wWaveIndex]
    inc a
    ld [wWaveIndex], a
    call SpawnWave
    ret

SECTION "Wave WRAM", WRAM0
wWaveIndex: db
wEnemyX: ds 4
wEnemyY: ds 4
wEnemyActive: ds 4
wEnemyHP: ds 4
wEnemyDX: ds 4
wEnemyDY: ds 4
wEnemyBulX: ds 4
wEnemyBulY: ds 4
wEnemyBulActive: ds 4
wEnemyShootTimer: ds 4
