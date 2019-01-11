#!/usr/bin/env perl

# Andrea Telatin, Jan 2016
# NOTES: Binaries in PATH have priority over local ones (to be fixed)

use Pod::Usage;
use Getopt::Long;
use File::Basename;
use Term::ANSIColor  qw(:constants);
use Digest::MD5 qw(md5 md5_hex md5_base64);
use Time::HiRes qw( time );
use Data::Dumper;
use strict;

my $version  = "1.04";
my $self_dirname  = dirname($0);
my $myBins = $self_dirname . '/bins';
my $myDb   = $self_dirname . '/db';
my $proteinDB = $myDb . '/sprot';
my $coliProtDB= $myDb . '/coli_proteins.faa';
my $coliGenesDB= $myDb . '/coli_genes_codes.fna';

title();
my $global_command_counter;
my %bin;


my $threads = 1;
my $skip  = 1;
my $log_file;
my $input_dir;
my $domerge;
my $debug;
my $opt_help;
my $output_dir;
my $noskip;
my $getinfo = GetOptions(
   'h|help'       => \$opt_help,
   'l|log=s'      => \$log_file,
   'i|input_dir=s'=> \$input_dir,
   'm|merge'      => \$domerge,
   'D|debug'      => \$debug,
   'o|outdir=s'   => \$output_dir,
   't|threads=i'  => \$threads,
   's|skip'       => \$skip,
   'recalculate'  => \$noskip
);

$skip = 0 if ($noskip);
# Handle help
pod2usage({-exitval => 0, -verbose => 2}) if ($opt_help);
unless (-d "$input_dir") {
	shortHelp();
}

title('Initialization');
check_dependencies();
info("Input dir: \"$input_dir\"");
$output_dir = $input_dir unless ($output_dir);
info("Output dir: \"$output_dir\"");
$log_file = $output_dir .'/denovo.log.txt' unless ($log_file);
info("Log file: \"$log_file\"");

open(LOG, ">>$log_file") || crash("Unable to write to log file: \"$log_file\".\n");

info('Debug mode: ON') if ($debug);


title('Checking input');
# CHECK INPUT DIRECTORY
#changed: was !/$!!
$input_dir=~s/\/$//;

my $reads_dir = $input_dir . '/reads';
my $refgenome_dir = $input_dir . '/ref_genome';
my $refgenes_dir = $input_dir . '/ref_genes';
my $refprot_dir = $input_dir . '/ref_prot'; 

my @reads_files;
crash("Input directory does not exist: \"$input_dir\".") unless (-d "$input_dir");
if (-d "$reads_dir") {
	#info("Reads dir found: \"$reads_dir\"");
	@reads_files = getCheckDir($reads_dir, 'Reads');
} else {
	crash("Unable to find input reads in \"$reads_dir\"");
}

my @refgenome_files = getCheckDir($refgenome_dir, 'Reference genomes');
my @refgenes_files  = getCheckDir($refgenes_dir,  'Reference genes');
my @refprot_files  =  getCheckDir($refgenes_dir,  'Reference proteins');

my $reads_params = '';
my $bwa_reads;
if (scalar @reads_files) {	
	my %pairs;
	foreach my $read_file (@reads_files) {
		if ($read_file =~/_R1/) {
			my ($base, $rest) = $read_file =~/(.*)_R1(.*)/;
			$pairs{"$base$rest"}.="$read_file,";
			$bwa_reads = "$input_dir/reads/$read_file $bwa_reads";
		} elsif ($read_file =~/_R2/) {
			my ($base, $rest) = $read_file =~/(.*)_R2(.*)/;
			$pairs{"$base$rest"}.="$read_file,";
			$bwa_reads = "$bwa_reads $input_dir/reads/$read_file";
		} else {
			$reads_params.= " -s \"$input_dir/reads/$read_file\" ";
			info("\tSingle read file: $read_file\n");
			$bwa_reads = $read_file;
		}
	}
	
	
	foreach my $key (keys %pairs) {
		my $reads = $pairs{$key};
		chop($reads);
		my ($file1, $file2) = split /,/, $reads;
		if ($file2) {
			if ($file1=~/_R([12])/) {
				$reads_params .= " -$1 \"$input_dir/reads/$file1\" ";
				info("Adding file \"$file1\" (R$1)");
				
			}
			if ($file2=~/_R([12])/) {
				$reads_params .= " -$1 \"$input_dir/reads/$file2\" ";
				info("Adding file \"$file2\" (R$1)");
			}
		} else {
			info(" ERROR: Invalid file input at $key -> $reads");
		}
		
	}
} else {
	crash("No files found in \"$reads_dir\". Nothing to do?");
}


