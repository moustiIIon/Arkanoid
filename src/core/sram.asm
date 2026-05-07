SECTION "SRAM", ROM0

DEF SRAM_ENABLE     EQU $0000
DEF SRAM_MAGIC_ADDR EQU $A000
DEF SRAM_SCORE1     EQU $A001
DEF SRAM_SCORE2     EQU $A002
DEF SRAM_SCORE3     EQU $A003
DEF SRAM_MAGIC_VAL  EQU $42


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
    ld a, SRAM_MAGIC_VAL
    jr z, .WasAlreadyInit

    ; si pas init alors :
    ld a, SRAM_MAGIC_VAL
    ld [SRAM_MAGIC_ADDR], a

    ld a, $00
    ld [SRAM_SCORE1], a
    ld [SRAM_SCORE2], a
    ld [SRAM_SCORE3], a

.WasAlreadyInit:
    call DisableSRAM
    ret

.EverythingDone:
    call DisableSRAM
    ret

