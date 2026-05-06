INCLUDE "hardware.inc"
SECTION "Reaction Game", ROM0

;faire des constantes d'état pour avoir une meilleure lisibilité du code
;plus modulaire pour changer les valeurs facilement

;DEF NOM EQU valeur
DEF REACT_STATE_MENU EQU 0
DEF REACT_STATE_DIFFICULTY EQU 1
DEF REACT_STATE_GAME EQU 2
DEF REACT_STATE_WIN EQU 3
DEF REACT_STATE_FAIL EQU 4

ReactionInit:
    ;clear tilemap ($9800-$9BFF, 1024 octet)
    ;hl est le registre d'adresse de référence
    ld hl, TILEMAP0 ;met l'adresse $9800 (début du tilemap en VRAM) dans hl
    ld bc, 1024 ;bc = 1024, on utilise bc pour les compteurs par conventions
    xor a ;xor a = ld a, 0 mais pèse 1 octet au lieu de 2
;on remplit la vram de 0 pour la nettoyer et iniatiliser une variable d'état
;c un label local qui existera que dans le scope de ReactionInit et ne va pas override dans d'autres labels de d'autres fichiers (c une fct pv)
.clearTilemap:
    xor a
    ld [hli], a ;ecrit a dans la mémoire pointée par hl et va l'incrémenter ensuite. Donc 1 octet de plus à 0 en VRAM
    dec bc ;decremente bc dcp bc = 1023. Il ne màj pas le flag z
    ld a, b ;copie b dans a
    or a, c ; a = a OR c, ça permet de tester bc == 0. bc = 0 ssi b = 0 et c = 0. il màj le flag z
    jp nz, .clearTilemap ;si bc != 0 alors en relance
    ;le premier bloc est un memset(0x9800, 0, 1024)

    ld [wReactionState], a ;écris a dans WRAM car le CPU GB ne permet pas d'écrire une valeur immédiatement à une adresse mémoire 16bits. Faut passer par un registre

    ;reset les input
    ;lors du boot la WRAM contient du garbage puisque la WRAM n'est pas init par le hardware
    ;init tous les élém de la WRAM pour ne pas boot dans le garbage
    xor a
    ld [wCurKeys], a
    ld [wNewKeys], a
    ld [wDifficultyDrawn], a
    ld [wSelectedDifficulty], a
    ld [wWinDrawn], a
    ld [wFailDrawn], a

    ;allumer lcd background
    ld a, LCDC_ON | LCDC_BG_ON
    ;rLCDC = registre ($FF40) - chaque bit de rLCDC active/desac une fonctionnalité graphique, c'est du PPU
    ld [rLCDC], a

ReactionLoop:
    ;wait vblank
    call MyWaitVBlank
    call UpdateKeys
    ;dispatch sur l'état courant
    ld a, [wReactionState]
    cp REACT_STATE_MENU
    jp z, MenuScreen
    cp REACT_STATE_DIFFICULTY
    jp z, DifficultyScreen
    cp REACT_STATE_GAME
    jp z, GameScreen
    cp REACT_STATE_WIN
    jp z, WinScreen
    cp REACT_STATE_FAIL
    jp z, FailScreen
    jp ReactionLoop ;safety net : si état inconnu, on boucle

MenuScreen:
    xor a ;a = 0 pour avoir la couleur blanche
    ld [rBGP], a ;couleur blanc
    ld a, [wNewKeys] ;a =0
    and a, PAD_A ;a = 0, Z levé
    jp z, ReactionLoop ;si A pas pressé, reboucle (=> continue)
    ld a, REACT_STATE_DIFFICULTY ;a = 1, prépare l'état suivant
    ld [wReactionState], a; wReactState = 1, on bascule
    jp ReactionLoop

DifficultyScreen:
    ; palette
    ld a, %11100100  ; a = 1
    ld [rBGP], a ;couleur gris
    ; dessiner
    ld a, [wDifficultyDrawn]
    cp 0
    jp nz, .skipDraw
    
    call DrawDifficultyText
    ld a, 1
    ld [wDifficultyDrawn], a
.skipDraw:
    ld a, [wNewKeys]
    and a, PAD_UP
    jr z, .checkDown
    ld a, [wSelectedDifficulty]
    cp 0
    jr z, .checkDown
    dec a
    ld [wSelectedDifficulty], a