# DE NOVO ASSEMBLY
title('De novo assembly');

my $run_denovo = $bin{'spades.py'} . 
	' -k 21,33,55,77,99,127 --careful '.
	' -o '. $output_dir.'/assembly'. 
	' -t '. $threads .
	$reads_params . ' 2>&1  > /dev/null';

run_command($run_denovo, 
			'SPAdes assembly',
			'assembly/contigs.fasta');

my $rename = qq(mv  "$output_dir/assembly/contigs.fasta"   "$output_dir/assembly/contigsRaw.fasta" && $bin{'renameContigs.pl'} "$output_dir/assembly/contigsRaw.fasta" > "$output_dir/assembly/contigs.fasta" );
		     
run_command($rename,
	'Renaming contigs',
	'assembly/contigsRaw.fasta');

# GENE PREDICTION AND ORF EXTRACTION
title('Gene prediction');

my $run_geneprediction = $bin{'g3-from-scratch.csh'} .
 ' ' . $output_dir . '/assembly/contigs.fasta' .
 ' ' . $output_dir . '/geneprediction/glimmer' .
 " 2>  $output_dir/geneprediction/glimmer.program.log ";

#run_command("mkdir \"$output_dir/geneprediction\"
#	&& mkdir \"$output_dir/alignments\" 
#	&& mkdir \"$output_dir/reports\" ", 'Creating directory') unless (-d "$output_dir/geneprediction");

make_subdirs($output_dir, 'geneprediction', 'alignments', 'reports', 'blast');

run_command($run_geneprediction,
			'Predicting ORFs with Glimmer',
			'geneprediction/glimmer.predict');
			

my $filter_predictions = qq(mv $output_dir/geneprediction/glimmer.predict $output_dir/geneprediction/glimmerFull.predict && ) .
	qq($bin{'filterGlimmer.pl'} $output_dir/geneprediction/glimmerFull.predict 3.0 >  $output_dir/geneprediction/glimmer.predict 2>  $output_dir/geneprediction/filtered_ORFs.log );
run_command($filter_predictions,
	'Filtering predicter ORFs',
	'geneprediction/glimmerFull.predict');	

my $run_orf = $bin{'glimmer_to_fasta.pl'} . 
 ' -g ' . $output_dir . '/geneprediction/glimmer.predict' .
 ' -f ' . $output_dir . '/assembly/contigs.fasta' .
 " 2>> $output_dir/geneprediction/orf_to_fasta.logs " .
 "  > $output_dir/geneprediction/genes.fasta";
 
run_command($run_orf,
 			'Extracting ORFs (genes)',
 			"geneprediction/genes.fasta");
 
my $run_prot = $run_orf;
$run_prot =~s/ -g / -t -x -g /;
$run_prot =~s/genes\.fasta$/proteins.fasta/;

run_command($run_prot,
 			'Extracting ORFs (proteins)',
 			"geneprediction/proteins.fasta");
 

my $prokka_out = $output_dir . '/PROKKA_annotation/';
my $prokka = "prokka --outdir \"$prokka_out\" " .  $output_dir . '/assembly/contigs.fasta' ;

run_command($prokka,
		'Automatic annotation (PROKKA)');

title('Reads alignments');
# Align against contigs

my $bwa = $bin{'bwa'} . " index \"$output_dir/assembly/contigs.fasta\" 2> \"$output_dir/alignments/bwaindex.log\"  && ";
$bwa.= $bin{'bwa'} . " mem -t $threads \"$output_dir/assembly/contigs.fasta\" $bwa_reads " .
 		" >  \"$output_dir/alignments/reads_on_contigs.sam\" ".
 		" 2> \"$output_dir/alignments/reads_on_contigs.bwa.log\"  " ;

run_command($bwa,
			'Align reads against contigs',
			'alignments/reads_on_contigs.sam');
			
my $bam = $bin{'samtools'}. " view -bS \"$output_dir/alignments/reads_on_contigs.sam\" >  \"$output_dir/alignments/unsorted.bam\"  2> \"$output_dir/alignments/samtoolsView.log\" && " .
	   $bin{'samtools'}. " sort  \"$output_dir/alignments/unsorted.bam\"  \"$output_dir/alignments/reads_on_contigs\" 2> \"$output_dir/alignments/samtoolsSort.log\"  && " .
	   "rm  \"$output_dir/alignments/unsorted.bam\" ";
	   
