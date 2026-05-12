SECTION "Touhou Sprites", ROM0

; Touhou_Sprite_Begin:
;     INCBIN "src/assets/reimu.chr"
; Touhou_Sprite_End:

Touhou_Sprite_Begin:

; Tile 0 : Reimu tête (haut)
    dw `00333300
    dw `03333330
    dw `33233233
    dw `33333333
    dw `33300333
    dw `33333333
    dw `03333330
    dw `00333300

; Tile 1 : Reimu corps (bas)
    dw `00033000
    dw `03333330
    dw `03133130
    dw `03333330
    dw `33333333
    dw `32333332
    dw `33333333
    dw `03300330

Touhou_Sprite_End:
