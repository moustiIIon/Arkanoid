SECTION "Touhou Sprites", ROM0

Touhou_Sprite_Begin:
; Sprite Reimu 2x4 tiles (16x32px), extrait depuis reimu.chr
; Layout 8x16 mode : tile N = haut, tile N+1 = bas

; Tile 0+1 : colonne gauche, moitie haute (OAM sprite 0)
    INCBIN "src/assets/reimu.chr", $350, $10
    INCBIN "src/assets/reimu.chr", $450, $10

; Tile 2+3 : colonne droite, moitie haute (OAM sprite 1)
    INCBIN "src/assets/reimu.chr", $360, $10
    INCBIN "src/assets/reimu.chr", $460, $10

; Tile 4+5 : colonne gauche, moitie basse (OAM sprite 2)
    INCBIN "src/assets/reimu.chr", $550, $10
    INCBIN "src/assets/reimu.chr", $650, $10

; Tile 6+7 : colonne droite, moitie basse (OAM sprite 3)
    INCBIN "src/assets/reimu.chr", $560, $10
    INCBIN "src/assets/reimu.chr", $660, $10

; Tile 8 : Bullet (top, visible) — reutilise balle brick
    dw `00033000
    dw `00311300
    dw `03011030
    dw `03011030
    dw `00311300
    dw `00033000
    dw `00000000
    dw `00000000

; Tile 9 : Bullet (bas, transparent) — requis par mode 8x16
    dw `00000000
    dw `00000000
    dw `00000000
    dw `00000000
    dw `00000000
    dw `00000000
    dw `00000000
    dw `00000000

Touhou_Sprite_End:
