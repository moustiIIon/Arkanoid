SECTION "Brick Game", ROM0

DEF BRICK_COUNT        EQU 28
DEF PADDLE_INIT_Y      EQU 144
DEF PADDLE_INIT_X      EQU 24
DEF BALL_INIT_Y        EQU 116
DEF BALL_INIT_X        EQU 40
DEF BALL_DEAD_Y        EQU 176
DEF BALL_LIVES         EQU 2
DEF BALL_RESET_X       EQU 100
DEF PADDLE_LEFT_LIMIT  EQU 15
DEF PADDLE_RIGHT_LIMIT EQU 105

BrickInit:

TitleScreen:
    ld de, Unbricked_Title_Screen_Tileset_Begin
    ld hl, $9000
    ld bc, Unbricked_Title_Screen_Tileset_End - Unbricked_Title_Screen_Tileset_Begin
    call MemCpy

    ld de, Unbricked_Title_Screen_Map_Begin
    ld hl, $9800
    ld bc, Unbricked_Title_Screen_Map_End - Unbricked_Title_Screen_Map_Begin
    call MemCpy
    ld a, LCDC_ON | LCDC_BG_ON
    ld [rLCDC], a
    ld a, %11100100
    ld [rBGP], a

    ld a, 0
    ld [wCurKeys], a
    ld [wNewKeys], a
    ld [wCntBallUnderPaddle], a

; wait le start pour le menu, car sinon cela catch le enter du menu et fais sauter le title screen du arkanoid, donc ce n'etait pas bon, donc la condition est tesé et fonctionne correctement
.waitCorrectStart:
    call UpdateKeys
    ld a, [wCurKeys]
    and PAD_START
    jr nz, .waitCorrectStart

TitleScreenLoop:
    call UpdateKeys
    ld a, [wNewKeys]
    and PAD_START
    jr z, TitleScreenLoop

    call GameTransitionToStartFaster
	ld a, 0
	ld [rLCDC], a


    ld de, Tiles
    ld hl, $9000
    ld bc, Tiles.End - Tiles
    call MemCpy

    ld de, Tilemap
    ld hl, $9800
    ld bc, Tilemap.End - Tilemap
    call MemCpy

    ; ici = counter briques
    ld a, BRICK_COUNT
	ld [wBrickCnt], a

    ld a, 0
    ld [wScore], a
    ld [wBallSpeedValue], a
    call UpdateScoreDisplay

    ld de, Paddle
    ld hl, $8000
    ld bc, Paddle.End - Paddle
    call MemCpy

    ld de, Ball
    ld hl, $8010
    ld bc, Ball.End - Ball
    call MemCpy

    ld a, 0
    ld b, 160
    ld hl, STARTOF(OAM)
ClearOam:
    ld [hli], a
    dec b
    jp nz, ClearOam

    ld hl, STARTOF(OAM)

    ; load the paddle
    ld a, PADDLE_INIT_Y
    ld [hli], a
    ld a, PADDLE_INIT_X
    ld [hli], a
    ld a, 0
    ld [hli], a
    ld [hli], a

    ; load the ball
    ld a, BALL_INIT_Y
    ld [hli], a
    ld a, BALL_INIT_X
    ld [hli], a
    ld a, 1
    ld [hli], a
    ld a, 0
    ld [hli], a

    ld a, 1
    ld [wBallMomentumX], a
    ld a, -1
    ld [wBallMomentumY], a

    ; the screen is now on so the objects will be visible as they are updated, but that's fine
    ld a, LCDC_ON | LCDC_BG_ON | LCDC_OBJ_ON
    ld [rLCDC], a
    ld a, %11100100
    ld [rBGP], a
    ld a, %11100100
    ld [rOBP0], a
    ld a, 0
    ld [wFrameCounter], a
    ld [wCurKeys], a
    ld [wNewKeys], a


Main:
    ld a, [rLY]
    cp 144
    jp nc, Main
WaitVBlank2:
    ld a, [rLY]
    cp 144
    jp c, WaitVBlank2

    ld a, [wFrameCounter]
    inc a
    ld [wFrameCounter], a

    call UpdateKeys
    ; pour check frame par frame
    call BallPhysicsStep

    ld a, [wBallSpeedValue]
    and a
    jr z, NoBonusStep
    cp 3
    jr z, DoBonusStep
    cp 2
    jr z, CheckEveryTwoFrames
    ld a, [wFrameCounter]
    and %00000011
    jr nz, NoBonusStep
    jr DoBonusStep
CheckEveryTwoFrames:
    ld a, [wFrameCounter]
    and %00000001
    jr nz, NoBonusStep
DoBonusStep:
    call BallPhysicsStep
