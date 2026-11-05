process COUNT_DEMUX_READS {

    tag "$meta.id"
    label 'process_single'

    input:
    tuple val(meta), path(fastq)

    output:
    tuple val(meta), path(fastq), path("count.txt")

    script:
    """
    zcat ${fastq} | awk 'END {print NR/4}' > count.txt
    """
}