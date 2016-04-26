#
# Infrastructure to manage patching thinkpad EC firmware
#
# Copyright (C) 2016 Hamish Coleman
#

all:
	cat README

list_images:
	$(info The following make targets are available to produce firmware images:)
	$(info )
	$(info $(basename $(wildcard *.d)))
	$(info )
	$(info The following make targets are available to produce FL2 files:)
	$(info )
	$(info $(foreach i,$(basename $(basename $(wildcard *.d))),$(basename $(wildcard $(i).*.FL2.slice))))
	$(info )
	$(info The following make targets are available to produce ISO images)
	$(info )
	$(info g2uj23us.iso)
	@true

# FIXME - need to automatically generate the iso image target list

.PHONY: list_images

# All the bios update iso images I have checked have had a fat16 filesystem
# embedded in a dos mbr image as the el-torito ISO payload.  They also all
# had the same offset to this fat filesystem, so hardcode that offset here.
FAT_OFFSET := 71680

#
# Radare didnt seem to let me specify the directory to store the project file,
# so this target hacks around that
#
install.radare.projects:
	mkdir -p ~/.config/radare2/projects/x220.8DHT34WW.d
	cp -fs $(PWD)/radare/x220.8DHT34WW ~/.config/radare2/projects
	mkdir -p ~/.config/radare2/projects/x230.G2HT35WW.d
	cp -fs $(PWD)/radare/x230.G2HT35WW ~/.config/radare2/projects

#
# Download any ISO image that we have a checksum for
# NOTE: makes an assumption about the Lenovo URL not changing
%.iso.orig:  %.iso.orig.sha1
	wget -O $@ https://download.lenovo.com/pccbbs/mobiles/$(basename $@)
	sha1sum -c $<
	touch $@

# Generate all the orig images so that we can diff against them later

# a the generic binary extractor
%.orig:  %.slice slice.extract
	./slice.extract $< $@

%.img.orig:  %.img.enc.orig %.img.orig.sha1 mec-tools/mec_encrypt
	mec-tools/mec_encrypt -d $< >$@
	sha1sum -c $@.sha1

# a generic encryptor
%.img.enc:  %.img xx30.encrypt
	./xx30.encrypt $< $@

# TODO
# - if we ever get generic extraction or encryption for more than
#   just the Xx30 series, these generic rules will need to be reworked

# keep intermediate files
.PRECIOUS: %.orig
.PRECIOUS: %.img
.PRECIOUS: %.img.orig

# Generate a working file with any known patches applied
%.img: %.img.orig
	cp --reflink=auto $< $@
	./hexpatch.pl $@ $@.d/*.patch

%.iso.bat: %.iso.orig autoexec.bat.template
	sed -e "s%__FL2%`mdir -/ -b -i $<@@$(FAT_OFFSET) |grep FL2 |cut -d/ -f3-`%" autoexec.bat.template >$@

# if you want to work on more patches, you probably want the pre-patched ver
%.img.prepatch: %.img.orig
	cp --reflink=auto $< $(basename $<)

%.hex: %
	hd -v $< >$@

# Generate a patch report
%.diff: %.hex %.orig.hex
	-diff -u $(basename $@).orig.hex $(basename $@).hex >$@
	cat $@

mec-tools/Makefile:
	git submodule update --init --remote

mec-tools/mec_encrypt: mec-tools/Makefile
	make -C mec-tools

#
# TODO:
# - most of these dependancies could be automatically calculated
dosflash.exe.slice: g2uj23us.iso.orig

w530.G4HT39WW.s01D5200.FL2.slice:  g5uj28us.iso.orig
x220.8DHT34WW.s01CB000.FL2.slice:  8duj27us.iso.orig
x230.G2HT35WW.s01D3000.FL2.slice:  g2uj23us.iso.orig
x230t.GCHT25WW.s01DA000.FL2.slice: gcuj24us.iso.orig
x250.N10HT17W.s01E5000.FL2.slice:  n10ur10w.iso.orig
x260.R02HT29W.s0AR0200.FL2.slice:  r02uj46d.iso.orig

t430.G1HT35WW.img.enc.slice:  g1uj38us.iso.orig
t430s.G7HT39WW.img.enc.slice: g7uj18us.iso.orig
w530.G4HT39WW.img.enc.slice:  w530.G4HT39WW.s01D5200.FL2.orig
x220.8DHT34WW.img.enc.slice:  x220.8DHT34WW.s01CB000.FL2.orig
x230.G2HT35WW.img.enc.slice:  x230.G2HT35WW.s01D3000.FL2.orig
x230t.GCHT25WW.img.enc.slice: x230t.GCHT25WW.s01DA000.FL2.orig
x250.N10HT17W.img.enc.slice:  x250.N10HT17W.s01E5000.FL2.orig
x260.R02HT29W.img.slice:      x260.R02HT29W.s0AR0200.FL2.orig

w530.G4HT39WW.s01D5200.FL2:  t430s.G7HT39WW.img.enc.slice w530.G4HT39WW.img.enc
x230.G2HT35WW.s01D3000.FL2:  x230.G2HT35WW.img.enc.slice x230.G2HT35WW.img.enc

g2uj23us.iso: x230.G2HT35WW.s01D3000.FL2.slice x230.G2HT35WW.s01D3000.FL2

# Hacky, non generic rules
w530.G4HT39WW.s01D5200.FL2:  w530.G4HT39WW.img.enc
	./slice.insert $<.slice $< $@
x230.G2HT35WW.s01D3000.FL2:  x230.G2HT35WW.img.enc
	./slice.insert $<.slice $< $@

g2uj23us.iso: x230.G2HT35WW.s01D3000.FL2 g2uj23us.iso.bat
	./slice.insert $<.slice $< $@
	mcopy -o -i $@@@$(FAT_OFFSET) $@.bat ::AUTOEXEC.BAT
