process MERGE_SUMMARIES {

    label 'process_single'
 
    input:
    path (summary)

    output:
    path ("final_summary.tsv"), emit: tsv

    script:
    """
    head -n 1 \$(ls *.tsv | head -1) > final_summary.tsv

    for f in *.tsv; do
        tail -n +2 \$f >> final_summary.tsv
    done
    """
}