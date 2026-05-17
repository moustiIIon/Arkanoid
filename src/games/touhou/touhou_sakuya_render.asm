SECTION "Sakuya Render", ROM0

RenderBossOAM:
    ; Sakuya - grille 2x3 tiles (16x24 px) aux sprites 0-5
    ld a, [wBossY]
    add a, OAM_Y_BIAS
    ld [wShadowOAM + OAM_BOSS], a
    ld a, [wBossX]
    add a, OAM_X_BIAS
    ld [wShadowOAM + OAM_BOSS + 1], a
    ld a, BOSS_TILE
    ld [wShadowOAM + OAM_BOSS + 2], a
    xor a
    ld [wShadowOAM + OAM_BOSS + 3], a

    ld a, [wBossY]
    add a, OAM_Y_BIAS
    ld [wShadowOAM + OAM_BOSS + 4], a
    ld a, [wBossX]
    add a, OAM_X_BIAS + SPRITE_ROW_H
    ld [wShadowOAM + OAM_BOSS + 5], a
    ld a, BOSS_TILE + 1
    ld [wShadowOAM + OAM_BOSS + 6], a
    xor a
    ld [wShadowOAM + OAM_BOSS + 7], a

    ld a, [wBossY]
    add a, OAM_Y_BIAS + SPRITE_ROW_H
    ld [wShadowOAM + OAM_BOSS + 8], a
    ld a, [wBossX]
    add a, OAM_X_BIAS
    ld [wShadowOAM + OAM_BOSS + 9], a
    ld a, BOSS_TILE + 2
    ld [wShadowOAM + OAM_BOSS + 10], a
    xor a
    ld [wShadowOAM + OAM_BOSS + 11], a

    ld a, [wBossY]
    add a, OAM_Y_BIAS + SPRITE_ROW_H
    ld [wShadowOAM + OAM_BOSS + 12], a
    ld a, [wBossX]
    add a, OAM_X_BIAS + SPRITE_ROW_H
    ld [wShadowOAM + OAM_BOSS + 13], a
    ld a, BOSS_TILE + 3
    ld [wShadowOAM + OAM_BOSS + 14], a
    xor a
    ld [wShadowOAM + OAM_BOSS + 15], a

    ld a, [wBossY]
    add a, OAM_Y_BIAS + SPRITE_ROW_H * 2
    ld [wShadowOAM + OAM_BOSS + 16], a
    ld a, [wBossX]
    add a, OAM_X_BIAS
    ld [wShadowOAM + OAM_BOSS + 17], a
    ld a, BOSS_TILE + 4
    ld [wShadowOAM + OAM_BOSS + 18], a
    xor a
    ld [wShadowOAM + OAM_BOSS + 19], a

    ld a, [wBossY]
    add a, OAM_Y_BIAS + SPRITE_ROW_H * 2
    ld [wShadowOAM + OAM_BOSS + 20], a
    ld a, [wBossX]
    add a, OAM_X_BIAS + SPRITE_ROW_H
    ld [wShadowOAM + OAM_BOSS + 21], a
    ld a, BOSS_TILE + 5
    ld [wShadowOAM + OAM_BOSS + 22], a
    xor a
    ld [wShadowOAM + OAM_BOSS + 23], a
    ret

ClearBossOAM:
    ; masque les 6 sprites Sakuya en mettant Y=0
    xor a
    ld [wShadowOAM + OAM_BOSS], a
    ld [wShadowOAM + OAM_BOSS + 4], a
    ld [wShadowOAM + OAM_BOSS + 8], a
    ld [wShadowOAM + OAM_BOSS + 12], a
    ld [wShadowOAM + OAM_BOSS + 16], a
    ld [wShadowOAM + OAM_BOSS + 20], a
    ret

; aff les balles de Sakuya à partir de OAM_BOSS_BULL
RenderBossBullets:
    ld b, 0
    ld hl, wShadowOAM + OAM_BOSS_BUL
