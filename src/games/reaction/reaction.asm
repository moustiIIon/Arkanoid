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
    ld hl, $9800 ;met l'adresse $9800 (début du tilemap en VRAM) dans hl
    ld bc, 1024
    xor a ;xor a = ld a, 0 mais pèse 1 octet au lieu de 2

SECTION "Reaction State", WRAM0
wReactionState: db ;db sans valeur = réserve 1 octet, le linker donnera une adresse WRAM auto