run_command($bam,
			'Create sorted BAM file',
			"/alignments/reads_on_contigs.bam");


my $cov_stats = $bin{'coverage'} . " --stats=\"$output_dir/alignments/coverageStats\" ".
				" \"$output_dir/alignments/reads_on_contigs.bam\" ";
run_command($cov_stats,
			'Coverage statistics',
			'alignments/coverageStats.refs.tsv');
			

if (@refgenome_files[0]) {
	title('Reference genome mapping');

	foreach my $reference (@refgenome_files) {
		if ($reference!~/(fna|fasta|fa)$/i) {
			info("Skipping $reference: accepted extensions are fna,fasta,fa");
			next;
		}
		my $rfile = "$input_dir/ref_genome/$reference";
		info("Analyzing reference: $reference");
		my $bwa = $bin{'bwa'} . " index \"$rfile\" && " . 
				  $bin{'bwa'} . " mem -t $threads  \"$rfile\" $bwa_reads  ".
				  " > \"$output_dir/alignments/reads_on_$reference.sam\" " .
				  "2> \"$output_dir/alignments/reads_on_$reference.log\" " ;
		run_command($bwa, 'Aligning reads', "alignments/reads_on_$reference.sam");
		my $bam = $bin{'samtools'}. " view -bS \"$output_dir/alignments/reads_on_$reference.sam\" | " .
	   			  $bin{'samtools'}. " sort -  \"$output_dir/alignments/reads_on_$reference\" ";
	   			  
	   	run_command($bam, 'Generating BAM file', "alignments/reads_on_$reference.bam" );
	   	
	   	my $cov_stats = $bin{'coverage'} . " -M 1 --stats=\"$output_dir/alignments/coverageStats_on_$reference\" ".
	   			" -r \"$output_dir/alignments/regionsMissing_vs_$reference.bed\" " .
				" \"$output_dir/alignments/reads_on_$reference.bam\" ";
		run_command($cov_stats,
			'Coverage statistics',
			"alignments/coverageStats_on_$reference.refs.tsv");
		
	}
} else {
	info("Skipping reference genome comparison: no reference genome(s) found.");
}



# BLAST TO PROTEIN
title('Blast to Protein DB');

my $blast_db = $bin{'blastall'} .
	' -p blastp -e 0.0001 -m 8 -d ' . $proteinDB .
	' -a ' . $threads .
	' -i ' . "$output_dir/geneprediction/proteins.fasta" .
	"  > \"$output_dir/blast/blast_proteins.txt\" " .
	" 2> \"$output_dir/blast/blast_proteins.log\" ";

unless (-e "$proteinDB") {
	info('Skipping Protein Blast: Protein database not found: '.$proteinDB);
} else {
	run_command($blast_db,
		'Blast ORFs against protein database',
		'blast/blast_proteins.txt'
		);
		
	my $annotate = "cat \"$output_dir/blast/blast_proteins.txt\"  | " . 
				$bin{'denovo_blastp.pl'} . " -d \"$proteinDB\" " .
				" > \"$output_dir/blast/blast_proteins.annotation.txt\" ";
	run_command($annotate, 
			'Annotating BLAST proteins',
			'blast/blast_proteins.annotation.txt');
	# Best reciprocal best hit BRBH
	# launchbr.pl -t THREADS FIle1 File2

	my $brbh_proteins = $bin{'launchbr.pl'} . ' -t ' . $threads .
		 ' --protein --minlen 22  --output ' . " \"$output_dir/blast/BRBH_PROTEINS\" " . 
		 " \"$output_dir/geneprediction/proteins.fasta\" \"$proteinDB\" ";

	run_command($brbh_proteins,
			'Best reciprocal best hit, proteins',
			'blast/BRBH_PROTEINS.blast1.txt');
	my $annotate2 = "cat \"$output_dir/BRBH_PROTEINS.brbh.txt\"  | " . 
				$bin{'denovo_blastp.pl'} . " --best -d \"$proteinDB\" " .
				" > \"$output_dir/blast/Proteins_brbh.annotation.txt\" ";
	
	run_command($annotate2, 'Annotation of BRBH', 'blast/Proteins_brbh.annotation.txt');

}

