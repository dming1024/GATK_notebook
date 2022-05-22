#!/usr/bin/bash
#GATKpipeline
#GIAB 使用VQSR

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
-O corhort.g.vGcf.gz

#genotyperGVCFs
$gatk GenotypeGVCFs \
-R ~/gatk_files/human_g1k_v37.fasta \
-V corhort.g.vcf.gz \
-O hg020304.vcf.gz

#可选
#selectVariant
$gatk SelectVariants \
-R ~/gatk_files/human_g1k_v37.fasta \
-V hg020304.vcf.gz \
--select-type-to-include SNP \
-O hg020304_SNP.vcf.gz

$gatk SelectVariants \
-R ~/gatk_files/human_g1k_v37.fasta \
-V hg020304.vcf.gz \
--select-type-to-include INDEL \
-O hg020304_INDEL.vcf.gz

#VQSR，都要用GATK IndexFeatureFile产生index
 hapmap=~/gatk_files/hapmap_3.3.b37.vcf
 omni=~/gatk_files/1000G_omni2.5.b37.vcf
 kG=~/gatk_files/1000G_phase1.snps.high_confidence.b37.vcf
 dbsnp=~/gatk_files/dbsnp_138.b37.vcf
#SNP
$gatk VariantRecalibrator \
   -R  ~/gatk_files/human_g1k_v37.fasta \
   -V hg020304_SNP.vcf.gz \
   --resource:hapmap,known=false,training=true,truth=true,prior=15.0 $hapmap  \
   --resource:omni,known=false,training=true,truth=false,prior=12.0 $omni \
   --resource:1000G,known=false,training=true,truth=false,prior=10.0 $kG \
   --resource:dbsnp,known=true,training=false,truth=false,prior=2.0 $dbsnp \
   -an QD -an MQ -an MQRankSum -an ReadPosRankSum -an FS -an SOR \
   -mode SNP \
   -O output_SNP_vcf.recal \
   --tranches-file output_SNP.tranches

$gatk ApplyVQSR -R ~/gatk_files/human_g1k_v37.fasta \
   -V hg020304_SNP.vcf.gz \
   -O ouput_SNP_recal.vcf.gz \
   --truth-sensitivity-filter-level 99.0 \
   --tranches-file output_SNP.tranches \
   --recal-file output_SNP_vcf.recal \
   -mode SNP

#对INDEL采用hard-filter
$gatk VariantFiltration \
-R ~/gatk_files/human_g1k_v37.fasta \
-V hg020304_INDEL.vcf.gz \
-O output_INDEL_hard_filtered.vcf.gz \
--filter-name "QD2.0" --filter-expression "QD < 2.0" \
--filter-name "FS200.0" --filter-expression "FS > 200.0" \
--filter-name "ReadPosRankSum" --filter-expression "ReadPosRankSum < -20.0" 

 
 #INDEL 需要分开处理,(原始VCF文件可以不需要分开，但是在做recalibrator时，需要针对原始文件进行依次SNP,INDEL的处理)
 kgindel=~/gatk_files/1000G_phase1.indels.b37.vcf
 stdinde=~/gatk_files/Mills_and_1000G_gold_standard.indels.b37.vcf
 $gatk VariantRecalibrator \
   -R  ~/gatk_files/human_g1k_v37.fasta \
   -V ouput_INDEL_vcf.gz \
   --resource:mills,known=false,training=true,truth=true,prior=15.0 $stdinde  \
   -an QD -an MQ -an MQRankSum -an ReadPosRankSum -an FS -an SOR \
   -mode INDEL \
   -O output_INDEL_vcf.recal \
   --tranches-file output_INDEL.tranches
 
#将以上分开处理得到的文件进行merge
$gatk MergeVcfs \
-I ouput_SNP_recal.vcf.gz \
-I output_INDEL_hard_filtered.vcf.gz \
-O hg020304_SNP_INDEL_filtered.vcf.gz
 