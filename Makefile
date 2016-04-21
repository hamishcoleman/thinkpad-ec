
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

#
# Download any ISO image that we have a checksum for
# NOTE: makes an assumption about the Lenovo URL not changing
%.iso.orig:  %.iso.orig.sha1
	wget -O $@ https://download.lenovo.com/pccbbs/mobiles/$(basename $@)
	sha1sum -c $<
	touch $@

# Generate orig images so that we can diff against them later
# If we have an extractor for this image, use it
%.img.orig:  %.extract %.img.orig.sha1
	./$< $@
	sha1sum -c $@.sha1

%.img.enc:  %.encrypt %.img
	./$< $(basename $<).img $@

# keep intermediate files
.PRECIOUS: %.img.orig

# Generate a working file that we can patch
%.img: %.img.orig
	sha1sum -c $<.sha1
	cp $< $@

mec-tools/Makefile:
	git submodule update --init --remote

mec-tools/mec_encrypt: mec-tools/Makefile
	make -C mec-tools

#
# TODO:
# - most of these dependancies could be automatically calculated
x220.8DHT34WW.extract: 8duj27us.iso.orig
x230.G2HT35WW.extract: g2uj23us.iso.orig mec-tools/mec_encrypt
x230.G2HT35WW.encrypt: mec-tools/mec_encrypt

