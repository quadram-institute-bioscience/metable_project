#!/usr/bin/env perl
use Getopt::Long;


$minProtLen = 10;
$getinfo =GetOptions(
   'g=s' => \$glimfile,
   'f=s' => \$contigfile,
   'x'   => \$discard,
   't'   => \$translate,
   'd'   => \$debug,
   'm=i' => \$minProtLen,
   'help'=> \$help
 );
init();

open (G, "$glimfile") || die "FATAL ERROR: Unable to open glimmer file: $glimfile\n";
open (F, "$contigfile") || die "FATAL ERROR: Unable to open glimmer file: $contigfile\n";

print STDERR " # Reading glimmer file...\n";
while (<G>) {
	chomp;
	if ($_=~/>(\S+)/) {
		$global_contig_counter++;
		$contig = $1;
		$contignames{$contig} = 1;
		
		#$contig=~/contig(\d+)/; # NEWBLER SPECIFIC
		
		if ($contig=~/contig(\d+)/) {			# Newbler
			$contig_id = $1;
		} elsif ($contig=~/(NODE_\d+)_/) {		# Spades/Velvet
			$contig_id = $1;
		}
			$contig_id = $contig;
		}
		print STDERR "GLIM::$contig id:$contig_id\n" if ($debug);
	} else {
		($orfname, $start, $end, $frame, $score) = split /\s+/, $_; #orf00009     5711     6937  +2     2.96
        ($start, $end) = sort {$a <=> $b} ($start, $end);
		${$contig}{"$start-$end"}="$contig_id.$orfname";
		$frame{"$contig_id.$orfname"}=$frame;
		print STDERR "----::$contig_id.$orfname\n" if ($debug);
		$orf_count++;		
	}
}

print STDERR "$orf_count ORFs in glimmer file (in $global_contig_counter contigs)\n";

# Parse FASTQ
my @aux = undef;

print STDERR " # Reading FASTA file...\n";

while (my ($name, $seq, $qual) = readfq(\*F, \@aux)) {
	$f++;
	print STDERR "SEQ::$name\n" if ($debug);
	foreach $range (keys %{$name}) {
		#print STDERR "\t$range ${$name}{$range}  '$frame{${$name}{$range}}'\n";
		my ($start, $end) = split /-/, $range;
		$start--; $end--;
		my ($start, $end) = sort {$a <=> $b} ($start, $end);
		my $len = $end-$start+1;
		my $dna = substr($seq, $start, $len);
		$dna = rc($dna) if ($frame{${$name}{$range}}<0);
		$str = substr($dna, 0, 3);
		$cnt{$str}++;

        if ($translate) {
            chop($dna);
            my $protein;
            for (my $i=0; $i<(length($dna)-2); $i+=3) {
                my $codon=uc(substr($dna,$i,3));
                $protein.=$g{$codon};
            }
            $dna = $protein;
            if ($discard) {
            	($first_chunk) = split /_/, $dna;
            	next if (length($first_chunk) < $minProtLen);
            	$dna = $first_chunk;
            }
        }
		print ">${$name}{$range} $frame{${$name}{$range}}\n".$dna."\n";	
	}
}
print STDERR "$f sequences parsed.\n";

foreach $i (sort {$cnt{$a} <=> $cnt{$b}} keys %cnt) {
	print STDERR "$i\t$cnt{$i}\t".sprintf("%.1f", 100*$cnt{$i}/$orf_count)."\n" if ($cnt{$i} > 2);
}

sub init {

    print STDERR " 
------------------------------------
 GLIMMER TO MULTIFASTA GENES
------------------------------------
 -g   glimmer predictions
 -f   contigs fasta
 -t   translate 
 -x   discard malformed proteins :)

" if ($help or !($glimfile) or !($contigfile));

    %g =('TCA'=>'S','TCC'=>'S','TCG'=>'S','TCT'=>'S','TTC'=>'F','TTT'=>'F',
'TTA'=>'L','TTG'=>'L','TAC'=>'Y','TAT'=>'Y','TAA'=>'_','TAG'=>'_',
'TGC'=>'C','TGT'=>'C','TGA'=>'_','TGG'=>'W','CTA'=>'L','CTC'=>'L',
'CTG'=>'L','CTT'=>'L','CCA'=>'P','CCC'=>'P','CCG'=>'P','CCT'=>'P',
'CAC'=>'H','CAT'=>'H','CAA'=>'Q','CAG'=>'Q','CGA'=>'R','CGC'=>'R',
'CGG'=>'R','CGT'=>'R','ATA'=>'I','ATC'=>'I','ATT'=>'I','ATG'=>'M',
'ACA'=>'T','ACC'=>'T','ACG'=>'T','ACT'=>'T','AAC'=>'N','AAT'=>'N',
'AAA'=>'K','AAG'=>'K','AGC'=>'S','AGT'=>'S','AGA'=>'R','AGG'=>'R',
'GTA'=>'V','GTC'=>'V','GTG'=>'V','GTT'=>'V','GCA'=>'A','GCC'=>'A',
'GCG'=>'A','GCT'=>'A','GAC'=>'D','GAT'=>'D','GAA'=>'E','GAG'=>'E',
'GGA'=>'G','GGC'=>'G','GGG'=>'G','GGT'=>'G');

}
sub rc {
	my $dna = shift;
	$dna = reverse($dna);
	$dna =~tr/acgtACGT/tgcaTGCA/;
	return $dna;

}
sub readfq {
    my ($fh, $aux) = @_;
    @$aux = [undef, 0] if (!defined(@$aux));
    return if ($aux->[1]);
    if (!defined($aux->[0])) {
        while (<$fh>) {
            chomp;
            if (substr($_, 0, 1) eq '>' || substr($_, 0, 1) eq '@') {
                $aux->[0] = $_;
                last;
            }
        }
        if (!defined($aux->[0])) {
            $aux->[1] = 1;
            return;
        }
    }
    my $name = /^.(\S+)/? $1 : '';
    my $seq = '';
    my $c;
    $aux->[0] = undef;
    while (<$fh>) {
        chomp;
        $c = substr($_, 0, 1);
        last if ($c eq '>' || $c eq '@' || $c eq '+');
        $seq .= $_;
    }
    $aux->[0] = $_;
    $aux->[1] = 1 if (!defined($aux->[0]));
    return ($name, $seq) if ($c ne '+');
    my $qual = '';
    while (<$fh>) {
        chomp;
        $qual .= $_;
        if (length($qual) >= length($seq)) {
            $aux->[0] = undef;
            return ($name, $seq, $qual);
        }
    }
    $aux->[1] = 1;
    return ($name, $seq);
}

