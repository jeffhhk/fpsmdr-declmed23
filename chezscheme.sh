#!/bin/bash
adirScript=$( cd $( dirname "$0" ) && pwd )

exec scheme --libdirs "$adirScript:$CHEZSCHEMELIBDIRS" "$@"