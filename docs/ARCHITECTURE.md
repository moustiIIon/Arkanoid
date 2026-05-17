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

### Architecture du Shadow OAM et DMA hardware

**Problème :** L'OAM réel ($FE00–$FE9F) ne peut être écrit que pendant le VBlank (~1,1 ms/frame). Touhou utilise 31 sprites simultanément ; les écrire une par une pendant le VBlank est trop lent et produit du flickering si la fenêtre est dépassée.

**Solution : Shadow OAM + DMA**

```
wShadowOAM (WRAM, 256-byte aligned, $C000–$C09F)
    ← toutes les fonctions de rendu écrivent ici (à tout moment)

Début de chaque VBlank :
    ld a, HIGH(wShadowOAM)   ; = $C0
    ld [rDMA], a             ; déclenche le transfert DMA hardware
    call hDMAWait            ; attend 160 cycles en HRAM

rDMA ($FF46) → copie 160 octets de $C000–$C09F vers $FE00–$FE9F
               en exactement 160 cycles CPU
               pendant lesquels seule la HRAM ($FF80–$FFFE) est accessible
```

**Contrainte hardware :** Durant le DMA, le CPU ne peut exécuter aucun code en ROM, WRAM ou VRAM — uniquement HRAM. La routine d'attente est donc copiée en HRAM ($FF80) lors du `TouhouInit` :

```asm
DMAWaitRoutine:       ; copiée à $FF80 au démarrage
    ld a, 40
.loop:
    dec a
    jr nz, .loop      ; 40 × (dec + jr) ≈ 160 cycles
    ret
```

**Alignement 256 octets :** `SECTION "Shadow OAM", WRAM0, ALIGN[8]` impose `HIGH(wShadowOAM) = $C0`. Sans cet alignement, `rDMA` pointerait vers une mauvaise page mémoire et copierait des données aléatoires.

**Résultat :** Mise à jour OAM atomique — le hardware lit le shadow et le copie en un seul bloc, sans glitch visible.

---

### Layout OAM complet (31 sprites)

```
Offset  Sprites  Contenu
$00     0– 5    Sakuya (boss) — grille 2×3 tiles 8×8 = 16×24 px
$18     6–11    Reimu (joueur) — grille 2×3 tiles 8×8 = 16×24 px
$30     12      Balle joueur slot 0
$34     13      Balle joueur slot 1
$38     14      Balle joueur slot 2
$3C–$6B 15–26   12 balles boss (BOSS_BUL_COUNT)
$6C     27      Sous-ennemi 0
$70     28      Sous-ennemi 1
$74     29      Balle sous-ennemi 0
$78     30      Balle sous-ennemi 1
```

Constantes OAM déclarées dans `touhou.asm` :
```asm
DEF OAM_BOSS      EQU $00
DEF OAM_REIMU     EQU $18
DEF OAM_PBUL0     EQU $30
DEF OAM_BOSS_BUL  EQU $3C
DEF OAM_SUBENEMY0 EQU $6C
DEF OAM_SUBENBUL0 EQU $74
```

**Constantes d'offset OAM hardware :**
```asm
DEF OAM_Y_BIAS   EQU 16   ; GB : sprite hors écran si Y < 16
DEF OAM_X_BIAS   EQU 8    ; GB : sprite hors écran si X < 8
DEF SPRITE_ROW_H EQU 8    ; hauteur d'une tuile en pixels
```
Les sprites composites (Reimu, Sakuya) utilisent `OAM_Y_BIAS + SPRITE_ROW_H * N` et `OAM_X_BIAS + SPRITE_ROW_H * N` pour positionner chaque tuile dans la grille.

---

### Machine à états (`wTouhouState`)

