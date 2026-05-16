SECTION "Touhou Game Screen", ROM0

DEF PLAYER_SPEED EQU 2
DEF PLAYER_X_MIN EQU 0
DEF PLAYER_X_MAX EQU 144
DEF PLAYER_Y_MIN EQU 0
DEF PLAYER_Y_MAX EQU 120
DEF BULLET_SPEED EQU 7
DEF BULLET_FRAMES EQU 5
DEF BULLET_TILE EQU 6

TouhouGameScreen:
    ; décrémenter invincibilité
    ld a, [wInvincTimer]
    cp 0
    jr z, .skipInvinc
    dec a
    ld [wInvincTimer], a
.skipInvinc:
    ; logique de vague ou boss selon état
    ld a, [wTouhouState]
    cp TOUHOU_STATE_WAVE
    jr nz, .skipWave
    call UpdateWave
    ; si UpdateWave vient de déclencher le boss, attendre le prochain VBlank
    ld a, [wTouhouState]
    cp TOUHOU_STATE_BOSS
    jp z, TouhouLoop
.skipWave:
    ld a, [wTouhouState]
    cp TOUHOU_STATE_BOSS
    jr nz, .skipBoss
    call UpdateBoss
.skipBoss:

    ld a, [wCurKeys]
    and PAD_LEFT
    jr z, .checkRight
    ld a, [wPlayerX]
    sub PLAYER_SPEED
    jr c, .clampLeft
    cp PLAYER_X_MIN
    jr nc, .applyLeft
.clampLeft:
    ld a, PLAYER_X_MIN
.applyLeft:
    ld [wPlayerX], a

.checkRight:
    ld a, [wCurKeys]
    and PAD_RIGHT
    jr z, .checkUp
    ld a, [wPlayerX]
    add a, PLAYER_SPEED
    jr c, .clampRight
    cp PLAYER_X_MAX
    jr c, .applyRight
.clampRight:
    ld a, PLAYER_X_MAX
.applyRight:
    ld [wPlayerX], a

.checkUp:
    ld a, [wCurKeys]
    and PAD_UP
    jr z, .checkDown
    ld a, [wPlayerY]
    sub PLAYER_SPEED
    jr c, .clampUp
    cp PLAYER_Y_MIN
    jr nc, .applyUp
.clampUp:
    ld a, PLAYER_Y_MIN
.applyUp:
    ld [wPlayerY], a

.checkDown:
    ld a, [wCurKeys]
    and PAD_DOWN
    jr z, .checkFire
    ld a, [wPlayerY]
    add a, PLAYER_SPEED
    jr c, .clampDown
    cp PLAYER_Y_MAX
    jr c, .applyDown
.clampDown:
    ld a, PLAYER_Y_MAX
.applyDown:
    ld [wPlayerY], a

.checkFire:
    ; decrementer cooldown chaque frame
    ld a, [wFireCooldown]
    cp 0
    jr z, .cooldownDone
    dec a
    ld [wFireCooldown], a
    jr .updateBullets
.cooldownDone:
    ld a, [wCurKeys]
    and PAD_A
    jr z, .updateBullets
    ; reset cooldown (10 frames entre chaque bullet)
    ld a, BULLET_FRAMES
    ld [wFireCooldown], a

    ; round-robin : ecrire dans le slot courant et avancer
    ld a, [wPlayerX]
    add a, 4
    ld b, a
    ld a, [wPlayerY]
    ld c, a

    ld a, [wFireSlot]
    cp 1
    jr z, .fireSlot1
    cp 2
    jr z, .fireSlot2

.fireSlot0:
    ld a, 1
    ld [wPBullet0Active], a
    ld a, b
    ld [wPBullet0X], a
    ld a, c
    ld [wPBullet0Y], a
    ld a, 1
    ld [wFireSlot], a
    jr .updateBullets

.fireSlot1:
    ld a, 1
    ld [wPBullet1Active], a
    ld a, b
    ld [wPBullet1X], a
    ld a, c
    ld [wPBullet1Y], a
    ld a, 2
    ld [wFireSlot], a
    jr .updateBullets

.fireSlot2:
    ld a, 1
    ld [wPBullet2Active], a
    ld a, b
    ld [wPBullet2X], a
    ld a, c
    ld [wPBullet2Y], a
    xor a
    ld [wFireSlot], a

.updateBullets:
    ld a, [wPBullet0Active]
    cp 0
    jr z, .upd1
    ld a, [wPBullet0Y]
    sub BULLET_SPEED
    jr c, .deact0 ; sorti par le haut
    ld [wPBullet0Y], a
    jr .upd1
.deact0:
    xor a
    ld [wPBullet0Active], a

.upd1:
    ld a, [wPBullet1Active]
    cp 0
    jr z, .upd2
    ld a, [wPBullet1Y]
    sub BULLET_SPEED
    jr c, .deact1
    ld [wPBullet1Y], a
    jr .upd2
.deact1:
    xor a
    ld [wPBullet1Active], a

.upd2:
    ld a, [wPBullet2Active]
    cp 0
    jr z, .updateOAM
    ld a, [wPBullet2Y]
    sub BULLET_SPEED
    jr c, .deact2
    ld [wPBullet2Y], a
    jr .updateOAM
.deact2:
    xor a
    ld [wPBullet2Active], a

.updateOAM:
    jp TouhouLoop

