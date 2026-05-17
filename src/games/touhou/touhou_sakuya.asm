SECTION "Touhou Sakuya Boss", ROM0

DEF BOSS_HP EQU 30
DEF BOSS_SPEED EQU 1
DEF BOSS_SHOOT_RATE EQU 30
DEF BOSS_BUL_SPD EQU 1
DEF BOSS_BUL_COUNT EQU 12

DEF BOSS_INIT_X EQU 72
DEF BOSS_INIT_Y EQU 16
DEF BOSS_X_MIN EQU 8
DEF BOSS_X_MAX EQU 136
DEF WRAP_THRESHOLD EQU 200

DEF BOSS_FIRE_Y_OFF EQU 24
DEF BOSS_CENTER_OFF EQU 8
DEF BOSS_COL_OFF EQU 12

DEF BOSS_HIT_W EQU 17
DEF BOSS_HIT_H EQU 25
DEF BOSS_BUL_HIT EQU 9
DEF SCREEN_H EQU 160

DEF SUB_ENEMY_HIT_W EQU 9
DEF SUB_ENEMY_HIT_H EQU 9
DEF SUB_ENEMY_SHOOT_RATE EQU 40
DEF SUB_ENEMY_BUL_SPD EQU 2
DEF SUB_ENEMY0_X EQU 24
DEF SUB_ENEMY1_X EQU 112

BossInit:
    ld a, FLAG_ACTIVE
    ld [wBossActive], a
    ld a, BOSS_HP
    ld [wBossHP], a
    ld a, BOSS_INIT_X
    ld [wBossX], a
    ld a, BOSS_INIT_Y
    ld [wBossY], a
    ld a, BOSS_SPEED
    ld [wBossDX], a
    ld a, BOSS_SHOOT_RATE
    ld [wBossShootTimer], a
    xor a
    ld [wBossBulSlot], a
    ld [wBossPhase], a
    ld [wSubEnemyActive], a
    ld [wSubEnemyActive + 1], a
    ld [wSubEnemyBulActive], a
    ld [wSubEnemyBulActive + 1], a
    ld hl, wBossBulActive
    ld b, BOSS_BUL_COUNT
.clr:
    ld [hli], a
    dec b
    jr nz, .clr
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

BossShoot:
    ld a, [wBossShootTimer]
    cp 0
    jr z, .fire
    dec a
    ld [wBossShootTimer], a
    ret
.fire:
    ld a, BOSS_SHOOT_RATE
    ld [wBossShootTimer], a
    ld a, [wBossBulSlot]
    ld e, a
    ld d, 0
    ld a, [wBossY]
    add a, BOSS_FIRE_Y_OFF
    ld b, a ; b = Y de spawn
    ;init des phases
    ld a, [wBossPhase]
    cp BOSS_PHASE_1
    jr nz, .phase2

    ; phase 1 : 3 colonnes verticales (DX=0)
    ld c, 0
    ld a, [wBossX]
    add a, BOSS_CENTER_OFF
    call SpawnBossBul
    ld a, [wBossX]
    add a, BOSS_CENTER_OFF
    sub BOSS_COL_OFF
    call SpawnBossBul
    ld a, [wBossX]
    add a, BOSS_CENTER_OFF + BOSS_COL_OFF
    call SpawnBossBul
    jr .advanceSlot

.phase2:
    ; phase 2 : 1 verticale + 2 diagonales 45° depuis le centre du boss
    ld a, [wBossX]
    add a, BOSS_CENTER_OFF
    ld c, 0 ; verticale
    call SpawnBossBul
    ld a, [wBossX]
    add a, BOSS_CENTER_OFF
    ld c, -BOSS_BUL_SPD & $FF ; diagonale gauche
    call SpawnBossBul
    ld a, [wBossX]
    add a, BOSS_CENTER_OFF
    ld c, BOSS_BUL_SPD ; diagonale droite
    call SpawnBossBul

.advanceSlot:
    ld a, e
    cp BOSS_BUL_COUNT
    jr c, .saveSlot
    xor a
.saveSlot:
    ld [wBossBulSlot], a
    ret

; SpawnBossBul : a=X, b=Y, c=DX, de=slot
SpawnBossBul:
    ld hl, wBossBulX
    add hl, de
    ld [hl], a
    ld hl, wBossBulY
    add hl, de
    ld a, b
    ld [hl], a
    ld hl, wBossBulActive
    add hl, de
    ld a, FLAG_ACTIVE
    ld [hl], a
    ld hl, wBossBulDY
    add hl, de
    ld a, BOSS_BUL_SPD
    ld [hl], a
    ld hl, wBossBulDX
    add hl, de
    ld a, c
    ld [hl], a
    inc e
    ret

