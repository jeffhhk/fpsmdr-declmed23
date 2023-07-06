#!/bin/bash
adirProj=$( cd $( dirname "$0" ) && pwd )
# Set CHEZSCHEMELIBDIRS, etc via akka
. "$adirProj/.akku/bin/activate"
# When Chez is started as a repl, (command-line) evaluates to (""), because there
# is no "current script."  Thus to find our default storage/ directory, we record
# our $0 so that it can be retrieved by Chez even when started as a repl.
export adirProj
# Run Chez
# In addition to the akku directories, the project root must be in the libdirs.
exec scheme --libdirs "$adirProj:$CHEZSCHEMELIBDIRS" "$@"