SECTION "Reaction Difficulty", ROM0

DifficultyScreen:
    ld a, %11100100
    ld [rBGP], a
    ld a, [wDifficultyDrawn]
    cp 0
    jp nz, .skipDraw

    call DrawDifficultyText
    ld a, 1
    ld [wDifficultyDrawn], a
.skipDraw:
    ld a, [wNewKeys]
    and a, PAD_UP
    jr z, .checkDown
    ld a, [wSelectedDifficulty]
    cp 0
    jr z, .checkDown
    dec a
    ld [wSelectedDifficulty], a
.checkDown:
    ld a, [wNewKeys]
    and a, PAD_DOWN
    jr z, .doCursor
    ld a, [wSelectedDifficulty]
    cp 2
    jr z, .doCursor
    inc a
    ld [wSelectedDifficulty], a
.doCursor:
    call DrawDifficultyCursor

    ld a, [wNewKeys]
    and a, PAD_A
    jp z, ReactionLoop
    ; transition vers GAME
    xor a
    ld [wDifficultyDrawn], a
    ld [wGameInitDone], a
    ld [wRoundCount], a
    ld a, REACT_STATE_GAME
    ld [wReactionState], a
    jp ReactionLoop

DrawDifficultyCursor:
    ; effacer les 3 positions curseur
    xor a
    ld hl, $9887
    ld [hl], a
    ld hl, $9906
    ld [hl], a
    ld hl, $9987
    ld [hl], a

    ld a, [wSelectedDifficulty]
    cp 0
    jr z, .easy
    cp 1
    jr z, .medium
    cp 2
    jr z, .hard
.hard:
    ld hl, $9987
    jr .draw
.medium:
    ld hl, $9906
    jr .draw
.easy:
    ld hl, $9887
.draw:
    ld a, TILE_CURSOR
    ld [hl], a
    ret

DrawDifficultyText:
    ; EASY row 4 col 8 = $9888
    ld hl, $9888
    ld a, TILE_E
    ld [hli], a
    ld a, TILE_A
    ld [hli], a
    ld a, TILE_S
    ld [hli], a
    ld a, TILE_Y
    ld [hli], a

    ; MEDIUM row 6 col 7 = $9907
    ld hl, $9907
    ld a, TILE_M
    ld [hli], a
    ld a, TILE_E
    ld [hli], a
    ld a, TILE_D
    ld [hli], a
    ld a, TILE_I
    ld [hli], a
    ld a, TILE_U
    ld [hli], a
    ld a, TILE_M
    ld [hli], a

    ; HARD row 8 col 8 = $9988
    ld hl, $9988
    ld a, TILE_H
    ld [hli], a
    ld a, TILE_A
    ld [hli], a
    ld a, TILE_R
    ld [hli], a
    ld a, TILE_D
    ld [hli], a
    ret

SECTION "Reaction Difficulty Vars", WRAM0
wDifficultyDrawn: db
wSelectedDifficulty: db
