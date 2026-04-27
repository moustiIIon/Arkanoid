INCLUDE "hardware.inc"

DEF BRICK_LEFT EQU $05
DEF BRICK_RIGHT EQU $06
DEF BLANK_TILE EQU $08

SECTION "Header", ROM0[$100]

    jp EntryPoint

    ds $150 - @

EntryPoint:

WaitVblank:
    ld a, [rLY]
    cp 144
    jp c, WaitVblank
    ld a, 0
    ld [rLCDC], a

TitleScreen:
    ld de, Unbricked_Title_Screen_Tileset_Begin
    ld hl, $9000
    ld bc, Unbricked_Title_Screen_Tileset_End - Unbricked_Title_Screen_Tileset_Begin
    call MemCpy

    ld de, Unbricked_Title_Screen_Map_Begin
    ld hl, $9800
    ld bc, Unbricked_Title_Screen_Map_End - Unbricked_Title_Screen_Map_Begin
    call MemCpy
    ld a, LCDC_ON | LCDC_BG_ON
    ld [rLCDC], a
    ld a, %11100100
    ld [rBGP], a

TitleScreenLoop:
    call UpdateKeys
    ld a, [wCurKeys]
    and PAD_START
    jr z, TitleScreenLoop

	ld a, 0
	ld [rLCDC], a
	
    ld de, Tiles
    ld hl, $9000
    ld bc, Tiles.End - Tiles
	call MemCpy

    ld de, Tilemap
    ld hl, $9800
    ld bc, Tilemap.End - Tilemap
	call MemCpy

	ld a, 33
	ld [wBrickCnt], a

    ld de, Paddle
    ld hl, $8000
    ld bc, Paddle.End - Paddle
	call MemCpy

	ld de, Ball
	ld hl, $8010
	ld bc, Ball.End - Ball
	call MemCpy

	ld a, 0
	ld b, 160
	ld hl, STARTOF(OAM)
ClearOam:
	ld [hli], a
	dec b
	jp nz, ClearOam

	ld hl, STARTOF(OAM)

	; load the paddle
    ld a, 128 + 16
    ld [hli], a
    ld a, 16 + 8
    ld [hli], a
    ld a, 0
    ld [hli], a
    ld [hli], a

	; load the ball
    ld a, 100 + 16
    ld [hli], a
    ld a, 32 + 8
    ld [hli], a
    ld a, 1
    ld [hli], a
    ld a, 0
    ld [hli], a

	ld a, 1
	ld [wBallMomentumX], a
	ld a, -1
	ld [wBallMomentumY], a

	; the screen is now on so the objects will be visible as they are updated, but that's fine
    ld a, LCDC_ON |  LCDC_BG_ON | LCDC_OBJ_ON
    ld [rLCDC], a
    ld a, %11100100
    ld [rBGP], a
    ld a, %11100100
    ld [rOBP0], a
	ld a, 0
	ld [wFrameCounter], a
	ld [wCurKeys], a
	ld [wNewKeys], a


; ============================================================================================================
;
; .___  ___.      ___       __  .__   __.      ______   ______   .______       _______ 
; |   \/   |     /   \     |  | |  \ |  |     /      | /  __  \  |   _  \     |   ____|
; |  \  /  |    /  ^  \    |  | |   \|  |    |  ,----'|  |  |  | |  |_)  |    |  |__   
; |  |\/|  |   /  /_\  \   |  | |  . `  |    |  |     |  |  |  | |      /     |   __|  
; |  |  |  |  /  _____  \  |  | |  |\   |    |  `----.|  `--'  | |  |\  \----.|  |____ 
; |__|  |__| /__/     \__\ |__| |__| \__|     \______| \______/  | _| `._____||_______|
;
; ============================================================================================================


Main:
    ld a, [rLY]
    cp 144
    jp nc, Main
WaitVBlank2:
    ld a, [rLY]
    cp 144
    jp c, WaitVBlank2

	; pos for the ball, in oam
	ld a, [wBallMomentumX]
	ld b, a
	ld a, [STARTOF(OAM) + 5]
	add a, b
	ld [STARTOF(OAM) + 5], a
	ld a, [wBallMomentumY]
	ld b, a
	ld a, [STARTOF(OAM) + 4]
	add a, b
	ld [STARTOF(OAM) + 4], a	

    call UpdateKeys


