# Embedded Computing - Cartridge

C'est quoi ? Ce projet consiste à coder une cartouche Game Boy contenant deux mini-jeux, un menu principal et un leaderboard sauvegardé en SRAM.

Développé en assembleur RGBDS pour la Game Boy originale (DMG-001).

---

## Prérequis

- [RGBDS](https://rgbds.gbdev.io/) (rgbasm, rgblink, rgbfix)
- Un émulateur Game Boy : [BGB](https://bgb.bircd.org/), [mGBA](https://mgba.io/), ou SameBoy

## Build

```sh
make        # compile → cartridge.gb
make re     # clean + recompile
make clean  # supprime les fichiers générés
```

La ROM produite est `cartridge.gb` (MBC5 + RAM + BATTERY, 32 Ko).

---

## Jeux

### Arkanoid (Casse-briques)

Brise toutes les briques avec la balle avant qu'elle ne tombe deux fois sous la raquette.

| Touche | Action |
|--------|--------|
| ← / → | Déplacer la raquette |
| START  | Lancer la partie depuis le titre |

- 28 briques à détruire
- Score incrémenté à chaque brique cassée (format BCD)
- 2 vies (la balle peut tomber une fois)
- Sauvegarde automatique du score en SRAM à la fin

### Reaction

Appuie sur le bon bouton affiché à l'écran avant que le temps soit écoulé. Complète 25 rounds pour gagner.

| Touche | Action |
|--------|--------|
| START  | Lancer le jeu depuis l'écran titre |
| A / B / ↑ / ↓ / ← / → | Répondre au prompt en jeu |
| START  | Continuer depuis WIN / FAIL |

**Niveaux de difficulté :**

| Niveau | Temps par round |
|--------|----------------|
| EASY   | 120 frames (~2 s) |
| MEDIUM | 60 frames (~1 s) |
| HARD   | 30 frames (~0.5 s) |

- Score = nombre de rounds complétés (0–25)
- Sauvegarde automatique en SRAM à chaque fin de partie

---

## Menu principal

- **↑ / ↓** : naviguer entre les jeux
- **START** : lancer le jeu sélectionné
- **SELECT** : afficher le leaderboard (top 3 scores par jeu)

Depuis le leaderboard, appuie sur **START** pour revenir au menu.

---

## Leaderboard

Les 3 meilleurs scores de chaque jeu sont sauvegardés en SRAM (batterie de la cartouche). Les scores persistent après extinction.

- Arkanoid : scores au format BCD (nombre de briques cassées)
- Reaction : score binaire (rounds complétés, 0–25)

---

## Architecture

```
main.asm                    point d'entrée, includes globaux

src/
  assets/
    tiles.asm               tileset partagé + constantes TILE_*

  core/
    memcpy.asm              copie mémoire générique (MemCpy)
    input.asm               lecture joypad (UpdateKeys, wCurKeys, wNewKeys)
    my_waitvblank.asm       synchronisation VBlank (MyWaitVBlank)
    sram.asm                enable/disable SRAM, save/init scores
    tile_lookup.asm         GetTileByPixel (collision tilemap)
    transition.asm          fade-to-black palette (TransitionScreenToBlack)

  games/
    menu/
      menu.asm              menu principal, curseur, leaderboard screen
      menu_map.asm          données tilemap du menu

    brick/
      brick.asm             init, boucle principale, OAM, physique balle
      brick_logic.asm       collision briques, mise à jour score
      brick_tiles.asm       tiles graphiques + chiffres
      brick_map.asm         données tilemap du niveau

    reaction/
      reaction.asm          constantes état, ReactionInit, ReactionLoop
      reaction_title.asm    écran titre + animation cadre tournant
      reaction_difficulty.asm  sélection EASY/MEDIUM/HARD
      reaction_game.asm     logique jeu, WinScreen, FailScreen, HUD round
      reaction_sprites.asm  tiles OBJ (A, B, ↑, ↓, ←, →)
```

### Machine à états - Reaction

```
ReactTitleScreen
      │ START
      ▼
 ReactionInit ──► ReactionLoop
                       │
          ┌────────────┼────────────┐
          ▼            ▼            ▼
  DifficultyScreen  GameScreen   WinScreen / FailScreen
          │ A          │ correct        │ START
          │            │ ×25 → WIN      │
          └────────────┴────────────────┘
                  retour DifficultyScreen
```

---

## Techniques Game Boy utilisées

| Technique | Où |
|-----------|-----|
| Synchronisation VBlank (rLY) | Toutes les boucles principales |
| Écriture OAM sécurisée (LCD off ou VBlank) | GameScreenInit, GameScreen |
| RNG via rDIV | Sélection bouton aléatoire (Reaction) |
| Window layer (rWY / rWX) | HUD compteur de rounds (Reaction) |
| Palette BG / OBJ indépendantes (rBGP, rOBP0) | Jeux + transitions |
| Animation palette (fade-to-black) | Transitions entre états |
| SRAM MBC5 avec magic byte | Persistance du leaderboard |
| BCD avec DAA | Score Arkanoid |

---

## Auteurs

- [Antony](https://github.com/antothP)
- [Aryan](https://github.com/moustiIIon)
