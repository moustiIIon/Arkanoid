SECTION "Touhou Sakuya Boss", ROM0

DEF BOSS_HP EQU 30
DEF BOSS_SPEED EQU 1
DEF BOSS_INIT_X EQU 72
DEF BOSS_INIT_Y EQU 16
DEF BOSS_X_MIN EQU 8
DEF BOSS_X_MAX EQU 136
DEF WRAP_THRESHOLD EQU 200

BossInit:
    ld a, 1
    ld [wBossActive], a
    ld a, BOSS_HP
    ld [wBossHP], a
    ld a, BOSS_INIT_X
    ld [wBossX], a
    ld a, BOSS_INIT_Y
    ld [wBossY], a
    ld a, BOSS_SPEED
    ld [wBossDX], a
    ret

MoveBoss:
    ld a, [wBossX]
    ld c, a
    ld a, [wBossDX]
    add a, c
    cp WRAP_THRESHOLD
    jr nc, .bounceL
    cp BOSS_X_MAX + 1
    jr nc, .bounceR
    cp BOSS_X_MIN
    jr c, .bounceL
    ld [wBossX], a
    ret
.bounceR:
    ld a, BOSS_X_MAX
    ld [wBossX], a
    ld a, -BOSS_SPEED & $FF
    ld [wBossDX], a
    ret
.bounceL:
    ld a, BOSS_X_MIN
    ld [wBossX], a
    ld a, BOSS_SPEED
    ld [wBossDX], a
    ret

UpdateBoss:
    call MoveBoss
    ret
