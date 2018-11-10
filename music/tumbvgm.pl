#!/usr/bin/perl
# -w
my $eofoff = 0;
my $nsamp = 0;
my $loopoff = 0;
my $loopsamp = 0;

my @mel = split//,
# b d   g i k   n p   s u w
#a c e f h j l m o q r t v x
#
# J L   O Q S   V X   [ ] _
#I K M N P R T U W Y Z \ ^ `
    
    'gdggdggdggdggdggdghehgdg'.#0
    'ebeebeebeebeebeebehehgdg'.#1
    'gdggdggdggdggdggdghehgdg'.#2
    'ebeebeebeebeebeebehgegdg'.#3
    'gdggdggdggdggdggdgjigiei'.#4
    'ieiieiieiieigeggeggeggeg'.#5
    'gdggdggdggdggdggdghehgdg'.#6
    'ebeebeebeebeebeebehgegdg'.#7
    'gdggdggdggdggdggdghehgdg'.#8
    'ebeebeebeebeebeebehgegdg'.#9
    'gdggdggdggdggdggdgjigiei'.#a
    'nqninieieb  knkgkgbgb[  '.#b

    'gdggdggdggdggdggdghehgdg'.#c
    'ebeebeebeebeebeebehehgdg'.#d
    'gdggdggdggdggdggdghehgdg'.#e
    'ebeebeebeebeebeebehgegdg'.#f
    'gdggdggdggdggdggdgjigiei'.#g
    'nqninieieb  knkgkgbgb`  '.#h

    '                        '.#i
    '                        '.#j
    '                        '.#k
    '                        '.#l
    '                        '.#m
    '                        '.#n
    '                        '.#o
    '                        '.#p

    'gdggdggdggdggdggdghehgdg'.#q
    'ebeebeebeebeebeebehehgdg'.#r
    'gdggdggdggdggdggdgjigiei'.#s
    'ieiieiieiieigeggeggeggeg'.#t
    'gdggdggdggdggdggdghehgdg'.#u
    'ebeebeebeebeebeebehehgdg'.#v
    'gdggdggdggdggdggdgjigiei'.#w
    'nqninieieb  knkgkgbgb`  '.#x
    'gdggdggdggdggdggdghehgdg'.#y
    'ebeebeebeebeebeebekjhgdg'.#z
    'gdggdggdggdggdggdgmljiei'.#A
    'ieiieiieiieigeggeggeggeg'.#B
    'gdggdggdggdggdggdghehgdg'.#C
    'ebeebeebeebeebeebekjhgdg'.#D
    'gdggdggdggdggdggdgmljiei'.#E
    'iXY[]_`bdegik[]_`abdegik'.#F
    'l                       '.#G
    '';

my @echo=split//,
    '                        '.#0
    '                        '.#1
    '                        '.#2
    '                        '.#3
    '                        '.#4
    '                        '.#5
    '                        '.#6
    '                        '.#7
    '                        '.#8
    '                        '.#9
    '                        '.#a
    '   nqninie     knkgkgb  '.#b
    '                        '.#c
    '                        '.#d
    '                        '.#e
    '                        '.#f
    '                        '.#g
    '   nqninie     knkgkg[  '.#h
    '                        '.#i
    '                        '.#j
    '                        '.#k
    '                        '.#l
    '                        '.#m
    '                        '.#n
    '                        '.#o
    '                        '.#p
    '                        '.#q
    '                        '.#r
    '                        '.#s
    '                        '.#t
    '                        '.#u
    '                        '.#v
    '                        '.#w
    '   nqninie     knkgkg[  '.#x
    '                        '.#y
    '                        '.#z
    '                        '.#A
    '                        '.#B
    '                        '.#C
    '                        '.#D
    '                        '.#E
    '    Y[]_`bdeg   ]^_`bdeg'.#F
    '`';

#my $fifthenv = 0,64 4,22 10,7 15,3 23,0
#               0,0  4,4  10,10, 15, 15

#my $melenv = 0,64  2,26 5,9 13,0
#             0,0   2,4, 5,10 

my $tick = 727.944; #735; #588; # 2000000/(128*309.5)=50.48465266558966074313

my @vollookup = (15, 3, 0);
my $freq = 50;
my $clock = 4000000;

sub note { exp(.05776226504666210911*shift) }

my $lastdelay=0;

sub psgwrite {
    if ($lastdelay>3) {
	#print STDERR "lastdelay=$lastdelay\n";
	$data .= pack"CCC", 0x61, $lastdelay&255,($lastdelay>>8);
	$lastdelay =0;#-= int($lastdelay);
    }
    $data .= pack"CC", 0x50, $_[0];
}

sub delay { 
    $lastdelay += $_[0];
    $nsamp += $_[0];
}

