#!/usr/bin/perl
use strict;

if(@ARGV != 4){
   print "perl $0 Gene_Models.txt Coverage_DIR Result_DIR Average_Length_of_Reads\n";
   exit(0);
}

my @tmp = ();
@tmp = split(/\//,$0);
my $path = "";
if(@tmp >= 2){
   $path = join("/",@tmp[0..$#tmp-1]);
}else{
   $path = ".";
}

my $f1 = $ARGV[0];
if(!-e $f1){
   print "ERROR! No File; $f1\n";
   exit(0);
}

my @files2 = glob("$ARGV[1]/*.depth");
if(@files2 == 0){
   print "ERROR! No Depth file(s) in the directory;$ARGV[1]\n";
   exit(0);
}

my $OUT_DIR = $ARGV[2];
if(!-e $OUT_DIR){
   system "mkdir $OUT_DIR";
}

my $READ_LEN = $ARGV[3];

my $script = $path . "/" . "calc_RPKM.pl";
foreach my $f2 (@files2){
   my $f2a = (split(/\//,$f2))[-1];
   $f2a =~ s/\.depth//;
   my $out = $OUT_DIR . "/"  . $f2a . ".RPKM.txt";
   print "$script $f1 $f2 $READ_LEN > $out\n";
}
