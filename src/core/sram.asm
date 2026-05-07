SECTION "SRAM", ROM0

DEF SRAM_ENABLE EQU $0000
DEF SRAM_MAGIC_ADDR EQU $A000
DEF SRAM_SCORE1 EQU $A001
DEF SRAM_SCORE2 EQU $A002
DEF SRAM_SCORE3 EQU $A003
DEF SRAM_REACT_SCORE1 EQU $A004
DEF SRAM_REACT_SCORE2 EQU $A005
DEF SRAM_REACT_SCORE3 EQU $A006
DEF SRAM_MAGIC_VAL EQU $43


EnableSRAM:
    ld a, $0A
    ld [SRAM_ENABLE], a
    ret

DisableSRAM:
    ld a, $00
    ld [SRAM_ENABLE], a
    ret

InitAllSram:
    call EnableSRAM
    ld a, [SRAM_MAGIC_ADDR]
    cp SRAM_MAGIC_VAL
    jr z, .WasAlreadyInit

    ld a, SRAM_MAGIC_VAL
    ld [SRAM_MAGIC_ADDR], a

    xor a
    ld [SRAM_SCORE1], a
    ld [SRAM_SCORE2], a
    ld [SRAM_SCORE3], a
    ld [SRAM_REACT_SCORE1], a
    ld [SRAM_REACT_SCORE2], a
    ld [SRAM_REACT_SCORE3], a

.WasAlreadyInit:
    call DisableSRAM
    ret


SaveScoreToSram:
    call EnableSRAM

    ld a, [wScore]
    ld b, a

    ld a, [SRAM_SCORE1]
    cp a, b
    jr nc, .CheckNextScore2

    ld c, a
    ld a, b
    ld [SRAM_SCORE1], a

    ld a, [SRAM_SCORE2]
    ld b, a
    ld a, c
    ld [SRAM_SCORE2], a

    ld a, b
    ld [SRAM_SCORE3], a
    jr .EverythingDone

.CheckNextScore2:
    ld a, [SRAM_SCORE2]
    cp a, b
    jr nc, .CheckNextScore3

    ld c, a
    ld a, b
    ld [SRAM_SCORE2], a
    ld a, c
    ld [SRAM_SCORE3], a
    jr .EverythingDone

.CheckNextScore3:
    ld a, [SRAM_SCORE3]
    cp a, b
    jr nc, .EverythingDone

    ld a, b
    ld [SRAM_SCORE3], a

.EverythingDone:
    call DisableSRAM
    ret


SaveReactScoreToSram:
    call EnableSRAM

    ld a, [wRoundCount]
    ld b, a

    ld a, [SRAM_REACT_SCORE1]
    cp a, b
    jr nc, .CheckReact2

    ld c, a
    ld a, b
    ld [SRAM_REACT_SCORE1], a

    ld a, [SRAM_REACT_SCORE2]
    ld b, a
    ld a, c
    ld [SRAM_REACT_SCORE2], a

    ld a, b
    ld [SRAM_REACT_SCORE3], a
    jr .ReactDone

.CheckReact2:
    ld a, [SRAM_REACT_SCORE2]
    cp a, b
    jr nc, .CheckReact3

    ld c, a
    ld a, b
    ld [SRAM_REACT_SCORE2], a
    ld a, c
    ld [SRAM_REACT_SCORE3], a
    jr .ReactDone

.CheckReact3:
    ld a, [SRAM_REACT_SCORE3]
    cp a, b
    jr nc, .ReactDone

    ld a, b
    ld [SRAM_REACT_SCORE3], a

.ReactDone:
    call DisableSRAM
    ret
