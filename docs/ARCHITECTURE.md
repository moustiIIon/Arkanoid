# Architecture du code <-> Cartridge Game Boy HEHEHE

Ce document décrit le fonctionnement interne du code : le chemin d'exécution depuis le boot jusqu'aux jeux, les patterns utilisés, les interactions entre modules, et les mécanismes clés.

---

## 1. Point d'entrée et chemin d'exécution global

Le ROM démarre à l'adresse `$0100` (header cartouche). Le CPU exécute un `jp EntryPoint` vers la zone programme.

```
$0100 ──► EntryPoint (main.asm)
              │
              ├─ Attend un VBlank (stabilisation écran)
              ├─ Désactive le LCD (LCDC = 0)
              └─► GlobalMenuInit (menu.asm)
                      │
                      ├─ InitAllSram      ← initialise le stockage persistant
                      ├─ MemCpy           ← charge les tuiles et la tilemap du menu
                      ├─ Active le LCD (mode fond uniquement)
                      └─► GlobalMenuLoop  ← boucle principale du programme
```

`GlobalMenuLoop` est le **hub central** : tout le programme tourne autour de cette boucle. Les jeux sont des sous-routines appelées depuis ce hub, et ils y retournent tous en fin de partie.

---

## 2. Architecture du menu

**Fichier :** [src/games/menu/menu.asm](src/games/menu/menu.asm)

Le menu gère 4 options sélectionnables (0 à 3) stockées dans `wSelectedGame` :

| Index | Option |
|-------|--------|
| 0 | Arkanoid (Brick Breaker) |
| 1 | Reaction (jeu de timing) |
| 2 | Touhou (bullet hell) |
| 3 | Leaderboard |

**Boucle du menu :**
```
GlobalMenuLoop:
    MyWaitVBlank          ← sync 60 Hz
    UpdateKeys            ← lecture joypad
    ├─ UP/DOWN  →  déplace le curseur (MenuMoveUp / MenuMoveDown)
    ├─ START    →  TransitionScreenToBlack + saut vers le jeu sélectionné
    └─ SELECT   →  affiche le leaderboard (LeaderboardScreen)
```

Le curseur est déplacé dans `wSelectedGame` (0-3, avec wrap-around), puis rendu via une tuile de sélection dans la tilemap.

**Leaderboard :** lit les scores depuis la SRAM (`$A000-$A006`), les affiche en format BCD pour Brick et binaire pour Reaction.

---

## 3. Infrastructure commune (src/core/)

Ces modules sont partagés par tous les jeux.

### Input — [src/core/input.asm](src/core/input.asm)

```
UpdateKeys:
    écrit dans rJOYP pour lire boutons puis D-pad
    wCurKeys  ← état courant (boutons maintenus)
    wNewKeys  ← boutons appuyés ce frame uniquement
```

Les jeux testent `wNewKeys` pour les actions one-shot (START, A) et `wCurKeys` pour les mouvements continus.

### Synchronisation verticale — [src/core/my_waitvblank.asm](src/core/my_waitvblank.asm)

```
MyWaitVBlank:
    boucle jusqu'à rLY >= 144   ← début de l'intervalle VBlank
```

Appelé en début de chaque frame. Garantit que le CPU touche au VRAM/OAM pendant la période sûre, sans glitch graphique.

### MemCpy — [src/core/memcpy.asm](src/core/memcpy.asm)

```
MemCpy(DE=source, HL=destination, BC=taille):
    copie BC octets de DE vers HL
```

Utilisé pour charger toutes les tuiles graphiques, tilemaps et sprites en VRAM.

### Gestion SRAM — [src/core/sram.asm](src/core/sram.asm)

L'accès à la SRAM (RAM externe sur cartouche) nécessite un déverrouillage MBC :

```
EnableSRAM:   écrit $0A dans la zone MBC → active l'accès $A000-$BFFF
DisableSRAM:  écrit $00 → protège le contenu
```

**Layout SRAM :**
```
$A000 : magic byte ($43) — marque une SRAM déjà initialisée
$A001 : score Brick  #1 (BCD)
$A002 : score Brick  #2 (BCD)
$A003 : score Brick  #3 (BCD)
$A004 : score React  #1 (binaire)
$A005 : score React  #2 (binaire)
$A006 : score React  #3 (binaire)
```

