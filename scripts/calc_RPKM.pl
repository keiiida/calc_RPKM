#!/usr/bin/perl
use strict;

if(@ARGV != 3){
   printf "perl $0 gene_modesl.dat depth Average_Length_of_Reads\n";
   exit(0);
}

my $READ_LEN = $ARGV[2];
if($READ_LEN <= 0){
   print "READ_LEN must be >= 0.\n";
   exit(0);
}

my $STEP = 100000;
my $GETA = 1000;
my $datREAD = $ARGV[1]; #For Depth
my @tmp = ();
@tmp = split(/\//,$datREAD);
my $datREAD0 = $tmp[-1];
my $datREAD_dir = join("/",@tmp[0..$#tmp-1]);
my @index_files = glob("$datREAD_dir/chr*/$datREAD0.Index");
my %fp_hash = ();
foreach my $f (@index_files){
   open(F,$f) || die "Cannot open index file:$f\n";
   while(<F>){
      chomp($_);
      my @tmp = ();
      @tmp = split(/\t/,$_);
      my $dev_datREAD = $f;
      $dev_datREAD =~ s/\.Index//;
      $fp_hash{$dev_datREAD}{$tmp[0]} = $tmp[1];
   }
   close(F);
}

my %dir_hash = (
"1" => "P",
"0" => "M"
);


open(F,$ARGV[0]) || die "Cannot open the input file; $ARGV[0]\n";
my @linesB = (); #BED Format
@linesB = <F>;
chomp(@linesB);
close(F);

my @linesD = @{&bed2dat(\@linesB)}; #Convert to Dat Format
print "#ID\tRegion_Length\tRPM(Lib-Size Normalization Depends on Depth File)\tRPKM\n";
foreach (@linesD){
   my $line = $_;
   my @tmp = ();
   @tmp = split(/\t/,$_);
   my $id = $tmp[0];
   my $chr = $tmp[2];
   my $dir = $tmp[1];
   my $start = $tmp[3];
   my $end = $tmp[4]; 
   if($tmp[5] !~ /\.\./){
      $tmp[5] = $tmp[3] . ".." . $tmp[4];
   }
   my @exons = split(/,/,$tmp[5]);
   my $len = 0;
   foreach my $tt (@exons){
      my @tmp2 = ();
      @tmp2 = split(/\.\./,$tt);
      $len = $len + $tmp2[1] - $tmp2[0] + 1;
   }

   my $dev_datREAD = $datREAD_dir . "/" . $chr . $dir_hash{$dir} . "/" . $datREAD0;
   if(!-e $dev_datREAD){
      printf "%s\t%.4f\n",$id,0;
      next;
   }

   open(F2,$dev_datREAD) || die "Cannot open the depth file; $dev_datREAD\n";
   my $start2 = int (($start - $GETA) / $STEP ) * $STEP;
   if($start2 < 0){
      $start2 = 0;
   }
  
   if($fp_hash{$dev_datREAD}{$start2} eq ""){
      printf "%s\t%.4f\n",$id,0;
      next;
   }
   seek F2,$fp_hash{$dev_datREAD}{$start2},0;
   my %ex_count = ();
   while(<F2>){
      chomp($_);
      my @tmp = ();
      @tmp = split(/\s+/,$_);
      if($tmp[1] >= $start && $tmp[0] <= $end){ # for checkin overlap
         for(my $i=$tmp[0];$i<=$tmp[1];$i++){
            $ex_count{$i} += $tmp[2];
         }
      }
      if($tmp[0] > $end){
         last;
      }
   }
   close(F2);

   my $sum = 0; #For counting sum of depth
   my $t = 0; #For counting region rength
   foreach my $tt (@exons){
      my @tmp2 = ();
      @tmp2 = split(/\.\./,$tt);
      for(my $i=$tmp2[0];$i<=$tmp2[1];$i++){
         $sum += $ex_count{$i};
         $t++;
      }
   }
   my $rpm = $sum / $READ_LEN; 
   my $rpkm = $rpm * 1000 / $t; 
   printf "%s\t%d\t%.4f\t%.4f\n",$id,$t,$rpm,$rpkm;
} 
#//main

sub bed2dat{
   my @lines = @{$_[0]};
   my @out = ();
   foreach (@lines){
      my @tmp = ();
      @tmp = split(/\t/,$_);
      my $chr = $tmp[0];
      my $id = $tmp[3];
      my $dir0 = $tmp[5];
      my $dir = $dir0;
      $dir =~ tr/+-/10/;
      my $start = $tmp[1] + 1;
      my @tmp2 = ();
      @tmp2 = split(/,/,$tmp[10]);
      my @tmp3 = ();
      @tmp3 = split(/,/,$tmp[11]);
      my @exons = ();
      for(my $i=0;$i<@tmp2;$i++){
         if($tmp2[$i] eq ""){
            next;
         }
         push(@exons,sprintf("%s..%s",$start+$tmp3[$i],$start+$tmp3[$i]+$tmp2[$i]-1));
      }
      my $end = (split(/\.\./,$exons[-1]))[1];
      if($dir eq '.'){
         next;
      }
      my $ll = sprintf "%s\t%s\t%s\t%s\t%s\t%s",$id,$dir,$chr,$start,$end,join(",",@exons);
      push(@out,$ll);
   }
   return(\@out);
}
