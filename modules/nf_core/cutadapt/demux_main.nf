// Copyright (c) the nf-core community under an open-source MIT license.
// See https://github.com/nf-core/modules for full license, file patching instructions and upstream contributing.

process DEMUX {
    tag "$meta.id"
    // label 'process_medium'
    label "no_publish"

    conda "${moduleDir}/environment.yml"
    container "${workflow.containerEngine in ['singularity'] && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/cutadapt:5.2--py311haab0aaa_0' :
        'quay.io/biocontainers/cutadapt:5.2--py311haab0aaa_0'}"


    input:
    tuple val(meta), path(inputreads)
    tuple val(meta3), path(barcode)

    output:
    tuple val(meta), path('*_demux.fastq.gz')        , emit: reads
    tuple val(meta), path("*_unclassified.fastq.gz") , emit: unclassified
    tuple val(meta), path('*.log')                   , emit: log
    tuple val("${task.process}"), val("cutadapt")    , eval('cutadapt --version'), topic: versions, emit: versions_cutadapt

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    cutadapt \\
        --cores $task.cpus \\
        -g file:$barcode \\
        --action=none \\
        -e 0 \\
        --no-indels \\
        -o {name}_demux.fastq.gz \\
        --untrimmed-output ${prefix}_unclassified.fastq.gz \\
        $inputreads \\
        > ${prefix}.cutadapt.log     
    """

    stub:
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    ${output_command}
    touch ${prefix}.cutadapt.log
    """
}