`InitAllSram` : si le magic byte est absent (premier démarrage), initialise tous les scores à 0 et écrit le magic byte.

`SaveScoreToSram` / `SaveReactScoreToSram` : insertion-sort dans le top 3 après chaque partie.

### Collision par tilemap — [src/core/tile_lookup.asm](src/core/tile_lookup.asm)

```
GetTileByPixel(B=Y_pixels, C=X_pixels) → HL = adresse dans la tilemap
```

Convertit des coordonnées pixel en adresse tilemap. Utilisé dans Brick pour la détection balle/mur et balle/brique.

### Transition d'écran — [src/core/transition.asm](src/core/transition.asm)

```
TransitionScreenToBlack:
    fait passer le registre rBGP par 4 états de palette sur 8 frames
    effet de fondu au noir avant chaque changement de jeu
```

---

## 4. Pattern commun à tous les jeux

Chaque jeu suit la même structure :

```
GameInit:
    CommonInit               ← vide VRAM/OAM, désactive LCD
    MemCpy(...)              ← charge tuiles et sprites spécifiques
    initialise variables WRAM
    configure LCDC
    └─► GameLoop:
            MyWaitVBlank     ← 60 Hz
            UpdateKeys       ← input
            logique jeu      ← physique, IA, état
            mise à jour OAM  ← positions sprites
            si fin de partie:
                SaveScoreToSram
                TransitionScreenToBlack
                jp GlobalMenuInit
```

---

## 5. Brick Breaker — [src/games/brick/](src/games/brick/)

### Variables clés (WRAM)

| Variable | Rôle |
|----------|------|
| `wBallMomentumX/Y` | Vélocité de la balle (-1 ou +1) |
| `wScore` | Score BCD courant |
| `wBrickCnt` | Briques restantes (28 au départ) |
| `wBallSpeedValue` | Nombre de pas par frame (multiplicateur) |
| `wFrameCounter` | Compteur frame pour bonus de vitesse |

### Pipeline physique (chaque frame)

```
BrickLoop:
    1. Applique wBallMomentumX/Y à la position balle
    2. Y >= BALL_DEAD_Y (176) ? → perd une vie / game over
    3. GetTileByPixel (haut balle)
       ├─ IsWallTile   → inverse Y momentum
       └─ CheckAndHandleBrick → décrémente wBrickCnt, incrémente wScore
    4. Pareil pour côté droit, côté gauche
    5. Collision raquette : Y == paddle_Y et X dans [paddle_X, paddle_X+8] → rebond
```

### Vitesse progressive

- Score 03 → vitesse 2 (2 pas/frame)
- Score 06 → vitesse 3
- Score 09 → vitesse 4
- Le score utilise l'instruction `daa` (BCD arithmetic) pour incrémenter sans conversion.

### OAM

```
Sprite 0 : Raquette (tuile paddle, 8×8)
Sprite 1 : Balle    (tuile ball,   8×8)
```

---

## 6. Reaction — [src/games/reaction/](src/games/reaction/)

### Machine à états

```
wReactionState:
    DIFFICULTY (0) ─── A pressé ───────────────────────► GAME (2)
    GAME (2)       ─── 25 rounds réussis ──────────────► WIN  (3)
    GAME (2)       ─── mauvaise touche / timeout ──────► FAIL (4)
    WIN/FAIL       ─── START ──────────────────────────► DIFFICULTY (0)
```

### Boucle de jeu (état GAME)

```
GameScreen:
    RNG : lit [rDIV] & $07, rejette 6-7, obtient 0-5
    Mapping bouton : 0=A 1=B 2=UP 3=DOWN 4=LEFT 5=RIGHT
    Affiche le sprite correspondant (Sprite 0 au centre)
    démarre wFrameTimer

    Chaque frame:
        wFrameTimer++
        wFrameTimer > seuil_difficulté ? → FAIL
        wNewKeys == wCurrentButton ?
            ├─ OUI → wRoundCount++, wRoundCount == 25 ? → WIN : prochain bouton
            └─ NON (autre bouton) → FAIL
```

**Seuils de timeout :**
- EASY : 120 frames (2 s)
- MEDIUM : 60 frames (1 s)
- HARD : 30 frames (0.5 s)

### HUD Window layer

