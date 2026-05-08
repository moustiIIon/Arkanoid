SECTION "Reaction Logic", ROM0

GameScreenInit:
    xor a
    ld [rLCDC], a

    ld de, Shared_Tileset_Begin
    ld hl, $9000
    ld bc, Shared_Tileset_End - Shared_Tileset_Begin
    call MemCpy

    ld hl, TILEMAP0
    ld bc, 1024
.clearMap:
    xor a
    ld [hli], a
    dec bc
    ld a, b
    or a, c
    jp nz, .clearMap

    ld de, Reaction_Sprite_Tiles_Begin
    ld hl, $8000
    ld bc, Reaction_Sprite_Tiles_End - Reaction_Sprite_Tiles_Begin
    call MemCpy

    ; vider OAM
    ld hl, $FE00
    ld b, 160
    xor a
.clearOam:
    ld [hli], a
    dec b
    jr nz, .clearOam

    ; sprite 0 au centre
    ld hl, $FE00
    ld a, 84
    ld [hli], a
    ld a, 84
    ld [hli], a
    ld a, 0
    ld [hli], a
    ld a, 0
    ld [hli], a

    ; window HUD (1 ligne en bas, row 136)
    ld hl, $9C00
    ld b, 32
    xor a
.clearWinMap:
    ld [hli], a
    dec b
    jr nz, .clearWinMap

    ld a, 136
    ld [rWY], a
    ld a, 7
    ld [rWX], a

    ; bouton aléatoire via rDIV
.pickButton:
    ld a, [rDIV]
    and $07
    cp 6
    jr nc, .pickButton
    ld [wCurrentButton], a
    ld [$FE02], a

    ld a, LCDC_ON | LCDC_BG_ON | LCDC_OBJ_ON | LCDC_WIN_ON | LCDC_WIN_9C00
    ld [rLCDC], a
    ld a, %11100100
    ld [rBGP], a
    ld a, %11100100
    ld [rOBP0], a

    xor a
    ld [wFrameTimer], a
    ret

GameScreen:
    ld a, [wGameInitDone]
    cp 0
    jr nz, .alreadyInit
    call GameScreenInit
    ld a, 1
    ld [wGameInitDone], a
.alreadyInit:
    ; sync sprite en VBlank
    ld a, [wCurrentButton]
    ld [$FE02], a
    call DrawRoundCounter

    ; timer
    ld a, [wFrameTimer]
    inc a
    ld [wFrameTimer], a
    ld b, a

    ; seuil selon difficulté
    ld a, [wSelectedDifficulty]
    cp 0
    jr nz, .notEasy
    ld a, 120
    jr .checkTimeout
.notEasy:
    cp 1
    jr nz, .notMedium
    ld a, 60
    jr .checkTimeout
.notMedium:
    ld a, 30
.checkTimeout:
    cp b
    jp c, .wrong

    ; check A
    ld a, [wNewKeys]
    and a, PAD_A
    jr z, .notA
    ld a, [wCurrentButton]
    cp 0
    jp z, .correct
    jp .wrong
.notA:
    ; check B
    ld a, [wNewKeys]
    and a, PAD_B
    jr z, .notB
    ld a, [wCurrentButton]
    cp 1
    jp z, .correct
    jp .wrong
.notB:
    ; check UP
    ld a, [wNewKeys]
    and a, PAD_UP
    jr z, .notUp
    ld a, [wCurrentButton]
    cp 2
    jp z, .correct
    jp .wrong
.notUp:
    ; check DOWN
    ld a, [wNewKeys]
    and a, PAD_DOWN
    jr z, .notDown
    ld a, [wCurrentButton]
    cp 3
    jp z, .correct
    jp .wrong
.notDown:
    ; check LEFT
    ld a, [wNewKeys]
    and a, PAD_LEFT
    jr z, .notLeft
    ld a, [wCurrentButton]
    cp 4
    jp z, .correct
    jp .wrong
.notLeft:
    ; check RIGHT
    ld a, [wNewKeys]
    and a, PAD_RIGHT
    jp z, ReactionLoop
    ld a, [wCurrentButton]
    cp 5
    jp z, .correct
    jp .wrong

.correct:
    xor a
    ld [wFrameTimer], a
    ld a, [wRoundCount]
    inc a
    ld [wRoundCount], a
    cp 25
    jp z, .win
.pickNext:
    ld a, [rDIV]
    and $07
    cp 6
    jr nc, .pickNext
    ld [wCurrentButton], a
    jp ReactionLoop

.win:
    call SaveReactScoreToSram
    ld a, REACT_STATE_WIN
    ld [wReactionState], a
    jp ReactionLoop

.wrong:
    call SaveReactScoreToSram
    ld a, REACT_STATE_FAIL
    ld [wReactionState], a
    jp ReactionLoop

WinScreen:
    ld a, LCDC_ON | LCDC_BG_ON
    ld [rLCDC], a
    ld a, %11100100
    ld [rBGP], a

    ld a, [wWinDrawn]
    cp 0
    jr nz, .skipWin
    ld hl, $9909
    ld a, TILE_W
    ld [hli], a
    ld a, TILE_I
    ld [hli], a
    ld a, TILE_N
    ld [hli], a
    ld a, 1
    ld [wWinDrawn], a
.skipWin:
    ld a, [wNewKeys]
    and a, PAD_START
    jp z, ReactionLoop
    xor a
    ld [wWinDrawn], a
    ld [wDifficultyDrawn], a
    ld a, REACT_STATE_DIFFICULTY
    ld [wReactionState], a
    jp ReactionLoop

FailScreen:
    ld a, LCDC_ON | LCDC_BG_ON
    ld [rLCDC], a
    ld a, %11100100
    ld [rBGP], a

    ld a, [wFailDrawn]
    cp 0
    jr nz, .skipFail
    ld hl, $9908
    ld a, TILE_F
    ld [hli], a
    ld a, TILE_A
    ld [hli], a
    ld a, TILE_I
    ld [hli], a
    ld a, TILE_L
    ld [hli], a
    ld a, 1
    ld [wFailDrawn], a
.skipFail:
    ld a, [wNewKeys]
    and a, PAD_START
    jp z, ReactionLoop
    xor a
    ld [wFailDrawn], a
    ld [wDifficultyDrawn], a
    ld a, REACT_STATE_DIFFICULTY
    ld [wReactionState], a
    jp ReactionLoop

DrawRoundCounter:
    ld a, [wRoundCount]
    inc a ; round affiché = complétés + 1

    ld b, 0 ; b = dizaine
.divTens:
    cp 10
    jr c, .divDone
    sub 10
    inc b
    jr .divTens
.divDone:
    ld c, a ; c = unité

    ld hl, $9C09 ; window tilemap col 9
    ld a, b
    add a, TILE_0
    ld [hli], a
    ld a, c
    add a, TILE_0
    ld [hl], a
    ret

SECTION "Reaction Game Vars", WRAM0
wGameInitDone: db
wCurrentButton: db ; 0=A 1=B 2=UP 3=DOWN 4=LEFT 5=RIGHT
wRoundCount: db ; 0 à 24
wWinDrawn: db
wFailDrawn: db
wFrameTimer: db