UpdateBossBullets:
    ld b, 0
.loop:
    ld a, b
    ld e, a
    ld d, 0
    ld hl, wBossBulActive
    add hl, de
    ld a, [hl]
    cp 0
    jr z, .next
    ; update Y
    ld hl, wBossBulY
    add hl, de
    ld a, [hl]
    ld c, a
    ld hl, wBossBulDY
    add hl, de
    ld a, [hl]
    add a, c
    ld hl, wBossBulY
    add hl, de
    ld [hl], a
    cp SCREEN_H
    jr nc, .deact
    ; update X
    ld hl, wBossBulX
    add hl, de
    ld a, [hl]
    ld c, a
    ld hl, wBossBulDX
    add hl, de
    ld a, [hl]
    add a, c
    ld hl, wBossBulX
    add hl, de
    ld [hl], a
    cp SCREEN_H ; >=160 attrape sortie droite ET wrap gauche (>=200)
    jr nc, .deact
    jr .next
.deact:
    ld hl, wBossBulActive
    add hl, de
    xor a
    ld [hl], a
.next:
    inc b
    ld a, b
    cp BOSS_BUL_COUNT
    jr nz, .loop
    ret

CheckBossBulletsVsReimu:
    ld a, [wInvincTimer]
    cp 0
    ret nz
    ld b, 0
.loop:
    ld a, b
    ld e, a
    ld d, 0
    ld hl, wBossBulActive
    add hl, de
    ld a, [hl]
    cp 0
    jr z, .next
    ; vérif X
    ld a, [wPlayerX]
    add a, HITBOX_OFF_X
    ld c, a
    ld hl, wBossBulX
    add hl, de
    ld a, [hl]
    ld h, c
    sub h
    jr nc, .chkX2
    cpl
    inc a
.chkX2:
    cp BOSS_BUL_HIT
    jr nc, .next
    ; vérif Y
    ld a, [wPlayerY]
    add a, HITBOX_OFF_Y
    ld c, a
    ld hl, wBossBulY
    add hl, de
    ld a, [hl]
    ld h, c
    sub h
    jr nc, .chkY2
    cpl
    inc a
.chkY2:
    cp BOSS_BUL_HIT
    jr nc, .next
    ld hl, wBossBulActive
    add hl, de
    xor a
    ld [hl], a
    call BossHitReimu
    ret
.next:
    inc b
    ld a, b
    cp BOSS_BUL_COUNT
    jr nz, .loop
    ret

BossHitReimu:
    ld a, [wPlayerLives]
    cp 0
    jr z, .over
    dec a
    ld [wPlayerLives], a
    ld a, INVINC_FRAMES
    ld [wInvincTimer], a
    ret
.over:
    ld a, TOUHOU_STATE_OVER
    ld [wTouhouState], a
    ret

CheckPlayerBulletsVsBoss:
    ld a, [wPBullet0Active]
    cp 0
    jr z, .pb1
    ld a, [wPBullet0X]
    ld b, a
    ld a, [wPBullet0Y]
    ld c, a
    call CheckBulletVsBoss
    ld a, h
    cp 0
    jr z, .pb1
    xor a
    ld [wPBullet0Active], a
.pb1:
    ld a, [wPBullet1Active]
    cp 0
    jr z, .pb2
    ld a, [wPBullet1X]
    ld b, a
    ld a, [wPBullet1Y]
    ld c, a
    call CheckBulletVsBoss
    ld a, h
    cp 0
    jr z, .pb2
    xor a
    ld [wPBullet1Active], a
.pb2:
    ld a, [wPBullet2Active]
    cp 0
    ret z
    ld a, [wPBullet2X]
    ld b, a
    ld a, [wPBullet2Y]
    ld c, a
    call CheckBulletVsBoss
    ld a, h
    cp 0
    ret z
    xor a
    ld [wPBullet2Active], a
    ret

; CheckBulletVsBoss : b=bulX c=bulY -> h=1 si touché
CheckBulletVsBoss:
    ld h, 0
    ld a, [wBossX]
    ld e, a
    ld a, b
    sub e
    jr nc, .chkX2
    cpl
    inc a
.chkX2:
    cp BOSS_HIT_W
    jr nc, .noHit
    ld a, [wBossY]
    ld e, a
    ld a, c
    sub e
    jr nc, .chkY2
    cpl
    inc a
