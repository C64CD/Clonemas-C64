;
; CLONEMAS
;

; Code, graphics and music by TMR


; A small "festive" demo thrown together as a "present" for C64Hater
; using some curve data which was created without any mathematics!
; Coded for C64CrapDebunk.Wordpress.com

; Notes: this source is formatted for the ACME cross assembler from
; http://sourceforge.net/projects/acme-crossass/
; Compression is handled with Exomizer 2 which can be downloaded at
; http://hem.bredband.net/magli143/exo/

; build.bat will call both to create an assembled file and then the
; crunched release version.


; Select an output filename
		!to "clonemas.prg",cbm


; Pull in the binary data
		* = $1000
music		!binary "binary\snata.prg",,2

		* = $2000
		!binary "binary\plain_font_8x8.chr"

		* = $2200
		!binary "binary\clonemas.spr"

; Raster split positions
raster_1_pos	= $00
raster_2_pos	= $5A
raster_3_pos	= $c9

; Label assignments
raster_num	= $50
sync		= $51
sine_at		= $52
colour_count	= $53
scroll_pos	= $54		; two bytes used
sprite_cols	= $56		; eight bytes used

; Add a BASIC startline
		* = $0801
		!word code_start-2
		!byte $40,$00,$9e
		!text "2066"
		!byte $00,$00,$00


; Entry point for the code
		* = $0812

; Stop interrupts, disable the ROMS and set up NMI and IRQ interrupt pointers
code_start	sei

		lda #$35
		sta $01

		lda #<nmi_int
		sta $fffa
		lda #>nmi_int
		sta $fffb

		lda #<irq_int
		sta $fffe
		lda #>irq_int
		sta $ffff

; Set the VIC-II up for a raster IRQ interrupt
		lda #$7f
		sta $dc0d
		sta $dd0d

		lda $dc0d
		lda $dd0d

		lda #raster_1_pos
		sta $d012

		lda #$1b
		sta $d011
		lda #$01
		sta $d019
		sta $d01a

; Set up the screen using "random" data from the music
		ldx #$00
screen_clear	lda #$00
		sta $0400,x
		sta $0500,x
		sta $0600,x
		sta $06e8,x
		lda #$01
		sta $d800,x
		sta $d900,x
		sta $da00,x
		sta $dae8,x
		inx
		bne screen_clear

		ldx #$00
screen_init_1	lda music+$100,x
		and #$1f
		ora #$80
		sta $0400,x
		inx
		cpx #$28
		bne screen_init_1

		ldx #$00
screen_init_2a	lda $0400,x
		clc
		adc #$01
		and #$1f
		ora #$80
		sta $0428,x
		inx
		cpx #$f0
		bne screen_init_2a

		ldx #$00
screen_init_2b	lda $04f0,x
		clc
		adc #$01
		and #$1f
		ora #$80
		sta $0518,x
		inx
		cpx #$f0
		bne screen_init_2b

		ldx #$00
screen_init_2c	lda $05e0,x
		clc
		adc #$01
		and #$1f
		ora #$80
		sta $0608,x
		inx
		cpx #$f0
		bne screen_init_2c

		ldx #$00
		txa
screen_init_3	sta $db20,x
		inx
		cpx #$c8
		bne screen_init_3


; Initialise some of our own labels
		lda #$01
		sta raster_num

		lda #$00
		sta colour_count

		ldx #$00
		txa
sprite_col_init	sta sprite_cols,x
		inx
		cpx #$08
		bne sprite_col_init

; Reset the text
		jsr scroll_reset

; Set up the music driver
		ldx #$00
		txa
		tay
		jsr music+$00


; Restart the interrupts
		cli

; Update the message
main_loop	ldx #$00
		ldy #$00
scroll_loop	jsr sync_wait
		jsr sync_wait
scroll_mread	lda (scroll_pos),y
		bne scroll_okay
		jsr scroll_reset
		jmp scroll_mread

scroll_okay	sta $0720,x
		inc scroll_pos+$00
		bne *+$04
		inc scroll_pos+$01
		inx
		cpx #$a0
		bne scroll_loop

; Wait for a few seconds before the next page
		ldy #$ff
scroll_wait	jsr sync_wait
		dey
		bne scroll_wait

		jmp main_loop


; IRQ interrupt handler
irq_int		pha
		txa
		pha
		tya
		pha

		lda $d019
		and #$01
		sta $d019
		bne int_go
		jmp irq_exit

; An interrupt has triggered
int_go		lda raster_num
		cmp #$02
		bne *+$05
		jmp irq_rout2

		cmp #$03
		bne *+$05
		jmp irq_rout3


