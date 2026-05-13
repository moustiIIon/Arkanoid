SECTION "Touhou Wave", ROM0

DEF TOUHOU_STATE_WAVE EQU 0
DEF TOUHOU_STATE_BOSS EQU 1
DEF TOUHOU_STATE_WIN  EQU 2
DEF TOUHOU_STATE_OVER EQU 3

DEF ENEMY_COUNT EQU 4
DEF ENEMY_HP_INIT EQU 3
DEF ENEMY_SPEED EQU 1
DEF ENEMY_BULLET_SPD EQU 2
DEF ENEMY_SHOOT_RATE EQU 60

; hitbox Reimu : centre du sprite 16x24
DEF HITBOX_OFF_X EQU 6
DEF HITBOX_OFF_Y EQU 10
DEF HITBOX_SIZE EQU 4
DEF INVINC_FRAMES EQU 60

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
    ret

.wave0:
    ; 4 ennemis diagonaux (en haut à gauche vers en bas à droite) : X=8,44,80,116 Y=0 DX=+1 DY=+1
    ld hl, wEnemyX
    ld a, 8
    ld [hli], a
    ld a, 44
    ld [hli], a
    ld a, 80
    ld [hli], a
    ld a, 116
    ld [hl], a

    ld hl, wEnemyY
    xor a
    ld [hli], a
    ld [hli], a
    ld [hli], a
    ld [hl], a

    ld hl, wEnemyDX
    ld a, ENEMY_SPEED
    ld [hli], a
    ld [hli], a
    ld [hli], a
    ld [hl], a

    ld hl, wEnemyDY
    ld a, ENEMY_SPEED
    ld [hli], a
    ld [hli], a
    ld [hli], a
    ld [hl], a
    jr .initCommon


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
