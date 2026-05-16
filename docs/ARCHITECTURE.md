# Architecture du code <-> Cartridge Game Boy HEHEHE

Ce document décrit le fonctionnement interne du code : le chemin d'exécution depuis le boot jusqu'aux jeux, les patterns utilisés, les interactions entre modules, et les mécanismes clés avec leurs valeurs exactes.

---

## 1. Point d'entrée et chemin d'exécution global

Le ROM démarre à l'adresse `$0100` (header cartouche). Le CPU exécute un `jp EntryPoint` vers la zone programme.

```
$0100 ──► EntryPoint (main.asm)
              │
              ├─ Attend un VBlank (stabilisation écran)
              ├─ Désactive le LCD (écrit 0 dans rLCDC)
              └─► GlobalMenuInit (menu.asm)
                      │
                      ├─ InitAllSram      ← initialise le stockage persistant
                      ├─ MemCpy           ← charge les tuiles et la tilemap du menu
                      ├─ Active le LCD (mode fond uniquement)
                      └─► GlobalMenuLoop  ← boucle principale du programme
```

`GlobalMenuLoop` est le **hub central** : tout le programme tourne autour de cette boucle. Les jeux sont des sous-routines appelées depuis ce hub, et ils y retournent tous en fin de partie via `jp GlobalMenuInit`.

---

## 2. Architecture du menu

**Fichier :** [src/games/menu/menu.asm](src/games/menu/menu.asm)

Le menu gère 4 options sélectionnables (0 à 3) stockées dans `wSelectedGame` :

| Index | Option | Adresse curseur tilemap |
|-------|--------|------------------------|
| 0 | Arkanoid (Brick Breaker) | `$9884` |
| 1 | Reaction (jeu de timing) | `$98C4` |
| 2 | Touhou (bullet hell) | `$9904` |
| 3 | Leaderboard | `$9944` |

La tuile de curseur est `$0B`. Chaque déplacement efface l'ancienne position (écrit `$00`) et réécrit `$0B` à la nouvelle.

**Boucle du menu :**
```
GlobalMenuLoop:
    MyWaitVBlank          ← sync 60 Hz (attend rLY >= 144)
    UpdateKeys            ← lecture joypad
    ├─ UP/DOWN  →  déplace le curseur (wrap-around 0↔3)
    ├─ START    →  TransitionScreenToBlack + saut vers le jeu sélectionné
    └─ SELECT   →  affiche le leaderboard (LeaderboardScreen)
```

### Écran Leaderboard

Affiché via `LeaderboardScreen`, déclenché par SELECT depuis le menu :

- Efface toute la tilemap (`$9800`, 1024 octets)
- Écrit `"ARK"` à `$9845` (ligne 2, col 5)
- Écrit `"REACT"` à `$9924` (ligne 9, col 4)
- Affiche les 3 scores Brick aux adresses `$9885 / $98A5 / $98C5` (format BCD, 2 tuiles chacun)
- Affiche les 3 scores Reaction aux adresses `$9965 / $9985 / $99A5` (format binaire, 2 tuiles chacun)

**DrawBCDScore** (scores Brick) :
```
nibble haut : AND %11110000, RRCA×4, ADD TILE_0  → chiffre dizaines
nibble bas  : AND %00001111, ADD TILE_0           → chiffre unités
```

**DrawBinaryScore** (scores Reaction) :
```
boucle soustraction : soustrait 10 jusqu'à < 10, compte les dizaines
reste = unités
écriture : dizaines + TILE_0, unités + TILE_0
```

---

## 3. Infrastructure commune (src/core/)

Ces modules sont partagés par tous les jeux.

### Input - [src/core/input.asm](src/core/input.asm)

Le joypad Game Boy utilise le registre `rJOYP` en mode multiplexé. Pour lire les 8 touches, il faut faire deux lectures séparées :

```
Séquence UpdateKeys :
    1. Écrire JOYP_GET_BUTTONS  → active le nibble boutons (A, B, SELECT, START)
       Lire rJOYP 3 fois (dummy reads pour stabilisation hardware)
       OR résultat avec $F0 pour isoler les bits hauts

    2. Écrire JOYP_GET_CTRL_PAD → active le nibble D-pad (UP, DOWN, LEFT, RIGHT)
       Lire rJOYP, SWAP pour ramener les bits en nibble haut

    3. Combiner les deux lectures :
       XOR résultat courant avec état précédent (wCurKeys)
       AND avec état courant → wNewKeys (uniquement les nouvelles pressions)
       Stocker état courant dans wCurKeys
```