```
TOUHOU_STATE_WAVE (0)  ← état initial
    UpdateWave → ennemis actifs
    Tous morts → wWaveIndex++ → SpawnWave
    wWaveIndex > 2 → BossInit → TOUHOU_STATE_BOSS (1)

TOUHOU_STATE_BOSS (1)
    UpdateBoss → mouvement + tir boss
    Phase 1 HP=0 → BOSS_PHASE_2, spawn sous-ennemis, reset HP
    Phase 2 HP=0 → TOUHOU_STATE_WIN (2)
    wPlayerLives=0 → TOUHOU_STATE_OVER (3)

TOUHOU_STATE_WIN (2)
    Affiche "WIN" (tuiles TILE_W/I/N à REACT_WIN_ADDR)
    START → GlobalMenuInit

TOUHOU_STATE_OVER (3)
    Affiche "FAIL" (tuiles TILE_F/A/I/L à REACT_FAIL_ADDR)
    START → GlobalMenuInit
```

---

### Système de vagues (`touhou_wave.asm`)

```
wWaveIndex : 0 → 1 → 2 → boss

Vague 0 — diagonale ↘ (DX=+1, DY=+1)
    X : WAVE_X0=8, WAVE_X1=44, WAVE_X2=80, WAVE_X3=116
    Y : 0 (tous en haut)

Vague 1 — diagonale ↙ (DX=-1, DY=+1)
    X : WAVE_X3=116, WAVE_X2=80, WAVE_X1=44, WAVE_X0=8
    Y : 0

Vague 2 — horizontal (±1, DY=1)
    X : WAVE_EDGE_L=0 (×2, depuis gauche) + WAVE_EDGE_R=160 (×2, depuis droite)
    Y : WAVE2_Y0=20, WAVE2_Y1=50 (décalés verticalement)
```

`CheckWaveDone` : vérifie `wEnemyActive[0..3]` — si tous à 0, incrémente `wWaveIndex` et appelle `SpawnWave`. Si `wWaveIndex > 2` → `BossInit`.

---

### Constantes et variables joueur

| Constante | Valeur | Rôle |
|-----------|--------|------|
| `PLAYER_SPEED` | 2 | px/frame (mouvement) |
| `PLAYER_X_MIN/MAX` | 0 / 144 | Bornes horizontales |
| `PLAYER_Y_MIN/MAX` | 0 / 120 | Bornes verticales |
| `BULLET_SPEED` | 7 | px/frame (montée balle) |
| `BULLET_FRAMES` | 5 | Cooldown entre tirs (frames) |
| `PLAYER_BUL_X_OFF` | 4 | Décalage X balle depuis joueur |
| `INVINC_FRAMES` | 60 | Frames d'invincibilité après touche |

**Tir (round-robin 3 slots) :**
```
Si wFireCooldown > 0 → décrémenter, pas de tir
Si wFireCooldown == 0 et A pressé :
    slot ← wFireSlot (0/1/2)
    wPBulletN_X ← wPlayerX + PLAYER_BUL_X_OFF
    wPBulletN_Y ← wPlayerY
    wPBulletN_Active ← 1
    wFireSlot ← (slot + 1) % 3
    wFireCooldown ← BULLET_FRAMES

Mise à jour (chaque frame, par slot actif) :
    wPBulletN_Y -= BULLET_SPEED
    carry set (underflow) → désactiver le slot
```

---

### Boss — Sakuya Izayoi (`touhou_sakuya.asm`)

#### Constantes boss

| Constante | Valeur | Rôle |
|-----------|--------|------|
| `BOSS_HP` | 30 | PV par phase |
| `BOSS_SPEED` | 1 | px/frame horizontal |
| `BOSS_X_MIN/MAX` | 8 / 136 | Bornes horizontales boss |
| `BOSS_INIT_X/Y` | 72 / 16 | Position de spawn |
| `BOSS_SHOOT_RATE` | 30 | Frames entre salves |
| `BOSS_BUL_SPD` | 1 | px/frame balle boss |
| `BOSS_BUL_COUNT` | 12 | Slots de balles simultanées |
| `BOSS_FIRE_Y_OFF` | 24 | Décalage Y spawn balle depuis boss |
| `BOSS_CENTER_OFF` | 8 | Décalage X centre depuis wBossX |
| `BOSS_COL_OFF` | 12 | Écart entre colonnes (phase 1) |
| `WRAP_THRESHOLD` | 200 | Seuil détection sortie droite+gauche |

