SECTION "Touhou Collision", ROM0

; CheckEnemyBulletsVsReimu : teste les 4 bullets ennemies contre la hitbox de Reimu
CheckEnemyBulletsVsReimu:
    ld a, [wInvincTimer]
    cp 0
    ret nz

    ld b, 0
.loop:
    ld hl, wEnemyBulActive
    ld a, b
    ld e, a
    ld d, 0
    add hl, de
    ld a, [hl]
    cp 0
    jr z, .next

    ld a, [wPlayerX]
    add a, HITBOX_OFF_X
    ld c, a

    ld hl, wEnemyBulX
    add hl, de
    ld a, [hl]
    ld h, c
    sub h
    jr nc, .checkX2
    cpl
    inc a
    cp 9
    jr nc, .next

.checkX2:
    cp HITBOX_SIZE + 1
    jr nc, .next

    ld a, [wPlayerY]
    add a, HITBOX_OFF_Y
    ld c, a

    ld hl, wEnemyBulY
    add hl, de
    ld a, [hl]
    ld h, c
    sub h
    jr nc, .checkY2
    cpl
    inc a
    cp 9
    jr nc, .next

.checkY2:
    cp HITBOX_SIZE + 1
    jr nc, .next

    ; collision : désactiver bullet + enlever une vie
    ld hl, wEnemyBulActive
    add hl, de
    xor a
    ld [hl], a

    ld a, [wPlayerLives]
    cp 0
    jr z, .gameOver
    dec a
    ld [wPlayerLives], a

    ld a, INVINC_FRAMES
    ld [wInvincTimer], a
    jr .next

.gameOver:
    ld a, TOUHOU_STATE_OVER
    ld [wTouhouState], a

.next:
    inc b
    ld a, b
    cp ENEMY_COUNT
    jr nz, .loop
    ret

; CheckPlayerBulletsVsEnemies : teste les 3 bullets joueur contre tous les ennemis
CheckPlayerBulletsVsEnemies:
    ld a, [wPBullet0Active]
    cp 0
    jr z, .skipB0
    ld a, [wPBullet0X]
    ld b, a
    ld a, [wPBullet0Y]
    ld c, a
    call CheckBulletVsAllEnemies
    ld a, h
    cp 0
    jr z, .skipB0
    xor a
    ld [wPBullet0Active], a
.skipB0:
    ld a, [wPBullet1Active]
    cp 0
    jr z, .skipB1
    ld a, [wPBullet1X]
    ld b, a
    ld a, [wPBullet1Y]
    ld c, a
    call CheckBulletVsAllEnemies
    ld a, h
    cp 0
    jr z, .skipB1
    xor a
    ld [wPBullet1Active], a
.skipB1:
    ld a, [wPBullet2Active]
    cp 0
    jr z, .skipB2
    ld a, [wPBullet2X]
    ld b, a
    ld a, [wPBullet2Y]
    ld c, a
    call CheckBulletVsAllEnemies
    ld a, h
    cp 0
    jr z, .skipB2
    xor a
    ld [wPBullet2Active], a
.skipB2:
    ret

; CheckBulletVsAllEnemies : b=bulX c=bulY -> h=1 si hit, h=0 sinon
CheckBulletVsAllEnemies:
    ld h, 0
    ld e, 0
.eloop:
    ld hl, wEnemyActive
    ld d, 0
    add hl, de
    ld a, [hl]
    cp 0
    jr z, .enext

    ld hl, wEnemyX
    add hl, de
    ld a, [hl]
    sub b
    jr nc, .checkEX2
    cpl
    inc a
.checkEX2:
    cp 9
    jr nc, .enext

    ld hl, wEnemyY
    add hl, de
    ld a, [hl]
    sub c
    jr nc, .checkEY2
    cpl
    inc a
.checkEY2:
    cp 9
    jr nc, .enext

    ld hl, wEnemyHP
    add hl, de
    ld a, [hl]
    dec a
    ld [hl], a
    cp 0
    jr nz, .hitDone
    ld hl, wEnemyActive
    add hl, de
    xor a
    ld [hl], a
    ld hl, wEnemyBulActive
    add hl, de
    ld [hl], a
.hitDone:
    ld h, 1
    ret

.enext:
    inc e
    ld a, e
    cp ENEMY_COUNT
    jr nz, .eloop
    ld h, 0
    ret
