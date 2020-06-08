# Newbler

## Usage

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

- **runAssembly** - perform actual assembly

```text
runAssembly [-o projdir] [-nrm] [-p (sfffile | [regionlist:]analysisDir)]... (sfffile | [regionlist:]analysisDir).
```

