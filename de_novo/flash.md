## FLASH 

The first implementation of the pipeline was using [Newbler](newbler.md) to perform the _de novo_ assembly. 

Newbler was developed to assemble 454 reads, performing the assembly of _single ends_ reads ("pair ends" in 454 world was more similar to "mate paired" libraries, _i.e._ for scaffolding).

FLASH was used to merge paired-end reads:

```text
flash -m ${MINOVERLAP} -o ${OUTPUT_BASENAME} --threads ${THREADS} file_R1.fq file_R2.fq

```

### Citation
-  T. Magoc and S. Salzberg. [FLASH: Fast length adjustment of short reads to improve genome assemblies](https://ccb.jhu.edu/software/FLASH/FLASH-reprint.pdf). Bioinformatics 27:21 (2011), 2957-63.
