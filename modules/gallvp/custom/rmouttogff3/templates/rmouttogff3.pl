#!/usr/bin/env perl
use strict;
use warnings;

# Originally written by Ross Crowhurst
# Adapted by Usman Rashid for Nextflow
# AS IS WHERE IS - USE AT YOUR OWN RISK
# License: MIT

=head1 DESCRIPTION

Converts a RepeatMasker .out file to gff3 format. The
standard gff output from RepeatMasker is gff version 2.

RepeatMasker "out.gff"

 seq1       RepeatMasker    similarity      1       1295    28.1    -       .       Target "Motif:Gypsy7-PTR_I-int" 3544 4847

RepeatMasker "out" file has the following format:

    SW   perc perc perc  query     position in query              matching              repeat                 position in repeat
 score   div. del. ins.  sequence  begin    end          (left)   repeat                class/family       begin   end    (left)      ID

  4634   28.1  1.2  0.5  seq1         1     1295        (0) C Gypsy7-PTR_I-int      LTR/Gypsy           (1215)   4847    3544      1

After conversion to gff3:

 seq1       RepeatMasker    dispersed_repeat        1       1295    4634    -       .       ID=1_seq1_1_1295_Gypsy7-PTR_I-int;Name=Gypsy7-PTR_I-int;class=LTR;family=Gypsy;percDiv=28.1;percDel=1.2;percIns=0.5

Notes:

- The Target attribute is not added in this implementation

=cut

my $repeatmaskerOutFile = "!{rmout}";
my $gff3Outfile = "!{prefix}.gff3";

my $source = "RepeatMasker";
my $type = "dispersed_repeat";

open(IN, "<$repeatmaskerOutFile") or die "ERROR can not open repeatmasker out file\n";
open(OUT, ">$gff3Outfile") or die "ERROR can not open gff3 out file\n";
select OUT; print OUT "##gff-version 3\n";
my $lastqName = "";
while ( my $line = <IN>)
{
	next if ($line =~ m/^$/);
	next if ($line =~ m/(perc|score|SW)/);
	chomp $line;
	$line =~ s/^([ ]+)//;
	$line =~ s/  / /g;
	$line =~ s/ /\t/g;
	$line =~ s/([\t]+)/\t/g;
	my ($SWscore, $percDiv, $percDel, $percIns, $qName, $qStart, $qEnd, $left, $ori, $repeatName, $repeatClassFamily, $rStart, $rEnd, $rLeft, $rId, @junk) = split/\t/, $line;
	($ori eq "C") and $ori = "-";
	my $id = join("_", $rId,  $qName, $qStart, $qEnd, $repeatName);
	my ($class, $family) = split/\//, $repeatClassFamily;
	$class ||= "na";
	$family ||= "na";
	my $gff3Line = join("\t",
		$qName,
		"$source",
		"$type",
		$qStart,
		$qEnd,
		$SWscore,
		$ori,
		".",
		"ID=$id;Name=$repeatName;class=$class;family=$family;percDiv=$percDiv;percDel=$percDel;percIns=$percIns");
	if (($lastqName ne $qName) and ($lastqName ne ""))
	{
		select OUT; print OUT "###\n";
	}
	select OUT; print OUT "$gff3Line\n";
	$lastqName = $qName;
}
select OUT; print OUT "###\n";

close(OUT);
close(IN);

# Capture the Perl version
my $perl_version = `perl --version`;
$perl_version =~ s/.*\(v(.*?)\).*/$1/s;

# Open the file and write the YAML content
open my $fh, '>', 'versions.yml' or die "Could not open versions.yml file";
print $fh qq{!{task.process}:\n    perl: $perl_version\n};
close $fh;

exit(0);
