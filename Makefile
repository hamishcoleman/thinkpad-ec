#
# Infrastructure to manage patching thinkpad EC firmware
#
# Copyright (C) 2016 Hamish Coleman
#

all:    list_laptops
	$(info See README file for additional details)
	$(info )

.PHONY: all

QEMU_OPTIONS ?= -enable-kvm

GITVERSION = $(shell git describe --dirty --abbrev=6 ) ($(shell date +%Y%m%d))
BUILDINFO = $(GITVERSION) $(MAKECMDGOALS)

list_laptops:
	$(info )
	$(info The following make targets are the supported usb images:)
	$(info )
	$(info patched.t430.img  - for patching Thinkpad T430)
	$(info patched.t430s.img - for patching Thinkpad T430s)
	$(info patched.t530.img  - for patching Thinkpad T530)
	$(info patched.t530i.img - for patching Thinkpad T530i)
	$(info patched.w530.img  - for patching Thinkpad W530)
	$(info patched.x230.img  - for patching Thinkpad X230)
	$(info patched.x230t.img - for patching Thinkpad X230t)
	$(info )
	$(info patched.t430.257.img  - for patching Thinkpad T430 BIOS 2.57 - no keyboard patch)
	$(info )

.PHONY: list_laptops

DEPSDIR := .d

# Remove all the locally generated junk (including any patched firmware
# images) and any small downloads
clean:
	rm -f patched.*.iso patched.*.img *.FL2 *.FL2.orig *.img.enc \
            *.img.enc.orig *.img.orig *.bat \
            *.img \
            *.txt.orig
	rm -rf $(DEPSDIR)

# Also remove the large iso images downloaded from remote servers.
really_clean: clean
	rm -f *.iso.orig

# manually managed list of laptops - update this if the BIOS versions change

patched.t430.iso: g1uj40us.iso
	$(call patched_iso,$<,$@)

patched.t430.257.iso: g1uj25us.iso
	$(call patched_iso,$<,$@)

patched.t430s.iso: g7uj19us.iso
	$(call patched_iso,$<,$@)

patched.t530.iso: g4uj30us.iso
	$(call patched_iso,$<,$@)

patched.t530i.iso: g4uj30us.iso
	$(call patched_iso,$<,$@)

patched.w530.iso: g5uj28us.iso
	$(call patched_iso,$<,$@)

patched.x230.iso: g2uj25us.iso
	$(call patched_iso,$<,$@)

patched.x230t.iso: gcuj24us.iso
	$(call patched_iso,$<,$@)


list_iso:
	$(info )
	$(info This list was a duplicate of the list_laptops list - please refer to that)
	$(info )
	@false

.PHONY: list_iso

# FIXME - need to automatically generate the iso image target list

list_images:
	$(info The following make targets are available to produce firmware images:)
	$(info )
	$(info $(basename $(wildcard *.d)))
	$(info )
	$(info Check the Descriptions.txt for the names of the known FL2 files)
	$(info )
	@true

.PHONY: list_images

# All the bios update iso images I have checked have had a fat16 filesystem
# embedded in a dos mbr image as the el-torito ISO payload.  They also all
# had the same offset to this fat filesystem, so hardcode that offset here.
FAT_OFFSET := 71680

# Some versions of mtools need this flag set to allow them to work with the
# dosfs images used by Lenovo - from my tests, it may be that Debian has
# applied some patch
export MTOOLS_SKIP_CHECK=1

#
# Radare didnt seem to let me specify the directory to store the project file,
# so this target hacks around that
#
install.radare.projects:
	mkdir -p ~/.config/radare2/projects/x220.8DHT34WW.d
	cp -fs $(PWD)/radare/x220.8DHT34WW ~/.config/radare2/projects
	mkdir -p ~/.config/radare2/projects/x230.G2HT35WW
	cp -fs $(PWD)/radare/x230.G2HT35WW ~/.config/radare2/projects/x230.G2HT35WW/rc
	mkdir -p ~/.config/radare2/projects/x260.R02HT29W.d/
	cp -fs $(PWD)/radare/x260.R02HT29W ~/.config/radare2/projects

