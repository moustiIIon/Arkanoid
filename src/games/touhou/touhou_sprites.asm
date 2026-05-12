SECTION "Touhou Sprites", ROM0

Touhou_Sprite_Begin:
; Sprite Reimu 2x3 tiles (16x24px), mode 8x8
; Layout : 6 tiles en une ligne dans le CHR
; [0][1] = rang haut, [2][3] = rang milieu, [4][5] = rang bas

    INCBIN "src/assets/reimu.chr", 0, 96

; Tile 6 : Bullet (8x8, une seule tile)
    dw `00033000
    dw `00311300
    dw `03011030
    dw `03011030
    dw `00311300
    dw `00033000
    dw `00000000
    dw `00000000

Touhou_Sprite_End:
