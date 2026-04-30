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
    ld [hli], a ;ecrit a dans la mémoire pointée par hl et va l'incrémenter ensuite. Donc 1 octet de plus à 0 en VRAM
    dec bc ;decremente bc dcp bc = 1023. Il ne màj pas le flag z
    ld a, b ;copie b dans a
    or a, c ; a = a OR c, ça permet de tester bc == 0. bc = 0 ssi b = 0 et c = 0. il màj le flag z
    jp nz, .clearTilemap ;si bc != 0 alors en relance
    ;le premier bloc est un memset(0x9800, 0, 1024)

    ld [wReactionState], a ;écris a dans WRAM car le CPU GB ne permet pas d'écrire une valeur immédiatement à une adresse mémoire 16bits. Faut passer par un registre

    ;reset les input
    ;lors du boot la WRAM contient du garbage puisque la WRAM n'est pas init par le hardware
    xor a
    ld [wCurKeys], a
    ld [wNewKeys], a

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
    ld a, %01010101  ; a = 0
    ld [rBGP], a ;couleur gris
    ld a, [wNewKeys]
    and a, PAD_A
    jp z, ReactionLoop
    ld a, REACT_STATE_GAME
    ld [wReactionState], a
    jp ReactionLoop


SECTION "Reaction State", WRAM0
wReactionState: db ;db sans valeur = réserve 1 octet, le linker donnera une adresse WRAM auto