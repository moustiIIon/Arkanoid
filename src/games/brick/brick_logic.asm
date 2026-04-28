DEF BRICK_LEFT  EQU $05
DEF BRICK_RIGHT EQU $06
DEF BLANK_TILE  EQU $08

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
