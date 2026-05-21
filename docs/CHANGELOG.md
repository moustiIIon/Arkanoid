# Changelog

All notable changes to this project are documented here.

---

## [2026-05-17]

### Added
- Sakuya 2nd phase: bullet patterns, sub-enemies spawning and rendering
- Sub-enemy logic initialization and wave handling via DMA
- `InitSubEnemies` and related WRAM structure for sub-enemy state

### Refactored
- Hardcoded player and bullet positions replaced with named constants

### Fixed
- Minor bullet flickering issues resolved

---

## [2026-05-16]

### Refactored
- Full OAM handling rewrite for Touhou: now uses DMA transfer (`HDMA`) for better visuals and correct hardware compliance

---

## [2026-05-15]

### Added
- Sakuya boss implementation: rendering, movement, and boundary clamping
- Merge of SFX branch into Touhou game branch

### Fixed
- Sakuya boundary handling corrected

---

## [2026-05-14]

### Added
- Enemy wave logic: direction handling, smooth movement via OAM flickering (every 2 frames)
- Enemy collision detection and hitbox handling
- Real sprite tiles replacing placeholder tiles for enemies

---

## [2026-05-13]

### Added
- APU initialization: SFX system scaffolded (`InitAPU` function)
- Menu SFX: click sound on game selection
- Brick-break SFX for Arkanoid
- Enemy sprites and enemy bullet sprites for Touhou
- Reimu hitbox logic and enemy wave init
- WRAM init for Touhou game state
- Documentation: complete guide on Game Boy audio (SFX/music) with RGBASM

---

## [2026-05-12]

### Added
- 3rd game: **Touhou** added to the cartridge
- Reimu player: 8-direction movement, OAM-centered sprite (8×8)
- Bullet system: 3-slot round-robin firing with cooldown and upward speed
- Arkanoid: ball speed increases with score via frame-counter system

### Refactored
- Whole codebase refactored for modularity and readability
- Common `InitGame` function shared across all 3 games (reduces duplication)
- Sprite mode switched from 8×16 to 8×8
- Menu logic cleaned up; game selection flow improved

---

## [2026-05-11]

### Added
- `touhou.asm` scaffold: Touhou game file initialized (init only)

---

## [2026-05-08]

### Added
- README.md with project description, game instructions, architecture diagram, state machine, and GB techniques table
- Reaction title screen with 16-position chasing-lights border animation (TILE_BORDER / TILE_BORDER_HL)
- Reaction game modularized into 4 files: `reaction_title.asm`, `reaction_difficulty.asm`, `reaction_game.asm`, `reaction_sprites.asm`

---

## [2026-05-07]

### Added
- SRAM leaderboard: top 3 scores per game saved with battery persistence
- Leaderboard display accessible via SELECT from the main menu (ARK / REACT sections)
- `SaveReactScoreToSram`: inserts reaction score into sorted top-3 slots ($A004–$A006)
- Round counter HUD via Window layer (rWY/rWX) displayed during Reaction game
- Number tiles (0–9) and `DrawRoundCounter` function
- Frame timer logic with per-difficulty timeout (EASY 120f / MEDIUM 60f / HARD 30f)

### Fixed
- Garbage tiles in leaderboard: `xor a` moved inside the tilemap clear loop
- OAM write blocked by PPU: moved OAM init to VBlank / LCD-off window
- Wrong initial button shown: sprite tile synced each frame in VBlank
- Score display in SELECT menu: BCD and binary digit extraction corrected

---

## [2026-05-06]

### Added
- Reaction game: full state machine (DIFFICULTY → GAME → WIN / FAIL)
- WIN / FAIL screens with START to return to difficulty selection
- Difficulty selection screen (EASY / MEDIUM / HARD) with cursor navigation
- Reaction sprites: OBJ tiles for A, B, ↑, ↓, ←, → buttons
- `GameScreen`: random button via rDIV, input checking for all 6 buttons
- Transitions between all Reaction states (fade-to-black palette animation)

### Fixed
- `GameScreenInit`: proper frame and OAM clearing before LCD on
- `wWinDrawn` / `wFailDrawn` initialized on each entry to avoid stale draw flag

### Refactored
- Menu tileset moved to `src/assets/` for better modularity

---

## [2026-05-05]

### Added
- Full letter tileset rewritten by hand (all uppercase glyphs)
- `DrawDifficultyText`: writes EASY / MEDIUM / HARD to tilemap
- Score display in Reaction game
- Transition effects between menu and Reaction game

### Fixed
- Letter tiles corrected after visual inspection

---

## [2026-05-04]

### Added
- Game-over system for Arkanoid (2 lives, ball falls twice → game over)
- Transition on START from Arkanoid title (faster fade)
- Score tracking in Arkanoid (BCD with `daa`)

### Fixed
- Ball X position reset correctly after losing a life

---

## [2026-05-03]

### Added
- Main menu: tilemap, cursor (↑/↓ to navigate, START to launch)
- `wSelectedGame` WRAM variable and `UpdateCursor` function
- Menu logic: VBlank sync, game dispatch (Arkanoid / Reaction)

---

## [2026-04-30]

### Added
- Reaction game loop and state dispatching (`wReactionState`)
- `MenuScreen`, `DifficultyScreen`, `GameScreen` initial implementations
- Personal `MyWaitVBlank` function

---

## [2026-04-29]

### Added
- Reaction game files scaffolding
- Tilemap clear and input/screen reset on init

---

## [2026-04-28]

### Refactored
- Full architecture overhaul: modular file layout (`src/core/`, `src/games/`, `src/assets/`)
- CPS counter game refactored for modularity (later replaced by Reaction)

### Fixed
- Brick counter corrected

---

## [2026-04-27]

### Changed
- New paddle sprite
- New brick sprite
- Title screen redrawn by hand

---

## [2026-04-26]

### Added
- CPS counter game branch started
- Whole program architecture refactored for modularity

---

## [2026-04-24]

### Added
- Commentary pass on main assembly file for readability

---

## [2026-04-22]

### Added
- Ball collision with bricks (breakable bricks working)

---

## [2026-04-21]

### Added
- Initial Arkanoid skeleton: paddle, ball, basic structure
- Makefile setup
