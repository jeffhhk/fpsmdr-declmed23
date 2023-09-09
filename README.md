# Synopsis

Demonstration code for "Functional Pearl: Signature Memoization for Drug Repurposing" at [Declarative Programming in Biology and Medicine (DeclMed) 2023](https://icfp23.sigplan.org/home/declmed-2023).

# Upstream repositories

See also the following upstream repositories:

> https://github.com/jeffhhk/dagopoly-py
> https://github.com/jeffhhk/dagopoly-scm

# Instructions

## Prerequisites

Tested with:
- Python 3.7.9
- Chez Scheme 9.5

## Setup

Clone this repository.  Make the local repository your current directory.

Obtain rtx-kg2c_7.6.tar.gz and copy to dagopoly-py/storage/exogenous/

## Demonstration 1 - minimal Python application

python dagopoly-py/test/autobin/test1.py

## Demonstration 2 - minimal Scheme application

bash dagopoly-scm/chezscheme.sh --script dagopoly-scm/test/adhoc/minimal-program.scm 

## Demonstration 3 - Scheme to Python IPC

bash dagopoly-scm/chezscheme.sh --script dagopoly-scm/test/adhoc/test-ipc-send.chezscheme.scm 

## Demonstration 4 - Drug Repurposing candidates for Alzheimer’s Disease

python alz/alz.py


# Footnotes

If you are using this repository, scheme dependencies from akku will be checked in.





