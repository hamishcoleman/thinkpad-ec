
all:
	false

x230.G2HT35WW.img: ../x230.G2HT35WW.img
	cp $< $@

ec.img: ec.asm x230.G2HT35WW.img
	nasm -f bin -o $@ $<

diff: ec.img x230.G2HT35WW.img
	vbindiff $^

