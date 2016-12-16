
%define orig_bin "x230.G2HT35WW.img"

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

table3f50:
    dd 0x00003f28
    dd 0x00003f3c
table3f58:
    dd 2        ; size
    dd table3f50
table3f60:
    dd table3f58
table3f64:
    dd 1        ; size
    dd table3f60

    ib 0x20edc-0x3f6c

; no code beyond this point
table20edc:
    ib 0x000210a4-0x20edc
table210a4:
    ib 0x000211a4-0x000210a4
table211a4:
    ib 0x000211bc-0x000211a4
table211bc:
    ib 0x000211cc-0x000211bc
table211cc:
    ib 0x000211dc-0x000211cc
table211dc:
    dd 0xf ; size
    dd table211cc
table211e4:
    ib 0x0002121c-0x000211e4
table2121c:
    dd 7 ; size
    dd table211e4
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
