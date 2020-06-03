#!/usr/bin/perl
use strict;

if(@ARGV != 1){
   print "perl $0 foo.bed\n";
   exit(0);
}

open(F,$ARGV[0]) || die "Cannot open the file $ARGV[0]\n";
my @linesB = (); #BED Format
@linesB = <F>;
chomp(@linesB);
close(F);

my @linesD = @{&bed2dat(\@linesB)}; #Convert to Dat Format
my @outD = ();
foreach (@linesD){
   my @tmp = ();
   @tmp = split(/\t/,$_);
   if($tmp[5] !~ /\.\./){
      $tmp[5] = $tmp[3] . ".." . $tmp[4];
   }
   my @tmp2 = ();
   @tmp2 = split(/,/,$tmp[5]);
   if($tmp[1] == 1){
      my $i2 = 0;
      for(my $i=1;$i<@tmp2;$i++){
         $i2++;
         my @tmp3 = ();
         @tmp3 = split(/\.\./,$tmp2[$i-1]);
         my @tmp4 = ();
         @tmp4 = split(/\.\./,$tmp2[$i]);
         my $ll = sprintf "%s.I%s\t%s\t%s\t%s\t%s",$tmp[0],$i2,$tmp[1],$tmp[2],$tmp3[1]+1,$tmp4[0]-1;
         push(@outD,$ll);
      }
   }elsif($tmp[1] == 0){
      my $i2 = 0;
      for(my $i=$#tmp2;$i>=1;$i--){
         $i2++;
         my @tmp3 = ();
         @tmp3 = split(/\.\./,$tmp2[$i-1]);
         my @tmp4 = ();
         @tmp4 = split(/\.\./,$tmp2[$i]);
         my $ll = sprintf "%s.I%s\t%s\t%s\t%s\t%s",$tmp[0],$i2,$tmp[1],$tmp[2],$tmp3[1]+1,$tmp4[0]-1;
         push(@outD,$ll);
      }
   }else{
      print "ERROR! Unknown Direction; $tmp[1]\n";
      exit(0);
   }
}

my @outB = @{&dat2bed(\@outD)}; #Convert to BED Format
printf "%s\n",join("\n",@outB);

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

sub dat2bed{
   my @lines = @{$_[0]};
   my @out = ();
   foreach (@lines){
      my @tmp = ();
      @tmp = split(/\t/,$_);
      my $dir = $tmp[1];
      my $dir2 = "";
      if($dir eq "1"){
         $dir2 = "+";
      }elsif($dir eq "0"){
         $dir2 = "-";
      }else{
         print "ERROR!\n";
         exit(0);
      }
      my $id = $tmp[0];
      my $chr = $tmp[2];
      my $s = $tmp[3];
      my $e = $tmp[4];
      if($tmp[5] !~ /\.\./){
         $tmp[5] = sprintf("%s..%s",$tmp[3],$tmp[4]);
      }
      
      my @tmp2 = ();
      @tmp2 = split(/,/,$tmp[5]);
      my $e_num = @tmp2;
      my @box1 = ();
      my @box2 = ();
      foreach my $tt (@tmp2){
         my @tmp3 = ();
         @tmp3 = split(/\.\./,$tt);
         push(@box1,sprintf("%d",$tmp3[1] - $tmp3[0] + 1));
         push(@box2,sprintf("%d",$tmp3[0] - $s));
      }
      push(@box1,"");
      push(@box2,"");
      my $ll= sprintf "%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s",
                   $chr,$s-1,$e,$id,"0",$dir2,$e,$e,"0",$e_num,join(",",@box1),join(",",@box2);
      push(@out,$ll);
   }
   return(\@out);
}
