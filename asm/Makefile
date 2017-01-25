
all:
	false

DEPSDIR := .d
$(shell mkdir -p $(DEPSDIR))

x230.G2HT35WW.img: ../x230.G2HT35WW.img
	cp $< $@

-include $(DEPSDIR)/ec.img.deps
$(DEPSDIR)/ec.img.deps: Makefile
	nasm -MT ec.img -M ec.asm >$@

%.img: %.asm
	nasm -f bin -o $@ $<

diff: ec.img x230.G2HT35WW.img
	vbindiff $^