.checkDown:
    ld a, [wNewKeys]
    and a, PAD_DOWN
    jr z, .doCursor
    ld a, [wSelectedDifficulty]
    cp 2
    jr z, .doCursor
    inc a
    ld [wSelectedDifficulty], a
.doCursor:
    call DrawDifficultyCursor

    ld a, [wNewKeys]
    and a, PAD_A
    jp z, ReactionLoop
    ;transition vers GAME
    xor a
    ld [wDifficultyDrawn], a
    ld [wGameInitDone], a
    ld [wRoundCount], a
    ld a, REACT_STATE_GAME
    ld [wReactionState], a
    jp ReactionLoop

DrawDifficultyCursor:
    ;erase les 3 dernieres positions
    xor a
    ld hl, $9887
    ld [hl], a
    ld hl, $9906
    ld [hl], a
    ld hl, $9987
    ld [hl], a

    ld a, [wSelectedDifficulty]
    cp 0
    jr z, .easy
    cp 1
    jr z, .medium
    cp 2
    jr z, .hard
.hard:
    ld hl, $9987
    jr .draw
.medium:
    ld hl, $9906
    jr .draw
.easy:
    ld hl, $9887
.draw:
    ld a, $0B
    ld [hl], a
    ret

GameScreenInit:
    ; éteindre LCD pour écrire VRAM + OAM librement
    xor a
    ld [rLCDC], a
    ; vider le tilemap
    ld hl, TILEMAP0
    ld bc, 1024
.clearMap:
    xor a
    ld [hli], a
    dec bc
    ld a, b
    or a, c
    jp nz, .clearMap

    ; charger les tiles sprites à $8000
    ld de, Reaction_Sprite_Tiles_Begin
    ld hl, $8000
    ld bc, Reaction_Sprite_Tiles_End - Reaction_Sprite_Tiles_Begin
    call MemCpy

    ; vider OAM
    ld hl, $FE00
    ld b, 160
    xor a
.clearOam:
    ld [hli], a
    dec b
    jr nz, .clearOam

    ; placer le sprite 0 au centre de l'écran
    ld hl, $FE00
    ld a, 84 ; Y = 68 + 16
    ld [hli], a
    ld a, 84 ; X = 76 + 8
    ld [hli], a
    ld a, 0 ; tile index
    ld [hli], a
    ld a, 0 ; flags
    ld [hli], a

    ; rallumer LCD avec sprites
    ld a, LCDC_ON | LCDC_BG_ON | LCDC_OBJ_ON
    ld [rLCDC], a
    ld a, %11100100
    ld [rBGP], a
    ld a, %11100100
    ld [rOBP0], a

    ; choisir un bouton aléatoire via rDIV
.pickButton:
    ld a, [rDIV]
    and $07
    cp 6
    jr nc, .pickButton
    ld [wCurrentButton], a
    ld [$FE02], a
    ret

GameScreen:
    ; init une seule fois
    ld a, [wGameInitDone]
    cp 0
    jr nz, .alreadyInit
    call GameScreenInit
    ld a, 1
    ld [wGameInitDone], a
.alreadyInit:
    ; check A
    ld a, [wNewKeys]
    and a, PAD_A
    jr z, .notA
    ld a, [wCurrentButton]
    cp 0
    jp z, .correct
    jp .wrong
.notA:
    ; check B
    ld a, [wNewKeys]
    and a, PAD_B
    jr z, .notB
    ld a, [wCurrentButton]
    cp 1
    jp z, .correct
    jp .wrong
.notB:
    ; check UP
    ld a, [wNewKeys]
    and a, PAD_UP
    jr z, .notUp
    ld a, [wCurrentButton]
    cp 2
    jp z, .correct
    jp .wrong
.notUp:
    ; check DOWN
    ld a, [wNewKeys]
    and a, PAD_DOWN
    jr z, .notDown
    ld a, [wCurrentButton]
    cp 3
    jp z, .correct
    jp .wrong
.notDown:
    ; check LEFT
    ld a, [wNewKeys]
    and a, PAD_LEFT
    jr z, .notLeft
    ld a, [wCurrentButton]
    cp 4
    jp z, .correct
    jp .wrong
