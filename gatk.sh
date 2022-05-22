#!/usr/bin/bash
#GATKpipeline
#GIAB 使用简单的hard-filter

gatk=/onc/home/fan_qiangqiang/biosoft/GATK/gatk4180/gatk4180/gatk
#haplotypeCaller
$gatk HaplotypeCaller \
-R ~/gatk_files/human_g1k_v37.fasta \
-L ~/gatk_files/giab_agilent_sureselect_v5.list.bed \
-D ~/gatk_files/dbsnp_138.b37.vcf \
-I 151002_7001448_0359_AC7F6GANXX_Sample_HG003-EEogPU_v02-KIT-Av5_TCTTCACA_L008.posiSrt.markDup.bam  \
-O interval4180/hg003.g.vcf.gz \
-ERC GVCF 

$gatk HaplotypeCaller \
-R ~/gatk_files/human_g1k_v37.fasta \
-L ~/gatk_files/giab_agilent_sureselect_v5.list.bed \
-D ~/gatk_files/dbsnp_138.b37.vcf \
-I 151002_7001448_0359_AC7F6GANXX_Sample_HG004-EEogPU_v02-KIT-Av5_CCGAAGTA_L008.posiSrt.markDup.bam  \
-O interval4180/hg004.g.vcf.gz \
-ERC GVCF

#combineGVCFs
$gatk CombineGVCFs \
-R ~/gatk_files/human_g1k_v37.fasta \
--variant hg002.g.vcf.gz \
--variant hg003.g.vcf.gz \
--variant hg004.g.vcf.gz \
-O corhort.g.vcf.gz

#genotyperGVCFs
$gatk GenotypeGVCFs \
-R ~/gatk_files/human_g1k_v37.fasta \
-V corhort.g.vcf.gz \
-O hg020304.vcf.gz

#hard-filter VCF
$gatk VariantFiltration \
-R ~/gatk_files/human_g1k_v37.fasta \
-V hg020304.vcf.gz \
-O hg020304_hard_filtered.vcf.gz \
--filter-name "QD2.0" --filter-expression "QD < 2.0" \
--filter-name "FS200.0" --filter-expression "FS > 200.0" \
--filter-name "ReadPosRankSum" --filter-expression "ReadPosRankSum < -20.0"

