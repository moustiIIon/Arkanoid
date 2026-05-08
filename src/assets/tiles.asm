DEF TILE_BLANK  EQU $00
DEF TILE_A EQU $01
DEF TILE_R EQU $02
DEF TILE_K EQU $03
DEF TILE_N EQU $04
DEF TILE_O EQU $05
DEF TILE_I EQU $06
DEF TILE_D EQU $07
DEF TILE_E EQU $08
DEF TILE_C EQU $09
DEF TILE_T EQU $0A
DEF TILE_CURSOR EQU $0B
DEF TILE_H EQU $0C
DEF TILE_M EQU $0D
DEF TILE_S EQU $0E
DEF TILE_U EQU $0F
DEF TILE_Y EQU $10
DEF TILE_W EQU $11
DEF TILE_F EQU $12
DEF TILE_L EQU $13

DEF TILE_0 EQU $14
DEF TILE_1 EQU $15
DEF TILE_2 EQU $16
DEF TILE_3 EQU $17
DEF TILE_4 EQU $18
DEF TILE_5 EQU $19
DEF TILE_6 EQU $1A
DEF TILE_7 EQU $1B
DEF TILE_8 EQU $1C
DEF TILE_9 EQU $1D
DEF TILE_BORDER EQU $1E
DEF TILE_BORDER_HL EQU $1F



SECTION "Shared Tiles", ROM0

Shared_Tileset_Begin:

; Tile $00 : Blanc
    dw `00000000
    dw `00000000
    dw `00000000
    dw `00000000
    dw `00000000
    dw `00000000
    dw `00000000
    dw `00000000

; Tile $01 : Lettre A
    ; dw `00333300
    ; dw `03300330
    ; dw `03000030
    ; dw `03000030
    ; dw `03333330
    ; dw `03000030
    ; dw `03000030
    ; dw `00000000

    dw `03333300
    dw `33000330
    dw `33000330
    dw `33000330
    dw `33333330
    dw `33000330
    dw `33000330
    dw `00000000


; Tile $02 : Lettre R
    dw `33333300
    dw `33000330
    dw `33000330
    dw `33333300
    dw `33033000
    dw `33003300
    dw `33000330
    dw `00000000

; Tile $03 : Lettre K
    dw `33000330
    dw `33003300
    dw `33033000
    dw `33330000
    dw `33033000
    dw `33003300
    dw `33000330
    dw `00000000

; Tile $04 : Lettre N
    dw `33000330
    dw `33300330
    dw `33330330
    dw `33033330
    dw `33003330
    dw `33000330
    dw `33000330
    dw `00000000

; Tile $05 : Lettre O
    dw `03333330
    dw `33000033
    dw `33000033
    dw `33000033
    dw `33000033
    dw `33000033
    dw `03333330
    dw `00000000

; Tile $06 : Lettre I
    dw `03333330
    dw `00033000
    dw `00033000
    dw `00033000
    dw `00033000
    dw `00033000
    dw `03333330
    dw `00000000

; Tile $07 : Lettre D
    dw `33333300
    dw `33000330
    dw `33000033
    dw `33000033
    dw `33000033
    dw `33000330
    dw `33333300
    dw `00000000

; Tile $08 : Lettre E
    dw `33333330
    dw `33000000
    dw `33000000
    dw `33333300
    dw `33000000
    dw `33000000
    dw `33333330
    dw `00000000

; Tile $09 : Lettre C
    dw `03333330
    dw `33000033
    dw `33000000
    dw `33000000
    dw `33000000
    dw `33000033
    dw `03333330
    dw `00000000

; Tile $0A : Lettre T
    dw `33333333
    dw `00033000
    dw `00033000
    dw `00033000
    dw `00033000
    dw `00033000
    dw `00033000
    dw `00000000

; Tile $0B : Curseur >
    ; dw `00000000
    ; dw `33000000
    ; dw `03300000
    ; dw `00330000
    ; dw `00330000
    ; dw `03300000
    ; dw `33000000
    ; dw `00000000

    dw `00000000
    dw `03333330
    dw `03033030
    dw `03333330
    dw `00000000
    dw `00000000
    dw `03333330
    dw `00000000

