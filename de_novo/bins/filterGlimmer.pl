#!/usr/bin/env perl

use strict;

# Version
my $version = "1.0";

my $default_min_score = 3.5;

print STDERR " FILTER GLIMMER PREDICTIONS $version
 Parameters: Input_File.predict [MinScore($default_min_score)]
";
my ($input_file, $threshold) = @ARGV;

$threshold = $default_min_score unless ($threshold);

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

while (my $line = <I>) {
	chomp($line);
	if (substr($line, 0, 1) eq '>') {
		print $line . "\n";
	} else {
		$total++;
		my @fields = split /\s+/, $line;
		if ($fields[-1] <= $threshold) {
			$discarded_orfs++;
		} else {
			print $line . "\n";
		}
	}
}
die " Nothing found in file\n" unless ($total);
my $percentage = sprintf("%.2f", 100 * $discarded_orfs / $total);
print STDERR "
TotalORFS:   $total
Discarded:   $discarded_orfs
Percentage:  $percentage%
";