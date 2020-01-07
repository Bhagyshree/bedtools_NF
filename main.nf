#!/usr/bin/env nextflow

/**************
* Parameters
**************/

params.files  =   "/scratch-cbe/users/bhagyshree.jamge/DANPOS_Dec2019/*.bed"
params.outdir = "Danpos_Bedtools_results"
params.featuresDir="/scratch-cbe/users/bhagyshree.jamge/annot/annot_refined/annot_metaplots/bedtools_annot/"
log.info """\
outdir  : ${params.outdir}
"""


/**************
* Start
**************/
// first put all bed files into channel "bedfiles"

bedfiles = Channel
  .fromPath(params.files)
  .map { file -> [ file.baseName, file] }
// each item in the channel has a file name and an actual file


featurefiles = ['PCG','TEG','TE','TEG_TSS','TEG_Promoter','TEG_GB']

/*************
* processes for sortBED
*************/


process sortBED {
	label 'env_bed_small'
	tag "$id"
	publishDir "$params.outdir/SORTED_signalFiles",mode:'copy'

    input:
    set id, file(bam) from bedfiles

    output:
    set val(id), file('*_sorted.bed') into sorted_bed

    script:
    """
	sort -k1,1 -k2,2n ${bam} > ${id}_sorted.bed
    """
    }



/**************
* any_feature
**************/
process avg_feature {
	publishDir "$params.outdir/${fid}",mode:'copy'
	label 'env_bed_small'

	input:
	set id, file(input) from sorted_bed
	each fid from featurefiles
	
	output:
	set id, file("${id}_${fid}.bed") into feature_results
	file("${id}_${fid}.bed")



	script:
	"""
	bedtools map -a ${params.featuresDir}/${fid}.bed -b ${input} -null -c 5 -o sum | cat > ${id}_${fid}.bed
	"""
}


workflow.onComplete {
	println ( workflow.success ? "Successfull!" : "Messed Up something" )
}
