#!/usr/bin/perl
use strict;

if(@ARGV != 1){
   print "perl make_table_index.pl In_File\n";
   exit(0);
}

my %dir_hash = (
"1" => "P",
"0" => "M"
);

my $STEP = 100000;
my $file = $ARGV[0];
my @tmp = ();
@tmp = split(/\//,$file);
my $file0 = $tmp[-1];
my $out_dir = join("/",@tmp[0..$#tmp-1]);
if($out_dir eq ""){
   $out_dir = ".";
}

open(F,$file) || die "Cannot open the file; $file\n";;
my %box = ();
while(<F>){
   chomp($_);
   my @tmp = ();
   @tmp = split(/\t/,$_);
   push(@{$box{$tmp[2]}{$tmp[1]}},join("\t",@tmp[3..$#tmp]));
}
close(F);

foreach my $chr (sort keys %box){
   foreach my $dir (keys %{$box{$chr}}){  
      my $dir2 = $dir_hash{$dir};
      my $out_dir2 = $out_dir . "/" . $chr . $dir2;
      if(!-e $out_dir2){
         print  "mkdir $out_dir2\n";
         system "mkdir $out_dir2";
      }
      my $out_file = $out_dir2 . "/" . $file0;
      my @box_tmp = sort { (split(/\t/,$a))[0] <=> (split(/\t/,$b))[0]} @{$box{$chr}{$dir}};
      print "Writing: $out_file\n";
      open(F,"> $out_file") || die "Cannot open the output file to write; $out_file\n";
      printf F "%s\n",join("\n",@box_tmp);
      close(F);
      
      my $out_file_index = $out_file . ".Index";
      open(F,$out_file) || die "Cannot open the file; $out_file\n";
      open(F2,"> $out_file_index") || die "Cannot open the index file; $out_file_index\n";
      print "Writing: $out_file_index\n";
      my $pos=0;
      my $FP = tell F;
      while(<F>){
         chomp($_);
         my @tmp = ();
         @tmp = split(/\t/,$_);
         while($tmp[0] >= $pos){
            print "Pos: $pos\n";
            #printf F2 "%s\t%s\t%s\t%s\n",$chr,$dir,$pos,$FP;
            printf F2 "%s\t%s\n",$pos,$FP;
            $pos += $STEP;
         }
         $FP = tell F;
      }
      close(F);
      close(F2);
   }
}