Bounce_on_top:
	ld a, [STARTOF(OAM) + 4]
	sub a, 16 + 1
	ld c, a
	ld a, [STARTOF(OAM) + 5]
	sub a, 8
	ld b, a
	call GetTileByPixel
	ld a, [hl]
	call IsWallTile
	jp nz, BounceOnRight
	ld d, 0
	call CheckAndHandleBrick
	inc d
	ld a, 1
	ld [wBallMomentumY], a
BounceOnRight:
    ld a, [STARTOF(OAM) + 4]
    sub a, 16
    ld c, a
    ld a, [STARTOF(OAM) + 5]
    sub a, 8 - 1
    ld b, a
    call GetTileByPixel
    ld a, [hl]
    call IsWallTile
    jp nz, BounceOnLeft
	ld e, 0
	call CheckAndHandleBrick
	inc e
    ld a, -1
    ld [wBallMomentumX], a

BounceOnLeft:
    ld a, [STARTOF(OAM) + 4]
    sub a, 16
    ld c, a
    ld a, [STARTOF(OAM) + 5]
    sub a, 8 + 1
    ld b, a
    call GetTileByPixel
    ld a, [hl]
    call IsWallTile
    jp nz, BounceOnBottom
	call CheckAndHandleBrick
    ld a, 1
    ld [wBallMomentumX], a

BounceOnBottom:
    ld a, [STARTOF(OAM) + 4]
    sub a, 16 - 1
    ld c, a
    ld a, [STARTOF(OAM) + 5]
    sub a, 8
    ld b, a
    call GetTileByPixel
    ld a, [hl]
    call IsWallTile
    jp nz, BounceDone
	call CheckAndHandleBrick
    ld a, -1
    ld [wBallMomentumY], a


BounceDone:
    ld a, [STARTOF(OAM)]
    ld b, a
    ld a, [STARTOF(OAM) + 4]
	add a, 4
    cp a, b
    jp nz, PaddleBounceDone
    ld a, [STARTOF(OAM) + 5]
    ld b, a
    ld a, [STARTOF(OAM) + 1]
    sub a, 8
    cp a, b
    jp nc, PaddleBounceDone
    add a, 8 + 16
    cp a, b
    jp c, PaddleBounceDone
    ld a, -1
    ld [wBallMomentumY], a


PaddleBounceDone:
	ld a, [wBrickCnt]
	cp a, 0
	jp nz, CheckLeft

WaitVblankWin:
	ld a, [rLY]
	cp a, 144
	jr c, WaitVblankWin
	ld a, 0
	ld [rLCDC], a
	jp TitleScreen


CheckLeft:
    ld a, [wCurKeys]
    and a, PAD_LEFT
    jp z, CheckRight
Left:
    ld a, [STARTOF(OAM) + 1]
	;vitesse par frame
    dec a
    cp a, 15
    jp z, Main
    ld [STARTOF(OAM) + 1], a
    jp Main

CheckRight:
    ld a, [wCurKeys]
    and a, PAD_RIGHT
    jp z, Main
Right:
    ld a, [STARTOF(OAM) + 1]
	;vitesse par frame
    inc a
    cp a, 105
    jp z, Main
    ld [STARTOF(OAM) + 1], a
    jp Main