.chkY2:
    cp BOSS_HIT_H
    jr nc, .noHit
    ld a, [wBossHP]
    dec a
    ld [wBossHP], a
    jr nz, .hit
    ; HP = 0 : vérifier la phase
    ld a, [wBossPhase]
    cp BOSS_PHASE_1
    jr nz, .killBoss
    ; transition phase 1 → phase 2
    ld a, BOSS_PHASE_2
    ld [wBossPhase], a
    ld a, BOSS_HP
    ld [wBossHP], a
    call SpawnSubEnemies
    jr .hit
.killBoss:
    ld a, TOUHOU_STATE_WIN
    ld [wTouhouState], a
.hit:
    ld h, 1
    ret
.noHit:
    ret

SpawnSubEnemies:
    ld a, [wBossY]
    ld b, a
    ; sous-ennemi 0 (gauche)
    ld a, SUB_ENEMY0_X
    ld [wSubEnemyX], a
    ld a, b
    ld [wSubEnemyY], a
    ld a, FLAG_ACTIVE
    ld [wSubEnemyActive], a
    ld a, SUB_ENEMY_SHOOT_RATE
    ld [wSubEnemyShootTimer], a
    ; sous-ennemi 1 (droite) avec timer décalé pour ne pas tirer en même temps
    ld a, SUB_ENEMY1_X
    ld [wSubEnemyX + 1], a
    ld a, b
    ld [wSubEnemyY + 1], a
    ld a, FLAG_ACTIVE
    ld [wSubEnemyActive + 1], a
    ld a, SUB_ENEMY_SHOOT_RATE / 2
    ld [wSubEnemyShootTimer + 1], a
    xor a
    ld [wSubEnemyBulActive], a
    ld [wSubEnemyBulActive + 1], a
    ret

UpdateSubEnemies:
    ; sous-ennemi 0 : statique, tire vers le bas
    ld a, [wSubEnemyActive]
    cp 0
    jr z, .upd1
    ld a, [wSubEnemyShootTimer]
    cp 0
    jr z, .fire0
    dec a
    ld [wSubEnemyShootTimer], a
    jr .upd1
.fire0:
    ld a, SUB_ENEMY_SHOOT_RATE
    ld [wSubEnemyShootTimer], a
    ld a, [wSubEnemyBulActive]
    cp 0
    jr nz, .upd1 ; balle déjà en vol
    ld a, FLAG_ACTIVE
    ld [wSubEnemyBulActive], a
    ld a, [wSubEnemyX]
    ld [wSubEnemyBulX], a
    ld a, [wSubEnemyY]
    ld [wSubEnemyBulY], a
.upd1:
    ; sous-ennemi 1 : statique, tire vers le bas
    ld a, [wSubEnemyActive + 1]
    cp 0
    ret z
    ld a, [wSubEnemyShootTimer + 1]
    cp 0
    jr z, .fire1
    dec a
    ld [wSubEnemyShootTimer + 1], a
    ret
.fire1:
    ld a, SUB_ENEMY_SHOOT_RATE
    ld [wSubEnemyShootTimer + 1], a
    ld a, [wSubEnemyBulActive + 1]
    cp 0
    ret nz
    ld a, FLAG_ACTIVE
    ld [wSubEnemyBulActive + 1], a
    ld a, [wSubEnemyX + 1]
    ld [wSubEnemyBulX + 1], a
    ld a, [wSubEnemyY + 1]
    ld [wSubEnemyBulY + 1], a
    ret

UpdateSubEnemyBullets:
    ld a, [wSubEnemyBulActive]
    cp 0
    jr z, .b1
    ld a, [wSubEnemyBulY]
    add a, SUB_ENEMY_BUL_SPD
    cp SCREEN_H
    jr nc, .deact0
    ld [wSubEnemyBulY], a
    jr .b1
.deact0:
    xor a
    ld [wSubEnemyBulActive], a
.b1:
    ld a, [wSubEnemyBulActive + 1]
    cp 0
    ret z
    ld a, [wSubEnemyBulY + 1]
    add a, SUB_ENEMY_BUL_SPD
    cp SCREEN_H
    jr nc, .deact1
    ld [wSubEnemyBulY + 1], a
    ret
.deact1:
    xor a
    ld [wSubEnemyBulActive + 1], a
    ret

CheckSubEnemyBulletsVsReimu:
    ld a, [wInvincTimer]
    cp 0
    ret nz
    ; balle 0
    ld a, [wSubEnemyBulActive]
    cp 0
    jr z, .chk1
    ld a, [wPlayerX]
    add a, HITBOX_OFF_X
    ld c, a
    ld a, [wSubEnemyBulX]
    ld h, c
    sub h
    jr nc, .seb0X2
    cpl
    inc a
