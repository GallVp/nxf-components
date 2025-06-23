include { SEQKIT_SORT                       } from '../../../modules/gallvp/seqkit/sort/main'
include { MINIMAP2_ALIGN                    } from '../../../modules/gallvp/minimap2/align/main'
include { JUICEBOXSCRIPTS_MAKEAGPFROMFASTA  } from '../../../modules/gallvp/juiceboxscripts/makeagpfromfasta/main'
include { HAPHIC_REFSORT                    } from '../../../modules/gallvp/haphic/refsort/main'

workflow FASTA_SEQKIT_REFSORT {

    take:
    ch_fasta                                // channel: [ val(meta), fasta ]
    val_fasta_combinations                  // val: []|null|"x x:y a:b ..."
    val_alphanumeric_sort                   // val: true|false
    val_refsort                             // val: true|false

    main:

    ch_versions                             = Channel.empty()

    // MODULE: SEQKIT_SORT; ext.args = '--ignore-case --natural-order'
    SEQKIT_SORT ( val_alphanumeric_sort ? ch_fasta : Channel.empty() )

    ch_sorted_fasta                         = val_alphanumeric_sort
                                            ? SEQKIT_SORT.out.fastx
                                            : ch_fasta
    ch_versions                             = ch_versions.mix(SEQKIT_SORT.out.versions.first())

    // Channels: ch_grouped_fastas, ch_single_fasta, ch_paired_fastas, ch_refsort_paired_fastas
    ch_combinations_list                    = ( val_fasta_combinations == null || val_fasta_combinations == [] )
                                            ? ch_fasta
                                            | map { meta, _fasta -> meta.id }
                                            | collect
                                            : Channel.of(
                                                val_fasta_combinations.tokenize( ' ' )
                                            )

    ch_grouped_fastas                       = ch_sorted_fasta
                                            | combine (
                                                ch_combinations_list
                                                | flatten
                                            )
                                            | filter { meta, _fasta, comb -> meta.id in comb.tokenize( ':' ) }
                                            | map { meta, fasta, comb ->
                                                [ comb, meta, fasta ]
                                            }
                                            | groupTuple
                                            | map { group_key, metas, fastas ->

                                                if ( metas.size() == 1 ) {
                                                    return [ metas, fastas ]
                                                }

                                                def group_ids = group_key.tokenize(':')
                                                def meta_ids = metas.collect { it.id }

                                                def query_id = group_ids.first()
                                                def ref_id = group_ids.last()

                                                def query_i = meta_ids.indexOf( query_id )
                                                def ref_i = meta_ids.indexOf( ref_id )

                                                def ordered_fastas = [
                                                    fastas[query_i],
                                                    fastas[ref_i],
                                                ]

                                                def new_id = group_ids.join('_')

                                                [
                                                    [ id: new_id, query: query_id, ref: ref_id ], // meta2
                                                    ordered_fastas
                                                ]
                                            }
                                            | branch { _meta2, fastas ->
                                                single: fastas.size() != 2
                                                paired: fastas.size() == 2
                                            }

    ch_single_fasta                         = ch_grouped_fastas.single
                                            | map { meta, fastas ->
                                                [ meta.first(), fastas.first() ]
                                            }

    ch_paired_fastas                        = ch_grouped_fastas.paired
    ch_refsort_paired_fastas                = val_refsort
                                            ? ch_grouped_fastas.paired
                                            : Channel.empty()

    // MODULE: MINIMAP2_ALIGN; ext.args = -x asm5 --secondary=no
    MINIMAP2_ALIGN (
        ch_refsort_paired_fastas.map { meta2, fastas -> [ meta2, fastas.first() ] },
        ch_refsort_paired_fastas.map { meta2, fastas -> [ meta2, fastas.last() ] },
        false, // bam_format
        [], // bam_format
        false, // cigar_paf_format
        false // cigar_bam
    )

    ch_refsort_paired_fastas_paf            = ch_refsort_paired_fastas
                                            | join ( MINIMAP2_ALIGN.out.paf )
    ch_versions                             = ch_versions.mix(MINIMAP2_ALIGN.out.versions.first())

    // JUICEBOXSCRIPTS_MAKEAGPFROMFASTA
    JUICEBOXSCRIPTS_MAKEAGPFROMFASTA (
        ch_refsort_paired_fastas.map { meta2, fastas -> [ meta2, fastas.first() ] }
    )

    ch_refsort_paired_fastas_paf_query_agp  = ch_refsort_paired_fastas_paf
                                            | join(
                                                JUICEBOXSCRIPTS_MAKEAGPFROMFASTA.out.agp
                                            )
    ch_versions                             = ch_versions.mix(JUICEBOXSCRIPTS_MAKEAGPFROMFASTA.out.versions.first())

    // MODULE: HAPHIC_REFSORT
    ch_refsort_inputs                       = ch_refsort_paired_fastas_paf_query_agp
                                            | multiMap { meta2, fastas, paf, query_agp ->
                                                agp:    [ meta2, query_agp ]
                                                paf:    paf
                                                fasta:  fastas.first()
                                            }
    HAPHIC_REFSORT (
        ch_refsort_inputs.agp,
        ch_refsort_inputs.paf,
        ch_refsort_inputs.fasta,
        [] //ref_order
    )

    ch_refsort_paired_fastas_refsort_fasta  = ch_refsort_paired_fastas
                                            | join ( HAPHIC_REFSORT.out.fasta )
    ch_versions                             = ch_versions.mix(HAPHIC_REFSORT.out.versions.first())

    // Channel: ch_ref_sorted_paired_fastas
    ch_ref_sorted_paired_fastas             = val_refsort
                                            ? ch_refsort_paired_fastas_refsort_fasta
                                            | map { meta2, fastas, refsort_fasta ->
                                                [
                                                    meta2,
                                                    [ refsort_fasta, fastas.last() ]
                                                ]
                                            }
                                            : ch_paired_fastas

    // Channel: ch_interleaved_fasta
    ch_interleaved_fasta                    = ch_ref_sorted_paired_fastas
                                            | map { meta2, fastas ->
                                                def query_fasta = fastas.first()
                                                def ref_fasta  = fastas.last()

                                                def query_fasta_records = query_fasta.splitFasta( record: [ id: true, sequence: true, width:80 ] )
                                                def ref_fasta_records = ref_fasta.splitFasta( record: [ id: true, sequence: true, width:80 ] )

                                                def query_ids = query_fasta_records.collect { it.id }
                                                def ref_ids = ref_fasta_records.collect { it.id }

                                                def n_query = query_ids.size()
                                                def n_ref = ref_ids.size()
                                                def max_n = Math.max ( n_query, n_ref )

                                                def should_prefix = query_ids.any { it in ref_ids }
                                                def query_prefix = should_prefix ? meta2.query : ''
                                                def ref_prefix = should_prefix ? meta2.ref : ''

                                                def interleaved_fasta_records = ( 0..<max_n ).collect { i ->
                                                    def query_record = ( i < n_query)
                                                        ? [ ">" + query_prefix + query_fasta_records[i].id + '\n', query_fasta_records[i].sequence ]
                                                        : []

                                                    def ref_record = ( i < n_ref)
                                                        ? [ ">" + ref_prefix + ref_fasta_records[i].id + '\n', ref_fasta_records[i].sequence ]
                                                        : []

                                                    [
                                                        query_record,
                                                        ref_record
                                                    ]
                                                }.flatten()

                                                [
                                                    "${meta2.id}.fasta",
                                                    interleaved_fasta_records.join('')
                                                ]
                                            }
                                            | collectFile
                                            | map { fasta ->
                                                [
                                                    [ id: fasta.simpleName ], // meta3
                                                    fasta
                                                ]
                                            }

    emit:
    fasta                                   = ch_interleaved_fasta
                                            | mix ( ch_single_fasta )   // channel: [ meta3, fasta ]
    versions                                = ch_versions               // channel: [ versions.yml ]
}
