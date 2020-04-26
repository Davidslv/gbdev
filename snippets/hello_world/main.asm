;; https://eldred.fr/gb-asm-tutorial/hello-world.html
;; compilation:
;; rgbasm -o hello_world.o main.asm ; rgblink -o hello_world.gb hello_world.o
;; rgbfix -v -p0 hello_world.gb

INCLUDE "hardware.inc"

SECTION "HEADER", ROM0[$100]
;; beginning of our code

EntryPoint:
  di ; Disable's interrupts. That way we can avoid dealing with them
  jp Start

REPT $150 - $104
  db 0
ENDR

SECTION "Game Code", ROM0

Start:
  .waitVBlank
    ld a, [rLY]
    cp 144
    jr c, .waitVBlank

    xor a ; equivalent to ld a , 0; We only need to reset the value with bit 7 reset but 0 does the job
    ld [rLCDC], a

;; we now have the LCD turned off
;; so we can access the VRAM
    ld [rLCDC], a
    ld hl, $9000
    ld de, FontTiles
    ld bc, FontTilesEnd - FontTiles
  .copyFont
    ld a, [de]    ; Grab 1 byte from the source
    ld [hli], a   ; Place it at the destination, incrementing hl
    inc de        ; move the next byte
    dec bc        ; decrement count

    ;; This sets the Z flag if an only if BC == 0.
    ;; IF BC == 0, then B == 0 and C == 0, which means
    ;; that A == 0 after `or c`.
    ;; However, if BC != 0, the either B != 0 or C != 0
    ;; which means that at least one bit of B or C is set,
    ;; therefore A != 0 after the `or c`
    ld a, b       ; Check if count is 0, since `dec bc` doesn't update flags
    or c
    jr nz, .copyFont

    ;; this will print the string at the top-left corner of the screen
    ld hl, $9800
    ld de, GreetingStr
  .copyString
    ld a, [de]
    ld [hli], a
    inc de
    and a               ; checks if the byte we copied is zero
    jr nz, .copyString  ; continue if it's not

    ;; Display registers
    ld a, LIGHT_GRAY_BGP;
    ld [rBGP], a

    xor a ; ld a, 0
    ld [rSCY], a
    ld [rSCX], a

    ;; shutdown sound
    ld [rNR52], a

    ;; Turn screen on, display background
    ;; We need to:
    ;; - set the palette (%11100100),
    ;; - set the scroll registers,
    ;; - turn sound off (we'll skip the details, just write 0 to NR52).
    ;; - set bit 7 of LCDC to turn on the screen
    ;;   - and set bit 0 of LCDC to get the background to display
    ld a, %10000001 ; Palette colour
    ld [rLCDC], a

  ;; Lock CPU on an infinite loop
  .lockup
    jr .lockup

SECTION "Font", ROM0

FontTiles:
  INCBIN "font.chr" ; makes RGBDS copy the file's contents directly into the produced ROM.
FontTilesEnd:

SECTION "Hello World", ROM0

GreetingStr:
  ;; db tells RGBASM to place some bytes of data
  ;; (similarly, there's dw for 16-bit words, and dl for 32-bit longs).
  ;; With db, you can also use strings, which are automatically encoded,
  ;; by default using ASCII. The 0 at the end tells the copy function to stop.
  db "HELLO WORLD!", 0
