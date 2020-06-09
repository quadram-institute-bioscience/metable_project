#!/usr/bin/env perl

use 5.012;
use warnings;
use File::Basename;
my $BIN = basename($0);
my $default_prefix = 'metable';
my $default_token  = 'P0000,Metable'

say STDERR "Usage: $BIN contigs_fasta [prefix] [project_token]";
say STDERR " - prefix:         table names prefix (default: $default_prefix)";
say STDERR " - project_token:  a string without spaces in the ProjectID,ProjectOwner format (default: $default_token)";

my $dir = shift;
my $prefix = shift // $default_prefix;

die "ERROR: Specify fasta file as input argument\n" unless $dir;

my $token = undef;

if ($dir =~/(\d{5})/) {
	say STDERR "Project ID: $1";
	my $id = $1;
	# sample2ps is the API returning ProjectID,ProjectNAME given a ProjectID
	# ^^^^^^^^^    it was an internal API, but any wrapper returning a comma delimited
	$token = `sample2ps $id 2>/dev/null` // 'PS0000,PROJECT';
	chomp($token);
}

my ($project_id, $project_owner) = split /,/ , $token;
my $sizes = `grep -v '>' $dir | wc -c`;
my $lines = `grep -v '>' $dir | wc -l`;
if ($0) {
	die "Error executing 'grep' and 'wc' on '$dir'";
}

chomp($sizes);
chomp($lines);;
($size) = split /\s/, $sizes;

print qq(INSERT INTO ${prefix}_genomes (id, owner, ps,size) VALUES
		 ("$id", "$project_owner", "$project_id", $size);\n);
