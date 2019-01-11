#!/usr/bin/env perl

use Getopt::Long;

# DEFAULTS
$every = 100000;
$format = 'fastq';

init();

if ($inputfile ne 'STDIN') {
	open (STDIN, "$inputfile") || die "  FATAL ERROR:\n   Unable to read \"$inputfile\".\n";
}


$header = "0";
while (<STDIN>) {
	chomp;
	my ($readname, $flag, $refname, $pos, $mapq, $cigar, $Rnext, $Pnext, $tlen, $seq, $qual, $opt) = split /\t/, $_;
	
	if ($f[0]=~/^\@/) {
		$header_lines++;
	} else {
		$c++;
		last if ($test and $test<=$c);
		my $strand = strand($flag);
		my $err = '';
		
		# SKIP IF ...
		$err += skip('unique') if ($uniq and $opt!~/IH:i:1/);
		$err += skip('reference') if ($r    and $refname ne $r);
		$err += skip('range_from') if ($from and $pos < $from);
		$err += skip('range_to') if ($to   and $pos > $to);
		if ($minq) {
			my $q = qual($qual);
			$err += skip('minqual') if ($q < $minq);
		}
		$err += skip('length') if ($minl and length($seq)<$minl);
		
		next if $err;
		$printed++;
		
		if ($norev==0 and $strand eq '-') {
		    $seq = reverse $seq;
		    $qual = reverse $qual;
		   # $seq =~ tr/acgt ryswkm bdhv ACGT RYSWKM BDHV/tgca yrswmk vhdb TGCA YRSWMK VHDB/;		
			$seq  =~tr/acgtACGT/tgcaTGCA/ unless ($noflip);
			
		}
		
		if ($format eq 'fasta') {
			print ">$readname\n".formatdna($seq);
		} else {
			print "\@$readname\n".formatdna($seq)."+\n".formatdna($qual);		
		}
		
		unless ($c % $every) {
			$p = sprintf("%.2f", 100*$printed/$c) if ($c);
			print STDERR "$c lines parsed ($p% printed)...\r";
		}
		
	}
}
$disc = $c-$printed;
$p    = sprintf("%.2f", 100*$printed/$c) if ($c);
print STDERR "Finished.                                 \n
Header      $header lines
Parsed      $c sequences
Printed     $printed sequences ($p%)
Discarded   $disc

Discarded by filter:
";

foreach $problem (keys %counter) {
	print STDERR fixed($problem)."\t$counter{$problem}\n";
}
sub fixed {
	my $s = shift;
	my $S = 12-length($s);
	my $f = ' ' x $S;
	return "$s$f";
}
sub skip {
	$tag = shift;
	$counter{$tag}++;
	return 1;
}
sub formatdna {
	my $s = shift;
	return "$s\n" unless ($break);
	my $formatted;
	my $line = 70; # change here
	for ($i=0; $i<length($s); $i+=$line) {
		my $frag = substr($s, $i, $line);
		$formatted.=$frag."\n";
	}
	return $formatted;
}

sub qual {
	my $string = shift;
	my $v;
	my $qstring;
        my $len;
	for (my $i=0; $i<length($string); $i++) {
		$q = substr($string, $i, 1);
		$Q = ord($q) - 33;
		$v+=$Q;
		$len++;
                   
	}
        $v/=$len if ($len);
	#print STDERR "$qstring\n";
	return $v;
}
sub strand{
  my $flag = shift;
  my $strand = '+';
  if ($flag & 0x10) {
	  $strand = '-';
  }
  return $strand;		
}

sub init {
$opt = GetOptions(
	'i=s' => \$inputfile,
	'f=s' => \$format,
	'u'   => \$unique,
	'r=s' => \$r,
	'b'   => \$break,
	'from=i' => \$from,
	'format=s' => \$format,
	'to=i'  => \$to,
	'minq=i' => \$minq,
	'minl=i' => \$minl,
	'every=i' => \$every,
	'debug'   => \$debug,
	'help'    => \$help,
	'norev'   => \$norev,
	'noflip'  => \$noflip,
	'test=i'  => \$test,
        'onlyfor' => \$onlyfor,
	'onlyrev' => \$onlyrev
);

print STDERR "
  SAM TO FASTQ CONVERSION
  ---------------------------------------------------------
";
if ($help or !$inputfile) {
print STDERR 
"   -i       FILE      SAM file to be converted ['STDIN' for STDIN]
   -f       FORMAT    fasta or fastq [default: fastq]
   -u                 convert only unique alignments
   -r       REFNAME   convert only sequences aligned in <REFNAME>
   -from    POSITION  convert only sequences aligned after <POS>
   -to      POSITION  convert only sequences aligned before <POS>
   -minq    QUAL      convert only sequences with avg quality > <QUAL>
   -minl    LEN       convert only sequences longer than <LEN>
   -b                 add new-lines in long sequences (every 70 chars)
   -noflip            avoid reversing reads aligned on minus strand
   -onlyfor    
   -onlyrev
";
exit;
}


if ($format ne 'fastq' and $format ne 'fasta') {
	print STDERR " [WARNING] Setting format=fastq: your '$format' parameter is not recognized.\n";
	$format = 'fastq';
}
if (($from or $to) and !$r) {
	print STDERR " [WARNING] You provided a range but not a reference... Could be an error?\n";
}

return 0;
}
