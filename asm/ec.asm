
%define orig_bin "x230.G2HT35WW.img"

%include "ec_keysym.mac"

; include orig_bin from $ for size $1
%macro ib 1
    incbin orig_bin,$,%1
%endmacro

; padding of byte %2 until address %1
%macro pad 2
    times %1-($-$$) db %2
%endmacro

    ; jump table
    ; common routines
    ib 0x120
    pad 0x200, 0xff             ; padding?

    ib 0x28

version:
    db 0x11, 0x40

    ib 2+(5*4)                  ; timestamps?

version_str:
    db "G2HT35WW"
    pad 0x250, 0                ; padding?

    ib 6*4

copyright_str:
    ib 0x354-0x268

    ib 0xf74-0x354

    dd 0
    pad 0xffc, 0xff             ; padding?

encryption_key_pre:
    dd 0xfffffff1
encryption_key:
    ib 0x2048-0x1000

checksum_results:
    ; one checksum result for each section
    ib 4*4
    pad 0x2080, 0xff            ; padding?

    ib 0x2154-0x2080

checksum_sections:
    ; one pair of (start,end) for each section, terminated with 0xffffffff
    dd 0,0x2048
    dd 0x2080,0x10000
    dd 0x10000,0x20000
    dd 0x20000,0x2e000
    dd 0xffffffff

    ib 0x218c-0x2178

table218c:
    dd 0x1f                     ; size
    times 20 dd 0x2816
    dd 0xd04
    times 10 dd 0x2816
table220c:
    dd 0x1f                     ; size
    times 31 dd 0x2816
table228c:
    dd 0x1f                     ; size
    times 8 dd 0x2816
    dd 0x0000d9e8
    dd 0x00002816
    dd 0x0000fdf4
    dd 0x000206bc
    times 19 dd 0x2816
table230c:
    dd 0x1f                     ; size
    dd 0x00000ca8
    times 9 dd 0x2816
    dd 0x00020688
    times 20 dd 0x2816
table238c:
    dd 0x12
    dd 0x0000e5d0
    dd 0x0000e5e0
    dd 0x0000e5f0
    times 11 dd 0x2816
    dd 0,0,0
    dd 0x2816
table23d8:
    dd 0x18
    times 3 dd 0x2816
    times 13 dd 0
    times 8 dd 0x2816
table243c:
    dd 0x13
    dd 0x2816
    dd 0x0000dca8
    times 6 dd 0x2816
    dd 0x000026d4
    times 7 dd 0
    times 3 dd 0x2816
table248c:
    dd 0xd
    dd 0x2816
    dd 0x0001fc28
    dd 0x2816
    times 5 dd 0
    times 5 dd 0x2816
table24c4:
    dd 9
    times 3 dd 0x2816
    dd 0xf414
    dd 0x2816
    times 3 dd 0
    dd 0x2816
table24ec:
    dd 6
    dd 0x00010104
    dd 0x00010114
    dd 0x00010124
    dd 0x00010134
    dd 0x00010144
    dd 0x00010154
table2508:
    dd 0x11
    times 6 dd 0x2816
    times 3 dd 0
    times 3 dd 0x2816
    times 4 dd 0
    dd 0x2816
table2550:
    dd 0x16
    dd 0x0000e8cc
    dd 0x0000e8b4
    times 11 dd 0
    dd 0x0000f43c
    dd 0x0000f44c
    dd 0x0000f45c
    dd 0
    times 5 dd 0x2816

; many more tables need to be filled in here
    ib 0x26c4-0x25ac

    ib 0x2920-0x26c4

table_encryption:
    dd encryption_key_pre
    dd encryption_iv

encryption_iv:
    ib 0x2934-0x2928

; another table
    ib 0x2954-0x2934

    ib 0x2be0-0x2954

; another set of tables
    ib 0x3f50-0x2be0

table.00003f50:
    dd 0x00003f28       ; pointer to earlier tables as yet undefined
    dd 0x00003f3c       ; pointer to earlier tables as yet undefined
