#
# Infrastructure to manage patching thinkpad EC firmware
#
# Copyright (C) 2016 Hamish Coleman
#

all:
	false

#
# Radare didnt seem to let me specify the direcrory to store the project file,
# so this target hacks around that
#
install.radare.projects:
	mkdir -p ~/.config/radare2/projects/x220.8DHT34WW.d
	cp -fs $(PWD)/radare/x220.8DHT34WW ~/.config/radare2/projects
	mkdir -p ~/.config/radare2/projects/x230.G2HT35WW.d
	cp -fs $(PWD)/radare/x230.G2HT35WW ~/.config/radare2/projects
	mkdir -p ~/.config/radare2/projects/t430s.G7HT39WW.d
	cp -fs $(PWD)/radare/t430s.G7HT39WW ~/.config/radare2/projects

#
# Download any ISO image that we have a checksum for
# NOTE: makes an assumption about the Lenovo URL not changing
%.iso.orig:  %.iso.orig.sha1
	wget -O $@ https://download.lenovo.com/pccbbs/mobiles/$(basename $@)
	sha1sum -c $<
	touch $@

# Generate all the orig images so that we can diff against them later

# a the generic binary extractor
%.orig:  %.orig.slice slice.extract
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
.PRECIOUS: %.img.orig

# Generate a working file with any known patches applied
%.img: %.img.orig
	cp --reflink=auto $< $@
	./hexpatch.pl $@ $@.d/*.patch

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
x220.8DHT34WW.img.enc.orig: 8duj27us.iso.orig
x230.G2HT35WW.img.enc.orig: g2uj23us.iso.orig
t430.G1HT35WW.img.enc.orig: g1uj38us.iso.orig
t430s.G7HT39WW.img.enc.orig: g7uj18us.iso.orig
