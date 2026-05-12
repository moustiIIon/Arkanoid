DEF BRICK_LEFT  EQU $05
DEF BRICK_RIGHT EQU $06
DEF BLANK_TILE  EQU $08
DEF SCORE_LEFT EQU $9931
DEF SCORE_RIGHT EQU $9932

SECTION "Brick Logic", ROM0

CheckAndHandleBrick:
    ld a, [hl]
    cp a, BRICK_LEFT
    jr nz, CheckAndHandleBrickRight
    ; Break a brick from the left side.
    ld [hl], BLANK_TILE
    inc hl
    ld [hl], BLANK_TILE

	; the counter
	ld a, [wBrickCnt]
	dec a
	ld [wBrickCnt], a
    ; the score counter
    xor a
    ld hl, wScore
    ld a, 1
    add a, [hl]
    daa
    ld [hl], a
    call UpdateScoreDisplay

    ; ici on va check le score pour ensuite augmenter la speed de la balle et donc on va appeller une fonction qui va check tout les 3 de scores
    call CheckScoreForBallSpeedIncrease
    ret

CheckAndHandleBrickRight:
    cp a, BRICK_RIGHT
    ret nz
    ; Break a brick from the right side.
    ld [hl], BLANK_TILE
    dec hl
    ld [hl], BLANK_TILE

	; the counter
	ld a, [wBrickCnt]
	dec a
	ld [wBrickCnt], a
    ; the score counter
    xor a
    ld hl, wScore
    ld a, 1
    add a, [hl]
    daa
    ld [hl], a
    call UpdateScoreDisplay

    ; et donc ici aussi pareil donc le meme commentaire que pour le brick de gauche que je mets en dessous pour rappeller
    ; ici on va check le score pour ensuite augmenter la speed de la balle et donc on va appeller une fonction qui va check tout les 3 de scores

    call CheckScoreForBallSpeedIncrease
    ret

IsWallTile:
    cp a, $00
    ret z
    cp a, $01
    ret z
    cp a, $02
    ret z
    cp a, $04
    ret z
    cp a, $05
    ret z
    cp a, $06
    ret z
    cp a, $07
    ret

UpdateScoreDisplay:
    ld a, [wScore]
    and %11110000
    rrca
    rrca
    rrca
    rrca
    add a, DIGIT_OFFSET
    ld hl, SCORE_LEFT
    ld [hl], a
    ld a, [wScore]
    and %00001111
    add a, DIGIT_OFFSET
    ld hl, SCORE_RIGHT
    ld [hl], a
    ret

CheckScoreForBallSpeedIncrease:
    ld a, [wScore]
    and $0F
    cp 3
    jr z, .IncreaseSpeed
    cp 6
    jr z, .IncreaseSpeed
    cp 9
    jr z, .IncreaseSpeed
    ret

.IncreaseSpeed:
    ld a, [wBallSpeedValue]
    cp 3
    ret z
    inc a
    ld [wBallSpeedValue], a
    ret