; Raster split 1
irq_rout1	lda #$00
		sta $d020
		lda #$06
		sta $d021

		lda #$18
		sta $d018

; Set up the sprites
		lda #$ff
		sta $d015
		sta $d01d
		lda #$00
		sta $d017

		ldx #$00
		lda #$20
set_sprite_x	sta $d000,x
		clc
		adc #$24
		inx
		inx
		cpx #$10
		bne set_sprite_x
		lda #$80
		sta $d010

		ldx #$00
		ldy sine_at
set_sprite_y	lda sprite_sinus,y
		clc
		adc #$36
		sta $d001,x
		tya
		sec
		sbc #$14
		tay
		inx
		inx
		cpx #$10
		bne set_sprite_y

		ldx #$00
set_sprite_dps	txa
		clc
		adc #$88
		sta $07f8,x
		lda sprite_cols,x
		sta $d027,x
		inx
		cpx #$08
		bne set_sprite_dps

; Update sprite positions
		inc sine_at
		inc sine_at

		lda colour_count
		lsr
		lsr
		tax

		ldy #$00
sprite_col_make	lda sprite_col_data,x
		sta sprite_cols,y
		txa
		clc
		adc #$03
		tax
		iny
		cpy #$08
		bne sprite_col_make


		inc colour_count


; Play the music
		jsr music+$03

; Set interrupt handler for split 2
		lda #$02
		sta raster_num
		lda #raster_2_pos
		sta $d012

; Exit IRQ interrupt
		jmp irq_exit


; Raster split 2
irq_rout2	lda #$ff
		sta $d017

; Set interrupt handler for split 1
		lda #$03
		sta raster_num
		lda #raster_3_pos
		sta $d012

; Exit IRQ interrupt
		jmp irq_exit


; Raster split 3
irq_rout3	nop
		nop
		nop

		lda #$01
		sta $d021

; Erase the old snowflakes...
		ldx #$00
		txa
snow_clear	ldy flake_y,x
		sta $2400,y
		inx
		cpx #$08
		bne snow_clear

; ...update their positions...
		ldx #$00
snow_update	lda flake_y,x
		clc
		adc flake_speed,x
		sta flake_y,x
		inx
		cpx #$08
		bne snow_update

; ...and draw them back in
		ldx #$00
		txa
snow_draw	ldy flake_y,x
		lda $2400,y
		ora flake_byte,x
		sta $2400,y
		inx
		cpx #$08
		bne snow_draw

; Send a message to the runtime code
		lda #$01
		sta sync

; Set interrupt handler for split 1
		lda #$01
		sta raster_num
		lda #raster_1_pos
		sta $d012

; Restore registers and exit IRQ interrupt
irq_exit	pla
		tay
		pla
		tax
		pla
nmi_int		rti


; Wait for the interrupt to set sync to $01
sync_wait	lda #$00
		sta sync

sw_loop		cmp sync
		beq sw_loop
		rts


; Subroutine to reset the scrolling message
scroll_reset	lda #<scroll_text
		sta scroll_pos+$00
		lda #>scroll_text
		sta scroll_pos+$01
		rts


; Snowflake data
flake_y		!byte $17,$69,$47,$06,$36,$72,$49,$2c
flake_speed	!byte $01,$02,$03,$04,$03,$02,$01,$02
flake_byte	!byte $80,$08,$40,$04,$20,$02,$10,$01


		* = $2800
; The message text (in chunks of 160 bytes)
scroll_text	!scr "    here comes   clonemas!   a cheap    "
		!scr " christmas knock-off from c64cd in 2015 "
		!scr "                                        "
		!scr "  but still better than novelty socks!  "

		!scr " coding, graphics and music ..... t.m.r "
		!scr "                                        "
		!scr " who has made quite a few festive demos "
		!scr " despite not being a fan of the season! "

		!scr " this was written around the curve data "
		!scr "    which was made without any maths!   "
		!scr "                                        "
		!scr " total coding time was two-ish hours... "

		!scr "  think of this as something to fill a  "
		!scr "  little time and space...  it was put  "
		!scr "   together while waiting for a video   "
		!scr "  to upload and/or dinner to be ready!  "

		!scr "  there's naff all on telly right now,  "
		!scr " so i made my own entertainment instead "
		!scr "   and it was either this or watching   "
		!scr "  die hard again - saw that yesterday!  "

		!scr "     the c64cd greetings go out to:     "
		!scr " harlow cracking service    rob hubbard "
		!scr "    happy democoder    stoat and tim    "
		!scr "  and all of the 8-bit fans out there!  "

		!byte $00