.notLeft:
    ; check RIGHT
    ld a, [wNewKeys]
    and a, PAD_RIGHT
    jp z, ReactionLoop
    ld a, [wCurrentButton]
    cp 5
    jp z, .correct
    jp .wrong
.correct:
    ld a, [wRoundCount]
    inc a
    ld [wRoundCount], a
    cp 25
    jp z, .win
    ; prochain bouton
.pickNext:
    ld a, [rDIV]
    and $07
    cp 6
    jr nc, .pickNext
    ld [wCurrentButton], a
    ld [$FE02], a
    jp ReactionLoop
.win:
    ld a, REACT_STATE_WIN
    ld [wReactionState], a
    jp ReactionLoop

.wrong:
    ld a, REACT_STATE_FAIL
    ld [wReactionState], a
    jp ReactionLoop

WinScreen:
    ld a, LCDC_ON | LCDC_BG_ON
    ld [rLCDC], a
    ld a, %11100100
    ld [rBGP], a

    ld a, [wWinDrawn]
    cp 0
    jr nz, .skipWin
    ld hl, $9907
    ld a, $11 ; W
    ld [hli], a ; ecrit W et hl++
    ld a, $06 ; I
    ld [hli], a ; ecrit I et hl++
    ld a, $04 ; N
    ld [hli], a ; ecrit N et hl++
.skipWin:
    ld a, [wNewKeys]
    and a, PAD_START
    jp z, ReactionLoop
    xor a
    ld [wWinDrawn], a
    ld a, REACT_STATE_MENU
    ld [wReactionState], a
    jp ReactionLoop

FailScreen:
    ld a, LCDC_ON | LCDC_BG_ON
    ld [rLCDC], a
    ; ld a, %11111111
    ld a, %11100100
    ld [rBGP], a

    ld a, [wFailDrawn]
    cp 0
    jr nz, .skipFail
    ld hl, $9907
    ld a, $12 ; F
    ld [hli], a ; ecrit F et hl++
    ld a, $01 ; A
    ld [hli], a ; ecrit A et hl++
    ld a, $06 ; I
    ld [hli], a ; ecrit I et hl++
    ld a, $13 ; L
    ld [hli], a ; ecrit L et hl++
.skipFail:    
    ld a, [wNewKeys]
    and a, PAD_START
    jp z, ReactionLoop
    xor a
    ld [wFailDrawn], a
    ld a, REACT_STATE_MENU
    ld [wReactionState], a
    jp ReactionLoop


DrawDifficultyText:
    ; écrit EASY
    ld hl, $9888
    ld a, $08 ; E
    ld [hli], a ; écris E, hl++
    ld a, $01 ; A
    ld [hli], a ; écris A, hl++
    ld a, $0E ; S
    ld [hli], a ; écris S, hl++
    ld a, $10 ; Y
    ld [hli], a ; écris Y, hl++

    ;MEDIUM
    ld hl, $9907
    ld a, $0D ; M
    ld [hli], a ; écris M, hl++
    ld a, $08 ; E
    ld [hli], a ; écris E, hl++
    ld a, $07 ; D
    ld [hli], a ; écris D, hl++
    ld a, $06 ; I
    ld [hli], a ; écris I, hl++
    ld a, $0F ; U
    ld [hli], a ; écris E, hl++
    ld a, $0D ; M
    ld [hli], a ; écris M, hl++

    ;HARD
    ld hl, $9988
    ld a, $0C ; H
    ld [hli], a ; écris H, hl++
    ld a, $01 ; A
    ld [hli], a ; écris A, hl++
    ld a, $02 ; R
    ld [hli], a ; écris R, hl++
    ld a, $07 ; D
    ld [hli], a ; écris D, hl++
    ret

SECTION "Reaction State", WRAM0
wReactionState: db ;db sans valeur = réserve 1 octet, le linker donnera une adresse WRAM auto

SECTION "Reaction Difficulty Vars", WRAM0
wDifficultyDrawn: db
wSelectedDifficulty: db
wGameInitDone: db ; 0 = pas encore init, 1 = déjà init
wCurrentButton: db ; 0=A 1=B 2=UP 3=DOWN 4=LEFT 5=RIGHT
wRoundCount: db ; 0 à 24
wWinDrawn: db
wFailDrawn: db