# Coli proteins
unless (-e "$coliProtDB") {
	info('Skipping *E. coli* Protein Blast: Protein database not found: '.$proteinDB);
} else {
	my $blastColi = $bin{'blastall'} .
	' -p blastp -e 0.0001 -m 8 -d ' . $coliProtDB .
	' -a ' . $threads .
	' -i ' . "$output_dir/geneprediction/proteins.fasta" .
	"  > \"$output_dir/blast/blast_coli_proteins.txt\" ".
	" 2> \"$output_dir/blast/blast_coli_proteins.log\" ";
	
		run_command($blastColi,
		'Blast ORFs against *E. coli* database',
		'blast/blast_coli_proteins.txt'
		);
		
	my $annotate = "cat \"$output_dir/blast/blast_coli_proteins.txt\"  | " . 
				$bin{'denovo_blastp.pl'} . " -d \"$coliProtDB\" " .
				" > \"$output_dir/blast/blast_coli_proteins.annotation.txt\" ";
	run_command($annotate, 
			'Annotating *E. coli* BLAST proteins',
			'blast/blast_coli_proteins.annotation.txt');
	# Best reciprocal best hit BRBH
	# launchbr.pl -t THREADS FIle1 File2

	my $brbh_proteins = $bin{'launchbr.pl'} . ' -t ' . $threads .
		 ' --protein --minlen 22  --output ' . " \"$output_dir/blast/BRBH_COLI_PROTEINS\" " . 
		 " \"$output_dir/geneprediction/proteins.fasta\" \"$coliProtDB\" ";

	run_command($brbh_proteins,
			'Best reciprocal best hit, *E. coli* proteins',
			'blast/BRBH_COLI_PROTEINS.blast1.txt');
			
	my $annotate = "cat \"$output_dir/blast/BRBH_COLI_PROTEINS.brbh.txt\"  | " . 
				$bin{'denovo_blastp.pl'} . " --best -d \"$proteinDB\" " .
				" > \"$output_dir/blast/Ecoli_brbh.annotation.txt\" ";
	
	run_command($annotate, 'Annotation of *E. coli* BRBH', 'blast/Ecoli_brbh.annotation.txt');

}



# Coli genes #TODO DA SISTEMRARE
unless (-e "$coliGenesDB") {
	info('Skipping *E. coli* Protein Blast: Protein genes not found: '.$coliGenesDB);
} elsif (0 == 3) { ##<<--- TODO RIMUOVERE ANTISTUPRO
	my $blastColi = $bin{'blastall'} .
	' -p blastn -e 0.0001 -m 8 -d ' . $coliGenesDB .
	' -a ' . $threads .
	' -i ' . "$output_dir/geneprediction/genes.fasta" .
	"  > \"$output_dir/blast/blast_coli_genes.txt\" " .
	" 2> \"$output_dir/blast/blast_coli_genes.log\"";
	
	run_command($blastColi,
		'Blast ORFs against *E. coli* genes database',
		'blast/blast_coli_genes.txt'
		);
		
	my $annotate = "cat \"$output_dir/blast/blast_coli_genes.txt\"  | " . 
				$bin{'denovo_blastp.pl'} . " -d \"$coliGenesDB\" " .
				" > \"$output_dir/blast/blast_coli_genes.annotation.txt\" ";
	run_command($annotate, 
			'Annotating *E. coli* BLAST genes',
			'blast/blast_coli_genes.annotation.txt');
	# Best reciprocal best hit BRBH
	# launchbr.pl -t THREADS FIle1 File2

	my $brbh_proteins = $bin{'launchbr.pl'} . ' -t ' . $threads .
		 ' --protein --minlen 22  --output ' . " \"$output_dir/blast/BRBH_COLI_GENES\" " . 
		 " \"$output_dir/geneprediction/proteins.fasta\" \"$coliGenesDB\" ";

	run_command($brbh_proteins,
			'Best reciprocal best hit, *E. coli* proteins',
			'blast/BRBH_COLI_GENES.blast1.txt');

}

####TODO
exit;
my $unmap = $bin{'samtools'} . "  view -f4 \"$output_dir/alignments/reads_on_contigs.bam\" | " .
			$bin{'sam2fastq.pl'} . " -i STDIN -q 18 > \"$output_dir/alignments/unmapped.fastq\" " ;

run_command($unmap,
			'Extracting unmapped reads',
			'alignments/unmapped.fastq');
			
