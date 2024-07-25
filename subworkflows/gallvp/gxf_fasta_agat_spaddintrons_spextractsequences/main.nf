include { AGAT_SPADDINTRONS             } from '../../../modules/gallvp/agat/spaddintrons/main'
include { AGAT_SPEXTRACTSEQUENCES       } from '../../../modules/gallvp/agat/spextractsequences/main'

workflow GXF_FASTA_AGAT_SPADDINTRONS_SPEXTRACTSEQUENCES {

    take:
    ch_gxf                              // channel: [ val(meta), gxf ]
    ch_fasta                            // channel: [ val(meta2), fasta ]

    main:
    ch_versions                         = Channel.empty()

    // collectFile: Remove all/partial introns
    ch_gxf_purged                       = ch_gxf
                                        | map { meta, gxf ->
                                            def gxf_lines = gxf.readLines().findAll { line ->

                                                if ( line.startsWith('#') ) { return true }

                                                def cols = line.tokenize('\t')
                                                def feat = cols[2].trim().toLowerCase()

                                                if ( feat == 'intron' ) { return false }

                                                return true
                                            }

                                            [ "${meta.id}.nointrons.${gxf.extension}", gxf_lines.join('\n') ]
                                        }
                                        | collectFile
                                        | map { gxf -> [ gxf.baseName.replace('.nointrons', ''), gxf ] }
                                        | join(
                                            ch_gxf.map { meta, gxf -> [ meta.id, meta ] }
                                        )
                                        | map { id, gxf, meta -> [ meta, gxf ] }

    // MODULE: AGAT_SPADDINTRONS
    AGAT_SPADDINTRONS ( ch_gxf_purged, [] )

    ch_introns_gff                      = AGAT_SPADDINTRONS.out.gff
    ch_versions                         = ch_versions.mix(AGAT_SPADDINTRONS.out.versions.first())

    // MODULE: AGAT_SPEXTRACTSEQUENCES
    ch_gxf_fasta                       = ch_introns_gff
                                        | map { meta, gff3 -> [ meta.id, meta, gff3 ] }
                                        | join(
                                            ch_fasta.map { meta2, fasta -> [ meta2.id, fasta ] }
                                        )
                                        | map { id, meta, gff3, fasta -> [ meta, gff3, fasta ] }

    AGAT_SPEXTRACTSEQUENCES(
        ch_gxf_fasta.map { meta, gff3, fasta -> [ meta, gff3 ] },
        ch_gxf_fasta.map { meta, gff3, fasta -> fasta },
        [] // config
    )

    ch_intron_sequences                 = AGAT_SPEXTRACTSEQUENCES.out.fasta
    ch_versions                         = ch_versions.mix(AGAT_SPEXTRACTSEQUENCES.out.versions.first())

    // collectFile: splice motifs
    ch_splice_motifs                    = ch_intron_sequences
                                        | map { meta, fasta ->
                                            def splice_motifs = fasta.splitFasta ( record: [id: true, seqString: true] )
                                                .collect { el -> [ el.id, "${el.seqString[0..1]}${el.seqString[-2..-1]}" ].join('\t') }

                                            [ "${meta.id}.motifs.tsv", splice_motifs.join('\n') ]
                                        }
                                        | collectFile
                                        | map { tsv -> [ tsv.baseName.replace('.motifs', ''), tsv ] }
                                        | join(
                                            ch_gxf_purged.map { meta, gxf -> [ meta.id, meta ] }
                                        )
                                        | map { id, tsv, meta -> [ meta, tsv ] }

    // collectFile: Mark gff3
    ch_marked_gff3                      = ch_introns_gff
                                        | join ( ch_splice_motifs )
                                        | map { meta, gff3, tsv ->
                                            def motif_map = [:]
                                            tsv.eachLine { line ->
                                                def cols = line.tokenize('\t')
                                                def id = cols[0]
                                                def motif = cols[1]

                                                motif_map [ ( id ) ] = motif
                                            }

                                            def marked_gff3 = gff3.readLines().collect{ line ->
                                                if ( line.startsWith('#') ) { return line }

                                                def cols = line.tokenize('\t')
                                                def feat = cols[2].trim()

                                                if ( feat != 'intron' ) { return line }

                                                def atts = cols[8].trim()
                                                def id = ( atts =~ /ID=([^;]*)/ )[0][1]

                                                def atts_r = "$atts;splice_motif=${motif_map[id]};canonical_splicing=${motif_map[id]=='GTAG'}"

                                                return ( cols[0..7] + [ atts_r ] ).join('\t')
                                            }

                                            [ "${meta.id}.marked.gff3", marked_gff3.join('\n') ]
                                        }
                                        | collectFile
                                        | map { gff3 -> [ gff3.baseName.replace('.marked', ''), gff3 ] }
                                        | join(
                                            ch_gxf_purged.map { meta, gxf -> [ meta.id, meta ] }
                                        )
                                        | map { id, gff3, meta -> [ meta, gff3 ] }

    emit:
    motifs_tsv                          = ch_splice_motifs  // channel: [ val(meta), tsv ]
    marked_gff3                         = ch_marked_gff3    // channel: [ val(meta), gff3 ]
    versions                            = ch_versions       // channel: [ versions.yml ]
}
