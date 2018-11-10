tumble.ssd: vgmplay.6502 tumb16k.exo
	beebasm -i vgmplay.6502 -do tumble.ssd -opt 2 -v > compile.txt

tumble.vgm: tumbvgm.pl
	perl tumbvgm.pl >tumble.vgm

tumble.raw: vgm2raw.pl tumble.vgm
	perl vgm2raw.pl tumble.vgm >tumble.raw

tumb16k.exo: tumble.raw
	exomizer raw -P0 -C -c -m 16384 tumble.raw -o tumb16k.exo

clean:
	-rm -f tumble.ssd tumble.vgm tumb*.exo