###
### SUBROUTINES
###

sub make_subdirs {
	my ($base_path, @dirs) = @_;
	my $existing;
	 
	
	unless (-d "$base_path") {
		my $create_output_dir = "mkdir --parents \"$base_path\" ";
		run_command($create_output_dir, 'Creating output directory');
	}
	foreach my $dir (@dirs) {
		if (-d "$base_path/$dir") {
			$existing++;
		} else {
			run_command("mkdir \"$base_path/$dir\" ", "Creating \"$dir\" subdirectory");
			 
		}
	}
	info("$existing directories were already present!") if ($existing);
}

sub getCheckDir {
	my @files;
	my ($dir, $label) = @_;
	if (-d "$dir") {
		info("$label directory found: \"$dir\"");
	} else {
		info("$label directory NOT found");
		return 0;
	}
	@files = getdirfiles($dir);
	my $count = 0;
	$count += scalar @files;
	
	info("\t$count files found");
	return sort @files;
}

sub shortHelp {
	print STDERR '
  +---------------------------------------------------------------+
  | De Novo Assembly Pipeline                                     |
  +---------------------------------------------------------------+
  
  Prepare a properly structured input directory then start the 
  pipeline with "denovo.pl -i InputDir".
  Type --help for further information.
  
';
exit;
}

sub getdirfiles {
	my ($dir_path, $ext) = @_;
	crash(" [getdirfiles] requested to crawl a non existing directory: $dir_path") unless (-d "$dir_path");
	opendir my $dir, "$dir_path" or crash(" [getdirfiles] Cannot *read* directory \"$dir_path\":\n $!");
	my @files = readdir $dir;
	closedir $dir;
	my @res;
	foreach my $file (@files) {
		push(@res, $file) if (substr($file, 0, 1) ne '.');
	}
	return @res;
}
sub secs2string { 
  my $time = shift; 
  my $days = int($time / 86400); 
  $time -= ($days * 86400); 
  my $hours = int($time / 3600); 
  $time -= ($hours * 3600); 
  my $minutes = int($time / 60); 
  my $seconds = $time % 60; 
 
  $days = $days < 1 ? '' : $days .'d '; 
  $hours = $hours < 1 ? '' : $hours .'h '; 
  $minutes = $minutes < 1 ? '' : $minutes . 'm '; 
  $time = $days . $hours . $minutes . $seconds . 's'; 
  return $time; 
}

sub title {
	my $title = uc($_[0]);
	my $len = 50;
	my $spacer_length = int(($len - length($title)) / 2);
	my $spaces = ' ' x $spacer_length;
	if ($title) {
		print STDERR "\n";
		print STDERR BOLD BLUE $spaces . '=== ' . $title. ' ==='.  $spaces . "\n", RESET;
		savelog('### '.$title, 2);
	} else {
		print STDERR BOLD GREEN ' '.'=' x ($len+8) ."\n", RESET;
		my $title  = 'De Novo Assembly Pipeline - version ' . $version;
		my $spacer_length = int(($len + 8 - length($title)) / 2);
		my $spaces = ' ' x $spacer_length;
		print STDERR BOLD GREEN $spaces . $title.  $spaces . "\n", RESET;

		print STDERR BOLD GREEN ' '.'=' x ($len+8) ."\n", RESET;
	}
}

sub run_command {
	
	my ($command, $description, $checkOutput) = @_;
	my @files = split /,/, $checkOutput;
	my $cant_skip;
	if ($skip and $checkOutput)  {
		foreach my $file (@files) {
			if (!-s "$output_dir/$file") {
				$cant_skip++;
			}
		}

	}
	$global_command_counter++;
	my $command_id = sprintf("%03d", $global_command_counter);
	my $s = Time::HiRes::gettimeofday();
	print STDERR BOLD GREEN "\n -> ", RESET;
	savelog("# -------------------------------------------------------------------------", 2);
	
	if ($debug) {
		savelog("[$command_id] Running '$description':\n$command");
	} else {
		savelog("[$command_id] Running '$description'");
		savelog("$command", 2);
	}
	
	if ($skip and $checkOutput and $cant_skip == 0) {
			savelog("Skipping this step: output file(s) present");
			return 1;
	} 
	my $exit_code;
	$exit_code = system("$command");
	if ($exit_code) {
		print STDERR RED BOLD "ERROR\n", RESET;
		print STDERR "Command: ", RED, "$command\n";
		savelog("# Exited with error code: $exit_code");
	}
	my $e = Time::HiRes::gettimeofday();
	savelog("Done in ".secs2string(sprintf("%.2f", $e - $s))."");
	
	# CHECK OUTPOUT
	foreach my $file (@files) {
		if (-e "$output_dir/$file"){
			my $info = '(but it\'s EMPTY!)' unless (-s "$output_dir/$file");
			savelog("Output file \"$file\" found $info");
		} else {
			crash("Output file NOT \"$file\" found\n -> [$command]");
		}
	}
}