; Sprite curve data - no mathematics required!
sprite_sinus	!byte $32,$30,$2e,$2c,$2a,$29,$27,$26
		!byte $24,$23,$21,$20,$1e,$1d,$1c,$1a
		!byte $19,$18,$17,$16,$15,$14,$13,$12
		!byte $11,$10,$0f,$0e,$0d,$0d,$0c,$0b
		!byte $0a,$0a,$09,$08,$08,$07,$07,$06
		!byte $06,$05,$05,$04,$04,$03,$03,$03
		!byte $02,$02,$02,$02,$01,$01,$01,$01
		!byte $01,$00,$00,$00,$00,$00,$00,$00

		!byte $00,$00,$00,$00,$00,$00,$01,$01
		!byte $01,$01,$01,$02,$02,$02,$02,$03
		!byte $03,$03,$04,$04,$05,$05,$06,$06
		!byte $07,$07,$08,$08,$09,$0a,$0a,$0b
		!byte $0c,$0d,$0d,$0e,$0f,$10,$11,$12
		!byte $13,$14,$15,$16,$17,$18,$1a,$1c
		!byte $1c,$1d,$1e,$20,$21,$23,$24,$26
		!byte $27,$29,$2a,$2c,$2e,$30,$32,$34

		!byte $36,$38,$3a,$3c,$3d,$3f,$40,$42
		!byte $43,$45,$46,$48,$49,$4a,$4c,$4d
		!byte $4e,$4f,$50,$51,$52,$53,$54,$55
		!byte $56,$57,$58,$59,$5a,$5a,$5b,$5c
		!byte $5d,$5d,$5e,$5f,$5f,$60,$60,$61
		!byte $61,$62,$62,$63,$63,$64,$64,$64
		!byte $65,$65,$65,$65,$66,$66,$66,$66
		!byte $66,$67,$67,$67,$67,$67,$67,$67

		!byte $67,$67,$67,$67,$67,$67,$66,$66
		!byte $66,$66,$66,$65,$65,$65,$65,$64
		!byte $64,$64,$63,$63,$62,$62,$61,$61
		!byte $60,$60,$5f,$5f,$5e,$5d,$5d,$5c
		!byte $5b,$5a,$59,$58,$57,$56,$55,$54
		!byte $53,$52,$51,$50,$4f,$4e,$4d,$4b
		!byte $4a,$49,$48,$47,$46,$44,$43,$41
		!byte $40,$3e,$3d,$3b,$39,$37,$35,$33

; Sprite colour table
sprite_col_data	!byte $00,$00,$00,$00,$00,$00,$00,$00
		!byte $00,$00,$00,$00,$00,$00,$00,$00
		!byte $00,$00,$00,$00,$00,$00,$00,$00
		!byte $00,$00,$00,$00,$00,$00,$00,$00
		!byte $00,$00,$00,$00,$00,$00,$00,$00
		!byte $00,$00,$00,$00,$00,$00,$00,$00
		!byte $00,$06,$0b,$04,$0e,$05,$03,$0d
		!byte $01,$07,$0f,$0a,$0c,$08,$02,$09

		!byte $00,$00,$00,$00,$00,$00,$00,$00
		!byte $00,$00,$00,$00,$00,$00,$00,$00
		!byte $00,$00,$00,$00,$00,$00,$00,$00
		!byte $00,$00,$00,$00,$00,$00,$00,$00
		!byte $00,$00,$00,$00,$00,$00,$00,$00
		!byte $00,$00,$00,$00,$00,$00,$00,$00
		!byte $00,$00,$00,$00,$00,$00,$00,$00
		!byte $00,$00,$00,$00,$00,$00,$00,$00

		!byte $00,$00,$00,$00,$00,$00,$00,$00
		!byte $00,$00,$00,$00,$00,$00,$00,$00
		!byte $00,$00,$00,$00,$00,$00,$00,$00
		!byte $00,$00,$00,$00,$00,$00,$00,$00
		!byte $00,$00,$00,$00,$00,$00,$00,$00
		!byte $00,$00,$00,$00,$00,$00,$00,$00
		!byte $00,$00,$00,$00,$00,$00,$00,$00
		!byte $00,$00,$00,$00,$00,$00,$00,$00

		!byte $00,$00,$00,$00,$00,$00,$00,$00
		!byte $00,$00,$00,$00,$00,$00,$00,$00
		!byte $00,$00,$00,$00,$00,$00,$00,$00
		!byte $00,$00,$00,$00,$00,$00,$00,$00
		!byte $00,$00,$00,$00,$00,$00,$00,$00
		!byte $00,$00,$00,$00,$00,$00,$00,$00
		!byte $00,$00,$00,$00,$00,$00,$00,$00
		!byte $00,$00,$00,$00,$00,$00,$00,$00