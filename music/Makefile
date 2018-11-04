tumble.ssd: vgmplay.6502 tumb16k.exo
	beebasm -i vgmplay.6502 -do tumble.ssd -opt 2 -v > compile.txt

tumble.vgm:
	perl tumbvgm.pl >tumble.vgm

tumb16k.exo: tumble.vgm
	exomizer raw -c -m 16384 tumble.vgm -o tumb16k.exo

tumb8k.exo: tumble.vgm
	exomizer raw -c -m 8192 tumble.vgm -o tumb8k.exo

clean:
	-rm -f tumble.ssd tumble.vgm tumb*.exo
