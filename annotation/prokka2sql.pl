#!/usr/bin/env perl


my $file = shift;
unless (-e "$file") {
	print STDERR " PROKKA GFF 2 SQL
	Parameter: <InputFile.gff>\n";
}
$file =~/(\d{5})/;
my $id = $1;

unless ($id) {
	print STDERR "\n WARNING:\n This program expects the ID of each sample to be a 5 digits code within the filename!\nNo ID has been found.\n";
}

open(STDIN, "$file") || die "\n FATAL ERROR:\n Unable to read $file.\n";
while (<STDIN>) {
	chomp;
	my ($ct, $X, $ty, $s, $e, $x, $str, $x, $cc) = split /\t/, $_;
	my @f = split /[=;]/, $cc;
	$strand = "TRUE";
	$strand = "FALSE" if ($str eq '-');
	while ($cc=~/(\w+)=([^;]+)/g) {
		$A = $1; $B=$2;
		$prokka = $B if ($A=~/ID/);
		$inf = $B if ($A=~/inference/);
		$locus = $B if ($A=~/locus_tag/);
		$product = $B if ($A=~/product/);
		$gene = $B if ($A=~/gene/);
		$ec = $B if ($A=~/EC/i);
		
#		print "# $A ->  $B\n";
	}
	next if ($s!~/^\d+$/);
	print qq(INSERT INTO bmr_genes (genome, type, contig, start, end, strand, prokka, ec, gene, inference, locus_tag, product)
	 VALUES ("$id", "$ty", "$ct", "$s", "$e", $strand, "$prokka", "$ec", "$gene", "$inf", "$locus", "$product");\n);
}



exit;

# EXAMPLE INPUT
#$and = '
#ctg_1   Prodig0       ID=PROKKA_00032;inference=ab initio prediction:Prodigal:2.6,protein motif:Pfam:PF01243.14;locus_tag=PROKKA_00032;product=Pyridoxamine 5'-phosphate oxidase
#ctg_1   Prodigal:2.6    CDS     34922   35875   .       -       0       ID=PROKKA_00033;inference=ab initio prediction:Prodigal:2.6;locus_tag=PROKKA_00033;product=hypothetical protein
#';