Reaction est le seul jeu qui utilise le **Window layer** du Game Boy :
```
rWY / rWX configurés pour afficher le HUD en bas d'écran
Compteur de rounds écrit dans la tilemap window à REACT_HUD_ADDR ($9C09)
```

---

## 7. Touhou — [src/games/touhou/](src/games/touhou/)

### Variables clés

| Variable | Rôle |
|----------|------|
| `wPlayerX/Y` | Position du joueur |
| `wPBullet0/1/2 X/Y/Active` | 3 slots de projectiles |
| `wFireCooldown` | Frames avant prochain tir autorisé |
| `wFireSlot` | Index round-robin (0→1→2→0→…) |

### Physique des projectiles

```
Tir (bouton A, si wFireCooldown == 0):
    active le slot wFireSlot
    positionne le projectile sur le joueur
    wFireSlot = (wFireSlot + 1) % 3
    wFireCooldown = 10

Chaque frame (par slot actif):
    Y -= 4            ← monte de 4 pixels/frame
    Y < 0 ? → désactive le slot
```

### OAM layout

```
Sprites 0-5 : Reimu (6 tuiles 8×8 formant un sprite 16×24)
Sprites 6-8 : 3 slots de projectiles
```

### Fin de partie

Appui sur START → `TransitionScreenToBlack` → `GlobalMenuInit`.

---

## 8. Mémoire — cartographie complète

```
$0000-$7FFF  ROM (code + données en flash)
$8000-$8FFF  VRAM — tuiles OBJ et BG
$9800-$9BFF  VRAM — tilemap background
$9C00-$9FFF  VRAM — tilemap window (Reaction HUD)
$A000-$BFFF  SRAM externe (leaderboard, accès via MBC)
$C000-$DFFF  WRAM — variables du programme
$FE00-$FE9F  OAM  — 40 sprites × 4 octets
$FF80-$FFFE  HRAM — stack et variables rapides
```

**Structure d'un sprite OAM (4 octets) :**
```
Octet 0 : Y position
Octet 1 : X position
Octet 2 : Numéro de tuile
Octet 3 : Attributs (palette, flip H/V, priorité)
```

---

## 9. Patterns récurrents dans le code

### RNG hardware via rDIV
Le registre `rDIV` incrémente en continu (hardware timer). Lire `[rDIV]` donne une valeur pseudo-aléatoire dépendante du timing humain — sans PRNG logiciel.

### BCD avec l'instruction `daa`
Brick stocke le score en BCD (Binary-Coded Decimal). L'instruction `daa` après une addition corrige le résultat en BCD, permettant l'affichage direct sans conversion.

### Multiplicateur de vitesse par frame counter
Plutôt qu'une vitesse fractionnaire, le code incrémente la balle `N` fois par frame. `wFrameCounter` compte les frames et `wBallSpeedValue` donne le nombre de pas à effectuer ce frame-là.

### Protection OAM
Toutes les écritures OAM se font pendant ou juste après le VBlank, quand le PPU n'accède pas à l'OAM. `MyWaitVBlank` assure cette synchronisation.

---

## 10. Diagramme d'interactions modules

```
main.asm
└─► menu.asm
    ├── sram.asm        (init + lecture leaderboard)
    ├── memcpy.asm      (charge tilemap menu)
    ├── input.asm       (navigation curseur)
    ├── transition.asm  (fondu au noir)
    │
    ├─► brick.asm
    │   ├── init.asm         (CommonInit)
    │   ├── memcpy.asm       (tuiles + sprites)
    │   ├── input.asm        (mouvement raquette)
    │   ├── tile_lookup.asm  (détection collision)
    │   ├── brick_logic.asm  (physique, score)
    │   ├── sram.asm         (sauvegarde score)
    │   └── transition.asm   (retour menu)
    │
    ├─► reaction.asm
    │   ├── init.asm         (CommonInit)
    │   ├── memcpy.asm       (sprites boutons)
    │   ├── input.asm        (détection touche)
    │   ├── reaction_game.asm (FSM + RNG rDIV)
    │   ├── sram.asm         (sauvegarde score)
    │   └── transition.asm
    │
    └─► touhou.asm
        ├── init.asm         (CommonInit)
        ├── memcpy.asm       (sprites Reimu)
        ├── input.asm        (mouvement + tir)
        ├── touhou_game.asm  (physique, OAM)
        └── transition.asm
```
