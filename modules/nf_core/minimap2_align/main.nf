// Copyright (c) the nf-core community under an open-source MIT license.
// See https://github.com/nf-core/modules for full license, file patching instructions and upstream contributing.

process MINIMAP2_ALIGN {
    tag "$meta.id"
    label 'process_high'

    // Note: the versions here need to match the versions used in the mulled container below and minimap2/index
    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine in ['singularity', 'apptainer'] && !task.ext.singularity_pull_docker_container ?
        'https://community-cr-prod.seqera.io/docker/registry/v2/blobs/sha256/37/37671219cfd244eb9b33db9345d3543ffd83037419a1c57f4648aace493ec2c2/data' :
        'community.wave.seqera.io/library/minimap2_samtools:b09096fc890429ce' }"

input:
tuple val(meta), path(reads)
tuple val(meta2), path(reference)
val (suffix) // filename suffix

output:
  tuple val(meta), path("*.sam")                       , emit: sam
  tuple val(meta), path("*.bam")                       , emit: bam
  tuple val(meta), path(reference)                     , emit: reference
  tuple val(meta), path("*.bam"), path(reference)      , emit: bam_reference
  path ("versions.yml")                                , emit: versions

  script:
  """
  minimap2 -ax map-ont $reference $reads | samtools view -h -F 4 > ${meta.id}.${suffix}.sam 
  samtools sort -O bam ${meta.id}.${suffix}.sam  > ${meta.id}.${suffix}.bam

  cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        minimap2: \$(minimap2 --version 2>&1)
        samtools: \$(echo \$(samtools --version 2>&1) | sed 's/^.*samtools //; s/Using.*\$//')
    END_VERSIONS
  """
}

process MINIMAP2_ALIGN_CONSENSUS {
	tag "$meta.id"
    label 'process_high'

    // Note: the versions here need to match the versions used in the mulled container below and minimap2/index
    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine in ['singularity', 'apptainer'] && !task.ext.singularity_pull_docker_container ?
        'https://community-cr-prod.seqera.io/docker/registry/v2/blobs/sha256/37/37671219cfd244eb9b33db9345d3543ffd83037419a1c57f4648aace493ec2c2/data' :
        'community.wave.seqera.io/library/minimap2_samtools:b09096fc890429ce' }"

  input:
  tuple val(meta),  path(reads), path(refseq)
  val (suffix) // filename suffix

  output:
  tuple val(meta), path("*.sam")                       , emit: sam
  tuple val(meta), path("*.bam")                       , emit: bam
  tuple val(meta), path(refseq)                        , emit: refseq
  tuple val(meta), path("*.bam"), path(refseq)         , emit: bam_refseq
  path ("versions.yml")                                , emit: versions

  script:
  """
  minimap2 -ax map-ont $refseq $reads | samtools view -h -F 4 > ${meta.id}_${suffix}.sam 
  samtools sort -O bam ${meta.id}_${suffix}.sam  > ${meta.id}_${suffix}.bam

  cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        minimap2: \$(minimap2 --version 2>&1)
        samtools: \$(echo \$(samtools --version 2>&1) | sed 's/^.*samtools //; s/Using.*\$//')
    END_VERSIONS
  """
}
