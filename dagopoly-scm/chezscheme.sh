#!/bin/bash
adirProj=$( cd $( dirname "$0" ) && pwd )
eval $("$adirProj/.akku/env" -s)     # Set CHEZSCHEMELIBDIRS, etc via akku
# When Chez is started as a repl, (command-line) evaluates to (""), because there
# is no "current script."  Thus to find our default storage/ directory, we record
# our $0 so that it can be retrieved by Chez even when started as a repl.
export adirProj
# In addition to the akku directories, the project root must be in the libdirs.
export CHEZSCHEMELIBDIRS="$adirProj:$CHEZSCHEMELIBDIRS"
# Run Chez
exec scheme "$@"