#!/usr/bin/env nextflow

nextflow.enable.dsl=2

// include modules from nf-core
include { DEMUX											 	 	  } from '../modules/nf_core/cutadapt/demux_main.nf'
include { NANOPLOT as NANOPLOT_PRE_TRIM					 	 	  } from '../modules/nf_core/nanoplot/main.nf'
include { PORECHOP										 	 	  } from '../modules/nf_core/porechop/main.nf'
include { TRIM_UMIS										 	 	  } from '../modules/nf_core/cutadapt/trim_umis_main.nf'
include { TRIM_ARMS										 	 	  } from '../modules/nf_core/cutadapt/trim_arms_main.nf'
include { NANOPLOT as NANOPLOT_POST_TRIM					 	  } from '../modules/nf_core/nanoplot/main.nf'
include { MINIMAP2_ALIGN as MINIMAP2_ALIGN_TO_REF  	 			  } from '../modules/nf_core/minimap2_align/main.nf'
include { SAMTOOLS_IDXSTATS 									  } from '../modules/nf_core/samtools/idxstats/main.nf'
include { BAMTOOLS_SPLIT as SPLIT_BAM_BY_TARGET              	  } from '../modules/nf_core/bamtools_split/main.nf'
include { CLEAN_BAM_HEADER              	 			          } from '../modules/nf_core/samtools/idxstats/clean_bam_main.nf'
include { VIRAL_CONSENSUS as CALL_INDIVIDUAL_CONSENSUS            } from '../modules/local/viral_consensus/main.nf'
include { REMOVE_TRAILING_FASTA_NS								  } from '../modules/local/remove_trailing_fasta_ns/main.nf'
include { CREATE_SUMMARY		   		   	  				      } from '../modules/local/create_summary/main.nf'
include { MERGE_SUMMARIES		   		   	  				      } from '../modules/local/merge_summary/main.nf'