table.00003f58:
    dd 2        ; size
    dd table.00003f50
table.00003f60:
    dd table.00003f58
table.00003f64:
    dd 1        ; size
    dd table.00003f60

    ib 0x20edc-0x3f6c

; no code beyond this point
table.00020edc:
    ib 0x000210a4-0x20edc
table.000210a4:
    ib 0x000211a4-0x000210a4
table.000211a4:
    ib 0x000211bc-0x000211a4
table.000211bc:
    ib 0x000211cc-0x000211bc
table.000211cc:
    ib 0x000211dc-0x000211cc
table.000211dc:
    dd 0xf ; size
    dd table.000211cc
table.000211e4:
    ib 0x0002121c-0x000211e4
table.0002121c:
    dd 7 ; size
    dd table.000211e4
table.00021224:
    ib 0x0002123c - 0x00021224
table.0002123c:
    ib 0x00021254 - 0x0002123c
table.00021254:
    ib 0x000212cc - 0x00021254
table.000212cc:
    ib 0x00021304 - 0x000212cc
table.00021304:
    ib 0x0002131c - 0x00021304
table.0002131c:
    ib 0x0002133c - 0x0002131c
table.0002133c:
    ib 0x0002135c - 0x0002133c
table.0002135c:
    ib 0x00021374 - 0x0002135c
table.00021374:
    ib 0x000213d4 - 0x00021374
table.000213d4:
    ib 0x0002140c - 0x000213d4
table.0002140c:
    ib 0x0002141c - 0x0002140c
table.0002141c:
    ib 0x00021434 - 0x0002141c
table.00021434:
    ib 0x0002145c - 0x00021434
table.0002145c:
    ib 0x00021494 - 0x0002145c
table.00021494:
    ib 0x000214a4 - 0x00021494
table.000214a4:
    dd table.0002123c
    dd table.00021254
    dd table.000212cc
    dd table.00021304
    dd table.0002131c
    dd table.00021304
    dd table.0002133c
    dd table.0002135c
    dd table.00021374
    dd table.000213d4
    dd table.00021494
    dd table.0002140c
    dd table.0002141c
    dd table.00021434
    dd table.0002145c
    dd table.000213d4
table.000214e4:
    dd 0x10     ; size of second table
    dd table.00021224
    dd table.000214a4
table_delayTab1:
    ib 0x000214fc - 0x000214f0
table_ptr_delayTab1:
    dd 6        ; size of table
    dd table_delayTab1
table.0x00021504:
    dd 0x38
    dd 0x102
    dd table.00003f64
table.00021510:
    dd table.00021e48
    dd table.00021f70
    dd table.000211bc
    dd table.0002121c
    dd table.000214e4
    dd table_ptr_delayTab1
    dd table_ptr_fn_key_complex_stuff
    dd table_ptr_numpad_stuff
    dd table_ptr_keysym_stuff
    dd table.00021aa8
    dd table.00021e68
table.0002153c:
    ib 0x00021574 - 0x0002153c
table.00021574:
    ib 0x000215b4 - 0x00021574
table.000215b4:
    ib 0x000215bc - 0x000215b4
table.000215bc:
    dd 8
    dd table.000215b4
table.000215c4:
    ib 0x0002164c - 0x000215c4
jump_table.0x0002164c:
    ib 0x0002166c - 0x0002164c
table_fn_key_complex:
    ; FIXME - add in the definitions
    ib 0x000216a4 - 0x0002166c
table_ptr_fn_key_complex_stuff:
    dd 8        ; jump table size
    dd jump_table.0x0002164c
    dd 0x1b     ; complex table size
    dd table_fn_key_complex
table.000216b4:
    ; FIXME - is this something to do with keysym mapping?
    ib 0x00021818 - 0x000216b4
table_numpad1:
    ; FIXME - add in the definitions
    ib 0x00021858 - 0x00021818
