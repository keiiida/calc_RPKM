#!/usr/bin/perl
use strict;

if(@ARGV != 6){
   print "perl $0 bam_directory Output_for_Depth Output_for_JunctionReads RAW/RPM Target_Size_for_Normalization(Ignored if RAW mode)  Direction(stranded or unstranded)\n";
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

my $target = $ARGV[4];
my $mode = "";
if($ARGV[3] eq "RAW"){
   $mode = "RAW";
   $target = "x";
}elsif($ARGV[3] eq "RPM"){
   $mode = "RPM";
}else{
   print "ERROR! Mode must be RAW or RPM.\n";
   exit(0);
}

my $script = $path . "/sam2depth_SE.pl";
my $strand_mode = "";
if($ARGV[5] =~ /^stranded$/i){
   $strand_mode = "stranded";
}elsif($ARGV[5] =~ /^unstranded$/i){
   $strand_mode = "unstranded";
}else{
   print "ERROR! set dir or nodir on ARGV[5].\n";
   exit(0);
}

my $dir1 = $ARGV[0];
$dir1 =~ s/\/$//;
if(!-d $dir1){
   print "ERROR! Cannot find $dir1\n";
   exit(0);
}

my $dir2 = $ARGV[1];
$dir2 =~ s/\/$//;
if(!-d $dir2){
   print "#mkdir $dir2\n";
   system "mkdir $dir2";
}

my $dir3 = $ARGV[2];
$dir3 =~ s/\/$//;
if(!-e $dir3){
   my $CMD = "mkdir $dir3";
   print "#$CMD\n";
   system "$CMD";
}

my $CMD0 = sprintf ("%s XXX %s %s YYY %s %s %s %s/YYY.scaling.log",$script,$dir2,$dir3,$mode,$target,$strand_mode,$dir2);

my @files = glob("$dir1/*.bam");
foreach my $f (@files){
   my $sig = (split(/\//,$f))[-1];
   $sig =~ s/\.bam//;
   my $CMD = $CMD0;
   $CMD =~ s/XXX/$f/g;
   $CMD =~ s/YYY/$sig/g;
   printf "$CMD\n";
}