#### Mouvement boss (`MoveBoss`)

```
Chaque frame :
    newX ← wBossX + wBossDX
    Si newX ≥ WRAP_THRESHOLD (wrap négatif) → bounce gauche
    Si newX > BOSS_X_MAX     → bounce droite (wBossDX ← -BOSS_SPEED & $FF)
    Si newX < BOSS_X_MIN     → bounce gauche (wBossDX ← +BOSS_SPEED)
    Sinon : wBossX ← newX
```

`wBossDX` stocké en complément à 2 sur 8 bits : `-BOSS_SPEED & $FF = $FF` pour aller à gauche.

#### Tir boss par phase (`BossShoot`)

```
Phase 1 (BOSS_PHASE_1 = 0) — 3 colonnes verticales (DX=0) :
    Balle centre    : X = wBossX + BOSS_CENTER_OFF, DX = 0
    Balle gauche    : X = wBossX + BOSS_CENTER_OFF - BOSS_COL_OFF, DX = 0
    Balle droite    : X = wBossX + BOSS_CENTER_OFF + BOSS_COL_OFF, DX = 0

Phase 2 (BOSS_PHASE_2 = 1) — éventail 3 directions :
    Balle verticale : X = centre, DX = 0
    Balle diag. ←   : X = centre, DX = -BOSS_BUL_SPD & $FF
    Balle diag. →   : X = centre, DX = +BOSS_BUL_SPD
```

`SpawnBossBul(a=X, b=Y, c=DX, de=slot)` écrit X/Y/Active/DY/DX dans les tableaux WRAM correspondants puis incrémente `e`.

#### Mise à jour balles boss (`UpdateBossBullets`)

```
Pour chaque slot 0..11 :
    Si actif :
        Y += wBossBulDY[slot]
        Si Y ≥ SCREEN_H (160) → désactiver
        X += wBossBulDX[slot]
        Si X ≥ SCREEN_H (160) → désactiver
```

**Astuce :** `cp SCREEN_H` après l'addition 8 bits attrape deux cas :
- Sortie droite : X ∈ [160, 199] → X ≥ 160
- Sortie gauche : X < 0 → underflow 8 bits → X ∈ [200, 255] → X ≥ 160 aussi (`WRAP_THRESHOLD = 200`)

#### Transition de phase et sous-ennemis

```
CheckBulletVsBoss :
    Collision → wBossHP--
    wBossHP == 0 ?
        wBossPhase == BOSS_PHASE_1 ?
            wBossPhase ← BOSS_PHASE_2
            wBossHP ← BOSS_HP       ; reset 30 PV
            call SpawnSubEnemies
        wBossPhase == BOSS_PHASE_2 ?
            wTouhouState ← TOUHOU_STATE_WIN
```

#### Sous-ennemis (`SpawnSubEnemies`)

```
Sous-ennemi 0 (gauche) : X = SUB_ENEMY0_X (24), Y = wBossY
    wSubEnemyShootTimer[0] ← SUB_ENEMY_SHOOT_RATE (40)

Sous-ennemi 1 (droite) : X = SUB_ENEMY1_X (112), Y = wBossY
    wSubEnemyShootTimer[1] ← SUB_ENEMY_SHOOT_RATE / 2 (20) ← décalé
```

Les sous-ennemis sont **statiques** (ne bougent pas). Chacun tire vers le bas toutes les 40 frames dès que son slot de balle est libre :

