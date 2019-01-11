#!/usr/bin/env perl

use strict;
my $v = "1.02";
print STDERR "RUNNING:deNovo.blastProteinDB.Annotate(<DataBase>).Version($v)\n";
print STDERR " Usage:
 cat BLAST_OUT | $0 -d DATABASE -m MINLEN -f MINLENRATIO [--best if BRBH]
 
 BLAST OUT" if ($ARGV[0]=~/-h/);
use Getopt::Long;
my $db_file;
my $bestformat;
my $minlenratio = 0.5;
my $minlen = 10;
my $getinfo = GetOptions(
   'd|db=s'       => \$db_file,
   'm|minlen=i'   => \$minlen,
   'f|minlenratio=f'=>\$minlenratio,
   'b|bestformat'   =>\$bestformat   
);



open(D, "$db_file") || die "error.DBmissing -> $db_file\n";

my %ec;
my %sym;
my %dsc;
my %len;
my $name;
my $description;
while (<D>) {
	chomp;
	if ($_=~/^>/) {
		my @description;
		($name, @description) = split / /, substr($_,1);
		$description = join(' ', @description);
		my ($ec, $symbol, $desc) = split /~~~/, $description;
		$ec{$name} = $ec;
		$sym{$name}= $symbol;
		$dsc{$name}= $desc;
		#print STDERR "$_\n\t-> $name|$ec|$symbol|$desc\n";
		
		if ($bestformat) {
			#>NP_414544.1 homoserine kinase [Escherichia coli str. K-12 substr. MG1655]
			$_=~s/\[.+\]//;
			my ($name, @description) = split / /, substr($_,1);
			print STDERR "$name -> $dsc{$name} ...$_\n";
			$dsc{$name} = join(' ', @description);
		}
		
		} else {
		$len{$name} += length($_);
		

	}
}
print STDERR "notify.DBparsed -> OK\n";
my %known;
print "Query\tSimilarProtein\tEC_Code\tSymbol\tBitScore\tE-Value\tTargetCoverage\tDescription\n" unless ($bestformat);
while (<STDIN>) {
	chomp;
	
	my ($query, $target, $id, $len, $A, $B, $C, $D, $E, $F, $eval, $bit);
	
	if ($bestformat) {
		($target, $query) = split /\,/, $_ if ($bestformat);
		$_=~tr/A-Za-z0-9_\-\.,//dc;
		($target, $query) = $_=~/^([^,]+),([^,]+)/;
	} else {
		($query, $target, $id, $len, $A, $B, $C, $D, $E, $F, $eval, $bit) = split /\t/, $_;
	}
		
	
	
	my $r = sprintf("%.4f", $len / $len{$target}) if ($len{$target});
	next if (!$bestformat and $r < $minlenratio);
	next if (!$bestformat and $len < $minlen);
	next if (!$bestformat and $known{$target});
	unless ($bestformat) {
		print "$query\t$target\t$ec{$target}\t$sym{$target}\t$bit\t$eval\t$r\t$dsc{$target}\n";
	} else {
		print "$query\t$target\t$ec{$target}\t$sym{$target}\t$dsc{$target}\n";
	}
	$known{$target} =1;
}
