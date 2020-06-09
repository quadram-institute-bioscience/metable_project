#!/usr/bin/env perl

use 5.012;
my %hits= ();
my $prev_ec;

say STDERR "Usage: cat FILE | perl $0";

while (my $line = <STDIN>) {
 my $ec;
  #INSERT INTO metable_genes (genome, type, contig, start, end, strand, prokka, ec, gene, inference, locus_tag, product)
  #         VALUES ("30286","CDS", "ctg_1", "67", "1062", 1,"PROKKA_00001", "3.1.-.-", "yqcG_1", "ab initio prediction:Prodigal:2.6,similar t
 if ($line=~/^INSERT/) {
	print $line;
 } else {
	my @array = split /,/, $line;
	my $gene = $array[8];
    $ec   = $array[7];
	my $key = "$array[0]$array[8]";

	if ($hits{$key} > 0) {
		$array[8] = ' NULL';
    $array[7] = ' NULL';
	}
  if ($ec eq $prev_ec) {
    $array[7] = ' NULL';
  }
	$hits{$key}++;
	print join(",", @array);
  $prev_ec = $ec;
 }

}
