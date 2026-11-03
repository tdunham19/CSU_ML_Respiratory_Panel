// Copyright (c) the nf-core community under an open-source MIT license.
// See https://github.com/nf-core/modules for full license, file patching instructions and upstream contributing.

process CLEAN_BAM_HEADER {
    tag "${meta.id}"
    label 'process_single'

    conda "${moduleDir}/environment.yml"
    container "${workflow.containerEngine in ['singularity', 'apptainer'] && !task.ext.singularity_pull_docker_container
        ? 'https://community-cr-prod.seqera.io/docker/registry/v2/blobs/sha256/87/87660348a4d032cc08d6ac8101ff9d4d27164300d39c9472043bb5001f9ba801/data'
        : 'community.wave.seqera.io/library/htslib_samtools:1.25--704fb80d75745bd4'}"

    input:
    tuple val(meta), path(bam)

    output:
    tuple val(meta), path("${bam.simpleName}.clean.bam"), emit: bam
    tuple val(meta), path("${bam.simpleName}.clean.bam.bai"), emit: bai    
    tuple val("${task.process}"), val('samtools'), eval("samtools version | sed '1!d;s/.* //'"), emit: versions_samtools, topic: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def prefix = task.ext.prefix ?: "${meta.id}"

    """
    ref=\$(samtools idxstats ${bam} | awk '\$3 > 0 {print \$1}')

	samtools view -h ${bam} \
	| awk -v ref="\$ref" '
	BEGIN { keep=0 }

	/^@SQ/ {
    	if (\$0 ~ "SN:" ref "(\t|\$)") print
    	next
	}

	/^@/ {
    	print
    	next
		}
	{
    if (\$3 == ref) print
	}
	' \
	| samtools view -b -o ${bam.simpleName}.clean.bam -

	samtools index ${bam.simpleName}.clean.bam
    """

    stub:
    def prefix = task.ext.prefix ?: "${meta.id}"

    """
    touch ${prefix}.idxstats
    """
}
