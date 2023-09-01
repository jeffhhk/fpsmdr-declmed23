#!/bin/bash

. subtrees-config.sh
. subtrees.sh

if ! subtrees-check-config
then
    exit 1
fi

subtrees-init subtree-dagopoly-py dagopoly-py dagopoly-py
subtrees-init subtree-dagopoly-scm dagopoly-scm dagopoly-scm