```
UpdateSubEnemies (par sous-ennemi i) :
    wSubEnemyShootTimer[i]--
    Si timer == 0 ET wSubEnemyBulActive[i] == 0 :
        wSubEnemyBulActive[i] ← 1
        wSubEnemyBulX[i] ← wSubEnemyX[i]
        wSubEnemyBulY[i] ← wSubEnemyY[i]
        reset timer ← SUB_ENEMY_SHOOT_RATE
```

---

### Hitboxes et collisions

| Entité | Dimensions hitbox |
|--------|------------------|
| Boss (Sakuya) | `BOSS_HIT_W=17` × `BOSS_HIT_H=25` |
| Balles boss/sous-ennemis | `BOSS_BUL_HIT=9` (seuil absolu X et Y) |
| Sous-ennemis | `SUB_ENEMY_HIT_W=9` × `SUB_ENEMY_HIT_H=9` |

**Méthode de collision (distance absolue signée) :**
```asm
; |a - e| < seuil ?
sub e
jr nc, .positive
cpl
inc a          ; a ← -a (valeur absolue)
.positive:
cp SEUIL       ; carry set si |diff| < SEUIL → collision
```

**Invincibilité :** `wInvincTimer` décrémenté chaque frame. Si > 0, `CheckBossBulletsVsReimu` et `CheckSubEnemyBulletsVsReimu` retournent immédiatement. Toute touche valide déclenche `wInvincTimer ← INVINC_FRAMES (60)`.

---

### WRAM Touhou (variables)

```
wTouhouState    : état machine (WAVE/BOSS/WIN/OVER)
wTouhouFrame    : compteur global de frames
wPlayerX/Y      : position joueur
wPlayerLives    : vies restantes (init = 5)
wInvincTimer    : frames d'invincibilité restantes
wPBullet0..2    : X, Y, Active × 3 slots joueur
wFireCooldown   : cooldown tir
wFireSlot       : index round-robin (0..2)

wBossActive/HP/X/Y/DX/ShootTimer/BulSlot/Phase
wBossBulX/Y/Active/DY/DX : ds 12   ← tableaux 12 balles boss

wSubEnemyX/Y/Active/ShootTimer : ds 2
wSubEnemyBulX/Y/Active         : ds 2

wTouhouWinDrawn / wTouhouOverDrawn  : flag one-shot affichage fin
```

---

### Flux d'exécution par frame (WAVE et BOSS)