workflow NANOPORE_WORKFLOW {

  ch_versions = Channel.empty()                                               

  // fastq input files

  Channel.fromFilePairs("${params.fastq_dir}/${params.nanopore_input_pattern}", size: -1, checkIfExists: true, maxDepth: 1)
  .map{ name, inputreads ->
         def matcher = name =~ /^([^.]+)/
         def meta = [:]
         if (matcher.find()) {
             meta.id = matcher.group(0)
         } else {
             meta.id = "UNKNOWN" 
         }
         [ meta, inputreads ]
     }
  .set { ch_inputreads }
  
  // refseq input files

    Channel.fromPath("${params.reference}", checkIfExists: true)
    .collect()
    .map { reference ->
            def meta2 = [:]
            meta2.id = "reference"
            [meta2, reference]
        }
    .set { ch_reference }
    
    // barcode input files

    Channel.fromPath("${params.barcode}")
    .collect()
    .map { barcode ->
            def meta3 = [:]
            meta3.id = "barcode"
            [meta3, barcode]
        }
    .set { ch_barcode }
    
  // demultiplex raw Nanopore reads
  DEMUX ( ch_inputreads, ch_barcode )
  
  demux_reads = DEMUX.out.reads
    .flatMap { meta, reads ->
    reads.collect { read ->
    	def sample_id = read.baseName
        .replaceFirst(/_demux$/, '')
        def new_meta = meta + [id: sample_id]
        tuple(new_meta, read)
        }
    }
  
  // run Nanoplot on demuxed fastq files
  NANOPLOT_PRE_TRIM ( demux_reads )
  
  // trim adapters using porechop
  PORECHOP ( demux_reads )
  
  // trim UMIs using cutadapt
  TRIM_UMIS ( PORECHOP.out.reads )
  
  // trim ARMS using cutadapt
  TRIM_ARMS ( TRIM_UMIS.out.reads )
    
  // run Nanoplot on trimmed fastq files
  NANOPLOT_POST_TRIM ( TRIM_ARMS.out.reads )
  
  // align trimmed reads using minimap2
  MINIMAP2_ALIGN_TO_REF ( TRIM_ARMS.out.reads, ch_reference, "align.to.refseq" )
  
  // determine if there are samples that aligned to nothing
  SAMTOOLS_IDXSTATS ( MINIMAP2_ALIGN_TO_REF.out.bam )
  
  mapped_bams = MINIMAP2_ALIGN_TO_REF.out.bam
    .join(SAMTOOLS_IDXSTATS.out.idxstats)
    .filter { meta, bam, idxstats ->

        def mapped = idxstats.readLines()
            .findAll { !it.startsWith('*') }
            .sum { it.split('\t')[2] as Integer }

        mapped > 0
    }
    .map { meta, bam, idxstats ->
        tuple(meta, bam)
    }
  
  // separate, one bam for each target being aligned to
  SPLIT_BAM_BY_TARGET ( mapped_bams )
  
  // ensure bams are in unique channels and have the target associated	
  split_bams = SPLIT_BAM_BY_TARGET.out.bam.flatMap { meta, bam_or_bams ->
  def bam_list = bam_or_bams instanceof List ? bam_or_bams : [ bam_or_bams ]
    			 bam_list.collect { bam ->
        		 def target = bam.getFileName().toString()
            	 .replaceFirst(/^.*REF_/, '')
            	 .replaceFirst(/\.bam$/, '')
		         tuple(
           		 meta + [target: target],
            	 bam)}
            	 }
                   
  // ensure that .bam header only has a single reference
  CLEAN_BAM_HEADER ( split_bams )
	
  // split up targets into individual sequences because viral_consensus
  // can only work on one sequence at a time
  // see: https://www.nextflow.io/docs/latest/reference/operator.html#splitfasta  
  Channel.fromPath("${params.reference}", checkIfExists: true)
    .splitFasta(by: 1, record: [id:true, sequence:true])
    .map { record -> def fasta = file("${record.id}.fa")
        			 fasta.text = ">${record.id}\n${record.sequence}\n"
		             tuple([target: record.id], fasta)
		             }
		             .set { individual_references }
  
  // this uses the nextflow combine operator to create a new channel
  // that contains the reads for each dataset and all individual fasta files 
  individual_fasta_ch = CLEAN_BAM_HEADER.out.bam.map { meta, bam -> tuple(meta.target, meta, bam) }
  						.combine(individual_references.map { meta, fasta -> tuple(meta.target, fasta) }, by: 0)
        			    .map { target, meta, bam, fasta -> tuple(meta, bam, fasta)}

  // parameters related consensus calling: min depth, basecall quality, frequency for consensus calling
  min_depth_ch = Channel.value(params.nanopore_min_depth)
  min_qual_ch  = Channel.value(params.nanopore_min_qual)
  min_freq_ch  = Channel.value(params.nanopore_min_freq)
  CALL_INDIVIDUAL_CONSENSUS(individual_fasta_ch, min_qual_ch, min_depth_ch, min_freq_ch)
     
  // pipe output through remove_trailing_fasta_Ns to strip N characters from beginning and ends of seqs
  REMOVE_TRAILING_FASTA_NS ( CALL_INDIVIDUAL_CONSENSUS.out.fasta )
  
  // filter out empty fasta files
  INDIVIDUAL_CONSENSUS_SEQUENCE_FILTERED = REMOVE_TRAILING_FASTA_NS.out.filter { meta, fasta ->
    fasta.text.readLines().find { it && !it.startsWith(">") } != null 
    }
  
  // create summary channel
  summary_input =
    CLEAN_BAM_HEADER.out.bam
        .map { meta, bam ->
            tuple(meta.target, meta, bam)
        }
        .join(
            INDIVIDUAL_CONSENSUS_SEQUENCE_FILTERED
                .map { meta, fasta ->
                    tuple(meta.target, fasta)
                }
        )
        .combine(
            individual_references
                .map { meta, ref ->
                    tuple(meta.target, ref)
                }
        )
        .filter { target1, meta, bam, consensus, target2, reference ->
            target1 == target2
        }
        .map { target1, meta, bam, consensus, target2, reference ->
            tuple(meta, bam, consensus, reference)
        }
             		  
  // create final summary table for each sample then merge into one
  // contains: target, reads aligned, genome coverage, and an overall Y/N/suspect result
  CREATE_SUMMARY ( summary_input )
  MERGE_SUMMARIES ( CREATE_SUMMARY.out.collect() )
    
  // final multiqc

  }
  
  // specify the entry point for the workflow
workflow {
  NANOPORE_WORKFLOW()
}

workflow.onComplete {

    def indiv_ref_dir = file(params.indiv_ref_dir)
    indiv_ref_dir.mkdirs()

    new File(workflow.launchDir.toString())
        .listFiles()
        .findAll { it.name.endsWith('.fa') }
        .each { fasta ->
            fasta.renameTo(new File(params.indiv_ref_dir, fasta.name))
        }
}
