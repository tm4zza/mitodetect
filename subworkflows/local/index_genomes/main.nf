include { BWAMEM2_INDEX as BWAMEM2_INDEX_MT         } from '../../../modules/nf-core/bwamem2/index/main.nf'
include { BWAMEM2_INDEX as BWAMEM2_INDEX_MT_SHIFTED } from '../../../modules/nf-core/bwamem2/index/main.nf'
include { BWAMEM2_INDEX as BWAMEM2_INDEX_NT         } from '../../../modules/nf-core/bwamem2/index/main.nf'
include { GATK4_SHIFTFASTA                          } from '../../../modules/nf-core/gatk4/shiftfasta/main.nf'
include { SAMTOOLS_FAIDX                            } from '../../../modules/nf-core/samtools/faidx/main'
include { GATK4_CREATESEQUENCEDICTIONARY            } from '../../../modules/nf-core/gatk4/createsequencedictionary/main'
include { TABIX_BGZIP                               } from '../../../modules/nf-core/tabix/bgzip/main'

workflow INDEX_GENOMES {

    // take:
    // ch_bam // channel: [ val(meta), [ bam ] ]

    main:
    // Declare placeholder channels for the optional outputs
    index_nt = Channel.empty()
    index_mt = Channel.empty()
    index_mt_shifted = Channel.empty()
    fasta_nt = Channel.empty()
    fasta_mt = Channel.empty()
    fasta_mt_shifted = Channel.empty()

    ch_versions = Channel.empty()

    if(params.aligner == "bwa-mem2") {
        // Index the NT genome
        def fnt = file(params.genome_nt)
        ch_fasta_nt = Channel.value( [ [id: fnt.getBaseName(fnt.name.count('.'))], file(params.genome_nt) ] )
        TABIX_BGZIP( ch_fasta_nt )
        ch_versions = ch_versions.mix(TABIX_BGZIP.out.versions)
        BWAMEM2_INDEX_NT( TABIX_BGZIP.out.output )
        ch_versions = ch_versions.mix(BWAMEM2_INDEX_NT.out.versions)

        // Index the MT genome
        def fmt = file(params.genome_mt)
        ch_fasta_mt = Channel.value( [ [id: fmt.getBaseName(fmt.name.count('.'))], file(params.genome_mt) ] )
        BWAMEM2_INDEX_MT( ch_fasta_mt )

        // Index the curcularized version of the MT genome
        SAMTOOLS_FAIDX( ch_fasta_mt, [[],[]], false )
        ch_versions = ch_versions.mix(SAMTOOLS_FAIDX.out.versions)
        GATK4_CREATESEQUENCEDICTIONARY( ch_fasta_mt )
        ch_versions = ch_versions.mix(GATK4_CREATESEQUENCEDICTIONARY.out.versions)
        GATK4_SHIFTFASTA(
            ch_fasta_mt,
            SAMTOOLS_FAIDX.out.fai,
            GATK4_CREATESEQUENCEDICTIONARY.out.dict
        )
        ch_versions = ch_versions.mix(GATK4_SHIFTFASTA.out.versions)
        BWAMEM2_INDEX_MT_SHIFTED( GATK4_SHIFTFASTA.out.shift_fa )


        index_nt = BWAMEM2_INDEX_NT.out.index
        index_mt = BWAMEM2_INDEX_MT.out.index
        index_mt_shifted = BWAMEM2_INDEX_MT_SHIFTED.out.index
        fasta_nt = ch_fasta_nt
        fasta_mt = ch_fasta_mt
        fasta_mt_shifted = GATK4_SHIFTFASTA.out.shift_fa

    } else {
        log.error "Only bwa-mem2 is supported for now."
    }


    emit:
    index_nt = index_nt                  // channel: [ val(meta), [ index_folder ] ]
    index_mt = index_mt                  // channel: [ val(meta), [ index_folder ] ]
    index_mt_shifted = index_mt_shifted  // channel: [ val(meta), [ index_folder ] ]
    fasta_nt = fasta_nt                  // channel: [ val(meta), fasta ]
    fasta_mt = fasta_mt                  // channel: [ val(meta), fasta ]
    fasta_mt_shifted = fasta_mt_shifted  // channel: [ val(meta), fasta ]

    versions = ch_versions                  // channel: [ versions.yml ]
}
