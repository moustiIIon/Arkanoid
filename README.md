# Embedded Computing — Cartridge Game Boy

Cartouche Game Boy DMG-001 contenant trois mini-jeux, un menu principal et un leaderboard sauvegardé en SRAM avec batterie. Développé entièrement en assembleur RGBDS (SM83 / Z80).

---

## Prérequis

- [RGBDS](https://rgbds.gbdev.io/) — `rgbasm`, `rgblink`, `rgbfix`
- Un émulateur Game Boy : [BGB](https://bgb.bircd.org/), [mGBA](https://mgba.io/) ou [SameBoy](https://sameboy.github.io/)

---

## Build

```sh
make        # compile → cartridge.gb
make re     # clean + recompile
make clean  # supprime les fichiers générés
```

La ROM produite est `cartridge.gb` (MBC5 + RAM + BATTERY, 32 Ko).

---

## Menu principal

Au démarrage, le menu propose quatre entrées naviguées au curseur :

| Touche  | Action                                      |
|---------|---------------------------------------------|
| ↑ / ↓  | Déplacer le curseur                         |
| START   | Lancer le jeu sélectionné                   |
| SELECT  | Afficher le leaderboard (top 3 par jeu)     |

Depuis le leaderboard, **START** ramène au menu.

---

## Jeux

### 1. Arkanoid (Casse-briques)

Brise les 28 briques avec la balle avant qu'elle tombe deux fois sous la raquette.

| Touche | Action                        |
|--------|-------------------------------|
| ← / → | Déplacer la raquette           |
| START  | Lancer la partie (écran titre) |

- **28 briques** à détruire, disposées sur un tilemap fixe
- **2 vies** — la balle peut tomber une fois avant game over
- **Score BCD** incrémenté à chaque brique cassée (max 28 = `$28`)
- Vitesse de la balle progressive : augmente toutes les 3 briques
- Sauvegarde automatique du score en SRAM à la fin de la partie

---

### 2. Reaction

Appuie sur le bon bouton affiché à l'écran avant que le temps soit écoulé. Réussis 25 rounds pour gagner.

| Touche               | Action                             |
|----------------------|------------------------------------|
| START                | Lancer le jeu (écran titre)        |
| A / B / ↑ / ↓ / ← / → | Répondre au prompt en jeu          |
| START                | Continuer depuis WIN / FAIL        |

**Niveaux de difficulté :**

| Niveau | Temps par round  |
|--------|-----------------|
| EASY   | 120 frames (~2 s) |
| MEDIUM | 60 frames (~1 s)  |
| HARD   | 30 frames (~0.5 s) |

- Bouton sélectionné aléatoirement via `rDIV` (registre hardware)
- Mauvais bouton ou timeout → FAIL immédiat
- Compteur de rounds affiché en temps réel (Window layer, coin supérieur droit)
- Score = nombre de rounds réussis (0–25)
- Sauvegarde automatique en SRAM à la fin de chaque partie

---

### 3. Touhou (Bullet Hell)

Shoot'em up inspiré de Touhou Project. Survive aux vagues d'ennemis et bats le boss en deux phases.

| Touche | Action                       |
|--------|------------------------------|
| ← / → / ↑ / ↓ | Déplacer Reimu (joueur) |
| A      | Tirer (cooldown 5 frames)    |
| START  | Retour au menu (WIN / FAIL)  |

#### Progression

```
Vague 0  →  Vague 1  →  Vague 2  →  Boss Sakuya
(diag. ↘)  (diag. ↙)  (horizontal)   phase 1 → phase 2
```

Chaque vague contient **4 ennemis** ; quand tous sont détruits, la vague suivante apparaît. Après la troisième vague, le boss est invoqué.

#### Vagues d'ennemis

| Vague | Trajectoire          | Positions initiales (X) |
|-------|----------------------|-------------------------|
| 0     | Diagonale ↘ (DX=+1, DY=+1) | 8, 44, 80, 116     |
| 1     | Diagonale ↙ (DX=-1, DY=+1) | 116, 80, 44, 8     |
| 2     | Horizontal (±1, DY=+1)     | 2 depuis la gauche (Y=20, 50) + 2 depuis la droite |

Chaque ennemi a **2 PV** et tire vers le bas toutes les 20 frames.

#### Boss — Sakuya Izayoi

**Phase 1 (30 PV)** — Sakuya oscille horizontalement et tire 3 colonnes de balles verticales simultanément depuis le centre.

**Phase 2 (30 PV)** — À 0 PV en phase 1, Sakuya passe en phase 2 :
- Tir en éventail : 1 balle verticale + 2 diagonales (±45°)
- Deux **sous-ennemis statiques** apparaissent (gauche et droite) ; chacun tire vers le bas indépendamment toutes les 40 frames

Vaincre Sakuya en phase 2 → **WIN**.

**Vies joueur :** 5. Chaque touche déclenche 60 frames d'invincibilité.

---

## Leaderboard

Les 3 meilleurs scores de chaque jeu sont conservés en SRAM (batterie de la cartouche) et persistent après extinction.

| Jeu      | Format       | Plage       | Adresse SRAM |
|----------|--------------|-------------|--------------|
| Arkanoid | BCD          | 0–28 briques | $A001–$A003 |
| Reaction | Binaire      | 0–25 rounds  | $A004–$A006 |

Magic byte d'initialisation : `$A000 = $43`. Tri insertion décroissant à chaque sauvegarde.

---

## Architecture

```
main.asm                    point d'entrée ($0100), includes globaux

src/
  assets/
    tiles.asm               tileset partagé (lettres, chiffres, UI) + constantes TILE_*
    reimu.chr               sprites joueur
    sakuya.chr              sprites boss
    enemies.chr             sprites ennemis
    enemies_bullet.chr      sprites balles ennemies

  core/
    init.asm                CommonInit : efface VRAM/OAM, charge tileset
    memcpy.asm              MemCpy(DE=src, HL=dst, BC=count)
    input.asm               UpdateKeys : joypad → wCurKeys, wNewKeys
    my_waitvblank.asm       MyWaitVBlank : attente scanline ≥ 144
    sram.asm                EnableSRAM, InitAllSram, SaveScoreToSram
    tile_lookup.asm         GetTileByPixel : collision via tilemap
    transition.asm          TransitionScreenToBlack : fondu palette

  games/
    menu/
      menu.asm              GlobalMenuInit/Loop, curseur, leaderboard
      menu_map.asm          données tilemap du menu

    brick/
      brick.asm             init, boucle principale, physique balle, OAM
      brick_logic.asm       collision briques, mise à jour score BCD
      brick_tiles.asm       tiles graphiques (raquette, balle, briques)
      brick_map.asm         données tilemap du niveau

    reaction/
      reaction.asm          machine à états, ReactionInit, ReactionLoop
      reaction_title.asm    écran titre, animation lumières cycliques
      reaction_difficulty.asm  sélection EASY / MEDIUM / HARD
      reaction_game.asm     logique jeu, WIN/FAIL, HUD round
      reaction_sprites.asm  tiles OBJ (A, B, ↑, ↓, ←, →)

    touhou/
      touhou.asm            init, constantes OAM, Shadow OAM, boucle principale
      touhou_game.asm       déplacement joueur, tir, mise à jour balles, TouhouRenderOAM
      touhou_wave.asm       états jeu, SpawnWave, UpdateWave, WRAM vagues
      touhou_enemies.asm    IA ennemis, RenderEnemyOAM
      touhou_sakuya.asm     boss : BossInit, MoveBoss, BossShoot, phases, sous-ennemis
      touhou_sakuya_render.asm  RenderBossOAM, RenderSubEnemies, RenderBossBullets
      touhou_collision.asm  CheckEnemyBulletsVsReimu, CheckPlayerBulletsVsEnemies

  sfx/
    sfx.asm                 effets sonores (registres APU)
```

### Machine à états — Reaction

```
ReactTitleScreen
      │ START
      ▼
DifficultyScreen
      │ A
      ▼
GameScreen
      ├─ [bonne réponse × 25] ──► WinScreen
      └─ [timeout / mauvais]  ──► FailScreen
                                       │ START
                                       ▼
                               DifficultyScreen
```

### Machine à états — Touhou

```
TouhouInit
      │
      ▼
[WAVE] UpdateWave ──► [toutes vagues done] ──► BossInit
  │                                                │
  │                                            [BOSS] UpdateBoss
  │                                                │
  │                                     ┌──────────┴───────────┐
  │                                     │                       │
  │                               [phase 1 HP=0]          [phase 2 HP=0]
  │                                     │                       │
  │                               phase 2 + spawn          WinScreen
  │                               sous-ennemis
  │
  └─ [wPlayerLives=0] ──► GameOverScreen
```

---

## Carte mémoire

| Plage         | Usage                            |
|---------------|----------------------------------|
| $0000–$7FFF   | ROM (MBC5, banques switchables)  |
| $8000–$97FF   | VRAM — tiles graphiques          |
| $9800–$9FFF   | VRAM — tilemaps BG/Window        |
| $A000–$BFFF   | SRAM (batterie) — leaderboard    |
| $C000–$DFFF   | WRAM — variables de jeu          |
| $FE00–$FE9F   | OAM — table des 40 sprites       |
| $FF80–$FFFE   | HRAM — routine d'attente DMA     |

---

## Techniques Game Boy utilisées

| Technique                          | Où                                    |
|------------------------------------|---------------------------------------|
| Synchronisation VBlank (`rLY`)     | Toutes les boucles principales        |
| Shadow OAM + DMA (`rDMA`)          | Touhou — mise à jour sprites atomique |
| Routine DMA en HRAM                | Touhou — CPU limité à HRAM 160 cycles |
| Composition sprites 2×3 tiles      | Touhou — Reimu (6 sprites) et Sakuya  |
| RNG via `rDIV`                     | Reaction — sélection bouton aléatoire |
| Window layer (`rWY` / `rWX`)       | Reaction — HUD compteur de rounds     |
| Score BCD avec `DAA`               | Arkanoid — arithmétique décimale      |
| Animation palette fade-to-black    | Toutes les transitions                |
| SRAM MBC5 avec magic byte          | Persistance du leaderboard            |
| Tri insertion                      | Menu — classement top 3 scores        |
| Détection collision via tilemap    | Arkanoid — `GetTileByPixel`           |
| Invincibilité temporelle (60 fr.)  | Touhou — protection après touche      |
| Compteur de vagues + spawn         | Touhou — progression des ennemis      |
| Tir en éventail (balles diagonales)| Touhou — phase 2 boss                 |

---

## Auteurs

- [Antony](https://github.com/antothP)
- [Aryan](https://github.com/moustiIIon)