```
TouhouLoop:
    MyWaitVBlank
    TouhouRenderOAM :
        ld a, HIGH(wShadowOAM)
        ld [rDMA], a            ; déclenche DMA → OAM réel mis à jour
        call hDMAWait           ; attend en HRAM
        [écrire nouvelles positions dans wShadowOAM pour la frame suivante]
    UpdateKeys

    STATE == WAVE ?
        UpdateWave
            UpdateEnemies, UpdateEnemyBullets
            CheckEnemyBulletsVsReimu, CheckPlayerBulletsVsEnemies
            CheckWaveDone → SpawnWave ou BossInit
    STATE == BOSS ?
        UpdateBoss
            MoveBoss, BossShoot, UpdateBossBullets
            UpdateSubEnemies, UpdateSubEnemyBullets
            CheckBossBulletsVsReimu, CheckSubEnemyBulletsVsReimu
            CheckPlayerBulletsVsBoss, CheckPlayerBulletsVsSubEnemies
    STATE == WIN/OVER ?
        Affichage + attente START
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
| `rDIV` | `$FF04` | Timer hardware (incrémente ~16 384×/s → source RNG) |
| `rDMA` | `$FF46` | Déclenche le DMA OAM (Touhou) |
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

### Sprites composites pour Reimu et Sakuya (Touhou)

Le Game Boy est limité à des sprites 8×8 ou 8×16. Reimu et Sakuya mesurent 16×24 pixels chacune, soit 6 tuiles. Le code maintient 6 entrées OAM avec des offsets calculés depuis la position de base :

```
Colonne 1 : X + OAM_X_BIAS         (= X + 8)
Colonne 2 : X + OAM_X_BIAS + SPRITE_ROW_H  (= X + 16)
Ligne 1   : Y + OAM_Y_BIAS         (= Y + 16)
Ligne 2   : Y + OAM_Y_BIAS + SPRITE_ROW_H  (= Y + 24)
Ligne 3   : Y + OAM_Y_BIAS + SPRITE_ROW_H*2 (= Y + 32)
```

Les constantes `OAM_Y_BIAS=16` et `OAM_X_BIAS=8` reflètent la contrainte hardware du Game Boy : un sprite à Y=0 est masqué au-dessus de l'écran, l'écran visible commence à Y=16.

### Protection OAM : Shadow OAM vs écriture directe

- **Brick et Reaction** : écrivent directement en OAM ($FE00) pendant le VBlank. `MyWaitVBlank` garantit la fenêtre d'accès (~1,1 ms).
- **Touhou** : utilise le Shadow OAM + DMA (voir section 7). Le rendu écrit dans `wShadowOAM` (WRAM) à tout moment, le DMA copie atomiquement en début de VBlank. Élimine tout risque de glitch même avec 31 sprites.

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
        ├── init.asm                CommonInit + copie DMAWaitRoutine → HRAM
        ├── memcpy.asm              Sprites Reimu, Sakuya, ennemis, balles
        ├── input.asm               Mouvement + tir (wCurKeys + wNewKeys)
        ├── touhou_game.asm
        │   ├── TouhouGameScreen    Physique joueur, balles joueur, bounds
        │   └── TouhouRenderOAM     DMA + écriture shadow OAM (31 sprites)
        ├── touhou_wave.asm
        │   ├── SpawnWave           Initialise positions/DX/DY des 4 ennemis
        │   ├── UpdateWave          UpdateEnemies + bullets + collisions + CheckWaveDone
        │   └── CheckWaveDone       Détecte vague terminée → vague suivante ou boss
        ├── touhou_enemies.asm
        │   ├── UpdateEnemies       IA ennemis (mouvement + tir périodique)
        │   ├── UpdateEnemyBullets  Déplacement balles ennemies vers le bas
        │   ├── RenderEnemyOAM      Écriture shadow OAM ennemis
        │   └── CheckPlayerBulletsVsEnemies
        ├── touhou_sakuya.asm
        │   ├── BossInit            Init HP, position, phase, slots balles
        │   ├── MoveBoss            Oscillation horizontale avec bounce
        │   ├── BossShoot           Tir phase 1 (3 colonnes) / phase 2 (éventail)
        │   ├── SpawnBossBul        Alloue un slot de balle boss
        │   ├── UpdateBossBullets   Déplacement X+Y, détection sortie écran
        │   ├── CheckBulletVsBoss   Collision + gestion transition de phase
        │   ├── SpawnSubEnemies     Spawn 2 sous-ennemis statiques
        │   ├── UpdateSubEnemies    Timer tir sous-ennemis
        │   ├── UpdateSubEnemyBullets
        │   ├── CheckBossBulletsVsReimu
        │   ├── CheckSubEnemyBulletsVsReimu
        │   ├── CheckPlayerBulletsVsBoss
        │   ├── CheckPlayerBulletsVsSubEnemies
        │   ├── BossHitReimu        Décrémenter vies + invincibilité
        │   └── UpdateBoss          Orchestrateur (appelle toutes les fonctions ci-dessus)
        ├── touhou_sakuya_render.asm
        │   ├── RenderBossOAM       6 sprites Sakuya dans shadow OAM
        │   ├── ClearBossOAM        Masque sprites boss hors phase boss
        │   ├── RenderBossBullets   Loop sur 12 slots → shadow OAM
        │   ├── RenderSubEnemies    2 sprites sous-ennemis
        │   └── RenderSubEnemyBullets
        └── transition.asm          Retour menu (WIN/OVER → START)
```
