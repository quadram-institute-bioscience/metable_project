# Metable.eu Assembly Pipeline

This script contains the [Metable](https://www.facebook.com/Metable/) pipeline for bacterial genome assembly, 
developed during the secondment of BMR Genomics to Computer Lab (Cambridge), in collaboration with the
University of Camerino.

### Description

For each genome the minimum pipeline consists of assembly using 
[SPAdes](http://bioinf.spbau.ru/spades), annotation using [Prokka](https://github.com/tseemann/prokka).
The wrapper can be extended to perform best reciprocal best hit analysis from reference gene sets.


### Usage

```

NAME
    denovo.pl - Pipeline for bacterial de novo projects

SYNOPSIS
    denovo.pl -d INPUTDIR

DESCRIPTION
    This programs performs de novo assembly, reference assisted scaffolding, gene prediction and annotation using a structured input directory with the following
    sub folders:

     --+-- reads          Input reads in FASTQ format
       |                  *NOTE* Should be 1 FASTQ file or 2 PE files for optimal results.
       |
       +-- reference      One or more FASTA files with reference genomes
       |
       +-- ref_genes      One FASTA file with genes from a reference organism
       |
       +-- ref_proteins   One FASTA file with proteins from a reference organism

REQUIREMENTS
    This program requires dependencies, partly expected to be found in its own directory and other to be available system wide.

PARAMETERS
    -i, --input DIR
                Input directory. Has to contain a /reads subdirectory. The others are optional (see Description).

    -o, --outdir DIR
                Output directory. By default the input directory will be used as output directory too.

    -t, --threads INT
                Number of threads for multi-core steps (most notable being assembly).
```

