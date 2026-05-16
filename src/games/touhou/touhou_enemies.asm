SECTION "Touhou Enemies", ROM0

; UpdateEnemies : déplace (1 frame/2) + tir pour chaque ennemi actif
UpdateEnemies:
    ld b, 0
.loop:
    ld hl, wEnemyActive
    ld a, b
    ld e, a
    ld d, 0
    add hl, de
    ld a, [hl]
    cp 0
    jp z, .next

    ; mouvement 1 frame sur 2
    ld a, [wTouhouFrame]
    and 1
    jr nz, .shoot

    ; déplacer X
    ld hl, wEnemyX
    add hl, de
    ld a, [hl]
    ld c, a
    ld hl, wEnemyDX
    add hl, de
    ld a, [hl]
    add a, c
    ld hl, wEnemyX
    add hl, de
    ld [hl], a

    ; déplacer Y
    ld hl, wEnemyY
    add hl, de
    ld a, [hl]
    ld c, a
    ld hl, wEnemyDY
    add hl, de
    ld a, [hl]
    add a, c
    ld hl, wEnemyY
    add hl, de
    ld [hl], a

    ; sortie par le bas -> désactiver
    cp 160
    jr nc, .deactivate

    ; rebond gauche/droite
    ld hl, wEnemyX
    add hl, de
    ld a, [hl]
    cp 200
    jr nc, .bounceLeft ; underflow (X ~0 -> 255)
    cp 152
    jr c, .shoot ; dans les bornes
    ; rebond droite
    ld a, 151
    ld [hl], a
    ld hl, wEnemyDX
    add hl, de
    ld a, -ENEMY_SPEED & $FF
    ld [hl], a
    jr .shoot

.bounceLeft:
    xor a
    ld [hl], a
    ld hl, wEnemyDX
    add hl, de
    ld a, ENEMY_SPEED
    ld [hl], a
    jr .shoot

.deactivate:
    ld hl, wEnemyActive
    add hl, de
    xor a
    ld [hl], a
    jr .next

.shoot:
    ld hl, wEnemyShootTimer
    add hl, de
    ld a, [hl]
    cp 0
    jr z, .doShoot
    dec a
    ld [hl], a
    jr .next

.doShoot:
    ld a, ENEMY_SHOOT_RATE
    ld hl, wEnemyShootTimer
    add hl, de
    ld [hl], a

    ld hl, wEnemyBulActive
    add hl, de
    ld a, [hl]
    cp 0
    jr nz, .next

    ld a, 1
    ld [hl], a

    ld hl, wEnemyX
    add hl, de
    ld a, [hl]
    ld hl, wEnemyBulX
    add hl, de
    ld [hl], a

    ld hl, wEnemyY
    add hl, de
    ld a, [hl]
    ld hl, wEnemyBulY
    add hl, de
    ld [hl], a

.next:
    inc b
    ld a, b
    cp ENEMY_COUNT
    jp nz, .loop
    ret

; UpdateEnemyBullets : descend les bullets ennemies
UpdateEnemyBullets:
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

    ld hl, wEnemyBulY
    add hl, de
    ld a, [hl]
    add a, ENEMY_BULLET_SPD
    ld [hl], a
    cp 160
    jr nc, .deact
    jr .next
.deact:
    ld hl, wEnemyBulActive
    add hl, de
    xor a
    ld [hl], a
.next:
    inc b
    ld a, b
    cp ENEMY_COUNT
    jr nz, .loop
    ret

; RenderEnemyOAM : écrit ennemis + leurs bullets dans l'OAM à partir de OAM_BOSS_BUL ($FE3C)
RenderEnemyOAM:
    ld b, 0
    ld hl, wShadowOAM + OAM_BOSS_BUL
.loop:
    ld a, b
    ld e, a
    ld d, 0
    
    push hl
    ld hl, wEnemyActive
    add hl, de
    ld a, [hl]
    pop hl
    cp 0
    jr z, .hideEnemy
    
    push hl
    ld hl, wEnemyY
    add hl, de
    ld a, [hl]
    pop hl
    add a, 16
    ld [hli], a
    push hl
    ld hl, wEnemyX
    add hl, de
    ld a, [hl]
    pop hl
    add a, 8
    ld [hli], a
    ld a, ENEMY_TILE
    ld [hli], a
    xor a
    ld [hli], a
    jr .enemyBullet

.hideEnemy:
    xor a
    ld [hli], a
    ld [hli], a
    ld [hli], a
    ld [hli], a

.enemyBullet:
    push hl
    ld hl, wEnemyBulActive
    add hl, de
    ld a, [hl]
    pop hl
    cp 0
    jr z, .hideBullet

    push hl
    ld hl, wEnemyBulY
    add hl, de
    ld a, [hl]
    pop hl
    add a, 16
    ld [hli], a
    push hl
    ld hl, wEnemyBulX
    add hl, de
    ld a, [hl]
    pop hl
    add a, 8
    ld [hli], a
    ld a, ENBUL_TILE
    ld [hli], a
    xor a
    ld [hli], a
    jr .next

.hideBullet:
    xor a
    ld [hli], a
    ld [hli], a
    ld [hli], a
    ld [hli], a

.next:
    inc b
    ld a, b
    cp ENEMY_COUNT
    jr nz, .loop
    ret