table_numpad2:
    ; FIXME - add in the definitions
    ib 0x00021898 - 0x00021858
table_keysym_replacements:
    %include "ec_key_combo1_x220.mac"

table_ptr_numpad_stuff:
    dd 0xb2     ; size of next table
    dd table.000216b4
    dd 0x40     ; size of both numpad tables
    dd table_numpad2
    dd table_numpad1
; FIXME - this could be part of the previous table...?!?
table_ptr_keysym_replacements:
    dd 0xb
    dd table_keysym_replacements
table_keysym:
    ; FIXME - add in the definitions
    ib 0x000219e8 - 0x000218d8
table_live_key_map:
    ; FIXME - add in the definitions
    ib 0x00021a0c - 0x000219e8
table.00021a0c:
    ib 0x00021a10 - 0x00021a0c
table_ptr_keysym_stuff:
    dd 0x110
    dd table_keysym
    dd table_live_key_map
    dd table.00021a0c
table.00021a20:
    ib 0x00021aa8 - 0x00021a20
table.00021aa8:
    dd 0x85
    dd table.00021a20
table.00021ab0:
    ib 0x00021acc - 0x00021ab0
table.00021acc:
    ib 0x00021ae8 - 0x00021acc
table.00021ae8:
    ib 0x00021b04 - 0x00021ae8
table.00021b04:
    ib 0x00021b20 - 0x00021b04
table.00021b20:
    ib 0x00021b3c - 0x00021b20
table.00021b3c:
    ib 0x00021b58 - 0x00021b3c
table.00021b58:
    ib 0x00021b74 - 0x00021b58
table.00021b74:
    ib 0x00021b90 - 0x00021b74
table.00021b90:
    ib 0x00021bac - 0x00021b90
table.00021bac:
    ib 0x00021bc8 - 0x00021bac
table.00021bc8:
    ib 0x00021be4 - 0x00021bc8
table.00021be4:
    ib 0x00021c00 - 0x00021be4
table.00021c00:
    ib 0x00021c1c - 0x00021c00
table.00021c1c:
    ib 0x00021c38 - 0x00021c1c
table.00021c38:
    ib 0x00021c54 - 0x00021c38
table.00021c54:
    ib 0x00021c70 - 0x00021c54
table.00021c70:
    dd 0x1d07
    dd table.00021ab0
table.00021c78:
    dd table.00021c70
table.00021c7c:
    dd 1
    dd table.00021c78
table.00021c84:
    dd 0x1d07
    dd table.00021acc
table.00021c8c:
    dd table.00021c84
table.00021c90:
    dd 1
    dd table.00021c8c
table.00021c98:
    dd 0x1d07
    dd table.00021ae8
table.00021ca0:
    dd table.00021c98
table.00021ca4:
    dd 1
    dd table.00021ca0
table.00021cac:
    dd 0x1d07
    dd table.00021b04
table.00021cb4:
    dd table.00021cac
table.00021cb8:
    dd 1
    dd table.00021cb4
table.00021cc0:
    dd 0x1d07
    dd table.00021b20
table.00021cc8:
    dd table.00021cc0
table.00021ccc:
    dd 1
    dd table.00021cc8
table.00021cd4:
    dd 0x1d07
    dd table.00021b3c
table.00021cdc:
    dd table.00021cd4
table.00021ce0:
    dd 1
    dd table.00021cdc
table.00021ce8:
    dd 0x1d07
    dd table.00021b58
table.00021cf0:
    dd table.00021ce8
table.00021cf4:
    dd 1
    dd table.00021cf0
table.00021cfc:
    dd 0x1d07
    dd table.00021b74
table.00021d04:
    dd table.00021cfc
table.00021d08:
    dd 1
    dd table.00021d04
table.00021d10:
    dd table.00021c7c
    dd table.00021ca4
    dd table.00021ca4
    dd table.00021ccc
    dd table.00021cf4
    dd table.00021cf4
    dd table.00021c90
    dd table.00021cb8
    dd table.00021cb8
    dd table.00021ce0
    dd table.00021d08
    dd table.00021d08