; =============================================================================================================
;  _______  __    __  .__   __.   ______ .___________. __    ______   .__   __.      _______.
; |   ____||  |  |  | |  \ |  |  /      ||           ||  |  /  __  \  |  \ |  |     /       |
; |  |__   |  |  |  | |   \|  | |  ,----'`---|  |----`|  | |  |  |  | |   \|  |    |   (----`
; |   __|  |  |  |  | |  . `  | |  |         |  |     |  | |  |  |  | |  . `  |     \   \    
; |  |     |  `--'  | |  |\   | |  `----.    |  |     |  | |  `--'  | |  |\   | .----)   |   
; |__|      \______/  |__| \__|  \______|    |__|     |__|  \______/  |__| \__| |_______/    
;
; =============================================================================================================
                                               
                                              
MemCpy:
	ld a, [de]
	ld [hli], a
	inc de
	dec bc
	ld a, b
	or a, c
	jp nz, MemCpy
	ret

UpdateKeys:
  ld a, JOYP_GET_BUTTONS
  call .onenibble
  ld b, a

  ld a, JOYP_GET_CTRL_PAD
  call .onenibble
  swap a
  xor a, b
  ld b, a

  ld a, JOYP_GET_NONE
  ldh [rJOYP], a

  ld a, [wCurKeys]
  xor a, b
  and a, b
  ld [wNewKeys], a
  ld a, b
  ld [wCurKeys], a
  ret

.onenibble
  ldh [rJOYP], a
  call .knownret
  ldh a, [rJOYP]
  ldh a, [rJOYP]
  ldh a, [rJOYP]
  or a, $F0
.knownret
  ret


GetTileByPixel:
ld a, c
and a, %11111000
ld l, a
ld h, 0
add hl, hl
add hl, hl
ld a, b
srl a
srl a
srl a
add a, l
ld l, a
adc a, h
sub a, l
ld h, a
ld bc, $9800
add hl, bc
ret


CheckAndHandleBrick:
    ld a, [hl]
    cp a, BRICK_LEFT
    jr nz, CheckAndHandleBrickRight
    ; Break a brick from the left side.
    ld [hl], BLANK_TILE
    inc hl
    ld [hl], BLANK_TILE

	; the counter
	ld a, [wBrickCnt]
	dec a
	ld [wBrickCnt], a
	ret

CheckAndHandleBrickRight:
    cp a, BRICK_RIGHT
    ret nz
    ; Break a brick from the right side.
    ld [hl], BLANK_TILE
    dec hl
    ld [hl], BLANK_TILE

	; the counter
	ld a, [wBrickCnt]
	dec a
	ld [wBrickCnt], a
    ret

IsWallTile:
    cp a, $00
    ret z
    cp a, $01
    ret z
    cp a, $02
    ret z
    cp a, $04
    ret z
    cp a, $05
    ret z
    cp a, $06
    ret z
    cp a, $07
    ret

; =============================================================================================================
;
; .___________. __   __       _______     _______.        ___   .___________. __   __       _______ .___  ___.      ___      .______   
; |           ||  | |  |     |   ____|   /       |       /  /   |           ||  | |  |     |   ____||   \/   |     /   \     |   _  \  
; `---|  |----`|  | |  |     |  |__     |   (----`      /  /    `---|  |----`|  | |  |     |  |__   |  \  /  |    /  ^  \    |  |_)  | 
;     |  |     |  | |  |     |   __|     \   \         /  /         |  |     |  | |  |     |   __|  |  |\/|  |   /  /_\  \   |   ___/  
;     |  |     |  | |  `----.|  |____.----)   |       /  /          |  |     |  | |  `----.|  |____ |  |  |  |  /  _____  \  |  |      
;     |__|     |__| |_______||_______|_______/       /__/           |__|     |__| |_______||_______||__|  |__| /__/     \__\ | _|      
;
; =============================================================================================================                   


