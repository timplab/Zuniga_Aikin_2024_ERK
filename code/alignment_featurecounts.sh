# Commands were run in a conda environment set up in the following way:
conda create -n regot_rna					
conda activate regot_rna						
conda install -c bioconda hisat2=2.2.1					
conda install -c bioconda samtools=1.7				
conda install -c bioconda subread=2.0.1	

# Important paths
reference_dir=/mithril/Data/NGS/projects/regot_rna/reference/grch38_masked
data_dir=/mithril/Data/NGS/projects/regot_rna/data/220128_wtimp1_EMT_novaseq
alignment_dir=/mithril/Data/NGS/projects/regot_rna/data/220128_wtimp1_EMT_novaseq/alignments
quant_dir=/mithril/Data/NGS/projects/regot_rna/data/quant

# Download hg38 reference sequence
wget https://ftp-trace.ncbi.nlm.nih.gov/ReferenceSamples/giab/release/references/GRCh38/GCA_000001405.15_GRCh38_no_alt_analysis_set_maskedGRC_exclusions_v2.fasta.gz -P $reference_dir

# Unpack fasta.gz
gunzip $reference_dir/GCA_000001405.15_GRCh38_no_alt_analysis_set_maskedGRC_exclusions_v2.fasta.gz

# make hisat2 index dir
mkdir $reference_dir/hisat2_index

# create hisat2 index
hisat2-build -p48 $refrence_dir/GCA_000001405.15_GRCh38_no_alt_analysis_set_maskedGRC_exclusions_v2.fasta $reference_dir/hisat2_index/masked_grch38

# move into the data dir
cd $data_dir

# for loop for aligning RNA-seq reads using hisat2
for i in `ls -v *wtimp*fastq.gz | cut -d "_" -f 1-5 | uniq`
do
hisat2 \
-p 48 \
--seed 24 \
--summary-file $alignment_dir/align_summary/${i}_summary \
--no-mixed \
--no-discordant \
--no-unal \
-x $reference_dir/hisat2_index/masked_grch38 \
-1 $data_dir/${i}_L001_R1_001.fastq.gz,$data_dir/${i}_L002_R1_001.fastq.gz -2 $data_dir/${i}_L001_R2_001.fastq.gz,$data_dir/${i}_L002_R2_001.fastq.gz \
-S $alignment_dir/${i}_hisat2.sam
done

# move into the alignment dir
cd $alignment_dir

# for loop for converting .sam to a sorted .bam
for i in `ls -v *.sam`
do
samtools view -@48 -bS $i | samtools sort -@48 - > $alignment_dir/bams/sorted_${i%.sam}.bam
done

# download gene annotation
wget https://ftp.ebi.ac.uk/pub/databases/gencode/Gencode_human/release_39/gencode.v39.annotation.gtf.gz -P $reference_dir

# get gene counts using featureCounts
featureCounts -T48 -p -B --primary -t exon -g gene_id -a $reference_dir/gencode.v39.annotation.gtf.gz -o $quant_dir/regot_counts.txt $alignment_dir/bams/*bam
