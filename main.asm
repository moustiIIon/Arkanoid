INCLUDE "hardware.inc"

SECTION "Header", ROM0[$100]

    jp EntryPoint

    ds $150 - @

EntryPoint:

WaitVblank:
    ld a, [rLY]
    cp 144
    jp c, WaitVblank
    ld a, 0
    ld [rLCDC], a

    jp GlobalMenuInit


; ============================================================================================================
;
; .___  ___.   ______    _______  __    __   __       _______     _______.
; |   \/   |  /  __  \  |       \|  |  |  | |  |     |   ____|   /       |
; |  \  /  | |  |  |  | |  .--.  |  |  |  | |  |     |  |__     |   (----`
; |  |\/|  | |  |  |  | |  |  |  |  |  |  | |  |     |   __|     \   \
; |  |  |  | |  `--'  | |  '--'  |  `--'  | |  `----.|  |____.----)   |
; |__|  |__|  \______/  |_______/ \______/  |_______||_______|_______/
;
; ============================================================================================================

INCLUDE "src/core/memcpy.asm"
INCLUDE "src/core/input.asm"
INCLUDE "src/core/tile_lookup.asm"
INCLUDE "src/core/my_waitvblank.asm"

INCLUDE "src/games/brick/brick.asm"
INCLUDE "src/games/brick/brick_logic.asm"
INCLUDE "src/games/brick/brick_tiles.asm"
INCLUDE "src/games/brick/brick_map.asm"

INCLUDE "src/games/reaction/reaction.asm"
INCLUDE "src/games/reaction/reaction_sprites.asm"

INCLUDE "src/games/menu/menu.asm"
INCLUDE "src/games/menu/menu_tiles.asm"
INCLUDE "src/games/menu/menu_map.asm"
INCLUDE "src/core/transition.asm"