.seb0X2:
    cp BOSS_BUL_HIT
    jr nc, .chk1
    ld a, [wPlayerY]
    add a, HITBOX_OFF_Y
    ld c, a
    ld a, [wSubEnemyBulY]
    ld h, c
    sub h
    jr nc, .seb0Y2
    cpl
    inc a
.seb0Y2:
    cp BOSS_BUL_HIT
    jr nc, .chk1
    xor a
    ld [wSubEnemyBulActive], a
    call BossHitReimu
    ret
.chk1:
    ; balle 1
    ld a, [wSubEnemyBulActive + 1]
    cp 0
    ret z
    ld a, [wPlayerX]
    add a, HITBOX_OFF_X
    ld c, a
    ld a, [wSubEnemyBulX + 1]
    ld h, c
    sub h
    jr nc, .seb1X2
    cpl
    inc a
.seb1X2:
    cp BOSS_BUL_HIT
    ret nc
    ld a, [wPlayerY]
    add a, HITBOX_OFF_Y
    ld c, a
    ld a, [wSubEnemyBulY + 1]
    ld h, c
    sub h
    jr nc, .seb1Y2
    cpl
    inc a
.seb1Y2:
    cp BOSS_BUL_HIT
    ret nc
    xor a
    ld [wSubEnemyBulActive + 1], a
    call BossHitReimu
    ret

CheckPlayerBulletsVsSubEnemies:
    ld a, [wPBullet0Active]
    cp 0
    jr z, .se_b1
    ld a, [wPBullet0X]
    ld b, a
    ld a, [wPBullet0Y]
    ld c, a
    call CheckBulletVsSubEnemies
    ld a, h
    cp 0
    jr z, .se_b1
    xor a
    ld [wPBullet0Active], a
.se_b1:
    ld a, [wPBullet1Active]
    cp 0
    jr z, .se_b2
    ld a, [wPBullet1X]
    ld b, a
    ld a, [wPBullet1Y]
    ld c, a
    call CheckBulletVsSubEnemies
    ld a, h
    cp 0
    jr z, .se_b2
    xor a
    ld [wPBullet1Active], a
.se_b2:
    ld a, [wPBullet2Active]
    cp 0
    ret z
    ld a, [wPBullet2X]
    ld b, a
    ld a, [wPBullet2Y]
    ld c, a
    call CheckBulletVsSubEnemies
    ld a, h
    cp 0
    ret z
    xor a
    ld [wPBullet2Active], a
    ret

; CheckBulletVsSubEnemies : b=bulX c=bulY → h=1 si touché
CheckBulletVsSubEnemies:
    ld h, 0
    ld a, [wSubEnemyActive]
    cp 0
    jr z, .chkSub1
    ld a, [wSubEnemyX]
    ld e, a
    ld a, b
    sub e
    jr nc, .se0X2
    cpl
    inc a
.se0X2:
    cp SUB_ENEMY_HIT_W
    jr nc, .chkSub1
    ld a, [wSubEnemyY]
    ld e, a
    ld a, c
    sub e
    jr nc, .se0Y2
    cpl
    inc a
.se0Y2:
    cp SUB_ENEMY_HIT_H
    jr nc, .chkSub1
    xor a
    ld [wSubEnemyActive], a
    ld h, 1
    ret
.chkSub1:
    ld a, [wSubEnemyActive + 1]
    cp 0
    ret z
    ld a, [wSubEnemyX + 1]
    ld e, a
    ld a, b
    sub e
    jr nc, .se1X2
    cpl
    inc a
.se1X2:
    cp SUB_ENEMY_HIT_W
    ret nc
    ld a, [wSubEnemyY + 1]
    ld e, a
    ld a, c
    sub e
    jr nc, .se1Y2
    cpl
    inc a
.se1Y2:
    cp SUB_ENEMY_HIT_H
    ret nc
    xor a
    ld [wSubEnemyActive + 1], a
    ld h, 1
    ret

UpdateBoss:
    call MoveBoss
    call BossShoot
    call UpdateBossBullets
    call UpdateSubEnemies
    call UpdateSubEnemyBullets
    call CheckBossBulletsVsReimu
    call CheckSubEnemyBulletsVsReimu
    call CheckPlayerBulletsVsBoss
    call CheckPlayerBulletsVsSubEnemies
    ret
