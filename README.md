# Synopsis

Demonstration code for [Functional Pearl: Signature Memoization for Drug Repurposing](https://icfp23.sigplan.org/details?action-call-with-get-request-type=1&d124aa49cc9f4620b41d3e4912a92a93action_17426506610570d81b003a6623243397ac022009bca=1&__ajax_runtime_request__=1&context=icfp-2023&track=declmed-2023-papers&urlKey=7&decoTitle=Functional-Pearl-Signature-Memoization-for-Drug-Repurposing) at [Declarative Programming in Biology and Medicine (DeclMed) 2023](https://icfp23.sigplan.org/home/declmed-2023).

[Talk recording](https://youtu.be/tRt1Rxru3T0?t=11052)

# Upstream repositories

See also the following upstream repositories:

> https://github.com/jeffhhk/dagopoly-py
> https://github.com/jeffhhk/dagopoly-scm

# Instructions

## Prerequisites

Tested with software versions:
- Python 3.7.9
- Chez Scheme 9.5

To run the demo application, you will need to obtain a copy of RTX-KG2c version 7.6.  The redistribution license terms of RTX-KG2c (in the words of its authors) are [It's complicated](https://github.com/RTXteam/RTX-KG2#what-licenses-cover-kg2).  Unfortunately, they currently have not posted a new enough version of this particular artifact to be suitabl for the demo.  Contact the author to arrange access: jeff at groovescale dot com.

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





