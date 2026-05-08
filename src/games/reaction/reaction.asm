INCLUDE "hardware.inc"
SECTION "Reaction Game", ROM0

DEF REACT_STATE_MENU       EQU 0
DEF REACT_STATE_DIFFICULTY EQU 1
DEF REACT_STATE_GAME       EQU 2
DEF REACT_STATE_WIN        EQU 3
DEF REACT_STATE_FAIL       EQU 4

ReactionInit:
    ld hl, TILEMAP0
    ld bc, 1024
.clearTilemap:
    xor a
    ld [hli], a
    dec bc
    ld a, b
    or a, c
    jp nz, .clearTilemap

    ld a, REACT_STATE_DIFFICULTY
    ld [wReactionState], a

    xor a
    ld [wCurKeys], a
    ld [wNewKeys], a
    ld [wDifficultyDrawn], a
    ld [wSelectedDifficulty], a
    ld [wGameInitDone], a
    ld [wWinDrawn], a
    ld [wFailDrawn], a

    ld a, LCDC_ON | LCDC_BG_ON
    ld [rLCDC], a

ReactionLoop:
    call MyWaitVBlank
    call UpdateKeys
    ld a, [wReactionState]
    cp REACT_STATE_DIFFICULTY
    jp z, DifficultyScreen
    cp REACT_STATE_GAME
    jp z, GameScreen
    cp REACT_STATE_WIN
    jp z, WinScreen
    cp REACT_STATE_FAIL
    jp z, FailScreen
    jp ReactionLoop

SECTION "Reaction State", WRAM0
wReactionState: db
