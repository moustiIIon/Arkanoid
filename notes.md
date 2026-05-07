## registres cpu
a = accumulateur -> reg principal pr les calculs et les transferts
b c d e h l = reg généraux -> peuvent se combiner par pair (16 bits)
=> note: hl privilégié pour les adresses mémoires
un reg = 8 bits
sp = stack pointer (la pile pr call/ret)
pc = program counter (où on est ds la ROM)

## carte mémoire
```
$0000 - $3FFF   ROM bank 0         (ta cartouche, début)
$4000 - $7FFF   ROM bank N         (cartouche, banque switchable - MBC5)
$8000 - $9FFF   VRAM               (tiles + tilemap)
$A000 - $BFFF   SRAM               (mémoire sauvegardée sur cartouche, leaderboard !)
$C000 - $DFFF   WRAM               (RAM de travail = tes variables)
$FE00 - $FE9F   OAM                (table des sprites, 40 entrées de 4 octets)
$FF00 - $FF7F   I/O registers      (rLCDC, rLY, rJOYP, etc.)
$FF80 - $FFFE   HRAM               (RAM ultra-rapide, 127 octets)
$FFFF           Interrupt enable
```

## tiles tilemap sprite
### tiles
une tile = 8x8 pixels, chaque pixel sur 2 bits (= 4 couleurs). Total: 16 octets par tile
Elles vivent en VRAM à $8000-$97FF

exemple:
```asm
Tiles:
    dw `33333333    ; ligne 1 : 8 pixels couleur 3 (noir)
```
Dans `33322222 le backtick lui dit "interprète les 8 chiffres comme les 8 pixels d'une ligne, chacun étant la couleur 0/1/2/3". Le dw (define word = 2 octets) encode les 2 bits par pixel sur les 8 pixels.

### tilemap
écran de fond, c'est une grille de 32x32 tiles soit 256x256 pixels soit 1024 octets stockés séquentiellement en mémoire
Une case de la tilemap est 1 octet = l'index de la tile à afficher
la tilemap vit aussi en VRAM à $9800-$9BFF

exemple
```asm
Tilemap:
    db $00, $01, $01, $01, ..., $02, $03, $03, ..., 0,0,0,0,...
    db $04, $05, $06, $05, ..., $07, $03, $03, ..., 0,0,0,0,...
```
Chaque ligne = 32 octets (largeur d'une rangée du tilemap)
Le $05 signifie "c'est ici on dessine la tile n°5" qui est destinée à Tiles + 5*16

note: seulement 160×144 pixels visibles

### calcul pour écrire sur n lignes n colonnes
On regarde le tableau en 2D 32x32
L'expression pour avoir l'adresse de la case se calcule de cette manière:
- adresse = base + (ligne * 32) + colonne
Où:
- base = $9800
- ligne * 32 -> on saute 32 octets par ligne pr descendre
- colonne -> on aance de qq octets sur la ligne
Exemple: $9800  + (4 × 32)  + 8
- 4 * 32 = 128 -> 128 + 8 = 136
- Convert Hexa : 136 <=> $88
- Résultat : $9888

### sprites / OAM (Object Attribute Memory) <=> objets mobiles
tiles + tilemap = décor fixe
Sprites = éléments mobiles ex: balle, personnage, ...
1 sprite a 4 octets dans l'OAM à $FE00-$FE9F
```
Octet 0 : position Y (+16 → un sprite à Y=0 est en (0-16) = hors écran en haut)
Octet 1 : position X (+8 → idem)
Octet 2 : index de tile à dessiner (0-255)
Octet 3 : flags (palette, flip horizontal/vertical, priorité)
```
Le ```+16``` et ```+8``` permettent de faire entrer/sortir le sprite par les bords de l'écran proprement.

exemple: src/games/brick/brick.asm:35-52, c'est l'init de l'OAM
```
ld hl, STARTOF(OAM)  ; hl pointe sur $FE00

; load the paddle
ld a, 128 + 16  ; Y = 128 (en bas)
ld [hli], a     ; écrit a en [hl], puis incrémente hl
ld a, 16 + 8    ; X = 16 (à gauche)
ld [hli], a
ld a, 0         ; tile index 0
ld [hli], a
ld [hli], a     ; flags 0
```
le [hli] signifie "écris à l'adresse pointée par hl puis incrémente hl"
ça permet de remplire des tableaux séquentiellement

## Boot
GB exec boot ROM interne 
saut à l'adresse $0100 de la cartouche
jp EntryPoint signifie "saute au vrai code" <=> skip le header ($0100 à $014F)
donc  EntryPoint commence à $0150

### VBlank
l'écran est dessiné ligne par ligne de haut en bas 
Quand le faisceau atteint la ligne 144, il sort de la zone visible (l'écran fait 144 lignes, mais le hardware compte jusqu'à 153) = VBlank (vertical blanking)
De la l.144-153 rien ne s'affiche et on peut modif la VRAM sans glitch visuel
Le reg rLY nous dis en permanence ql ligne le hardware est en train de dessiner
La boucle WaitVblank fais juste : while LY < 144, wait

## Memcpy
```
MemCpy:
    ld a, [de]      ; charge l'octet pointé par de dans a
    ld [hli], a     ; écris a à [hl], incrémente hl
    inc de          ; incrémente de
    dec bc          ; décrémente le compteur
    ld a, b         ; (b OR c) == 0  <=>  bc == 0
    or a, c
    jp nz, MemCpy   ; tant que bc != 0, recommence
    ret
```

## rLCDC - Picture Processing Unit

Le registre rLCDC ($FF40)
C'est le chef d'orchestre du PPU (Picture Processing Unit). Chaque bit de rLCDC active/désactive une fonctionnalité graphique :

```
bit 7 = LCD ON/OFF              ← LCDC_ON
bit 6 = Window tilemap area
bit 5 = Window enable
bit 4 = BG/Window tile area
bit 3 = BG tilemap area
bit 2 = OBJ size (8x8 ou 8x16)
bit 1 = OBJ (sprites) enable    ← LCDC_OBJ_ON
bit 0 = BG enable               ← LCDC_BG_ON
```

## Flags

### Flag Carry (c)

c'est un flag du registre f qu'on ne lit jms directement. Il est màj auto par certaines opérations
