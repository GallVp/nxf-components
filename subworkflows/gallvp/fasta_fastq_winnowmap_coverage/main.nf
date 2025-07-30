include { MERYL_COUNT                   } from '../../../modules/gallvp/meryl/count/main'
include { WINNOWMAP                     } from '../../../modules/gallvp/winnowmap/main'
include { PAFTOOLS_SAM2PAF              } from '../../../modules/gallvp/paftools/sam2paf/main'
include { T2TPOLISH_PAFTOCOVCLIPPEDWIG  } from '../../../modules/gallvp/t2tpolish/paftocovclippedwig/main'

workflow FASTA_FASTQ_WINNOWMAP_COVERAGE {

    take:
    ch_fasta                            // channel: [ val(meta), fasta ]
    ch_fastq                            // channel: [ val(meta2), fasta ]
                                        // Combine by: meta2.ref_id = meta.id
    val_k                               // Integer; Default: 15
    val_meryl_distinct                  // Float; Default: 0.9998
    val_coverage_span                   // Integer; Default: 1024

    main:

    ch_versions                         = Channel.empty()

    // MODULE: MERYL_COUNT
    MERYL_COUNT ( ch_fastq, val_k ?: 15 )
    ch_versions                         = ch_versions.mix(MERYL_COUNT.out.versions.first())

    // MODULE: WINNOWMAP
    ch_win_inputs                       = ch_fastq
                                        | join ( MERYL_COUNT.out.meryl_db )
                                        | map { meta2, fastq, meryl_db -> [ meta2.ref_id, fastq, meryl_db ] }
                                        | combine(
                                            ch_fasta.map { meta, fasta -> [ meta.id, meta, fasta ] },
                                            by: 0
                                        )
                                        | multiMap { _ref_id, fastq, meryl_db, meta, fasta ->
                                            reads: [ meta, fastq ]
                                            reference: [ meta, fasta ]
                                            meryl_db: [ meta, meryl_db ]
                                        }
    WINNOWMAP (
        ch_win_inputs.reads,
        ch_win_inputs.reference,
        ch_win_inputs.meryl_db,
        val_meryl_distinct ?: 0.9998,
        true, // bam_format
        false, // bam_index_extension
        true, // cigar_paf_format
        true, // cigar_paf_format
        false, // sort_bam
    )

    ch_versions                         = ch_versions.mix(WINNOWMAP.out.versions.first())

    // MODULE: PAFTOOLS_SAM2PAF
    PAFTOOLS_SAM2PAF (
        WINNOWMAP.out.bam
    )

    ch_versions                         = ch_versions.mix(PAFTOOLS_SAM2PAF.out.versions.first())

    // MODULE: T2TPOLISH_PAFTOCOVCLIPPEDWIG
    ch_t2t_inputs                       = PAFTOOLS_SAM2PAF.out.paf
                                        | multiMap { meta, paf ->
                                            paf: [ meta, paf ]
                                            name: "${meta.id}"
                                            span: val_coverage_span ?: 1024
                                        }
    T2TPOLISH_PAFTOCOVCLIPPEDWIG (
        ch_t2t_inputs.paf,
        ch_t2t_inputs.name,
        ch_t2t_inputs.span
    )

    ch_versions                         = ch_versions.mix(T2TPOLISH_PAFTOCOVCLIPPEDWIG.out.versions.first())


    emit:
    wig                                 = T2TPOLISH_PAFTOCOVCLIPPEDWIG.out.cov  // channel: [ val(meta), wig ]
    versions                            = ch_versions                           // channel: [ versions.yml ]
}
