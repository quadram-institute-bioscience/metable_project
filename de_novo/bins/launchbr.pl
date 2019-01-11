#!/usr/bin/env perl

# Andrea Telatin, Cambridge 2016
# Version 2 (reduced dependencies)

use strict;
use Pod::Usage;
use Getopt::Long;
use File::Basename;
use Term::ANSIColor  qw(:constants);
my $crash = 0;
my $self_dir   = dirname($0);
my $bestScript = $self_dir . '/find-reciprocal.py';
my $opt_help;
my ($file1, $file2) = ('','');
my $threads = 1;
my $protein;
my $out = 'BRBH';
my $minE = 0.0001;
my $minLen = 20;

my $quiet_mode = 0;

my $result = GetOptions(
	'help'         => \$opt_help,
	'p|protein'    => \$protein,
	't|threads=i'  => \$threads,
	'm|minlen=i'   => \$minLen,
	'e|mineval=f'  => \$minE,
	'o|output=s'   => \$out,
	'q|quiet'      => \$quiet_mode
);

my $program = 'blastn';
my $no_prot = ' -p F ';
if ($protein) {
	$program    = 'blastp';
	$no_prot    = ' -p T ';
}

($file1, $file2) = @ARGV;
pod2usage({-exitval => 0, -verbose => 2}) if ($opt_help);
shortHelp( 'Best Reciprocal Best Hit Pipeline',
            'v. 0.2 -- Andrea Telatin 2016') unless ($file2);

d("Missing parameters: two multifasta files to be compared") if (($file1 eq '') or ($file2  eq ''));
d("First file doesn't exist: $file1") unless (-e "$file1");
d("Second file doesn't exist: $file2") unless (-e "$file2");

# Dependencies – have been stripped during last cleanup
my @depencencies = (
	$bestScript
);



## CHECK INPUT FILE NUM SEQ
my $l1 = `grep -c ">" "$file1"`;
my $l2 = `grep -c ">" "$file2"`;
($l1) = split /\s/, $l1;
($l2) = split /\s/, $l2;

unless ($quiet_mode) {
	print STDERR YELLOW " Sequence in $file1: ", RESET BOLD, "$l1\n", RESET;
	print STDERR YELLOW " Sequence in $file2: ", RESET BOLD, "$l2\n\n", RESET;
}

## FORMAT DATABASE FOR BLAST
my  $format1 = "formatdb $no_prot -i \"$file1\" ";
my  $format2 = "formatdb $no_prot -i \"$file2\" ";
run($format1);
run($format2);

my  $blast1 = "blastall -a $threads -p $program -d $file1 -i $file2 -m 8 -e $minE 2> $out.blast1.log ";
my  $blast2 = "blastall -a $threads -p $program -d $file2 -i $file1 -m 8 -e $minE 2> $out.blast2.log ";

my $temp1 = $out . '.blast1.txt';
my $temp2 = $out . '.blast2.txt';
blastcmd($blast1, $temp1);
blastcmd($blast2, $temp2);

run("python $bestScript $temp1 $temp2 > $out.brbh.txt");
my $l3 = `wc -l "$out.brbh.txt"`;
($l3) = split /\s/, $l3;

print STDERR "Best reciprocal best hits: $l3
Sequences in $file1: $l1
Sequences in $file2: $l2
Severe errors:       $crash
";
sub blastcmd {
	my $blastcmd = shift(@_);
	my $output   = shift(@_);
	my %hash;
	
	open(A, "$blastcmd |") || d("Unable to stream \"$blastcmd\"");
	open(O, ">$output")  || d("Unable to write BLAST output to \"$output\".");
	unless ($quiet_mode) {
		print STDERR YELLOW BOLD "\n BLAST: ", RESET YELLOW, " \"$blastcmd\"\n", RESET;
		print STDERR BOLD GREEN " Saving to \"$output\"";
	}
	my $last_pick;
	my $total = 0;
	my $filtered = 0;
	while (my $line = <A>) {
		$total++;
		chomp($line);
		my ($queryId, $subjectId, $percIdentity, 
			$alnLength, $mismatchCount, $gapOpenCount,
			$queryStart, $queryEnd, $subjectStart, $subjectEnd, 
			$eVal, $bitScore) = split /\t/, $line;
		next if ($alnLength < $minLen);
		$filtered++;
		print O "$queryId,$subjectId,$bitScore,$eVal\n";
	}
	print STDERR " $filtered/$total alignments.\n\n", RESET unless ($quiet_mode);
	close A;
	close O;
}

#run($blast1);
#run($blast2);

sub run {
	my $command = shift(@_);
	print STDERR YELLOW, BOLD, "\n Run: ", RESET YELLOW "\$ $command\n", RESET  unless ($quiet_mode);
	`$command`;
	if ($?) {
		$crash++;
		print STDERR "[ERROR $?] executing:\n#$command\n\n";
	}
}
sub d {
	my $message = shift(@_);
	print BOLD RED " FATAL ERROR\n", RESET;
	die " $message\n";
}
sub shortHelp {
	my ($title, $subtitle) = @_;
	my $line = ' ' . '-'x80 . "\n";
	print STDERR GREEN $line, RESET;
	print STDERR BOLD center($title, 82), RESET;
	print STDERR center($subtitle, 82), RESET;
	print STDERR GREEN $line, RESET;
	print STDERR " Usage: brbh.pl -t Threads File1.fa File2.fa \n";
	print STDERR " Type \"", GREEN BOLD, "--help" , RESET, "\" to display documentation.\n\n";
	exit;
}

sub center {
	my ($string, $space) = @_;
	my $side = int(($space - length($string)) / 2);	
	my $side_space = ' ' x $side;
	return $side_space . $string . $side_space."\n";
}
__END__
 
=head1 NAME
 
B<brbh.pl> - best reciprocal best hit table launcher

=head1 SYNOPSIS
 
brbh.pl --threads 2 file1.fasta file2.fasta
 
=head1 DESCRIPTION
 
This program performs a best reciprocal best hit analysis using scripts
in Python 2 from <http://ged.msu.edu/angus/tutorials/reciprocal-blast.html>.
 
=head1 REQUIREMENTS

This program requires: B<blastall> to be installed, in addition all the Python
scripts mentioned tin the ANGUS 2.0 tutorial.

=head1 PARAMETERS

=over 12

=item B<-t, --threads> INT

Number of cores for BLAST.

=item B<-p, --protein> 

Enable protein blast, rather than nucleotide blast

=item B<-o, --output> STRING

Output file basename.
Will save two blast results (.blast1.txt and .blast2.txt) 
and the best reciprocal best hit file (.brbh.txt).

=item B<-m, --minlen> INT

Minimum length for BLAST alignment

=item B<-e, --minevalue> FLOAT

Minimum e-value for BLAST

=back
 
=head1 AUTHOR
 
Andrea Telatin, 2016 <andrea@telatin.com> - Feel free to report bugs.
 
=head1 COPYRIGHT
 
Copyright (C) 2013 Andrea Telatin 
 
This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.
 
This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.
 
You should have received a copy of the GNU General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>.
 
=cut