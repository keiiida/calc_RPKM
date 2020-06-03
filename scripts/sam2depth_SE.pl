#!/usr/bin/perl
use strict;

if(@ARGV != 8 || 
   ($ARGV[4] ne "RAW" && $ARGV[4] ne "RPM")){
   print "perl $0 IN_FILE OUT_DIR(EXON) OUT_DIR(INTRON) SIG RAW/RPM Norm_param(Million reads) stranded/unstranded LOG_FILE\n";
   print "samtools is required.\n";
   exit(0); 
}

my @tmp = ();
@tmp = split(/\//,$0);
my $path = join("/",@tmp[0..$#tmp-1]);

my %dir_hash = ();
if($ARGV[6] =~ /^stranded$/){
   %dir_hash = (
      "F"  => "Plus",
      "R"  => "Minus",
   );
}elsif($ARGV[6] =~ /^unstranded$/){
   %dir_hash = (
      "F"  => "Plus",
      "R"  => "Plus",
   );
}else{
   print "ERROR! Starand mode must be stranded or unstranded\n"+
   exit(0);
}

my $log_file = $ARGV[7];

my $RPM = 0;
my $NORM = 0;
if($ARGV[4] eq "RPM"){
   $RPM = 1;
   $NORM = $ARGV[5] * 1000000;
}else{
   $RPM = 0;
   $NORM = "RAW";
}

my $OUT_DIR = $ARGV[1];
$OUT_DIR =~ s/\/$//;
if(! -e $OUT_DIR){
   my $CMD = "mkdir $OUT_DIR";
   print "$CMD\n";
   system "$CMD";
}

my $OUT_DIR_INTRON = $ARGV[2];
$OUT_DIR_INTRON =~ s/\/$//;
if(! -e $OUT_DIR_INTRON){
   my $CMD = "mkdir $OUT_DIR_INTRON";
   print "$CMD\n";
   system "$CMD";
}

my $SIG = $ARGV[3];
my $f = $ARGV[0];
if($f !~ /\.bam$/){
   print "ERROR FILE TYPE $f\n";
   exit(0);
}

my $f_bai = $f . ".bai";
if(!-e $f_bai){
   print "#There is no index file; $f_bai\n";
   my $CMD = "samtools index $f";
   print "#$CMD\n"; 
   system "$CMD";
}

#Count Unmapped
open(F,"samtools view -f 0x4 -c $f|") || die "Cannot open the file; $f, with samtools\n";
my $tt = <F>;
close(F);
chomp($tt);
my $unmapped = $tt;

#Count Primary, total reads
open(F,"samtools view -F 0x100 -c $f|") || die "Cannot open the file; $f, with samtools\n";
my $tt = <F>;
close(F);
chomp($tt);
my $READS = $tt - $unmapped;

#Check multiple mapping
my %nh_mem = ();
open(F,"samtools view -f 0x100 $f|") || die "Cannot open the file; $f, with samtools\n";
while(<F>){
   $nh_mem{ (split(/\t/,$_))[0] }++;
}
close(F);

my $multi=0;
my %count_count = ();
foreach my $id (keys %nh_mem){
   $nh_mem{$id}++; #Add 1 for the primary alignment
   $count_count{$nh_mem{$id}}++;
   $multi++;
}
$count_count{"1"} = $READS - $multi;

my $multi_hits_report = $OUT_DIR . "/" . $SIG . ".MultiHitsReport.txt";
open(F,"> $multi_hits_report") || die "Cannot open the file; $multi_hits_report\n";
printf F "#_of_Hits\tCounts\tFraction\tCumulative_Fractions\n";
my $ss = 0;
foreach my $count (sort {$a <=> $b} keys %count_count){
   $ss += $count_count{$count};
   printf F "%s\t%s\t%.6f\t%.6f\n",$count,$count_count{$count},$count_count{$count}/$READS,
                                   $ss/$READS;
}
close(F);

my $RATIO = 0;
if($RPM){
   $RATIO = $NORM / $READS;
}else{
   $RATIO = 1;
}

if(! -e $log_file){
   open(F,"> $log_file") || die "Cannot open the file to write; $log_file\n";
   printf F "#%s\t%s\t%s\t%s\t%s\n",
                "Date","File","#_of_Reads","Nomarization_Target(Millions_Reads)","Ratio";
}else{
   open(F,">> $log_file") || die "Cannot open the file to write; $log_file\n";
}
open(F2,"LANG=C;date |");
my $date = <F2>;
close(F2);
chomp($date);

printf F "%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n",$date,$f,$READS,$NORM,$RATIO;
close(F);

my %dir2 = ("Plus" => 1,
            "Minus" => 0);

open(F,"samtools idxstats $f|") || die "Cannot open the file; $f, with samtools\n";
my @c_box = (); #Chromosome box
while(<F>){
   chomp($_);
   my @tmp = ();
   @tmp = split(/\t/,$_);
   if($tmp[0] ne '*'){
      push(@c_box,$tmp[0]);
   }
}
close(F);
@c_box = sort { ($b =~ m/chr\d+/) <=> ($a =~ m/chr\d+/) or
                ($b =~ m/chr[A-Z]+/) <=> ($a =~ m/chr[A-Z]+/) or
                substr($a,3) <=> substr($b,3) or 
                $a cmp $b } @c_box;
my %ini_flag = ();
foreach my $chr (@c_box){
   open(F,"samtools view $f $chr|") || die "Cannot open the file; $f, with samtools\n";
   my %count2  = ();
   my %count2I = ();
   while(<F>){
      my @tmp = ();
      @tmp = split(/\t/,$_);
      if($tmp[2] eq '*'){
         next;
      }
      my $nh = 0; 
      if($nh_mem{$tmp[0]} ne ""){
         $nh = $nh_mem{$tmp[0]};
      }else{  
         $nh = 1;
      }
      my $count_tmp = 1; 
      if($RPM == 1){
         $count_tmp = 1/$nh*$RATIO;
      }else{
         $count_tmp = 1/$nh;
      }
   
      my $Hit_info = $tmp[5];
      #Fix InDel and SoftClipping
      $Hit_info =~ s/\d+S//g;
      $Hit_info =~ s/\d+I//g;
      $Hit_info =~ s/D/M/g;
   
      while(1){ 
         if($Hit_info =~ /(\d+)M(\d+)M/){ 
            my $t_len = $1 + $2; 
            my $t_len2 = $t_len . "M"; 
            $Hit_info =~ s/$&/$t_len2/;
         }else{
            last;
         }
      }

      my $dir = "";
      my $bb = sprintf "%012b",$tmp[1];
      my $dir0 = "";
      if(substr($bb,-5,1) == 1){
         $dir0 = "R";
      }elsif(substr($bb,-5,1) == 0){
         $dir0 = "F";
      }
      $dir = $dir_hash{$dir0};
      if($dir eq ""){
         next;
      }

      my $left = $tmp[3];
      my @site_box = ();
      my @site_boxI = ();
      while($Hit_info =~ /\d+[MN]/g){
         my $Hit_info2 = $&;
         my $len = 0;
         if($Hit_info2 =~ /(\d+)/){
            $len = $1;
         }else{
            print "ERROR! At Hit_info; $Hit_info\n";
            exit(0);
         }

         #For Location Information
         my $right = $left + $len - 1;
         my $site = $left . ":" . $right;
         $left = $left + $len; #Update the left
    
         if($Hit_info2 =~ /M$/){
            push(@site_box,$site);
         }elsif($Hit_info2 =~ /N$/){
            push(@site_boxI,$site);
         }
      }
     
      if(@site_box == 0){
         next;
      }
      foreach my $site (@site_box){
         $count2{$dir}{$site} += $count_tmp;
      }
      foreach my $site (@site_boxI){
         $count2I{$dir}{$site} += $count_tmp;
      }
   }
   close(F);
      
   foreach my $dir ("Plus","Minus"){
      my $out = $OUT_DIR . "/" . $SIG . ".depth";
      if($ini_flag{$out} != 1){
         open(F2,"> $out") || die "Cannot open the file; $out to write\n";
         $ini_flag{$out} = 1;
      }else{
         open(F2,">> $out") || die "Cannot open the file; $out to write\n";
      } 

      my @b = ();
      @b = sort { (split(/:/,$a))[0] <=> (split(/:/,$b))[0] } keys %{$count2{$dir}};
      foreach my $p (@b){
         my @tmp2 = split(/:/,$p);
         printf F2 "%s\t%s\t%s\t%s\t%s\t%.5f\n","-",$dir2{$dir},$chr,$tmp2[0],$tmp2[1],$count2{$dir}{$p};
      }
      close(F2);
   }
   
   foreach my $dir ("Plus","Minus"){
      my $out = $OUT_DIR_INTRON . "/" . $SIG . ".junction_info";
      if($ini_flag{$out} != 1){
         open(F2,"> $out") || die "Cannot open the file; $out to write\n";
         $ini_flag{$out} = 1;
      }else{
         open(F2,">> $out") || die "Cannot open the file; $out to write\n";
      }

      my @b = ();
      @b = sort { (split(/:/,$a))[0] <=> (split(/:/,$b))[0] } keys %{$count2I{$dir}};
      foreach my $p (@b){
         my @tmp2 = split(/:/,$p);
         printf F2 "%s\t%s\t%s\t%s\t%s\t%.5f\n","-",$dir2{$dir},$chr,$tmp2[0],$tmp2[1],$count2I{$dir}{$p};
      }
      close(F2);
   }
   undef %count2;
   undef %count2I;
}
