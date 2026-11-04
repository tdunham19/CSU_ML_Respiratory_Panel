process FINAL_SUMMARY {

    tag "${meta.id}_${meta.target}"
    label 'process_single'
    // label "no_publish"
    
    conda "${moduleDir}/environment.yml"
    container "${workflow.containerEngine in ['singularity', 'apptainer'] && !task.ext.singularity_pull_docker_container
        ? 'https://community-cr-prod.seqera.io/docker/registry/v2/blobs/sha256/87/87660348a4d032cc08d6ac8101ff9d4d27164300d39c9472043bb5001f9ba801/data'
        : 'community.wave.seqera.io/library/htslib_samtools:1.25--704fb80d75745bd4'}"

    input:
    tuple val(meta), path(bam), path(consensus), path(reference)

    output:
    path("*_summary.tsv"), emit: summary

    script:
    """
   READS=\$(samtools view -c -F 4 ${bam})

   CONS_LEN=\$(grep -v '^>' ${consensus} | tr -d '\\n' | wc -c)

   REF_LEN=\$(grep -v '^>' ${reference} | tr -d '\\n' | wc -c)

   COVERAGE=\$(awk \
    -v cons="\$CONS_LEN" \
    -v reads="\$READS" \
    -v ref="\$REF_LEN" \
    'BEGIN{
        if(ref>0)
            printf "%.2f", (cons*reads)/ref
        else
            printf "0"
    }')

   CONCLUSION=\$(awk \
    -v reads="\$READS" \
    -v yes="${params.reads_yes_cutoff}" \
    -v maybe="${params.reads_maybe_cutoff}" \
    'BEGIN{
        if(reads >= yes)
            print "Yes"
        else if(reads > maybe)
            print "Maybe"
        else
            print "No"
    }')

   echo -e "Sample\\tTarget\\tReads_Aligned\\tGenome_Coverage\\tConclusion" \
    > ${meta.id}_${meta.target}_summary.tsv

   echo -e "${meta.id}\\t${meta.target}\\t\$READS\\t\$COVERAGE\\t\$CONCLUSION" \
    >> ${meta.id}_${meta.target}_summary.tsv
    """
}