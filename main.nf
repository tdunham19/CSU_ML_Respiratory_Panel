include { NANOPORE_WORKFLOW } from './workflows/nanopore.nf'

println "Selected reference: ${params.reference}"
println "Selected barcode file: ${params.barcode}"
println "fastq directory: ${params.fastq_dir}"
println "Output directory: ${params.outdir}"

workflow {  
      NANOPORE_WORKFLOW()
}