my @lastvol;
sub vol {
    my ($chan,$vol)=@_;
    return if $lastvol[$chan] == $vol;
    $lastvol[$chan] = $vol;
    psgwrite($chan | $vol);
}

sub end { $data.=pack"C", 0x66 }
use constant T1F => 0x80;
use constant T1V => 0x90;
use constant T2F => 0xa0;
use constant T2V => 0xb0;
use constant T3F => 0xc0;
use constant T3V => 0xd0;
use constant NF => 0xe0;
use constant NV => 0xf0;

my @lastfreq;
sub freq {
    my ($chan,$freq)=@_;
    return if $lastfreq[$chan] == $freq;
    $lastfreq[$chan] = $freq;
    psgwrite($chan + ($freq&15)); 
    psgwrite(0x40+(($freq>>4) & 0x3f));
}

my @ev;

my $frame = 0;

sub in { 
    my ($delay, $cb, $ch) = @_;
    die if !defined $ch;
    @ev = grep { $_->[2] ne $ch } @ev if $ch;
    push @ev, [$nsamp+$delay, $cb, $ch];
}

{
    my $meltick;
    my $echotick;
    my @env=(4,6,8,10,11,12,12,13,13,14,14,15);
    sub mel {
	my $m = ord($mel[$frame])-95;
	if ($m>-16) {
	    $meltick = 0;
	    my $freq = 400/note($m);
	    freq (T2F, $freq);
	    in(0, \&mel2, 2);
	    # if (int($frame/24)==5 ||
	    # 	int($frame/24)==11) {
	    # 	in($tick*6, sub {
	    # 	    freq (T3F, $freq);$echotick = 0;
	    # 	    in(0, \&echo2, 3);
	    # 	   }, 99);
	    # }
	}

	my $e = ord($echo[$frame])-95;
	if ($e>-16) {
	    $echotick = 0;
	    my $freq = 400/note($e);
	    freq (T1F, $freq);
	    in(0, \&echo2, 3);
	}
    }
    
    sub mel2 {
	$vol = $env[$meltick];
	$vol++ if !$meltick && $frame%3;
	vol(T2V, $vol);
	in ($tick, \&mel2, 2) unless ++$meltick>$#env;
    }

    sub echo2 {
	$vol = $env[$echotick]+2;
	$vol = 15 if $vol>15;
	#print STDERR "frame=$frame vol=$vol echotick=$echotick\n";
	vol(T1V, $vol);
	in ($tick, \&echo2, 3) unless ++$echotick>$#env;
    }

}

{
    my @click = split//,
	'000000000000000000000000'.#0
	'000000000000000000000000'.#1
	'111111111111111111111111'.#2
	'111111111111111111111111'.#3
	'111111111111111111111111'.#4
	'100000000020100000000000'.#5
	'000000000000000000000000'.#6
	'000000000000000000000000'.#7
	'111111111111111111111111'.#8
	'111111111111111111111111'.#9
	'111111111111111111111111'.#a
	'100000000000000000000000'.#b
	'000000000000000000000000'.#c
	'000000000000000000000000'.#d
	'111111111111111111111111'.#e
	'111111111111111111111111'.#f
	'111111111111111111111111'.#g
	'100000000000000000000000'.#h
	'000000000000000000000000'.#i
	'000000000000000000000000'.#j
	'111111111111111111111111'.#k
	'111111111111111111111111'.#l
	'111111111111111111111111'.#m
	'111111111111111111111111'.#n
	'111111111111111111111111'.#o
	'111111111111111111111111'.#p
	'111111311111111111311111'.#q
	'111111311111111111311111'.#r
	'111111311111111111311111'.#s
	'111111311111111111311111'.#t
	'111111311111111111311111'.#u
	'111111311111111111311111'.#v
	'111111311111111111311111'.#w	
	'1                       '.#x
	'111111311111111111311111'.#y	
	'111111311111111111311111'.#z	
	'111111311111111111311111'.#A	
	'111111311111111111311111'.#B	
	'111111311111111111311111'.#C
	'111111311111111111311111'.#D	
	'111111311111111111311111'.#E
	'1                       '.#F
	''
	;

    sub click {
	clickon(($frame % 3) ? 4 : 2) if $click[$frame]==1;
	if ($click[$frame]==2) {
	    for my $y (0..3) {
		in($tick*$y*3,sub { clickon([6,5,4,3]->[$y]) },0);
	    }
	}
	snareon() if $click[$frame]==3;
    }

    sub clickon {
	psgwrite(NF | 4); # high, white
	vol(NV, shift);
	in(350, \&clickoff, 4);
    }

    sub clickoff {
	vol(NV, 15);
    }

    my $sntick;
    sub snareon {
	$sntick = 0;
	psgwrite(NF | 7); # T3 (==1), white
	in(0, \&snare_2, 4);
    }

    sub snare_2 {
	#my @env=(0,1,2,12,0,1,2,12,2,4,10,14,15);
	my @env=(0,1,2,12,0,1,2,12,2,4,6,12,4,8,10,14,15,12,15);
	my $vol = $env[$sntick];
	vol(NV, $vol);
	in(250, \&snare_2, 4) if ++$sntick<@env;
    }
}

