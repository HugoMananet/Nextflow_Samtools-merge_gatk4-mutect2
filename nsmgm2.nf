#!/usr/bin/env nextflow

ref = file(params.ref)
ref_index = file(params.ref+'.fai')
ref_dict = file(params.dict)


bamfile = Channel.fromPath(params.initfilesdir+'/*.bam').toList()

process samtools_merge{

	publishDir "${params.resdir}/", mode: 'copy'
	// label 'samtools'

	input:
	file (bamlist) from bamfile


	output:
	file ("allbams_merged.bam") into merged_bam


	"""
	samtools merge \
	-@ 6 \
	allbams_merged.bam \
	${bamlist}
	"""

}


process gatk_change_sample_names{

	publishDir "${params.resdir}/", mode: 'copy'
	// label 'gatk'

	input:
	file (bam_merged) from merged_bam


	output:
	file ("allbams_merged_RG_SM.bam") into merged_bam_RG_SM


	"""
	gatk AddOrReplaceReadGroups \
	-I ${bam_merged} \
	-O allbams_merged_RG_SM.bam \
	-LB lib1 \
	-PL illumina \
	-PU unit1 \
	-SM test_data
	"""

}


process samtools_index{

	publishDir "${params.resdir}/", mode: 'copy'
	// label 'samtools'

	input:
	file (bams_merged_RG_SM) from merged_bam_RG_SM


	output:
	file ("${bams_merged_RG_SM}.bai") into merged_bam_RG_SM_index


	"""
	samtools index \
	-b \
	${bams_merged_RG_SM} \
	${bams_merged_RG_SM}.bai
	"""

}

process gatk_mutect2{

	publishDir "${params.resdir}/", mode: 'copy'
	// label 'gatk'


	input:
	file (bams_merged_RG_SM) from merged_bam_RG_SM
	file (bams_merged_index) from merged_bam_RG_SM_index
	file (ref) from ref
	file (index) from ref_index
	file (dictionary) from ref_dict

	output:
	file ("restest_mutect2_tumoronly.vcf.gz")

	"""
	gatk --java-options -Xmx18g Mutect2 \
	-R ${ref} \
	-I ${bams_merged_RG_SM} \
	-tumor-sample test_data \
	-O restest_mutect2_tumoronly.vcf.gz
	"""


}