**Note importante :** les touches sont **actives à 0** sur le hardware Game Boy. Le code inverse la logique pour que les bits à 1 signifient "touche appuyée".

| Variable | Contenu |
|----------|---------|
| `wCurKeys` | État courant de toutes les touches (maintenues) |
| `wNewKeys` | Touches pressées **ce frame uniquement** (fronts montants) |

Les jeux testent `wNewKeys` pour les actions one-shot (START, A, changement d'état) et `wCurKeys` pour les mouvements continus (déplacement joueur).

### Synchronisation verticale - [src/core/my_waitvblank.asm](src/core/my_waitvblank.asm)

```
MyWaitVBlank:
    boucle : lire rLY, comparer avec 144
    continuer tant que rLY < 144
    retour quand rLY >= 144 (début VBlank)
```

Appelé en début de chaque frame. Le PPU (Picture Processing Unit) n'accède pas à l'OAM ni à la VRAM pendant le VBlank, ce qui permet des écritures sans glitch graphique. Sans cette synchronisation, les modifications de sprites pendant le rendu produiraient des artefacts visuels.

Le VBlank dure environ 1,1 ms sur 16,7 ms de frame totale (60 Hz), soit ~6,5% du temps disponible.

### MemCpy - [src/core/memcpy.asm](src/core/memcpy.asm)

```
MemCpy(DE = adresse source, HL = adresse destination, BC = nombre d'octets)
    copie BC octets de [DE] vers [HL], incrémente les deux pointeurs
```

Utilisé pour charger toutes les tuiles graphiques (tilesets), tilemaps et sprites en VRAM. Appelé plusieurs fois lors des initialisations de jeu.

### Initialisation commune - [src/core/init.asm](src/core/init.asm)

`CommonInit` fournit une ardoise vierge avant chaque jeu :

```
CommonInit:
    1. Désactiver le LCD    : ld [rLCDC], a  (xor a = 0)
    2. Charger tileset commun : MemCpy(Shared_Tileset_Begin → $9000)
    3. Effacer tilemap BG   : 1024 octets à $9800 → 0
    4. Effacer OAM          : 160 octets à $FE00 → 0 (40 sprites × 4 octets)
```

Le tileset commun contient les tuiles partagées (chiffres, lettres, murs) utilisées par tous les jeux.

### Gestion SRAM - [src/core/sram.asm](src/core/sram.asm)

La SRAM est une RAM externe sur la cartouche, alimentée par batterie. L'accès nécessite un déverrouillage via le MBC5 (Memory Bank Controller) :

```
EnableSRAM:   écrire $0A à $0000 → déverrouille la SRAM ($A000-$BFFF accessible)
DisableSRAM:  écrire $00 à $0000 → reverrouille (protection contre corruption)
```

**Layout SRAM :**
```
$A000 : magic byte ($43) ← présence = SRAM déjà initialisée
$A001 : score Brick  #1 (format BCD)
$A002 : score Brick  #2 (format BCD)
$A003 : score Brick  #3 (format BCD)
$A004 : score React  #1 (binaire, 0–25)
$A005 : score React  #2 (binaire, 0–25)
$A006 : score React  #3 (binaire, 0–25)
```

**`InitAllSram` :**
```
EnableSRAM
Lire [$A000]
Si == $43 → déjà initialisée, skip
Sinon :
    Écrire $43 à $A000
    Écrire $00 à $A001–$A006
DisableSRAM
```

**`SaveScoreToSram` (insertion-sort top 3, Brick) :**
```
EnableSRAM
b ← wScore

Comparer b avec [SRAM_SCORE1] :
    Si b >= [SRAM_SCORE1] :
        c ← [SRAM_SCORE1]   (sauvegarder ancien #1)
        [SRAM_SCORE1] ← b   (nouveau #1)
        b ← [SRAM_SCORE2]   (récupérer ancien #2)
        [SRAM_SCORE2] ← c   (décaler)
        [SRAM_SCORE3] ← b   (décaler)
        → fin
    Sinon → comparer avec SRAM_SCORE2, même logique
    Sinon → comparer avec SRAM_SCORE3, écrire si meilleur
DisableSRAM
```

`SaveReactScoreToSram` est identique mais lit `wRoundCount` et écrit dans `$A004–$A006`.

### Collision par tilemap - [src/core/tile_lookup.asm](src/core/tile_lookup.asm)

```
GetTileByPixel(b = Y_pixels, c = X_pixels) → HL = adresse tilemap

Calcul :
    colonne : c AND %11111000  → efface les 3 bits bas (arrondi à la tuile)
              × 4 (shift left 2) via HL = HL << 2
    ligne   : b SRL 3× → b >> 3  (divise par 8 = taille d'une tuile)
    adresse : HL + b + $9800
```

**Exemple :** pixel (116, 40) → ligne = 116 >> 3 = 14, colonne = 40 & $F8 = 32 → adresse = `$9800 + 14*32 + 5 = $9A45`

Ce mécanisme transforme le problème de collision pixel-par-pixel en une simple lecture mémoire : si la tuile à cette adresse est dans la liste des tuiles solides, il y a collision.

### Transition d'écran - [src/core/transition.asm](src/core/transition.asm)

```
TransitionScreenToBlack (8 frames par étape) :
    Étape 1 → rBGP = %11100100  (palette normale : blanc/gris clair/gris foncé/noir)
    Étape 2 → rBGP = %11111001  (fondu 1 : tout tend vers le sombre)
    Étape 3 → rBGP = %11111110  (fondu 2 : quasi-noir)
    Étape 4 → rBGP = %11111111  (tout noir)
```

Le registre `rBGP` encode 4 entrées de 2 bits chacune. Chaque entrée mappe un index couleur (0–3) vers une teinte réelle (00=blanc, 01=gris clair, 10=gris foncé, 11=noir). Faire pointer toutes les entrées vers 11 produit un écran entièrement noir.

Il existe aussi `GameTransitionToStartFaster` (3 frames par étape) pour les transitions plus rapides entre sous-écrans.

---

## 4. Pattern commun à tous les jeux

Chaque jeu suit la même structure :

```
GameInit:
    CommonInit                  ← vide VRAM/OAM, désactive LCD
    MemCpy(tileset → VRAM)      ← charge tuiles graphiques spécifiques
    MemCpy(tilemap → $9800)     ← charge la carte du niveau
    initialise variables WRAM   ← positions, compteurs, état initial
    configure rLCDC             ← active LCD + sprites + fond (± window)
    └─► GameLoop:
            MyWaitVBlank        ← sync 60 Hz, gate pour écriture VRAM/OAM
            UpdateKeys          ← lecture joypad → wCurKeys, wNewKeys
            logique jeu         ← physique, IA, machine à états
            mise à jour OAM     ← nouvelles positions sprites à $FE00
            fin de partie ?
                SaveScoreToSram
                TransitionScreenToBlack
                jp GlobalMenuInit
```

---

## 5. Brick Breaker - [src/games/brick/](src/games/brick/)

### Constantes et variables clés

| Constante / Variable | Valeur | Rôle |
|----------------------|--------|------|
| `BRICK_COUNT` | 28 | Briques totales au début |
| `PADDLE_INIT_Y` | 144 | Position Y initiale raquette |
| `PADDLE_INIT_X` | 24 | Position X initiale raquette |
| `BALL_INIT_Y` | 116 | Position Y initiale balle |
| `BALL_INIT_X` | 40 | Position X initiale balle |
| `BALL_DEAD_Y` | 176 | Seuil de mort (balle sort en bas) |
| `PADDLE_LEFT_LIMIT` | 15 | Limite gauche raquette |
| `PADDLE_RIGHT_LIMIT` | 105 | Limite droite raquette |
| `wBallMomentumX/Y` | ±1 | Vélocité balle (signé) |
| `wScore` | BCD | Score courant |
| `wBrickCnt` | 0–28 | Briques restantes |
| `wBallSpeedValue` | 0–3 | Multiplicateur de vitesse |
| `wFrameCounter` | compteur | Frames jouées |
| `wCntBallUnderPaddle` | 0–2 | Vies perdues |

### Pipeline physique (chaque frame)

```
BrickLoop:
    Pour i = 0 à wBallSpeedValue :   ← répéter N fois selon vitesse
        1. Appliquer momentum : OAM[1].X += wBallMomentumX
                                OAM[1].Y += wBallMomentumY

        2. Mort si Y >= 176 (BALL_DEAD_Y)
               wCntBallUnderPaddle++
               Si == 2 → SaveScoreToSram + transition menu
               Sinon   → respawn balle à (BALL_RESET_X, BALL_INIT_Y)

        3. BounceOnTop    : GetTileByPixel(Y-16-1, X-8)
               IsWallTile ?    → inverser wBallMomentumY (rebond vertical)
               IsBrickTile ?   → CheckAndHandleBrick, inverser Y

        4. BounceOnRight  : GetTileByPixel(Y-16, X-8+1)
               IsWallTile ?    → wBallMomentumX = -1
               IsBrickTile ?   → CheckAndHandleBrick, wBallMomentumX = -1

        5. BounceOnLeft   : GetTileByPixel(Y-16, X-8-1)
               IsWallTile ?    → wBallMomentumX = +1
               IsBrickTile ?   → CheckAndHandleBrick, wBallMomentumX = +1

        6. Paddle bounce  : ball.Y+4 == paddle.Y
                            ET ball.X ∈ [paddle.X-8, paddle.X+24)
                            → wBallMomentumY = -1
```

### Détection et destruction de briques

Tuiles définies dans [src/games/brick/brick_logic.asm](src/games/brick/brick_logic.asm) :

| Tuile | ID | Signification |
|-------|----|---------------|
| `BRICK_LEFT` | `$05` | Moitié gauche d'une brique |
| `BRICK_RIGHT` | `$06` | Moitié droite d'une brique |
| `BLANK_TILE` | `$08` | Case vide (après destruction) |

**`IsWallTile`** : retourne Z (zéro) si le tile est solide → IDs `$00 $01 $02 $04 $05 $06 $07`.

**`CheckAndHandleBrick`** :
```
Si tile == BRICK_LEFT ($05) :
    Écrire BLANK_TILE à [HL] et [HL+1]   ← efface les 2 moitiés
    wBrickCnt--
    wScore++ (instruction DAA pour rester en BCD)
    UpdateScoreDisplay (extrait nibbles, écrit à $9931/$9932)
    CheckScoreForBallSpeedIncrease

Si tile == BRICK_RIGHT ($06) :
    Écrire BLANK_TILE à [HL-1] et [HL]
    même suite
```

### Vitesse progressive

La vitesse augmente tous les 3 briques cassées (nibble bas du score BCD = 3, 6 ou 9) :

| Score | `wBallSpeedValue` | Pas/frame |
|-------|--------------------|-----------|
| 0–02 | 0 | 1 |
| 03–05 | 1 | 2 |
| 06–08 | 2 | 3 |
| 09+ | 3 | 4 (plafonné) |

`CheckScoreForBallSpeedIncrease` : compare `wScore & $0F` avec 3, 6, 9. Si correspondance et `wBallSpeedValue < 3` → incrémente.

### Affichage du score

```
UpdateScoreDisplay :
    nibble haut : AND %11110000, RRCA×4, ADD DIGIT_OFFSET → tuile dizaines → $9931
    nibble bas  : AND %00001111, ADD DIGIT_OFFSET          → tuile unités  → $9932
```

### OAM Brick

```
Sprite 0 (OAM $FE00) : Raquette - tuile paddle 8×8
Sprite 1 (OAM $FE04) : Balle    - tuile ball   8×8
```

---

## 6. Reaction - [src/games/reaction/](src/games/reaction/)

### Machine à états (`wReactionState`)

```
DIFFICULTY (0)
    Affiche sélection EASY/MEDIUM/HARD
    A pressé → wSelectedDifficulty = valeur choisie → GAME (2)

GAME (2)
    Tirage RNG → affiche bouton → démarre wFrameTimer
    wNewKeys == wCurrentButton avant timeout → wRoundCount++
        wRoundCount == 25 → SaveReactScoreToSram → WIN (3)
        Sinon → prochain tirage
    Mauvaise touche OU timeout → SaveReactScoreToSram → FAIL (4)

WIN (3)
    Écrit "WIN" à REACT_WIN_ADDR ($9909) : TILE_W, TILE_I, TILE_N
    START pressé → DIFFICULTY (0)

FAIL (4)
    Écrit "FAIL" à REACT_FAIL_ADDR ($9908) : TILE_F, TILE_A, TILE_I, TILE_L
    START pressé → DIFFICULTY (0)
```

### Boucle de jeu (état GAME)

```
Constantes de timeout :
    REACT_TIME_EASY   = 120 frames (~2 s à 60 fps)
    REACT_TIME_MEDIUM =  60 frames (~1 s)
    REACT_TIME_HARD   =  30 frames (~500 ms)

Tirage RNG :
    Lire [rDIV] AND $07
    Si résultat >= 6 → relire (biais rejection)
    Résultat ∈ [0,5] : 0=A, 1=B, 2=UP, 3=DOWN, 4=LEFT, 5=RIGHT

Chaque frame :
    wFrameTimer++
    wFrameTimer > seuil ? → FAIL
    wNewKeys a le bit du bouton attendu ?
        OUI → wRoundCount++
              Si wRoundCount == 25 → WIN
              Sinon → nouveau tirage, reset wFrameTimer
        NON (autre touche pressée) → FAIL immédiat
```

### Affichage du compteur de rounds

Le compteur (1–25) est écrit dans le **Window layer**, unique jeu à l'utiliser :

```
rWY = 136, rWX = 7    ← Window démarre à Y=136 (8 lignes du bas)

DrawRoundCounter :
    a ← wRoundCount + 1  (affiche "round en cours" = complétés + 1)
    Division par 10 :
        soustraire 10 en boucle, incrémenter compteur_dizaines
        s'arrêter quand a < 10 (reste = unités)
    Écrire compteur_dizaines + TILE_0 → $9C09
    Écrire reste + TILE_0             → $9C0A
```

Le **Window layer** est un second plan superposé au fond, non scrollable, toujours à l'avant-plan. Activé par le bit `LCDC_WIN_ON=$20` et adressé via la tilemap `$9C00` (bit `LCDC_WIN_9C00=$40`).

### Sprite du bouton affiché

```
Sprite 0 positionné au centre : REACT_SPRITE_Y = 84, REACT_SPRITE_X = 84
6 variantes de tuiles (une par bouton possible)
```

---

## 7. Touhou - [src/games/touhou/](src/games/touhou/)

### Constantes et variables clés

| Constante / Variable | Valeur | Rôle |
|----------------------|--------|------|
| `PLAYER_SPEED` | 2 | Pixels/frame par direction |
| `PLAYER_X_MIN/MAX` | 0 / 144 | Bornes horizontales joueur |
| `PLAYER_Y_MIN/MAX` | 0 / 120 | Bornes verticales joueur |
| `BULLET_SPEED` | 4 | Pixels/frame (montée) |
| `BULLET_FRAMES` | 10 | Cooldown entre tirs |
| `BULLET_TILE` | 6 | ID de tuile projectile |
| `wPlayerX/Y` | - | Position joueur |
| `wFireCooldown` | 0–10 | Frames avant prochain tir |
| `wFireSlot` | 0–2 | Index round-robin actif |
| `wPBullet0/1/2 X/Y/Active` | - | État des 3 slots |

### OAM Touhou (9 sprites)

```
Sprites 0–5 : Reimu (sprite composite 16×24 = 6 tuiles 8×8)
    Sprite 0 : (Y+16, X+8 ) tuile 0    Sprite 1 : (Y+16, X+16) tuile 1
    Sprite 2 : (Y+24, X+8 ) tuile 2    Sprite 3 : (Y+24, X+16) tuile 3
    Sprite 4 : (Y+32, X+8 ) tuile 4    Sprite 5 : (Y+32, X+16) tuile 5

Sprites 6–8 : Projectiles (1 tuile 8×8 chacun, BULLET_TILE)
    Sprite 6 : slot 0 (wPBullet0X/Y)
    Sprite 7 : slot 1 (wPBullet1X/Y)
    Sprite 8 : slot 2 (wPBullet2X/Y)
```

### Gestion des projectiles (round-robin)

```
Tir (bouton A, si wFireCooldown == 0) :
    Activer slot wFireSlot
    wPBulletNX ← wPlayerX + 4   (centré sur le joueur)
    wPBulletNY ← wPlayerY
    wFireSlot  ← (wFireSlot + 1) % 3
    wFireCooldown ← 10

Mise à jour (chaque frame, par slot actif) :
    wPBulletNY -= BULLET_SPEED (4)
    Si underflow (carry set, Y < 0) → désactiver le slot
    Écrire position dans OAM sprite 6+N
```

### Déplacement joueur

```
Chaque frame :
    UP    → wPlayerY -= PLAYER_SPEED, clamp ≥ PLAYER_Y_MIN (0)
    DOWN  → wPlayerY += PLAYER_SPEED, clamp ≤ PLAYER_Y_MAX (120)
    LEFT  → wPlayerX -= PLAYER_SPEED, clamp ≥ PLAYER_X_MIN (0)
    RIGHT → wPlayerX += PLAYER_SPEED, clamp ≤ PLAYER_X_MAX (144)

    Mettre à jour les 6 sprites OAM en fonction de wPlayerX/Y
```

### Machine à états (`wTouhouState`)

```
TOUHOU_STATE_GAME (0) :
    Traite mouvement, tir, sync OAM
    START pressé → TransitionScreenToBlack → GlobalMenuInit

TOUHOU_STATE_OVER (1) :
    Attend START → GlobalMenuInit
```

---

## 8. Registres hardware Game Boy utilisés

| Registre | Adresse | Rôle dans ce projet |
|----------|---------|---------------------|
| `rLCDC` | `$FF40` | Active/configure LCD (sprites, fond, window) |
| `rLY` | `$FF44` | Scanline courante (0–153), 144+ = VBlank |
| `rBGP` | `$FF47` | Palette fond (4×2 bits) |
| `rOBP0` | `$FF48` | Palette sprites (4×2 bits) |
| `rJOYP` | `$FF00` | Joypad (lecture multiplexée boutons/D-pad) |
| `rDIV` | `$FF04` | Timer hardware (incrémente en continu → source RNG) |
| `rWY / rWX` | `$FF4A / $FF4B` | Position de la Window layer (Reaction HUD) |

**Bits `rLCDC` utilisés :**

| Bit | Masque | Effet |
|-----|--------|-------|
| 7 | `$80` | Active le LCD |
| 6 | `$40` | Tilemap window à `$9C00` (sinon `$9800`) |
| 5 | `$20` | Active le Window layer |
| 1 | `$02` | Active les sprites OBJ |
| 0 | `$01` | Active le fond BG |

---

## 9. Cartographie mémoire complète

```
$0000–$7FFF   ROM Flash (32 KB) ── code + données graphiques en flash
    $0100–$014F   Header cartouche (titre, type MBC, checksum)
    $0150+        Code programme (main.asm, jeux, core)

$8000–$97FF   VRAM - données tuiles (256 tuiles × 16 octets)
    $8000–$8FFF   Tuiles OBJ (sprites)
    $9000–$97FF   Tuiles BG + tileset commun

$9800–$9FFF   VRAM - tilemaps
    $9800–$9BFF   Tilemap fond BG  (32×32 tuiles = 1024 octets)
    $9C00–$9FFF   Tilemap Window   (32×32 tuiles, utilisée par Reaction)

$A000–$BFFF   SRAM externe (8 KB) - sauvegarde via batterie
    $A000         Magic byte ($43)
    $A001–$A003   Top 3 Brick (BCD)
    $A004–$A006   Top 3 Reaction (binaire)

$C000–$DFFF   WRAM (8 KB) - variables programme
$FE00–$FE9F   OAM (160 octets) - 40 sprites × 4 octets
$FF80–$FFFE   HRAM (127 octets) - stack et variables rapides
```

**Structure d'un sprite OAM (4 octets) :**
```
Octet 0 : Y position  (Y_écran + 16, donc Y=0 = hors écran haut)
Octet 1 : X position  (X_écran + 8,  donc X=0 = hors écran gauche)
Octet 2 : Numéro de tuile (index dans $8000–$8FFF)
Octet 3 : Attributs
              Bit 7 : priorité (0 = devant fond, 1 = derrière fond couleur 1-3)
              Bit 6 : flip vertical
              Bit 5 : flip horizontal
              Bit 4 : palette OBP0 (0) ou OBP1 (1)
```

---

## 10. Patterns récurrents dans le code

### RNG via rDIV - sans PRNG logiciel

`rDIV` est un registre hardware qui s'incrémente en continu (toutes les 256 cycles CPU, environ 16 384 Hz). Sa valeur dépend entièrement du timing humain depuis le boot. En lisant `[rDIV] & $07`, on obtient un octet pseudo-aléatoire sans implémenter de PRNG.

Reaction utilise une **rejection sampling** : si la valeur est 6 ou 7, on re-lit immédiatement jusqu'à obtenir 0–5. Cela garantit une distribution uniforme sur 6 boutons.

### BCD et l'instruction `daa`

Brick stocke son score en BCD (Binary-Coded Decimal) : le nibble haut représente les dizaines, le nibble bas les unités. Après chaque `add a, 1`, l'instruction `daa` corrige automatiquement le résultat pour rester valide en BCD (par exemple, `$09 + 1 = $10` au lieu de `$0A`).

Avantage : l'affichage ne nécessite aucune conversion - les nibbles sont directement utilisables comme index dans la table de tuiles de chiffres.

### Multiplicateur de vitesse par comptage de pas

Plutôt qu'une vitesse fractionnaire (impossible en entiers simples), le code répète la physique balle `N` fois par frame via `wBallSpeedValue`. La boucle `BrickLoop` itère 1 à 4 fois selon ce multiplicateur. Chaque itération applique un pas complet de momentum + détection de collision.

### Sprites composites pour Reimu (Touhou)

Le Game Boy est limité à des sprites 8×8 ou 8×16. Reimu mesure 16×24 pixels, soit 6 tuiles. Le code maintient 6 entrées OAM avec des offsets calculés depuis `wPlayerX/Y`, simulant un unique sprite large. Toutes les 6 entrées sont mises à jour ensemble chaque frame.

### Protection OAM et fenêtre d'accès

Écrire en OAM (`$FE00–$FE9F`) pendant le rendu provoque des glitches. `MyWaitVBlank` garantit que toutes les écritures OAM se font dans la fenêtre VBlank (scanline >= 144). Cette contrainte est la raison pour laquelle chaque game loop commence par `MyWaitVBlank`.

### Palette comme outil de transition

Plutôt qu'une animation complexe, les transitions utilisent uniquement `rBGP`. Les 4 étapes de palette passent progressivement de la palette normale à tout-noir en 32 frames (8 × 4 étapes). C'est l'équivalent d'un fondu au noir sans aucun calcul sur les graphismes eux-mêmes.

---

## 11. Diagramme d'interactions modules

```
main.asm
└─► menu.asm
    ├── sram.asm         InitAllSram, lecture scores leaderboard
    ├── memcpy.asm       Charge tileset + tilemap menu
    ├── input.asm        Navigation curseur (wCurKeys, wNewKeys)
    ├── transition.asm   Fondu au noir avant changement de jeu
    │
    ├─► brick.asm
    │   ├── init.asm          CommonInit (VRAM/OAM clear, tileset commun)
    │   ├── memcpy.asm        Tuiles briques + sprites paddle/balle
    │   ├── input.asm         Mouvement raquette (wCurKeys LEFT/RIGHT)
    │   ├── tile_lookup.asm   GetTileByPixel → collision balle
    │   ├── brick_logic.asm   IsWallTile, CheckAndHandleBrick, DAA score
    │   ├── sram.asm          SaveScoreToSram (insertion-sort BCD)
    │   └── transition.asm    Retour menu
    │
    ├─► reaction.asm
    │   ├── reaction_title.asm   Écran titre
    │   ├── reaction_difficulty  Sélection difficulté
    │   ├── reaction_game.asm    FSM DIFFICULTY/GAME/WIN/FAIL
    │   │   ├── init.asm         CommonInit
    │   │   ├── memcpy.asm       Sprites 6 boutons
    │   │   ├── input.asm        Détection touche (wNewKeys)
    │   │   └── rDIV             RNG hardware (tirage bouton)
    │   ├── sram.asm             SaveReactScoreToSram (insertion-sort binaire)
    │   └── transition.asm
    │
    └─► touhou.asm
        ├── init.asm          CommonInit
        ├── memcpy.asm        Sprites Reimu + projectiles
        ├── input.asm         Mouvement + tir (wCurKeys + wNewKeys)
        ├── touhou_game.asm   Physique bullets, OAM 9 sprites, bounds
        └── transition.asm    Retour menu sur START
```