{
    my @sweep = split//,
	'                        '.#0
	'                        '.#1
	'                        '.#2
	'                        '.#3
	'                        '.#4
	'                        '.#5
	'                        '.#6
	'                        '.#7
	'                        '.#8
	'                        '.#9
	'                        '.#a
	'                        '.#b
	'                        '.#c
	'                        '.#d
	'                        '.#e
	'                        '.#f
	'                        '.#g
	'                    1   '.#h
	'        1           1   '.#i
	'        1           1   '.#j
	'        1           1   '.#k
	'        1           1   '.#l
	
	'2     2 1   2     2 1   '.#m
	'2     2 1   2     2 1   '.#n
	'2     2 1   2     2 1   '.#o
	'2     2 1   2     2 1   '.#p
	
	'2     2 1   2     2 1   '.#q
	'2     2 1   2     2 1   '.#r
	'2     2 1   2     2 1   '.#s
	'2     2 1   2     2 1   '.#t
	'2     2 1   2     2 1   '.#u
	'2     2 1   2     2 1   '.#v
	'2     2 1   2     2 1   '.#w
	'2                       '.#x
	'2     2 1   2     2 1   '.#y
	'2     2 1   2     2 1   '.#z
	'2     2 1   2     2 1   '.#A
	'2     2 1   2     2 1   '.#B
	'2     2 1   2     2 1   '.#C
	'2     2 1   2     2 1   '.#D
	'2     2 1   2     2 1   '.#E
	'2                       '.#F
	'';

    my $t;
    my $fr;
    sub sweep {
	in (0,\&dosweep, 3) if $sweep[$frame]==1;
	in (0,\&dobd, 3) if $sweep[$frame]==2;
    }

    sub dosweep {
	freq (T1F, 1);
	$t = 0;
	$fr = 0;
	in($tick*6-100, \&sweep_2, 0);
    }
    sub sweep_2 {
	my @waveform = (8,3,1,0,1,3,8,15);
	#my @waveform = (3,0,3,15);
	#my @freq = (76, 57, 41, 29, 23, 19, 16, 12, 11, 9, 6, 6, 5, 5, 4, 4, 3, 3);
	my @freq = (57, 41, 29, 23, 19, 16, 12, 11, 9, 6, 6, 5, 5, 4, 4, 3, 3);	my $vol = $waveform[$t];
	#$vol += [3,3,2,2,1,1,0,0,0,0,0,0,0,1,2,2,2,3]->[$fr];
	$vol += [3,3,2,2,1,1,0,0,0,0,0,0,0,0,0,0,0,0]->[$fr];
	$vol=15 if $vol>15;
	$fr++,$t=0 if ++$t==@waveform;
	vol(T1V, $vol);
	$cycles = $freq[$fr]*1;
	#print STDERR "vol=$vol cycles=$cycles\n";
	in ($cycles, \&sweep_2, 3) unless ($fr==$#freq);
    }

    sub dobd {
	freq (T1F, 1);
	$t = 0;
	$fr = 0;
	in(0, \&bd_2, 3);
    }
    sub bd_2 {
	#my @waveform = (8,3,1,0,1,3,8,15);
	#my @waveform = (13,8,3,2,1,0,0,0,1,2,3,8,13,15);
	my @waveform = (3,2,1,0,0,0,1,2,3,4,7,9,11,9,7,5,3);
	#my @waveform = (0,0,0,0,0,0,0,15,15,15,15,15,15,15,15);
	my @freq = (10,10,12,13,14,17,19,23,28,32,36,44,52);
	my $vol = $waveform[$t];
	#$vol += [3,3,2,2,1,1,0,0,0,0,0,0,0,1,2,2,2,3]->[$fr];
	$vol += [0,0,0,0,0,0,0,0,0,0,1,2,3,4,5,6,7,8]->[$fr];
	$vol=15 if $vol>15;
	$fr++,$t=0 if ++$t==@waveform;
	vol(T1V, $vol);
	$cycles = $freq[$fr]*1;
	#print STDERR "vol=$vol cycles=$cycles\n";
	in ($cycles, \&bd_2, 3) unless ($fr==$#freq);
    }
}

{

    my @basspatt = split//,
    'a aa aa mm aa mm aa aa aa aa aa mm aa mm aa aa a'.#0
    'a aa aa mm aa mm aa aa aa aa aa mm aa mm aa aa a'.#2
    'a aa aa mm aa mm MM ff FF        CEFH        HJL'.#4
    'M aa aa mm aa mm aa aa aa aa aa mm aa mm aa aa a'.#6
    'a aa aa mm aa mm aa aa aa aa aa mm aa mm aa aa a'.#8
    'a aa aa mm aa mm MM ff FF        CEFH        HJL'.#a
    'M aa aa mm aa mm aa aa aa aa aa mm aa mm aa aa a'.#c
    'a aa aa mm aa mm aa aa aa aa aa mm aa mm aa aa a'.#e
    'a aa aa mm aa mm MM ff FF        CEFH       aa a'.#g
    'a mm aa    aa mm aa    aa mm aa    aa mm aa    a'.#i
    'a mm aa    aa mm aa    aa mm aa    aa mm aa    a'.#k
    'a mm aa    aa mm aa    aa mm aa    aa mm aa    a'.#m
    'a mm aa    aa mm aa    FF ff ff FF HH hh hh HH a'.#o
    'a aa aa mm aa mm aa aa aa aa aa mm aa mm aa aa a'.#q
    'a aa aa mm aa mm MM ff FF FF ff FF HH hh hh HH a'.#s
    'a aa aa mm aa mm aa aa aa aa aa mm aa mm aa aa a'.#u
    'a aa aa mm aa mm MM ff FF        CEFH       aa a'.#w
    'a aa aa mm aa mm aa aa aa aa aa mm aa mm aa aa a'.#y
    'a aa aa mm aa mm MM ff FF FF ff FF HH hh hh HH a'.#A
    'a aa aa mm aa mm aa aa aa aa aa mm aa mm aa aa a'.#C
    'a aa aa mm aa mm MM ff FF        CEFH        HJL'.#E
    'M'
    ;
    
    my $basstick;
    my $basscycle;
    my $cycles;
    my $waveform;
    my $wavelen;

    sub bass {
	my $op = (ord$basspatt[$frame])-65;
	bassoct(41*note($op)) if $op>=0 && $op<20;
	bass5th(41*note($op-32)) if $op>=32 && $op<52;
    }
    
    sub bassoct {
	$basstick = 0;
	$basscycle = $nsamp;
	$cycles = 44100 / $_[0] / 4;
	$waveform = [0,1,1,2];
	$wavelen = 4;
	in($cycles, \&bass_2, 1);
    }

    sub bass5th {
	$basstick = 0;
	$basscycle = $nsamp;
	$cycles = 44100 / $_[0] / 12;
	$waveform = [0,0,1,2,1,1,1,1,0,1,2,2];
	$wavelen = 12;
	in($cycles, \&bass_2, 1);
    }

    sub bass_2 {
	my $vol = $vollookup[$waveform->[$basstick%$wavelen]];
	$basstick++;
	my $n = ($nsamp - $basscycle)/$tick;
#	$vol += [0,3,6,8,10,12,13,14,15,15,15,15,15]->[$n];
#	$vol += [0,1,2,3,4,6,7,8,9,10,11,12,13,14,14,15]->[$n];
	$vol += [0,1,1,2,3,4,5,6,7,8,9,10,11,12,13,14,14,15]->[$n];

	$vol = 15 if ($vol > 15);
	vol(T3V, $vol);
	in ($cycles, \&bass_2, 1) unless ($n>17);
    }
}

#my $notes = [
    
sub doframe {
    bass();
    click();
    sweep();
    mel();
    $frame++;
    in($tick*6, \&doframe, 0);
}

vol(T1V, 15);
vol(T2V, 15);
vol(T3V, 15);
vol(NV, 15);
freq(T3F, 1);

in(0, \&doframe, 0);
#in(40000, \&dosweep,0);
#in(40000, \&dobd,0);
#in(40000, \&snareon,0);
#in(80000, \&clickoff, 0);
#kernel
while ($nsamp < 44100*110) {
    last unless @ev;
    @ev = sort { $a->[0] <=> $b->[0] } @ev;
    my $ev = shift(@ev);
    my $diff = $ev->[0] - $nsamp;
    delay($diff);
    ($ev->[1])->();
}

end();
print STDERR "datasize=".length($data)."\n";
$eofoff = length($data)+64-4;

my $header=pack"A4VVVVVVVVVVVVVVV",
    "Vgm ", $eofoff, 0x150, $clock,
    0, 0, $nsamp, $loopoff, 
    $loopsamp, 50, 0x000f0003, 0,
    0, 12, 0, 0;
print $header.$data;
