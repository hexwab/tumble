#!/usr/bin/perl -w
undef $/;
$v=<>; # slurp
my $out;

sub byte { unpack"C",substr($v,0,1,'') }
sub word { unpack"v",substr($v,0,2,'') }
sub put { $out.=pack"C",shift }
sub putw { $out.=pack"n",shift }
substr($v,0,64,'');# skip header
putw(0);
while (length $v) {
    #print "vlen=".length($v)."\n";
    my $cmd = byte();
    if ($cmd == 0x50) {
	my $b=byte();
	die if $b<0x40;
	put($b);
    } elsif ($cmd == 0x61) {
	my $del = word();
	my $d = int($del*1e6/44100);
	#print STDERR sprintf "del=$del d=%04x\n", $d;
	#warn if $d>16383;
	while ($d>0x3fff) {
	    putw(0x3ffd);
	    $d-=0x3fff;
	} 
	putw($d-2);
    } elsif ($cmd == 0x66) {
	# nothing
    } else {
	die "$cmd";
    }
}
putw(0x3fff);

print $out;