table.00021d40:
    dd 0xc      ; size of table
    dd table.00021d10
table.00021d48:
    dd table.00021d40
    dd table.000215c4
table.00021d50:
    dd 0x1d07
    dd table.00021b90
table.00021d58:
    dd table.00021d50
table.00021d5c:
    dd 1
    dd table.00021d58
table.00021d64:
    dd 0x1d07
    dd table.00021bac
table.00021d6c:
    dd table.00021d64
table.00021d70:
    dd 1
    dd table.00021d6c
table.00021d78:
    dd 0x1d07
    dd table.00021bc8
table.00021d80:
    dd table.00021d78
table.00021d84:
    dd 1
    dd table.00021d80
table.00021d8c:
    dd 0x1d07
    dd table.00021be4
table.00021d94:
    dd table.00021d8c
table.00021d98:
    dd 1
    dd table.00021d94
table.00021da0:
    dd 0x1d07
    dd table.00021c00
table.00021da8:
    dd table.00021da0
table.00021dac:
    dd 1
    dd table.00021da8
table.00021db4:
    dd 0x1d07
    dd table.00021c1c
table.00021dbc:
    dd table.00021db4
table.00021dc0:
    dd 1
    dd table.00021dbc
table.00021dc8:
    dd 0x1d07
    dd table.00021c38
table.00021dd0:
    dd table.00021dc8
table.00021dd4:
    dd 1
    dd table.00021dd0
table.00021ddc:
    dd 0x1d07
    dd table.00021c54
table.00021de4:
    dd table.00021ddc
table.00021de8:
    dd 1
    dd table.00021de4
table.00021df0:
    dd table.00021d5c
    dd table.00021d84
    dd table.00021d84
    dd table.00021dac
    dd table.00021dd4
    dd table.00021dd4
    dd table.00021d70
    dd table.00021d98
    dd table.00021d98
    dd table.00021dc0
    dd table.00021de8
    dd table.00021de8
table.00021e20:
    dd 0xc
    dd table.00021df0
table.00021e28:
    dd table.00021e20
    dd table.000215c4
table.00021e30:
    dd table.00021d48
    dd table.00021e28
table.00021e38:
    dd 1
    dd 2        ; size of table?
    dd table.00021e30
table.00021e44:
    dd table.00021e38
table.00021e48:
    dd 1
    dd table.00021e44
table.00021e50:
    ib 0x00021e68 - 0x00021e50
table.00021e68:
    dd 4
    dd table.00021e50
table.00021e70:
    ib 4
table.00021e74:
    ib 4
table.00021e78:
    ib 4
table.00021e7c:
    ib 4
table.00021e80:
    ib 4
table.00021e84:
    ib 4
table.00021e88:
    ib 4
table.00021e8c:
    dd table.00021e70
    dd table.00021e74
    dd table.00021e78
    dd table.00021e7c
    dd table.00021e80
    dd table.00021e84
    dd table.00021e88
table.00021ea8:
    ib 0x00021ef8 - 0x00021ea8
table.00021ef8:
    dd 7        ; size
    dd table.00021e8c
    dd 0xa      ; size
    dd table.00021ea8
table.00021f08:
    ib 0x00021f20 - 0x00021f08
table.00021f20:
    dd 2        ; size?
    dd table.00021f08
table.00021f28:
    ib 0x00021f44 - 0x00021f28
table.00021f44:
    ib 0x00021f60 - 0x00021f44
table.00021f60:
    dd 0xd      ; size
    dd table.00021f28
    dd 0xd      ;
    dd table.00021f44
table.00021f70:
    dd 2        ; size
    dd table.00021f60

; TODO
; I've added the entire remainder of the firmware here as one big blob,
; but to match the above, it should have the tables defined
    ib 0x30000 - 0x21f78
