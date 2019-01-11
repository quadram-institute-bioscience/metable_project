#!/usr/bin/env perl

use strict;

# Version
my $version = "1.0";

my $default_prefix = "ctg_";

print STDERR " CONTIG RENAMER $version
 Parameters: Input_File.predict [Prefix default=\"$default_prefix\"]
";
my ($input_file, $prefix) = @ARGV;

$prefix = $default_prefix unless ($prefix);

unless ($input_file) {
	exit;
}

open(I, '<', "$input_file") || die qq( FATAL ERROR: \n Unable to read input file: "$input_file".\n);

# EXAMPLE INPUT:
#>NODE_1_length_1459683_cov_83.4392_ID_2173
#orf00001       67     1062  +1     6.32
#orf00002     1078     1593  +1     6.21

my $discarded_orfs;
my $total;
my $counter = 0;
while (my $line = <I>) {
	
	if (substr($line, 0, 1)  eq '>') {
		$counter++;
		print ">$prefix$counter\n";
	} else {
		print $line;
	}
}
die " Nothing found in file\n" unless ($counter);
print STDERR " $counter contigs renamed.\n";