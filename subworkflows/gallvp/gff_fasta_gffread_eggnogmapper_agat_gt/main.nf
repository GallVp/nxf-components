include { GFFREAD as GFF2FASTA_FOR_EGGNOGMAPPER } from '../../../modules/gallvp/gffread/main'
include { EGGNOGMAPPER                          } from '../../../modules/gallvp/eggnogmapper/main'
include { AGAT_SPFILTERFEATUREFROMKILLLIST      } from '../../../modules/gallvp/agat/spfilterfeaturefromkilllist/main'
include { GT_GFF3 as FINAL_GFF_CHECK            } from '../../../modules/gallvp/gt/gff3/main'

workflow GFF_FASTA_GFFREAD_EGGNOGMAPPER_AGAT_GT {
    take:
    ch_gff                      // Channel: [ meta, gff ]
    ch_fasta                    // Channel: [ meta2, fasta ]; meta and meta2 are only required to have the same id
    val_db_folder               // val(val_db_folder); Path to eggnogmapper database
    val_purge_nohits            // val(true|false); Purge models without eggnog hits
    val_describe_gff            // val(true|false); Add eggnogmapper descriptions to gff

    main:
    // Versions
    ch_versions                 = Channel.empty()

    // MODULE: GFFREAD as GFF2FASTA_FOR_EGGNOGMAPPER
    ch_gffread_inputs           = ch_gff
                                | map { meta, gff -> [ meta.id, meta, gff ] }
                                | join(
                                    ch_fasta
                                    | map { meta2, fasta -> [ meta2.id, fasta ] }
                                )
                                | map { _id, meta, gff, fasta -> [ meta, gff, fasta ] }

    GFF2FASTA_FOR_EGGNOGMAPPER(
        ch_gffread_inputs.map { meta, gff, _fasta -> [ meta, gff ] },
        ch_gffread_inputs.map { _meta, _gff, fasta -> fasta }
    )

    ch_gffread_fasta            = GFF2FASTA_FOR_EGGNOGMAPPER.out.gffread_fasta
    ch_versions                 = ch_versions.mix(GFF2FASTA_FOR_EGGNOGMAPPER.out.versions.first())


    // MODULE: EGGNOGMAPPER
    ch_eggnogmapper_inputs      = ! val_db_folder
                                ? Channel.empty()
                                : ch_gffread_fasta
                                | combine(Channel.fromPath(val_db_folder))

    EGGNOGMAPPER(
        ch_eggnogmapper_inputs.map { meta, fasta, _db -> [ meta, fasta ] },
        [],
        ch_eggnogmapper_inputs.map { _meta, _fasta, db -> db },
        [ [], [] ]
    )

    ch_eggnogmapper_annotations = EGGNOGMAPPER.out.annotations
    ch_eggnogmapper_orthologs   = EGGNOGMAPPER.out.orthologs
    ch_eggnogmapper_hits        = EGGNOGMAPPER.out.hits
    ch_versions                 = ch_versions.mix(EGGNOGMAPPER.out.versions.first())

    // COLLECTFILE: Transcript level kill list
    ch_kill_list                = ch_gff
                                | join(ch_eggnogmapper_hits)
                                | map { meta, gff, hits ->

                                    def tx_with_hits = hits.readLines()
                                        .collect { it.split('\t')[0] }
                                        .sort(false)
                                        .unique()

                                    def tx_in_gff = gff.readLines()
                                        .findAll { line ->
                                            if ( line.startsWith('#') || line == '' ) { return false }

                                            def feat = line.split('\t')[2]
                                            ( feat == 'transcript' || feat == 'mRNA' )
                                        }
                                        .collect { it ->
                                            def attrs = it.split('\t')[8]

                                            ( attrs =~ /ID=([^;]*)/ )[0][1]
                                        }
                                        .sort(false)
                                        .unique()

                                    def tx_without_hits = tx_in_gff - tx_with_hits

                                    [ "${meta.id}.kill.list.txt" ] + tx_without_hits.join('\n')
                                }
                                | collectFile(newLine: true)
                                | map { file ->
                                    [ [ id: file.baseName.replace('.kill.list', '') ], file ]
                                }

    // MODULE: AGAT_SPFILTERFEATUREFROMKILLLIST
    ch_agat_kill_inputs         = ! ( val_purge_nohits && val_db_folder )
                                ? Channel.empty()
                                : ch_gff
                                | join(ch_kill_list)


    AGAT_SPFILTERFEATUREFROMKILLLIST(
        ch_agat_kill_inputs.map { meta, gff, _kill -> [ meta, gff ] },
        ch_agat_kill_inputs.map { _meta, _gff, kill -> kill },
        [] // default config
    )

    ch_purged_gff               = AGAT_SPFILTERFEATUREFROMKILLLIST.out.gff
                                | mix(
                                    ( val_purge_nohits && val_db_folder )
                                    ? Channel.empty()
                                    : ch_gff
                                )
    ch_versions                 = ch_versions.mix(AGAT_SPFILTERFEATUREFROMKILLLIST.out.versions.first())

    // COLLECTFILE: Add eggnogmapper hits to gff
    ch_described_gff            = ! ( val_describe_gff && val_db_folder )
                                ? Channel.empty()
                                : ch_purged_gff
                                | join(ch_eggnogmapper_annotations)
                                | map { meta, gff, annotations ->
                                    def tx_annotations  = annotations.readLines()
                                        .findAll { ! it.startsWith('#') }
                                        .collect { line ->
                                            def cols    = line.split('\t')
                                            def id      = cols[0]
                                            def txt     = cols[7]
                                            def pfams   = cols[20]

                                            [ id, txt, pfams ]
                                        }
                                        .collect { id, txt, pfams ->
                                            if ( txt != '-' ) { return [ id, txt ] }
                                            if ( pfams != '-' ) { return [ id, "PFAMs: $pfams" ] }

                                            [ id, 'No eggnog description and PFAMs' ]
                                        }
                                        .collectEntries { id, txt ->
                                            [ id, txt ]
                                        }

                                    def gene_tx_annotations = [:]
                                    gff.readLines()
                                        .findAll { line ->
                                            if ( line.startsWith('#') || line == '' ) { return false }

                                            def cols    = line.split('\t')
                                            def feat    = cols[2]

                                            if ( ! ( feat == 'transcript' || feat == 'mRNA' ) ) { return false }

                                            return true
                                        }
                                        .each { line ->
                                            def cols    = line.split('\t')
                                            def atts    = cols[8]

                                            def matches = atts =~ /ID=([^;]*)/
                                            def tx_id   = matches[0][1]

                                            def matches_p= atts =~ /Parent=([^;]*)/
                                            def gene_id = matches_p[0][1]

                                            if ( ! gene_tx_annotations.containsKey(gene_id) ) {
                                                gene_tx_annotations[gene_id] = [:]
                                            }

                                            def anno    = tx_annotations.containsKey(tx_id)
                                                        ? java.net.URLEncoder.encode(tx_annotations[tx_id], "UTF-8").replace('+', '%20')
                                                        : java.net.URLEncoder.encode('Hypothetical protein | no eggnog hit', "UTF-8").replace('+', '%20')

                                            gene_tx_annotations[gene_id] += [ ( tx_id ): anno ]
                                        }

                                    gene_tx_annotations = gene_tx_annotations
                                        .collectEntries { gene_id, tx_annos ->
                                            def default_anno = tx_annos.values().first()

                                            if ( tx_annos.values().findAll { it != default_anno }.size() > 0 ) {
                                                return [ gene_id, ( tx_annos + [ 'default': 'Differing%20isoform%20descriptions' ] ) ]
                                            }

                                            [ gene_id, ( tx_annos + [ 'default': default_anno ] ) ]
                                        }

                                    def gff_lines = gff.readLines()
                                        .collect { line ->

                                            if ( line.startsWith('#') || line == '' ) { return line }

                                            def cols    = line.split('\t')
                                            def feat    = cols[2]
                                            def atts    = cols[8]

                                            if ( ! ( feat == 'gene' || feat == 'transcript' || feat == 'mRNA' ) ) { return line }

                                            def id      = feat == 'gene' ? ( atts =~ /ID=([^;]*)/ )[0][1] : ( atts =~ /Parent=([^;]*)/ )[0][1]

                                            if ( ! gene_tx_annotations.containsKey(id) ) { return line }

                                            def tx_id   = feat == 'gene' ? null : ( atts =~ /ID=([^;]*)/ )[0][1]
                                            def desc    = feat == 'gene' ? gene_tx_annotations[id]['default'] : gene_tx_annotations[id][tx_id]

                                            return ( line + ";description=$desc" )
                                        }

                                    [ "${meta.id}.described.gff" ] + gff_lines.join('\n')
                                }
                                | collectFile(newLine: true)
                                | map { file ->
                                    [ [ id: file.baseName.replace('.described', '') ], file ]
                                }

    // MODULE: GT_GFF3 as FINAL_GFF_CHECK
    ch_final_check_input        = ( val_describe_gff && val_db_folder )
                                ? ch_described_gff
                                : ch_purged_gff

    FINAL_GFF_CHECK ( ch_final_check_input )

    ch_final_gff                = FINAL_GFF_CHECK.out.gt_gff3
    ch_versions                 = ch_versions.mix(FINAL_GFF_CHECK.out.versions.first())

    emit:
    eggnogmapper_annotations    = ch_eggnogmapper_annotations   // Channel: [ meta, annotations ]
    eggnogmapper_orthologs      = ch_eggnogmapper_orthologs     // Channel: [ meta, orthologs ]
    eggnogmapper_hits           = ch_eggnogmapper_hits          // Channel: [ meta, hits ]
    final_gff                   = ch_final_gff                  // Channel: [ meta, gff ]
    versions                    = ch_versions                   // Channel: [ versions.yml ]
}