#
# These enable and disable targets change which patches are configured to be
# applied

PATCHES_KEYBOARD := 001_keysym.patch 002_dead_keys.patch \
    003_keysym_replacements.patch 004_fn_keys.patch 005_fn_key_swap.patch

patch_enable_battery:
	$(call patch_enable,006_battery_validate.patch)

patch_disable_battery:
	$(call patch_disable,006_battery_validate.patch)

patch_enable_keyboard:
	for j in $(PATCHES_KEYBOARD); do \
	 $(call patch_enable,$$j); \
	done

patch_disable_keyboard:
	for j in $(PATCHES_KEYBOARD); do \
	 $(call patch_disable,$$j); \
	done

# $1 is the old patch name
# $2 is the new patch name
define patch_mv
	for i in *.img.d; do \
	 if [ -e $$i/$1 ]; then mv $$i/$1 $$i/$2; fi; \
	done
endef

# $1 is the patch name
define patch_enable
	$(call patch_mv,$1.OFF,$1)
endef

# $1 is the patch name
define patch_disable
	$(call patch_mv,$1,$1.OFF)
endef

$(shell mkdir -p $(DEPSDIR))
-include $(DEPSDIR)/slice.extract.deps
$(DEPSDIR)/slice.extract.deps: Makefile
	for i in *.slice; do read SLICEE other <$$i; echo $$i: $$SLICEE; done >$@.tmp
	mv $@.tmp $@
-include $(DEPSDIR)/slice.insert.deps
$(DEPSDIR)/slice.insert.deps: Makefile
	for i in *.slice; do read SLICEE other <$$i; echo `basename $$SLICEE .orig`: $$i `basename $$i .slice`; done >$@.tmp
	mv $@.tmp $@

# FIXME - the slice.deps targets basically do not handle add/del/change of
# the *.slice files.  I dont use any of the regular tricks because I also
# dont want to download every .iso file as a result of depending on the %.slice
# file - and I dont want to work around that with makefile magic as that would
# defeat the purpose of keeping the makefile simple

# TODO - the scripts/describe output depends on Descriptions.txt -
# could parse that file and create some deps

#
# Download any ISO image that we have a checksum for
# NOTE: makes an assumption about the Lenovo URL not changing
%.iso.orig:
	@echo -n "Downloading "
	@scripts/describe $@
	wget -O $@ https://download.lenovo.com/pccbbs/mobiles/$(basename $@)
	scripts/checksum --rm_on_fail $@
	touch $@

# Download any README text file released alongside to ISO images.
# Useful for looking up firmware versions and the changelog.
# Note that Lenovo produces two sets of release notes: *uc.txt and
# *.us.txt - the "us" ones contain instructions for using the .exe
# version of the bios update tool instead of the instructions for
# bootable cdrom image, but other than that they /should/ be identical
%uc.txt.orig:
	@echo -n "Downloading release notes for "
	@scripts/describe $(subst uc.txt,us.iso,$@)
	wget -O $@ https://download.lenovo.com/pccbbs/mobiles/$(basename $@)

# For newer systems they have used names that match for the iso and the txt
%.txt.orig:
	@echo -n "Downloading release notes for "
	@scripts/describe $(subst .txt.,.iso.,$@)
	wget -O $@ https://download.lenovo.com/pccbbs/mobiles/$(basename $@)

# Generate all the orig images so that we can diff against them later

# A generic binary extractor
%.orig:  %.slice scripts/slice.extract
	./scripts/slice.extract $< $@