; Tile $0C : Lettre H
    dw `33000330
    dw `33000330
    dw `33000330
    dw `33333330
    dw `33333330
    dw `33000330
    dw `33000330
    dw `00000000

; Tile $0D : Lettre M
    ; dw `33000033
    ; dw `33300333
    ; dw `33333333
    ; dw `33033033
    ; dw `33000033
    ; dw `33000033
    ; dw `33000033
    ; dw `00000000

    dw `33000330
    dw `33303330
    dw `33333330
    dw `33030330
    dw `33000330
    dw `33000330
    dw `33000330
    dw `00000000

; Tile $0E : Lettre S
    dw `03333330
    dw `33000033
    dw `33000000
    dw `03333330
    dw `00000033
    dw `33000033
    dw `03333330
    dw `00000000

; Tile $0F : Lettre U
    dw `33003300
    dw `33003300
    dw `33003300
    dw `33003300
    dw `33003300
    dw `33003300
    dw `03333000
    dw `00000000

; Tile $10 : Lettre Y
    dw `03300330
    dw `03300330
    dw `03300330
    dw `00333300
    dw `00033000
    dw `00033000
    dw `00033000
    dw `00000000

; Tile $11 : Lettre W
    dw `33000330
    dw `33000330
    dw `33000330
    dw `33030330
    dw `33333330
    dw `33303330
    dw `33000330
    dw `00000000

; Tile $12 : Lettre F
    dw `33333300
    dw `33000000
    dw `33000000
    dw `33333000
    dw `33000000
    dw `33000000
    dw `33000000
    dw `00000000

; Tile $13 : Lettre L
    dw `33000000
    dw `33000000
    dw `33000000
    dw `33000000
    dw `33000000
    dw `33000000
    dw `33333330
    dw `00000000

; Tile $14 : Chiffre 0
    dw `03333300
    dw `33000330
    dw `33000330
    dw `33000330
    dw `33000330
    dw `33000330
    dw `03333300
    dw `00000000

; Tile $15 : Chiffre 1
    dw `00033000
    dw `00333000
    dw `00033000
    dw `00033000
    dw `00033000
    dw `00033000
    dw `03333330
    dw `00000000

; Tile $16 : Chiffre 2
    dw `03333300
    dw `33000330
    dw `00000330
    dw `00003300
    dw `00033000
    dw `00330000
    dw `33333330
    dw `00000000

; Tile $17 : Chiffre 3
    dw `03333300
    dw `33000330
    dw `00000330
    dw `00333300
    dw `00000330
    dw `33000330
    dw `03333300
    dw `00000000

; Tile $18 : Chiffre 4
    dw `00033330
    dw `00330330
    dw `03300330
    dw `33333333
    dw `00000330
    dw `00000330
    dw `00000330
    dw `00000000

; Tile $19 : Chiffre 5
    dw `33333330
    dw `33000000
    dw `33000000
    dw `33333300
    dw `00000330
    dw `33000330
    dw `03333300
    dw `00000000

; Tile $1A : Chiffre 6
    dw `03333300
    dw `33000000
    dw `33000000
    dw `33333300
    dw `33000330
    dw `33000330
    dw `03333300
    dw `00000000

; Tile $1B : Chiffre 7
    dw `33333330
    dw `00000330
    dw `00003300
    dw `00033000
    dw `00330000
    dw `00330000
    dw `00330000
    dw `00000000

; Tile $1C : Chiffre 8
    dw `03333300
    dw `33000330
    dw `33000330
    dw `03333300
    dw `33000330
    dw `33000330
    dw `03333300
    dw `00000000

; Tile $1D : Chiffre 9
    dw `03333300
    dw `33000330
    dw `33000330
    dw `03333330
    dw `00000330
    dw `33000330
    dw `03333300
    dw `00000000


; Tile $1E : Border dim — petit point central
    dw `00000000
    dw `00000000
    dw `00000000
    dw `00033000
    dw `00033000
    dw `00000000
    dw `00000000
    dw `00000000

; Tile $1F : Border highlight — carré plein
    dw `00000000
    dw `03333330
    dw `03333330
    dw `03333330
    dw `03333330
    dw `03333330
    dw `03333330
    dw `00000000

Shared_Tileset_End: