SECTION "Touhou Wave", ROM0

DEF TOUHOU_STATE_WAVE EQU 0
DEF TOUHOU_STATE_BOSS EQU 1
DEF TOUHOU_STATE_WIN EQU 2
DEF TOUHOU_STATE_OVER EQU 3

SECTION "Wave WRAM", WRAM0
;vague ennemis : max 4
wWaveIndex: db ; 3 vagues (0, 1, 2)
wEnemyX: ds 4
wEnemyY: ds 4
wEnemyActive: ds 4
wEnemyHP: ds 4
wEnemyDX: ds 4
wEnemyDY: ds 4
wEnemyBulX: ds 4
wEnemyBulY: ds 4
wEnemyBulActive: ds 4
wEnemyShootTimer: ds 4