NoBonusStep:

CheckLeft:
    ld a, [wCurKeys]
    and PAD_LEFT
    jp z, CheckRight
Left:
    ld a, [STARTOF(OAM) + 1]
    dec a
    cp a, 15
    jp z, Main
    ld [STARTOF(OAM) + 1], a
    jp Main
CheckRight:
    ld a, [wCurKeys]
    and PAD_RIGHT
    jp z, Main
Right:
    ld a, [STARTOF(OAM) + 1]
    inc a
    cp a, 105
    jp z, Main
    ld [STARTOF(OAM) + 1], a
    jp Main


; Deplace la balle de 1px et effectue toutes les verifications de collision
; donc le deplacement comme avant simplement si appellé plusieurs foix alors va bouger plus vite par definition
BallPhysicsStep:
    ld a, [wBallMomentumX]
    ld b, a
    ld a, [STARTOF(OAM) + 5]
    add a, b
    ld [STARTOF(OAM) + 5], a
    ld a, [wBallMomentumY]
    ld b, a
    ld a, [STARTOF(OAM) + 4]
    add a, b
    ld [STARTOF(OAM) + 4], a

; ici on va check si la balle est dessous du paddle donc la mort =
; game over on a perdu et ensuite on aura juste a faire le score pour le leaderboard etc
    ld a, [STARTOF(OAM) + 4]
    cp a, BALL_DEAD_Y
    jp c, BounceOnTop

    ld a, [wCntBallUnderPaddle]
    inc a
    ld [wCntBallUnderPaddle], a
    cp a, BALL_LIVES
    jp z, ThisIsGameOver

ResetBall:
    ld a, BALL_INIT_Y
    ld [STARTOF(OAM) + 4], a
    ld a, BALL_RESET_X
    ld [STARTOF(OAM) + 5], a
    ld a, 1
    ld [wBallMomentumX], a
    ld a, -1
    ld [wBallMomentumY], a
    ret

ThisIsGameOver:
    call SaveScoreToSram
    call TransitionScreenToBlack
    ld a, 0
    ld [rLCDC], a
    jp GlobalMenuInit

BounceOnTop:
    ld a, [STARTOF(OAM) + 4]
    sub a, 16 + 1
    ld c, a
    ld a, [STARTOF(OAM) + 5]
    sub a, 8
    ld b, a
    call GetTileByPixel
    ld a, [hl]
    call IsWallTile
    jp nz, BounceOnRight
    call CheckAndHandleBrick
    ld a, 1
    ld [wBallMomentumY], a

BounceOnRight:
    ld a, [STARTOF(OAM) + 4]
    sub a, 16
    ld c, a
    ld a, [STARTOF(OAM) + 5]
    sub a, 8 - 1
    ld b, a
    call GetTileByPixel
    ld a, [hl]
    call IsWallTile
    jp nz, BounceOnLeft
    call CheckAndHandleBrick
    ld a, -1
    ld [wBallMomentumX], a

BounceOnLeft:
    ld a, [STARTOF(OAM) + 4]
    sub a, 16
    ld c, a
    ld a, [STARTOF(OAM) + 5]
    sub a, 8 + 1
    ld b, a
    call GetTileByPixel
    ld a, [hl]
    call IsWallTile
    jp nz, BounceDone
    call CheckAndHandleBrick
    ld a, 1
    ld [wBallMomentumX], a

BounceDone:
    ld a, [STARTOF(OAM)]
    ld b, a
    ld a, [STARTOF(OAM) + 4]
    add a, 4
    cp a, b
    jp nz, PaddleBounceDone
    ld a, [STARTOF(OAM) + 5]
    ld b, a
    ld a, [STARTOF(OAM) + 1]
    sub a, 8
    cp a, b
    jp nc, PaddleBounceDone
    add a, 8 + 16
    cp a, b
    jp c, PaddleBounceDone
    ld a, -1
    ld [wBallMomentumY], a

PaddleBounceDone:
    ld a, [wBrickCnt]
    cp a, 0
    ret nz

    call SaveScoreToSram
WaitVblankWin:
    ld a, [rLY]
    cp a, 144
    jr c, WaitVblankWin
    ld a, 0
    ld [rLCDC], a
    jp GlobalMenuInit


SECTION "Counter", WRAM0
wFrameCounter: db

SECTION "Ball Data", WRAM0
wBallMomentumX: db
wBallMomentumY: db

SECTION "Ball speed data", WRAM0
wBallSpeedValue: db

SECTION "Brick Data", WRAM0
wBrickCnt: db
wScore: db

SECTION "Game Over Data", WRAM0
wCntBallUnderPaddle: db