# TODO - checking the checksum here is probably too strict - it adds
# more barriers to downloading some random bios ISO and starting to port
# the code to it.
# FIXME - wrap the mec-tools with something that gives --rm_on_fail semantics
%.img.orig:  %.img.enc.orig mec-tools/mec_encrypt
	mec-tools/mec_encrypt -d $< $@
	scripts/checksum --rm_on_fail $@
	mec-tools/mec_csum_flasher -c $@
	mec-tools/mec_csum_boot -c $@


# A generic encryptor
%.img.enc:  %.img scripts/xx30.encrypt
	./scripts/xx30.encrypt $< $@

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
	./scripts/hexpatch.pl --rm_on_fail $@ $@.d/*.patch

# using both __DIR and __FL2 is a hack to get around needing to quote the
# DOS path separator.  It feels like there should be a better way if I put
# my mind to it..
#
%.iso.bat: %.iso.orig autoexec.bat.template
	sed -e "s%__DIR%`mdir -/ -b -i $<@@$(FAT_OFFSET) |grep FL2 |cut -d/ -f3`%; s%__FL2%`mdir -/ -b -i $<@@$(FAT_OFFSET) |grep FL2 |cut -d/ -f4`%; s%__DESC%`scripts/describe $<`%; s/__BUILDINFO/$(BUILDINFO)/" autoexec.bat.template >$@.tmp
	mv $@.tmp $@
	touch -d @1 $@

# helper to write the ISO onto a cdrw
%.iso.blank_burn: %.iso
	wodim -eject -v speed=40 -tao gracetime=0 blank=fast $<

# if you want to work on more patches, you probably want the pre-patched ver
%.img.prepatch: %.img.orig
	cp --reflink=auto $< $(basename $<)

%.hex: %
	hd -v $< >$@.tmp
	mv $@.tmp $@

# Generate a patch report
%.diff: %.hex %.orig.hex
	-diff -u $(basename $@).orig.hex $(basename $@).hex >$@.tmp
	mv $@.tmp $@
	cat $@

# If we ever want a copy of the dosflash.exe, just get it from the iso image
%.dosflash.exe.orig: %.iso.orig
	mcopy -m -i $^@@$(FAT_OFFSET) ::FLASH/DOSFLASH.EXE $@

## Use the system provided geteltorito script, if there is one
#GETELTORITO := $(shell if type geteltorito >/dev/null; then echo geteltorito; else echo ./geteltorito; fi)

# use the included geteltorito script always, since we know it does not have
# the hdd size bug
GETELTORITO := ./scripts/geteltorito

# extract the DOS boot image from an iso (and fix it up so qemu can boot it)
%.img: %.iso
	$(GETELTORITO) -o $@ $<
	if [ ! -e fix-hdd-image-`stat -c %s $@`.patch ]; then \
            echo ERROR: need the correct fix-hdd-image patch; \
            rm -f $@; \
            false; \
	fi
	./scripts/hexpatch.pl --rm_on_fail $@ fix-hdd-image-`stat -c %s $@`.patch
	$(call build_info,$<.bat)

# $1 is the lenovo named iso
# $2 is the nicely named iso
define patched_iso
	mv $1 $2
	mv $1.bat $2.bat
	$(call build_info,$2.bat)
endef

# $1 is the bat file
define build_info
	@echo
	@echo
	@echo Your build has completed with the following details:
	@grep Buil $1
endef

# simple testing of images in an emulator
%.iso.test: %.iso
	qemu-system-x86_64 $(QEMU_OPTIONS) -cdrom $<

%.img.test: %.img
	qemu-system-x86_64 $(QEMU_OPTIONS) -hda $<

mec-tools/Makefile:
	git submodule update --init --remote

mec-tools/mec_encrypt: mec-tools/Makefile
	git submodule update
	make -C mec-tools

# using function calls to build rules with actions is kind of a hack,
# which is why these are all on oneline.

# Insert the new firmware into the FL2 file
# $1 = encoded EC firmware
# $2 = FL2 filename
define rule_fl2_patch
    $(2): $(1) ; ./scripts/slice.insert $(1).slice $(1) $(2)
endef

# Create a new ISO image with patches applied
# $1 = FL2 filename
# $2 = ISO image
define rule_iso
    $(2): $(1) $(2).bat ; cp --reflink=auto $(2).orig $(2) && ./scripts/copyFL2 to_iso $(2) $(1) && sed -i "s/__BUILT/`sha1sum $(1)`/" $(2).bat && mcopy -m -o -i $(2)@@$(FAT_OFFSET) $(2).bat ::AUTOEXEC.BAT && mdel -i $(2)@@$(FAT_OFFSET) ::EFI/Boot/BootX64.efi
endef

# Extract the FL2 file from an ISO image
# Note that the parameters here are essentially the same as rule_iso, but you cannot
# define two targets with one define..
# $1 = FL2 filename basename
# $2 = ISO image basename
#
# TODO - checking the checksum here is probably too strict - it adds
# more barriers to downloading some random bios ISO and starting to port
# the code to it.
define rule_fl2_extract
    $(1).orig: $(2).orig ; ./scripts/copyFL2 from_iso $(2).orig $(1).orig && ./scripts/checksum --rm_on_fail $(2).orig
endef

#
# TODO:
# - add a simple method to autogenerate these non-generic rules
# - once that is done, convert the defines back to action bodies, not
#   rule definitions

# Hacky, non generic rules
$(call rule_fl2_patch,t430.G1HT34WW.img.enc,t430.G1HT34WW.s01D2000.FL2)
$(call rule_fl2_patch,t430.G1HT35WW.img.enc,t430.G1HT35WW.s01D2000.FL2)
$(call rule_fl2_patch,t430s.G7HT39WW.img.enc,t430s.G7HT39WW.s01D8000.FL2)
$(call rule_fl2_patch,t530.G4HT39WW.img.enc,t530.G4HT39WW.s01D5100.FL2)
$(call rule_fl2_patch,w530.G4HT39WW.img.enc,w530.G4HT39WW.s01D5200.FL2)
$(call rule_fl2_patch,x230.G2HT35WW.img.enc,x230.G2HT35WW.s01D3000.FL2)
$(call rule_fl2_patch,x230t.GCHT25WW.img.enc,x230t.GCHT25WW.s01DA000.FL2)

$(call rule_iso,t430.G1HT34WW.s01D2000.FL2,g1uj25us.iso)
$(call rule_iso,t430.G1HT35WW.s01D2000.FL2,g1uj40us.iso)
$(call rule_iso,x230.G2HT35WW.s01D3000.FL2,g2uj25us.iso)
$(call rule_iso,t530.G4HT39WW.s01D5100.FL2,g4uj30us.iso)
$(call rule_iso,w530.G4HT39WW.s01D5200.FL2,g5uj28us.iso)
$(call rule_iso,t430s.G7HT39WW.s01D8000.FL2,g7uj19us.iso)
$(call rule_iso,x230t.GCHT25WW.s01DA000.FL2,gcuj24us.iso)

$(call rule_fl2_extract,t430.G1HT35WW.s01D2000.FL2,g1uj40us.iso)
$(call rule_fl2_extract,t430.G1HT34WW.s01D2000.FL2,g1uj25us.iso)
$(call rule_fl2_extract,x230.G2HT35WW.s01D3000.FL2,g2uj25us.iso)
$(call rule_fl2_extract,t530.G4HT39WW.s01D5100.FL2,g4uj30us.iso)
$(call rule_fl2_extract,w530.G4HT39WW.s01D5200.FL2,g5uj28us.iso)
$(call rule_fl2_extract,t430s.G7HT39WW.s01D8000.FL2,g7uj19us.iso)
$(call rule_fl2_extract,x230t.GCHT25WW.s01DA000.FL2,gcuj24us.iso)