Tiles:
	dw `33333333
	dw `33333333
	dw `33333333
	dw `33322222
	dw `33322222
	dw `33322222
	dw `33322211
	dw `33322211

	dw `33333333
	dw `33333333
	dw `33333333
	dw `22222222
	dw `22222222
	dw `22222222
	dw `11111111
	dw `11111111

	dw `33333333
	dw `33333333
	dw `33333333
	dw `22222333
	dw `22222333
	dw `22222333
	dw `11222333
	dw `11222333

	dw `33333333
	dw `33333333
	dw `33333333
	dw `33333333
	dw `33333333
	dw `33333333
	dw `33333333
	dw `33333333

	dw `33322211
	dw `33322211
	dw `33322211
	dw `33322211
	dw `33322211
	dw `33322211
	dw `33322211
	dw `33322211

	; brique
	dw `33333333
	dw `30000000
	dw `30111111
	dw `30111111
	dw `30111111
	dw `30111111
	dw `30111111
	dw `33333333
	; brique
	dw `33333333
	dw `00000003
	dw `11111103
	dw `11111103
	dw `11111103
	dw `11111103
	dw `11111103
	dw `33333333

	dw `11222333
	dw `11222333
	dw `11222333
	dw `11222333
	dw `11222333
	dw `11222333
	dw `11222333
	dw `11222333

	dw `00000000
	dw `00000000
	dw `00000000
	dw `00000000
	dw `00000000
	dw `00000000
	dw `00000000
	dw `00000000

	dw `11001100
	dw `11111111
	dw `11111111
	dw `21212121
	dw `22222222
	dw `22322232
	dw `23232323
	dw `33333333

	dw `22222222
	dw `22222222
	dw `22222222
	dw `22222222
	dw `22222222
	dw `22222211
	dw `22222211
	dw `22222211

	dw `22222222
	dw `22222222
	dw `22222222
	dw `11111111
	dw `11111111
	dw `11221111
	dw `11221111
	dw `11000011

	dw `22222222
	dw `22222222
	dw `22222222
	dw `22222222
	dw `22222222
	dw `11222222
	dw `11222222
	dw `11222222

	dw `22222222
	dw `22222222
	dw `22222222
	dw `22222222
	dw `22222222
	dw `22222222
	dw `22222222
	dw `22222222

	dw `22222211
	dw `22222200
	dw `22222200
	dw `22000000
	dw `22000000
	dw `22222222
	dw `22222222
	dw `22222222

	dw `11000011
	dw `11111111
	dw `11111111
	dw `11111111
	dw `11111111
	dw `11111111
	dw `11111111
	dw `11000022

	dw `11222222
	dw `11222222
	dw `11222222
	dw `22222222
	dw `22222222
	dw `22222222
	dw `22222222
	dw `22222222

	dw `22222222
	dw `22222222
	dw `22222222
	dw `22222222
	dw `22222222
	dw `22222222
	dw `22222222
	dw `22222222

	dw `22222222
	dw `22222200
	dw `22222200
	dw `22222211
	dw `22222211
	dw `22221111
	dw `22221111
	dw `22221111

	dw `11000022
	dw `00112222
	dw `00112222
	dw `11112200
	dw `11112200
	dw `11220000
	dw `11220000
	dw `11220000

	dw `22222222
	dw `22222222
	dw `22222222
	dw `22000000
	dw `22000000
	dw `00000000
	dw `00000000
	dw `00000000

	dw `22222222
	dw `22222222
	dw `22222222
	dw `22222222
	dw `22222222
	dw `11110022
	dw `11110022
	dw `11110022

	dw `22221111
	dw `22221111
	dw `22221111
	dw `22221111
	dw `22221111
	dw `22222211
	dw `22222211
	dw `22222222

	dw `11220000
	dw `11110000
	dw `11110000
	dw `11111111
	dw `11111111
	dw `11111111
	dw `11111111
	dw `22222222

	dw `00000000
	dw `00111111
	dw `00111111
	dw `11111111
	dw `11111111
	dw `11111111
	dw `11111111
	dw `22222222

	dw `11110022
	dw `11000022
	dw `11000022
	dw `00002222
	dw `00002222
	dw `00222222
	dw `00222222
	dw `22222222
.End:

Paddle:
    dw `13333331
    dw `30000003
    dw `13333331
    dw `00000000
    dw `00000000
    dw `00000000
    dw `00000000
    dw `00000000
.End:

Ball:
    dw `00033000
    dw `00322300
    dw `03222230
    dw `03222230
    dw `00322300
    dw `00033000
    dw `00000000
    dw `00000000
.End:


Tilemap:
	db $00, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $02, $03, $03, $03, $03, $03, $03, 0,0,0,0,0,0,0,0,0,0,0,0
	db $04, $05, $06, $05, $06, $05, $06, $05, $06, $05, $06, $05, $06, $07, $03, $03, $03, $03, $03, $03, 0,0,0,0,0,0,0,0,0,0,0,0
	db $04, $08, $05, $06, $05, $06, $05, $06, $05, $06, $05, $06, $08, $07, $03, $03, $03, $03, $03, $03, 0,0,0,0,0,0,0,0,0,0,0,0
	db $04, $05, $06, $05, $06, $05, $06, $05, $06, $05, $06, $05, $06, $07, $03, $03, $03, $03, $03, $03, 0,0,0,0,0,0,0,0,0,0,0,0
	db $04, $08, $05, $06, $05, $06, $05, $06, $05, $06, $05, $06, $08, $07, $03, $03, $03, $03, $03, $03, 0,0,0,0,0,0,0,0,0,0,0,0
	db $04, $05, $06, $05, $06, $05, $06, $05, $06, $05, $06, $05, $06, $07, $03, $03, $03, $03, $03, $03, 0,0,0,0,0,0,0,0,0,0,0,0
	db $04, $08, $05, $06, $05, $06, $05, $06, $05, $06, $05, $06, $08, $07, $03, $03, $03, $03, $03, $03, 0,0,0,0,0,0,0,0,0,0,0,0
	db $04, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $07, $03, $03, $03, $03, $03, $03, 0,0,0,0,0,0,0,0,0,0,0,0
	db $04, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $07, $03, $03, $03, $03, $03, $03, 0,0,0,0,0,0,0,0,0,0,0,0
	db $04, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $07, $03, $03, $03, $03, $03, $03, 0,0,0,0,0,0,0,0,0,0,0,0
	db $04, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $07, $03, $03, $03, $03, $03, $03, 0,0,0,0,0,0,0,0,0,0,0,0
	db $04, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $07, $03, $03, $03, $03, $03, $03, 0,0,0,0,0,0,0,0,0,0,0,0
	db $04, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $07, $03, $03, $03, $03, $03, $03, 0,0,0,0,0,0,0,0,0,0,0,0
	; db $04, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $07, $03, $03, $03, $03, $03, $03, 0,0,0,0,0,0,0,0,0,0,0,0
	; db $04, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $07, $03, $03, $03, $03, $03, $03, 0,0,0,0,0,0,0,0,0,0,0,0
	; db $04, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $07, $03, $03, $03, $03, $03, $03, 0,0,0,0,0,0,0,0,0,0,0,0
	; db $04, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $07, $03, $03, $03, $03, $03, $03, 0,0,0,0,0,0,0,0,0,0,0,0
	; db $04, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $07, $03, $03, $03, $03, $03, $03, 0,0,0,0,0,0,0,0,0,0,0,0
	db $04, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $07, $03, $03, $03, $03, $03, $03, 0,0,0,0,0,0,0,0,0,0,0,0
	db $04, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $07, $03, $03, $03, $03, $03, $03, 0,0,0,0,0,0,0,0,0,0,0,0
	db $04, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $07, $03, $03, $03, $03, $03, $03, 0,0,0,0,0,0,0,0,0,0,0,0
	db $04, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $07, $03, $03, $03, $03, $03, $03, 0,0,0,0,0,0,0,0,0,0,0,0
	db $04, $09, $09, $09, $09, $09, $09, $09, $09, $09, $09, $09, $09, $07, $03, $03, $03, $03, $03, $03, 0,0,0,0,0,0,0,0,0,0,0,0
.End:


;
;   TITLE SCREEN
;

Unbricked_Title_Screen_Tileset_Begin:

; Tile $00 : Blanc
    dw `00000000
    dw `00000000
    dw `00000000
    dw `00000000
    dw `00000000
    dw `00000000
    dw `00000000
    dw `00000000

; ============================================================
;  LETTRE "U"
; ============================================================

; Tile $01 : LETTRE U
    dw `33000033
    dw `33000033
    dw `33000033
    dw `33000033
    dw `33000033
    dw `33000033
    dw `03333330
    dw `00333300

; Tile $02 : LETTRE N
    dw `33000330
    dw `33300330
    dw `33330330
    dw `33033330
    dw `33003330
    dw `33000330
    dw `33000330
    dw `33000330

; Tile $03 : LETTRE B
    dw `33333300
    dw `33000330
    dw `33000330
    dw `33333300
    dw `33333300
    dw `33000330
    dw `33000330
    dw `33333300

; Tile $04 : LETTRE R
    dw `33333300
    dw `33000330
    dw `33000330
    dw `33333300
    dw `33033000
    dw `33003300
    dw `33000330
    dw `33000033