; TouhouRenderOAM : appelé en tout premier après VBlank
; Déclenche le DMA (copie shadow → OAM réel en 160 cycles)
; puis écrit les nouvelles positions dans le shadow pour la frame suivante
TouhouRenderOAM:
    ld a, HIGH(wShadowOAM)
    ld [rDMA], a
    call hDMAWait

    ; selon l'état : afficher ennemis OU Sakuya, jamais les deux
    ld a, [wTouhouState]
    cp TOUHOU_STATE_BOSS
    jr z, .renderBoss
    call RenderEnemyOAM
    call ClearBossOAM
    jr .renderReimu
.renderBoss:
    call RenderBossOAM
    call RenderBossBullets
.renderReimu:
    ; Reimu - sprites 6-11, tiles 0-5
    ld a, [wPlayerY]
    add a, 16
    ld [wShadowOAM + OAM_REIMU], a
    ld a, [wPlayerX]
    add a, 8
    ld [wShadowOAM + OAM_REIMU + 1], a
    xor a
    ld [wShadowOAM + OAM_REIMU + 2], a
    ld [wShadowOAM + OAM_REIMU + 3], a

    ld a, [wPlayerY]
    add a, 16
    ld [wShadowOAM + OAM_REIMU + 4], a
    ld a, [wPlayerX]
    add a, 16
    ld [wShadowOAM + OAM_REIMU + 5], a
    ld a, 1
    ld [wShadowOAM + OAM_REIMU + 6], a
    xor a
    ld [wShadowOAM + OAM_REIMU + 7], a

    ld a, [wPlayerY]
    add a, 24
    ld [wShadowOAM + OAM_REIMU + 8], a
    ld a, [wPlayerX]
    add a, 8
    ld [wShadowOAM + OAM_REIMU + 9], a
    ld a, 2
    ld [wShadowOAM + OAM_REIMU + 10], a
    xor a
    ld [wShadowOAM + OAM_REIMU + 11], a

    ld a, [wPlayerY]
    add a, 24
    ld [wShadowOAM + OAM_REIMU + 12], a
    ld a, [wPlayerX]
    add a, 16
    ld [wShadowOAM + OAM_REIMU + 13], a
    ld a, 3
    ld [wShadowOAM + OAM_REIMU + 14], a
    xor a
    ld [wShadowOAM + OAM_REIMU + 15], a

    ld a, [wPlayerY]
    add a, 32
    ld [wShadowOAM + OAM_REIMU + 16], a
    ld a, [wPlayerX]
    add a, 8
    ld [wShadowOAM + OAM_REIMU + 17], a
    ld a, 4
    ld [wShadowOAM + OAM_REIMU + 18], a
    xor a
    ld [wShadowOAM + OAM_REIMU + 19], a

    ld a, [wPlayerY]
    add a, 32
    ld [wShadowOAM + OAM_REIMU + 20], a
    ld a, [wPlayerX]
    add a, 16
    ld [wShadowOAM + OAM_REIMU + 21], a
    ld a, 5
    ld [wShadowOAM + OAM_REIMU + 22], a
    xor a
    ld [wShadowOAM + OAM_REIMU + 23], a

    ; sprite 12 : balle joueur 0
    ld a, [wPBullet0Active]
    cp 0
    jr z, .hideBullet0
    ld a, [wPBullet0Y]
    add a, 16
    ld [wShadowOAM + OAM_PBUL0], a
    ld a, [wPBullet0X]
    add a, 8
    ld [wShadowOAM + OAM_PBUL0 + 1], a
    ld a, BULLET_TILE
    ld [wShadowOAM + OAM_PBUL0 + 2], a
    xor a
    ld [wShadowOAM + OAM_PBUL0 + 3], a
    jr .oamBullet1
.hideBullet0:
    xor a
    ld [wShadowOAM + OAM_PBUL0], a

    ; sprite 13 : balle joueur 1
.oamBullet1:
    ld a, [wPBullet1Active]
    cp 0
    jr z, .hideBullet1
    ld a, [wPBullet1Y]
    add a, 16
    ld [wShadowOAM + OAM_PBUL1], a
    ld a, [wPBullet1X]
    add a, 8
    ld [wShadowOAM + OAM_PBUL1 + 1], a
    ld a, BULLET_TILE
    ld [wShadowOAM + OAM_PBUL1 + 2], a
    xor a
    ld [wShadowOAM + OAM_PBUL1 + 3], a
    jr .oamBullet2
.hideBullet1:
    xor a
    ld [wShadowOAM + OAM_PBUL1], a

    ; sprite 14 : balle joueur 2
.oamBullet2:
    ld a, [wPBullet2Active]
    cp 0
    jr z, .hideBullet2
    ld a, [wPBullet2Y]
    add a, 16
    ld [wShadowOAM + OAM_PBUL2], a
    ld a, [wPBullet2X]
    add a, 8
    ld [wShadowOAM + OAM_PBUL2 + 1], a
    ld a, BULLET_TILE
    ld [wShadowOAM + OAM_PBUL2 + 2], a
    xor a
    ld [wShadowOAM + OAM_PBUL2 + 3], a
    ret
.hideBullet2:
    xor a
    ld [wShadowOAM + OAM_PBUL2], a
    ret

TouhouWinScreen:
    ld a, [wNewKeys]
    and PAD_START
    jp z, TouhouLoop
    call TransitionScreenToBlack
    xor a
    ld [rLCDC], a
    jp GlobalMenuInit

TouhouGameOver:
    ld a, [wNewKeys]
    and PAD_START
    jp z, TouhouLoop
    call TransitionScreenToBlack
    xor a
    ld [rLCDC], a
    jp GlobalMenuInit
