
all:
	false

#
# Radare didnt seem to let me specify the direcrory to store the project file,
# so this target hacks around that
#
install.radare.projects:
	mkdir -p ~/.config/radare2/projects/x220.8DHT34WW.d
	cp -s $(PWD)/radare/x220.8DHT34WW ~/.config/radare2/projects

#
# Download any ISO image that we have a checksum for
# NOTE: makes an assumption about the Lenovo URL not changing
%.iso:  %.iso.sha1
	wget -O $@ https://download.lenovo.com/pccbbs/mobiles/$@
	sha1sum -c $<
	touch $@

#
# If we have an extractor for this image, use it
%.img:  %.extract %.img.sha1
	./$< $@
	sha1sum -c $@.sha1

mec-tools/Makefile:
	git submodule update --init --remote

mec-tools/mec_encrypt: mec-tools/Makefile
	make -C mec-tools

#
# TODO:
# - most of these dependancies could be automatically calculated
x220.8DHT34WW.extract: 8duj27us.iso
x230.G2HT35WW.extract: g2uj23us.iso mec-tools/mec_encrypt