; Tile $05 : LETTRE I
    dw `33333333
    dw `00033000
    dw `00033000
    dw `00033000
    dw `00033000
    dw `00033000
    dw `00033000
    dw `03333333

; Tile $06 : LETTRE C
    dw `03333330
    dw `33000000
    dw `33000000
    dw `33000000
    dw `33000000
    dw `33000000
    dw `33000000
    dw `03333330

; Tile $07 : LETTRE K
    dw `33000330
    dw `33003300
    dw `33033000
    dw `33330000
    dw `33330000
    dw `33033000
    dw `33003300
    dw `33000330

; Tile $08 : LETTRE E
    dw `33333330
    dw `33000000
    dw `33000000
    dw `33333000
    dw `33333000
    dw `33000000
    dw `33000000
    dw `33333330

; Tile $09 : LETTRE D
    dw `33333300
    dw `33000330
    dw `33000033
    dw `33000033
    dw `33000033
    dw `33000033
    dw `33000330
    dw `33333300

; ============================================================
;  SÉPARATEUR
; ============================================================

; Tile $0A : Ligne
    dw `00000000
    dw `00000000
    dw `33333333
    dw `11111111
    dw `11111111
    dw `33333333
    dw `00000000
    dw `00000000

; ============================================================
; "PRESS START"
; ============================================================

; Tile $0B : Lettre P
    dw `11111100
    dw `11000110
    dw `11000110
    dw `11111100
    dw `11000000
    dw `11000000
    dw `11000000
    dw `00000000

; Tile $0C : Lettre R
    dw `11111100
    dw `11000110
    dw `11000110
    dw `11111100
    dw `11011000
    dw `11001100
    dw `11000110
    dw `00000000

; Tile $0D : Lettre E
    dw `11111110
    dw `11000000
    dw `11000000
    dw `11111100
    dw `11000000
    dw `11000000
    dw `11111110
    dw `00000000

; Tile $0E : Lettre S
    dw `01111110
    dw `11000000
    dw `11000000
    dw `01111100
    dw `00000110
    dw `00000110
    dw `11111100
    dw `00000000

; Tile $0F : Lettre " "
    dw `00000000
    dw `00000000
    dw `00000000
    dw `00000000
    dw `00000000
    dw `00000000
    dw `00000000
    dw `00000000

; Tile $10 : Lettre T
    dw `11111110
    dw `00110000
    dw `00110000
    dw `00110000
    dw `00110000
    dw `00110000
    dw `00110000
    dw `00000000

; Tile $11 : Lettre A
    dw `01111100
    dw `11000110
    dw `11000110
    dw `11111110
    dw `11000110
    dw `11000110
    dw `11000110
    dw `00000000

; Tile $12 : Lettre N
    dw `11000110
    dw `11100110
    dw `11110110
    dw `11011110
    dw `11001110
    dw `11000110
    dw `11000110
    dw `00000000

	; brique
	dw `33333333
	dw `30000000
	dw `30111111
	dw `30111111
	dw `30111111
	dw `30111111
	dw `30111111
	dw `33333333
	; brique
	dw `33333333
	dw `00000003
	dw `11111103
	dw `11111103
	dw `11111103
	dw `11111103
	dw `11111103
	dw `33333333
Unbricked_Title_Screen_Tileset_End:


Unbricked_Title_Screen_Map_Begin:
    DB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
    DB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
    DB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
    DB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
    DB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
	; start of "UNBRICKED"
	DB $01,$02,$03,$04,$05,$06,$07,$08,$09,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
    DB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
    DB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
    DB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
    DB $93,$94,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
    DB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
    DB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
    DB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
    DB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
    DB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
    DB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00

	;start of "PRESS START"
    DB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
    DB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
    DB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00


    DB $00,$00,$00,$00,$00,$00,$00,$00,$0B,$0C,$0D,$0E,$0E,$0F,$0E,$10,$11,$0C,$10,$00

Unbricked_Title_Screen_Map_End:



SECTION "Counter", WRAM0
wFrameCounter: db

SECTION "Input Variables", WRAM0
wCurKeys: db
wNewKeys: db

SECTION "Ball Data", WRAM0
wBallMomentumX: db
wBallMomentumY: db

SECTION "Brick Data", WRAM0
wBrickCnt: db
