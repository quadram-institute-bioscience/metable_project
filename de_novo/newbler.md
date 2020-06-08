# Newbler

## Docker container

Newbler was commonly available in any NGS core facility operating a Roche 454. It has been long time discontinued, but it's still available as a Docker container, for example from:
```text
docker pull bryce911/newbler-2.8
```


## Usage

- **newAssembly** 
```text
newAssembly ProjectName
```

- **addRun** - to create a Newbler project

```text
addRun
Usage:  addRun [options] [projectDir] [MID_List@](sfffile | fnafile | [regions:]analysisDirectory)...
Options:
   -p             - These runs/files contain 454 paired reads
   -lib libname   - Default paired-end library to use for these files
   -mcf filename  - Location of multiplex config file
```

The project directory may either be specified on the command line, or
the program will check the current working directory to see if it is
a project directory (or the mapping/assembly sub-directory), and use it
if so.

Example:

```
addRun -p ProjectName/ merged_reads.fq 
```

- **newbler** - actual assembly step
```text
newbler ProjectName
```
