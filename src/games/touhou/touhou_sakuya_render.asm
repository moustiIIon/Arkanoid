SECTION "Sakuya Render", ROM0

RenderBossOAM:
    ; Sakuya - grille 2x3 tiles (16x24 px) aux sprites 0-5
    ld a, [wBossY]
    add a, 16
    ld [wShadowOAM + OAM_BOSS], a
    ld a, [wBossX]
    add a, 8
    ld [wShadowOAM + OAM_BOSS + 1], a
    ld a, BOSS_TILE
    ld [wShadowOAM + OAM_BOSS + 2], a
    xor a
    ld [wShadowOAM + OAM_BOSS + 3], a

    ld a, [wBossY]
    add a, 16
    ld [wShadowOAM + OAM_BOSS + 4], a
    ld a, [wBossX]
    add a, 16
    ld [wShadowOAM + OAM_BOSS + 5], a
    ld a, BOSS_TILE + 1
    ld [wShadowOAM + OAM_BOSS + 6], a
    xor a
    ld [wShadowOAM + OAM_BOSS + 7], a

    ld a, [wBossY]
    add a, 24
    ld [wShadowOAM + OAM_BOSS + 8], a
    ld a, [wBossX]
    add a, 8
    ld [wShadowOAM + OAM_BOSS + 9], a
    ld a, BOSS_TILE + 2
    ld [wShadowOAM + OAM_BOSS + 10], a
    xor a
    ld [wShadowOAM + OAM_BOSS + 11], a

    ld a, [wBossY]
    add a, 24
    ld [wShadowOAM + OAM_BOSS + 12], a
    ld a, [wBossX]
    add a, 16
    ld [wShadowOAM + OAM_BOSS + 13], a
    ld a, BOSS_TILE + 3
    ld [wShadowOAM + OAM_BOSS + 14], a
    xor a
    ld [wShadowOAM + OAM_BOSS + 15], a

    ld a, [wBossY]
    add a, 32
    ld [wShadowOAM + OAM_BOSS + 16], a
    ld a, [wBossX]
    add a, 8
    ld [wShadowOAM + OAM_BOSS + 17], a
    ld a, BOSS_TILE + 4
    ld [wShadowOAM + OAM_BOSS + 18], a
    xor a
    ld [wShadowOAM + OAM_BOSS + 19], a

    ld a, [wBossY]
    add a, 32
    ld [wShadowOAM + OAM_BOSS + 20], a
    ld a, [wBossX]
    add a, 16
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
    add a, 16
    ld [hli], a
    push hl
    ld hl, wBossBulX
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
