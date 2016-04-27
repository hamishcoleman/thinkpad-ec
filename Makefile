#
# Infrastructure to manage patching thinkpad EC firmware
#
# Copyright (C) 2016 Hamish Coleman
#

all:
	cat README

list_iso:
	$(info The following make targets are available to produce patched and)
	$(info bootable ISO images)
	$(info )
	@for i in *.desc; do echo `basename $$i .orig.desc` - for patching `cat $$i`; done
	@echo

# FIXME - need to automatically generate the iso image target list

list_images:
	$(info The following make targets are available to produce firmware images:)
	$(info )
	$(info $(basename $(wildcard *.d)))
	$(info )
	$(info The following make targets are available to produce FL2 files:)
	$(info )
	$(info $(foreach i,$(basename $(basename $(wildcard *.d))),$(basename $(wildcard $(i).*.FL2.slice))))
	$(info )
	@true

.PHONY: list_iso list_images

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

DEPSDIR := .d
$(shell mkdir -p $(DEPSDIR))
-include $(DEPSDIR)/slice.extract.deps
$(DEPSDIR)/slice.extract.deps:
	for i in *.slice; do read SLICEE other <$$i; echo $$i: $$SLICEE; done >$@
-include $(DEPSDIR)/slice.insert.deps
$(DEPSDIR)/slice.insert.deps:
	for i in *.slice; do read SLICEE other <$$i; echo `basename $$SLICEE .orig`: $$i `basename $$i .slice`; done >$@

# FIXME - the slice.deps targets basically do not handle add/del/change of
# the *.slice files.  I dont use any of the regular tricks because I also
# dont want to download every .iso file as a result of depending on the %.slice
# file - and I dont want to work around that with makefile magic as that would
# defeat the purpose of keeping the makefile simple

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

%.iso.bat: %.iso.orig %.iso.orig.desc autoexec.bat.template
	sed -e "s%__FL2%`mdir -/ -b -i $<@@$(FAT_OFFSET) |grep FL2 |cut -d/ -f3-`%; s%__DESC%`cat $<.desc`%" autoexec.bat.template >$@

# helper to write the ISO onto a cdrw
%.iso.blank_burn: %.iso
	wodim -eject -v speed=40 -tao gracetime=0 blank=fast $<

# if you want to work on more patches, you probably want the pre-patched ver
%.img.prepatch: %.img.orig
	cp --reflink=auto $< $(basename $<)

%.hex: %
	hd -v $< >$@

# Generate a patch report
%.diff: %.hex %.orig.hex
	-diff -u $(basename $@).orig.hex $(basename $@).hex >$@
	cat $@

# If we ever want a copy of the dosflash.exe, just get it from the iso image
%.dosflash.exe.orig: %.iso.orig
	mcopy -i $^@@$(FAT_OFFSET) ::FLASH/DOSFLASH.EXE $@

mec-tools/Makefile:
	git submodule update --init --remote

mec-tools/mec_encrypt: mec-tools/Makefile
	make -C mec-tools

#
# TODO:
# - add a simple method to autogenerate these non-generic rules

# Hacky, non generic rules
t430.G1HT35WW.s01D2000.FL2:  t430.G1HT35WW.img.enc
	./slice.insert $<.slice $< $@
w530.G4HT39WW.s01D5200.FL2:  w530.G4HT39WW.img.enc
	./slice.insert $<.slice $< $@
x230.G2HT35WW.s01D3000.FL2:  x230.G2HT35WW.img.enc
	./slice.insert $<.slice $< $@

g1uj38us.iso: t430.G1HT35WW.s01D2000.FL2 g1uj38us.iso.bat
	./slice.insert $<.slice $< $@
	mcopy -o -i $@@@$(FAT_OFFSET) $@.bat ::AUTOEXEC.BAT

g2uj23us.iso: x230.G2HT35WW.s01D3000.FL2 g2uj23us.iso.bat
	./slice.insert $<.slice $< $@
	mcopy -o -i $@@@$(FAT_OFFSET) $@.bat ::AUTOEXEC.BAT

g5uj28us.iso: w530.G4HT39WW.s01D5200.FL2 g5uj28us.iso.bat
	./slice.insert $<.slice $< $@
	mcopy -o -i $@@@$(FAT_OFFSET) $@.bat ::AUTOEXEC.BAT
