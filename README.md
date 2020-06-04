calc_RPKM
---------
Scripts to calcuate RPKM values for genes/exons/regions with mapped RNA-seq data.  
\*RPKM; <ins>R</ins>eads per <ins>K</ins>ilobase of exon per <ins>M</ins>illion mapped sequence <ins>R</ins>eads   

Features
---------
The scripts designed to calculate RPKM values for genomic elements in ***variable sizes***, like genes, exons, and even certain regions of introns or intergenic regions. 
It is useful to assess transcriptinal profiles of the genomic elements in several aspects.
See examples the refference; [Takeuch *et al.* 2018. *Cell Rep.*](https://doi.org/10.1016/j.celrep.2018.03.141 "DOI"), Fig 3 or Fig. 4. 
In the scripts, base-wise depth is calculated initially (.depth files), then calculate read numbers on each region based on total depths and average length of RNA-seq reads (See the document for detail.)

Author
---------
Kei IIDA, iida.kei.3r@kyoto-u.ac.jp

Requirement
---------
 * Perl is required.  
  (The current version is tested on 64 bit Linux.)
 * samtools is required.
 
DEMO
---------
This demo is for calculate RPKM values Initial- and Terminal-10kb-regions of introns of the mouse genes.  
Genes on chr17, chr18, and chr19 in the genome annotaion GRCm38.p4 from Refseq is used.  
A directory ./test_files/bam_files_SE/ contains test bam files used with STAR aligner.  
See detail for the bam files; [Takeuch *et al.* 2018. *Cell Rep.*](https://doi.org/10.1016/j.celrep.2018.03.141 "DOI") and [GSE60241](https://www.ncbi.nlm.nih.gov/geo/query/acc.cgi?acc=GSE60241 "NCBI GEO").

Awk is used for make batch files, Can be replaced any others.
```
#At the Downloaded Directory
#For Single-end RNA-seq data
$./scripts/make_bat__sam2depth_SE.pl  ./test_files/bam_files_SE/ Depth.dir Junction.dir RPM 1 stranded > sam2coverage_SE.bat
$chmod +x sam2coverage_SE.bat
$./sam2coverage_SE.bat

#For Single-end RNA-seq data 
$./scripts/make_bat__sam2depth_PE.pl test_files/bam_files_PE/ Depth.dir Junction.dir RPM 1 stranded > sam2coverage_PE.bat

#Make Index for the .depth files
$ls Depth.dir/*.depth |awk '{print "./scripts/make_index.pl " $1}' > make_index.bat
$chmod +x make_index.bat
$./make_index.bat

#Prepare bed file for the target of calculate RPKM
$./scripts/print_Introns.pl test_files/refseq_mm10_GRCm38.p4.representative.chr17_chr19.bed > refseq_mm10_GRCm38.p4.representative.chr17_chr19.introns.bed
$awk '{if ($3 - $2 >= 20000) print}' refseq_mm10_GRCm38.p4.representative.chr17_chr19.introns.bed > refseq_mm10_GRCm38.p4.representative.chr17_chr19.introns.o20k.bed
$./scripts/make_IniTerRegion.pl refseq_mm10_GRCm38.p4.representative.chr17_chr19.introns.o20k.bed 10000 > refseq_mm10_GRCm38.p4.representative.chr17_chr19.introns.o20k.Ini_Ter_10k.bed
$./scripts/make_bat__calc_RPKM.pl refseq_mm10_GRCm38.p4.representative.chr17_chr19.introns.o20k.Ini_Ter_10k.bed Depth.dir RPKM.dir 100 > calc_RPKM.bat
$chmod +x calc_RPKM.bat
$./calc_RPKM.bat

#Results were found in the directory; RPKM.dir
```


 ---------
