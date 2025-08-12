include { SAMTOOLS_FAIDX                    } from '../../../modules/gallvp/samtools/faidx/main'
include { JUICEBOXSCRIPTS_MAKEAGPFROMFASTA  } from '../../../modules/gallvp/juiceboxscripts/makeagpfromfasta/main'
include { JUICEBOXSCRIPTS_AGP2ASSEMBLY      } from '../../../modules/gallvp/juiceboxscripts/agp2assembly/main'
include { CUSTOM_ASSEMBLY2BEDPE             } from '../../../modules/gallvp/custom/assembly2bedpe/main'
include { YAHS_JUICERPRE                    } from '../../../modules/gallvp/yahs/juicerpre/main'
include { SORT                              } from '../../../modules/gallvp/sort/main'
include { JUICER_INDEXBYCHR                 } from '../../../modules/gallvp/juicer/indexbychr/main'
include { JUICERTOOLS_PRE                   } from '../../../modules/gallvp/juicertools/pre/main'

// DEPRECATED
// Use bam_fasta_yahs_juicer_pre_hictk_load instead
workflow BAM_FASTA_YAHS_JUICER_PRE_JUICER_TOOLS_PRE {

    take:
    ch_bam                          // channel: [ val(meta), bam ]; meta: [ id, ref_id ]
    ch_fasta                        // channel: [ val(meta2), fasta ]; meta2: [ id ]
                                    // meta2.id = meta.ref_id
    val_assembly_mode               // true|false; Turn on/off assembly mode '-a' for YAHS_JUICERPRE
    val_use_index                   // true|false; Turn on/off the use of JUICER_INDEXBYCHR
                                    // Currently, JUICER_INDEXBYCHR leads to a broken HiC map and
                                    // its use is not recommended

    main:
    ch_versions                     = Channel.empty()

    // MODULE: SAMTOOLS_FAIDX
    SAMTOOLS_FAIDX ( ch_fasta,
        [ [] , []],
        true // get_sizes
    )

    ch_fasta_fai_sizes              = ch_fasta
                                    | join(SAMTOOLS_FAIDX.out.fai)
                                    | join(SAMTOOLS_FAIDX.out.sizes)
    ch_versions                     = ch_versions.mix(SAMTOOLS_FAIDX.out.versions.first())

    // MODULE: JUICEBOXSCRIPTS_MAKEAGPFROMFASTA
    JUICEBOXSCRIPTS_MAKEAGPFROMFASTA ( ch_fasta )

    ch_fasta_fai_sizes_agp          = ch_fasta_fai_sizes
                                    | join(JUICEBOXSCRIPTS_MAKEAGPFROMFASTA.out.agp)
    ch_versions                     = ch_versions.mix(JUICEBOXSCRIPTS_MAKEAGPFROMFASTA.out.versions.first())

    // MODULES: JUICEBOXSCRIPTS_AGP2ASSEMBLY > CUSTOM_ASSEMBLY2BEDPE
    JUICEBOXSCRIPTS_AGP2ASSEMBLY (
        val_assembly_mode
        ? JUICEBOXSCRIPTS_MAKEAGPFROMFASTA.out.agp
        : Channel.empty()
    )

    CUSTOM_ASSEMBLY2BEDPE (
        JUICEBOXSCRIPTS_AGP2ASSEMBLY.out.assembly
    )

    ch_versions                     = ch_versions
                                    | mix(JUICEBOXSCRIPTS_AGP2ASSEMBLY.out.versions.first())
                                    | mix(CUSTOM_ASSEMBLY2BEDPE.out.versions.first())

    // MODULE: YAHS_JUICERPRE
    ch_yahs_juicerpre_inputs        = ch_bam
                                    | map { meta, bam ->
                                        [ meta.ref_id, meta, bam ]
                                    }
                                    | join(
                                        ch_fasta_fai_sizes_agp
                                        | map { meta2, fasta, fai, sizes, agp ->
                                            [ meta2.id, fasta, fai, sizes, agp ]
                                        }
                                    )
                                    | multiMap { _ref_id, meta, bam, _fasta, fai, sizes, agp ->
                                        bam: [ meta, bam ]
                                        agp: agp
                                        fai: fai
                                        sizes: [ meta, sizes ]
                                    }

    YAHS_JUICERPRE (
        ch_yahs_juicerpre_inputs.bam,
        ch_yahs_juicerpre_inputs.agp,
        ch_yahs_juicerpre_inputs.fai
    )

    ch_versions                     = ch_versions.mix(YAHS_JUICERPRE.out.versions.first())

    // MODULE: SORT
    ch_sort_input                   = ! val_assembly_mode
                                    ? YAHS_JUICERPRE.out.txt
                                    : Channel.empty()
    SORT ( ch_sort_input )
    ch_versions                     = ch_versions.mix(SORT.out.versions.first())

    // MODULE: JUICER_INDEXBYCHR
    ch_juicer_indexbychr_inputs     = (
                                        val_assembly_mode
                                        ? YAHS_JUICERPRE.out.txt
                                        : SORT.out.sorted
                                    )
                                    | join (
                                        val_assembly_mode
                                        ? YAHS_JUICERPRE.out.sizes
                                        : ch_yahs_juicerpre_inputs.sizes
                                    )

    JUICER_INDEXBYCHR (
        val_use_index
        ? ch_juicer_indexbychr_inputs.map { meta, sorted, _sizes -> [ meta, sorted ] }
        : Channel.empty(),
        500000 // chunk_size
    )

    ch_versions                     = ch_versions.mix(JUICER_INDEXBYCHR.out.versions.first())

    // MODULE: JUICERTOOLS_PRE
    ch_juicertools_pre_inputs       = val_use_index
                                    ? ch_juicer_indexbychr_inputs
                                    | join(
                                        JUICER_INDEXBYCHR.out.index
                                    )
                                    | multiMap { meta, sorted, sizes, index ->
                                        sorted: [ meta, sorted ]
                                        index: index
                                        sizes: sizes
                                    }
                                    : ch_juicer_indexbychr_inputs
                                    | multiMap { meta, sorted, sizes ->
                                        sorted: [ meta, sorted ]
                                        index: []
                                        sizes: sizes
                                    }

    JUICERTOOLS_PRE (
        ch_juicertools_pre_inputs.sorted,
        ch_juicertools_pre_inputs.index,
        ch_juicertools_pre_inputs.sizes
    )

    ch_versions                     = ch_versions.mix(JUICERTOOLS_PRE.out.versions.first())

    emit:
    hic                             = JUICERTOOLS_PRE.out.hic                   // channel: [ meta, hic ]
    assembly                        = JUICEBOXSCRIPTS_AGP2ASSEMBLY.out.assembly // channel: [ meta, assembly ]
    bedpe                           = CUSTOM_ASSEMBLY2BEDPE.out.bedpe           // channel: [ meta, bedpe ]
    bed                             = CUSTOM_ASSEMBLY2BEDPE.out.bed             // channel: [ meta, bed ]
    versions                        = ch_versions                               // channel: [ versions.yml ]
}
