# Bio-PacbioMethylation
Runs Pacbio methylation pipeline

[![Build Status](https://travis-ci.org/sanger-pathogens/Bio-PacbioMethylation.svg?branch=master)](https://travis-ci.org/sanger-pathogens/Bio-PacbioMethylation)   
[![License: GPL v3](https://img.shields.io/badge/License-GPL%20v3-brightgreen.svg)](https://github.com/sanger-pathogens/Bio-PacbioMethylation/blob/master/GPL-LICENSE)   

## Contents
  * [Introduction](#introduction)
  * [Installation](#installation)
    * [Required dependencies](#required-dependencies)
    * [From Source](#from-source)
    * [Running the tests](#running-the-tests)
  * [Usage](#usage)
  * [License](#license)
  * [Feedback/Issues](#feedbackissues)

## Introduction
Runs the RS_Modification_and_Motif_Analysis pipeline and tidies output files.

## Installation
Bio-PacbioMethylation has the following dependencies:

### Required dependencies
* tabix
* bgzip

Details for installing Bio-PacbioMethylation are provided below. If you encounter an issue when installing Bio-PacbioMethylation please contact your local system administrator. If you encounter a bug please log it [here](https://github.com/sanger-pathogens/Bio-PacbioMethylation/issues) or email us at path-help@sanger.ac.uk.

### From Source
Clone the repository:   
   
`git clone https://github.com/sanger-pathogens/Bio-PacbioMethylation.git`   
   
Move into the directory and install all dependencies using [DistZilla](http://dzil.org/):   
  
```
cd Bio-PacbioMethylation
dzil authordeps --missing | cpanm
dzil listdeps --missing | cpanm
```
  
Run the tests:   
  
`dzil test`   
If the tests pass, install Bio-PacbioMethylation:   
  
`dzil install`   

### Running the tests
The test can be run with dzil from the top level directory:  
  
`dzil test`  

## Usage
```
pacbio_methylation [options] <output dir> <reference.fasta> <*.bax.h5>

Runs the Pacio Methylation pipeline, makes Artemis plot files, and
cleans up unneeded files.

Options:

-h,help
    Show this help and exit

-m,-min_ipdratio
    Cutoff for the ipdratio when making Artemis plot file.
    Any value less than -min_ipdratio will be set to zero [0]

-n,-noclean
    Do not delete intermediate files

-t,-threads INT
    Number of threads [1]
```

## License
Bio-PacbioMethylation is free software, licensed under [GPLv3](https://github.com/sanger-pathogens/Bio-PacbioMethylation/blob/master/GPL-LICENSE).

## Feedback/Issues
Please report any issues to the [issues page](https://github.com/sanger-pathogens/Bio-PacbioMethylation/issues) or email path-help@sanger.ac.uk.