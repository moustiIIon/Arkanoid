SECTION "Sakuya Render", ROM0

RenderBossOAM:
    ; Sakuya — grille 2x3 tiles (16x24 px) aux sprites 0-5 (OAM_BOSS)
    ld a, [wBossY]
    add a, 16
    ld [OAM_BOSS], a
    ld a, [wBossX]
    add a, 8
    ld [OAM_BOSS + 1], a
    ld a, BOSS_TILE
    ld [OAM_BOSS + 2], a
    xor a
    ld [OAM_BOSS + 3], a

    ld a, [wBossY]
    add a, 16
    ld [OAM_BOSS + 4], a
    ld a, [wBossX]
    add a, 16
    ld [OAM_BOSS + 5], a
    ld a, BOSS_TILE + 1
    ld [OAM_BOSS + 6], a
    xor a
    ld [OAM_BOSS + 7], a

    ld a, [wBossY]
    add a, 24
    ld [OAM_BOSS + 8], a
    ld a, [wBossX]
    add a, 8
    ld [OAM_BOSS + 9], a
    ld a, BOSS_TILE + 2
    ld [OAM_BOSS + 10], a
    xor a
    ld [OAM_BOSS + 11], a

    ld a, [wBossY]
    add a, 24
    ld [OAM_BOSS + 12], a
    ld a, [wBossX]
    add a, 16
    ld [OAM_BOSS + 13], a
    ld a, BOSS_TILE + 3
    ld [OAM_BOSS + 14], a
    xor a
    ld [OAM_BOSS + 15], a

    ld a, [wBossY]
    add a, 32
    ld [OAM_BOSS + 16], a
    ld a, [wBossX]
    add a, 8
    ld [OAM_BOSS + 17], a
    ld a, BOSS_TILE + 4
    ld [OAM_BOSS + 18], a
    xor a
    ld [OAM_BOSS + 19], a

    ld a, [wBossY]
    add a, 32
    ld [OAM_BOSS + 20], a
    ld a, [wBossX]
    add a, 16
    ld [OAM_BOSS + 21], a
    ld a, BOSS_TILE + 5
    ld [OAM_BOSS + 22], a
    xor a
    ld [OAM_BOSS + 23], a
    ret

ClearBossOAM:
    ; masque les 6 sprites Sakuya en mettant Y=0
    xor a
    ld [OAM_BOSS], a
    ld [OAM_BOSS + 4], a
    ld [OAM_BOSS + 8], a
    ld [OAM_BOSS + 12], a
    ld [OAM_BOSS + 16], a
    ld [OAM_BOSS + 20], a
    ret

ClearEnemyOAM:
    ; masque les 8 slots ennemis (4 ennemis + 4 balles) en mettant Y=0
    xor a
    ld [OAM_BOSS_BUL], a
    ld [OAM_BOSS_BUL + 4], a
    ld [OAM_BOSS_BUL + 8], a
    ld [OAM_BOSS_BUL + 12], a
    ld [OAM_BOSS_BUL + 16], a
    ld [OAM_BOSS_BUL + 20], a
    ld [OAM_BOSS_BUL + 24], a
    ld [OAM_BOSS_BUL + 28], a
    ret
