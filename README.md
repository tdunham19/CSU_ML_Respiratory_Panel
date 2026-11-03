# CSU_ML_Respiratory_Panel
Colorado State University Molecular Loop Respiratory Pathogen Panel

### to run pipeline as of 11/03/26
nextflow run main.nf --fastq_dir path/to/fastq/directory/ --barcode /path/to/barcode/sequence/file/{file}.fasta --reference /path/to/reference/sequence/file/{file}.fasta -resume

### example
nextflow run main.nf --fastq_dir ../cutadapt_demux_round4/fastq_dir/ --barcode ../cutadapt_demux_round4/ML_custom_sequences_control_run_withRC_092026.fasta --reference ./reference/molecular_loop_reference_sequences_controls_only.fasta -resume

