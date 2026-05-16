SECTION "Touhou Sakuya Boss", ROM0

DEF BOSS_HP          EQU 30
DEF BOSS_SPEED       EQU 1
DEF BOSS_SHOOT_RATE  EQU 30
DEF BOSS_BUL_SPD     EQU 2
DEF BOSS_BUL_COUNT   EQU 12

DEF BOSS_INIT_X      EQU 72
DEF BOSS_INIT_Y      EQU 16
DEF BOSS_X_MIN       EQU 8
DEF BOSS_X_MAX       EQU 136
DEF WRAP_THRESHOLD   EQU 200

DEF BOSS_FIRE_Y_OFF  EQU 24
DEF BOSS_CENTER_OFF  EQU 8
DEF BOSS_COL_OFF     EQU 12

DEF BOSS_HIT_W       EQU 17
DEF BOSS_HIT_H       EQU 25
DEF BOSS_BUL_HIT     EQU 9
DEF SCREEN_H         EQU 160

; ---------- init ----------

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
    ld a, BOSS_SHOOT_RATE
    ld [wBossShootTimer], a
    xor a
    ld [wBossBulSlot], a
    ld hl, wBossBulActive
    ld b, BOSS_BUL_COUNT
.clr:
    ld [hli], a
    dec b
    jr nz, .clr
    ret

; ---------- mouvement ----------

MoveBoss:
    ld a, [wBossX]
    ld c, a
    ld a, [wBossDX]
    add a, c           ; newX = X + DX (DX négatif = $FF en complément à 2)
    cp WRAP_THRESHOLD  ; sécurité underflow extrême
    jr nc, .bounceL
    cp BOSS_X_MAX + 1  ; rebond mur droit
    jr nc, .bounceR
    cp BOSS_X_MIN      ; rebond mur gauche
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

; ---------- tir ----------

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
    ld b, a            ; b = Y de spawn
    ; colonne centre
    ld a, [wBossX]
    add a, BOSS_CENTER_OFF
    call SpawnBossBul
    ; colonne gauche
    ld a, [wBossX]
    add a, BOSS_CENTER_OFF
    sub BOSS_COL_OFF
    call SpawnBossBul
    ; colonne droite
    ld a, [wBossX]
    add a, BOSS_CENTER_OFF + BOSS_COL_OFF
    call SpawnBossBul
    ; avancer le slot (wrap à BOSS_BUL_COUNT)
    ld a, e
    cp BOSS_BUL_COUNT
    jr c, .saveSlot
    xor a
.saveSlot:
    ld [wBossBulSlot], a
    ret

; SpawnBossBul : a=X, b=Y, de=slot (d=0) - sauvegarde X en premier, puis écrit Y/active/DY
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
    ld a, 1
    ld [hl], a
    ld hl, wBossBulDY
    add hl, de
    ld a, BOSS_BUL_SPD
    ld [hl], a
    inc e
    ret

; ---------- mise à jour des balles ----------

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

; ---------- collision : balles boss vs Reimu ----------

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
    ; touché : désactiver la balle et blesser Reimu
    ld hl, wBossBulActive
    add hl, de
    xor a
    ld [hl], a
    call BossHitReimu
    ret                ; une seule touche par frame
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

; ---------- collision : balles joueur vs Sakuya ----------

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
    ld a, TOUHOU_STATE_WIN
    ld [wTouhouState], a
.hit:
    ld h, 1
    ret
.noHit:
    ret

; ---------- update principal ----------

UpdateBoss:
    call MoveBoss
    call BossShoot
    call UpdateBossBullets
    call CheckBossBulletsVsReimu
    call CheckPlayerBulletsVsBoss
    ret