sub info {
	my $info = shift;
	$info = "[*] " . $info unless (substr($info, 0, 1) eq "\t");
	savelog($info, 1);
}
sub savelog {
	my ($message, $screenOnly) = @_;
	# ScreenOnly 1: screen
	#            2: only Log
	
	if ($screenOnly == 1) {
		#print STDERR BLUE "[$screenOnly] Printing only to screen: $message\n", RESET if ($debug);
		print STDERR " " . $message . "\n";
		return 1;
	}
	
	if ($log_file) {
		print LOG $message."\n";
	} 
	
	print STDERR " $message\n" unless ($screenOnly == 2);
	
}

sub check_dependencies {
	my %check_bins = (
		'flash'                  => ' --version 2>&1;FLASH v',
		'bwa'                    => ' 2>&1;Heng Li',
		'spades.py'              => ' 2>&1 | head;SPAdes genome assembler',
		'blastall'               => ' 2>&1 ;blastall',
		'samtools'               => ' 2>&1 ;samtools',
		'sam2fastq.pl'           => ' 2>&1;SAM TO FASTQ CONVERSION',
		'launchbr.pl'            => ' 2>&1;Best Reciprocal Best Hit Pipeline',
		'denovo_blastp.pl'       => ' 2>&1;deNovo',
		'renameContigs.pl'       => ' 2>&1;RENAMER',
		'prokka'                 => ' 2>&1|head;Torsten Seemann'
	);

	foreach my $binary (keys %check_bins) {
		my ($command, $test) = split /;/, $check_bins{$binary};
		my $output1 = `$binary $command`;
		if ($output1=~/$test/) {
			$bin{$binary} = $binary;
			info("Checking \"$binary\": OK");
		} else {
			my $output = `$myBins/$binary $command`;
			if ($output=~/$test/) {
				$bin{$binary} = "$myBins/$binary";
				info("Checking \"$binary\": OK (in $myBins)");
			} else {
				chomp($output); chomp($output1);
				crash("Checking \"$binary\": not found or unexpected answer (in \$PATH and $myBins).\n".
				" Executing: \"$binary $command\"\n Response expected: \"$test\"\n".
				" Responses received:\n 1. PATH \"$output1\"\n 2. LOCAL: \"$output\"");
			}
		}
	}
}
sub crash {
	my $message = shift;
	savelog("####", 2);
	print STDERR RED BOLD " === ERROR\n", RESET;
	savelog("EXITING FOR FATAL ERROR:\n $message");
	die "\n";
}
__END__
 
=head1 NAME
 
B<denovo.pl> - Pipeline for bacterial de novo projects

=head1 SYNOPSIS
 
denovo.pl -d INPUTDIR 
 
=head1 DESCRIPTION
 
This programs performs de novo assembly, reference assisted scaffolding, gene prediction
and annotation using a structured input directory with the following sub folders:

 --+-- reads          Input reads in FASTQ format 
   |                  *NOTE* Should be 1 FASTQ file or 2 PE files for optimal results. 
   | 
   +-- reference      One or more FASTA files with reference genomes
   |
   +-- ref_genes      One FASTA file with genes from a reference organism
   |
   +-- ref_proteins   One FASTA file with proteins from a reference organism
   
      
=head1 REQUIREMENTS

This program requires dependencies, partly expected to be found in its own directory and other to be
available system wide.

=head1 PARAMETERS

=over 12

=item B<-i, --input> DIR

Input directory. Has to contain a /reads subdirectory. The others are optional (see Description).

=item B<-o, --outdir> DIR

Output directory. By default the input directory will be used as output directory too.

=item B<-t, --threads> INT

Number of threads for multi-core steps (most notable being assembly).

=item B<--recalculate>

Force the pipeline to run each step, EVEN IF its "checkpoint" output is presence. 
By default if the output is present, the pipeline will skip its producing step. 



