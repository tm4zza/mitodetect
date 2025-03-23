include { FASTQ_ALIGN_DNA as FASTQ_ALIGN_MTDNA         } from '../../nf-core/fastq_align_dna/main'
include { FASTQ_ALIGN_DNA as FASTQ_ALIGN_MTDNA_SHIFTED } from '../../nf-core/fastq_align_dna/main'

workflow FASTQ_CIRCULARALIGN_MTDNA {

    take:
    ch_reads            // channel: [mandatory] meta, reads
    ch_aligner_index    // channel: [mandatory] aligner index
    ch_fasta            // channel: [mandatory] fasta file

    main:
    ch_versions = Channel.empty()

    // Align reads
    FASTQ_ALIGN_MTDNA (
        ch_reads,
        ch_mt_index,
        ch_mt_shifted_index,
        ch_mt_fasta,
        ch_mt_fasta_shifted,
        params.aligner,     // one of [bowtie2, bwamem, bwamem2, dragmap, snap]
        true                // sort alignment by default
    )
    ch_versions = ch_versions.mix(FASTQ_ALIGN_MTDNA.out.versions.first())



    emit:
    bam         = ch_bam        // channel: [ [meta], bam       ]
    bam_index   = ch_bam_index  // channel: [ [meta], csi/bai   ]
    reports     = ch_reports    // channel: [ [meta], log       ]
    versions    = ch_versions   // channel: [ versions.yml      ]
}