.loop:
    ld a, b
    ld e, a
    ld d, 0
    push hl
    ld hl, wBossBulActive
    add hl, de
    ld a, [hl]
    pop hl
    cp 0
    jr z, .hide
    ; balle active
    push hl
    ld hl, wBossBulY
    add hl, de
    ld a, [hl]
    pop hl
    add a, OAM_Y_BIAS
    ld [hli], a
    push hl
    ld hl, wBossBulX
    add hl, de
    ld a, [hl]
    pop hl
    add a, OAM_X_BIAS
    ld [hli], a
    ld a, ENBUL_TILE
    ld [hli], a
    xor a
    ld [hli], a
    jr .next
.hide:
    xor a
    ld [hli], a
    ld [hli], a
    ld [hli], a
    ld [hli], a
.next:
    inc b
    ld a, b
    cp BOSS_BUL_COUNT
    jr nz, .loop
    ret

RenderSubEnemies:
    ; sous-ennemi 0
    ld a, [wSubEnemyActive]
    cp 0
    jr z, .hide0
    ld a, [wSubEnemyY]
    add a, OAM_Y_BIAS
    ld [wShadowOAM + OAM_SUBENEMY0], a
    ld a, [wSubEnemyX]
    add a, OAM_X_BIAS
    ld [wShadowOAM + OAM_SUBENEMY0 + 1], a
    ld a, ENEMY_TILE
    ld [wShadowOAM + OAM_SUBENEMY0 + 2], a
    xor a
    ld [wShadowOAM + OAM_SUBENEMY0 + 3], a
    jr .sub1
.hide0:
    xor a
    ld [wShadowOAM + OAM_SUBENEMY0], a
.sub1:
    ; sous-ennemi 1
    ld a, [wSubEnemyActive + 1]
    cp 0
    jr z, .hide1
    ld a, [wSubEnemyY + 1]
    add a, OAM_Y_BIAS
    ld [wShadowOAM + OAM_SUBENEMY1], a
    ld a, [wSubEnemyX + 1]
    add a, OAM_X_BIAS
    ld [wShadowOAM + OAM_SUBENEMY1 + 1], a
    ld a, ENEMY_TILE
    ld [wShadowOAM + OAM_SUBENEMY1 + 2], a
    xor a
    ld [wShadowOAM + OAM_SUBENEMY1 + 3], a
    ret
.hide1:
    xor a
    ld [wShadowOAM + OAM_SUBENEMY1], a

RenderSubEnemyBullets:
    ld a, [wSubEnemyBulActive]
    cp 0
    jr z, .hideBul0
    ld a, [wSubEnemyBulY]
    add a, OAM_Y_BIAS
    ld [wShadowOAM + OAM_SUBENBUL0], a
    ld a, [wSubEnemyBulX]
    add a, OAM_X_BIAS
    ld [wShadowOAM + OAM_SUBENBUL0 + 1], a
    ld a, ENBUL_TILE
    ld [wShadowOAM + OAM_SUBENBUL0 + 2], a
    xor a
    ld [wShadowOAM + OAM_SUBENBUL0 + 3], a
    jr .bul1
.hideBul0:
    xor a
    ld [wShadowOAM + OAM_SUBENBUL0], a
.bul1:
    ld a, [wSubEnemyBulActive + 1]
    cp 0
    jr z, .hideBul1
    ld a, [wSubEnemyBulY + 1]
    add a, OAM_Y_BIAS
    ld [wShadowOAM + OAM_SUBENBUL1], a
    ld a, [wSubEnemyBulX + 1]
    add a, OAM_X_BIAS
    ld [wShadowOAM + OAM_SUBENBUL1 + 1], a
    ld a, ENBUL_TILE
    ld [wShadowOAM + OAM_SUBENBUL1 + 2], a
    xor a
    ld [wShadowOAM + OAM_SUBENBUL1 + 3], a
    ret
.hideBul1:
    xor a
    ld [wShadowOAM + OAM_SUBENBUL1], a
    ret
