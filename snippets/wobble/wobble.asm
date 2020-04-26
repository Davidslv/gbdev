; wobble.asm
; You will need to turn off bgb 'break on invalid opcode'
; On BGB: Options > Exceptions > Uncheck 'break on invalid opcode'
;
; compiling with RBGDS
; rgbasm -o wobble.o nintendo_wobble.asm
; rgblink -o wobble.gb wobble.o
; rgbfix -v -p0 wobble.gb
;
; This won’t work with a Game Boy Color because that system
; clears the logo from VRAM after booting up.

section "HEADER", ROM0[$0100]
	nop
	jp wobble_main
	; The ROM header needed by
	; the system to validate the rom.
	db $CE,$ED,$66,$66,$CC,$0D,$00,$0B
	db $03,$73,$00,$83,$00,$0C,$00,$0D
	db $00,$08,$11,$1F,$88,$89,$00,$0E
	db $DC,$CC,$6E,$E6,$DD,$DD,$D9,$99
	db $BB,$BB,$67,$63,$6E,$0E,$EC,$CC
	db $DD,$DC,$99,$9F,$BB,$B9,$33,$3E
	db "WOBBLE",$00
	; Entry point
section "WOBBLE", ROM0[$0150]
wobble_main:
	; E is our LUT offset
	ld e,$00
	; Initialize H to the
	; MSB of WOBBLE_DATA
	ld h,$20
wobble_loop:
	; B will be the scanline we
	; want to transform
	ld b,$00
.inner_loop:
	; Load the current scanline
	; position and compare it to B
	ldh a,[$44]
	cp b
	jr nz,.inner_loop
	ld a,b
	inc b
	add a,e
	and $1F
	; We use the current scanline
	; position and the LUT offset
	; to calculate the index into
	; the LUT.
	; idx = (scanline + lut_ofs) & 0x1F
	ld l,a
	ld a,[hl]
	; scroll_x = LUT[idx]
	ldh [$43],a
	ld a,l
	add a,$09
	and $1F
	ld l,a
	ld a,[hl]
	; idx = (idx + 9) & 0x1F
	; scroll_y = LUT[idx]
	ldh [$42],a
	ldh a,[$44]
	; Finally we check if we've
	; reached vblank to
	; break the loop
	cp $90
	jr nz,.inner_loop
	; Increment the LUT offset so
	; we can have motion.
	inc e
	jr wobble_loop
	; Lookup table of simple sine wave
section "WOBBLE_DATA", ROM0[$2000]
	db $00,$00,$01,$01,$02,$02,$02,$02
	db $02,$02,$02,$02,$01,$01,$00,$00
	db $00,$00,$FF,$FF,$FE,$FE,$FE,$FE
	db $FE,$FE,$FE,$FE,$FF,$FF,$00,$00
