#!/bin/bash

. subtrees-config.sh
. subtrees.sh

if ! subtrees-check-config
then
    exit 1
fi

subtrees-pull subtree-dagopoly-py dagopoly-py dagopoly-py
subtrees-pull subtree-dagopoly-scm dagopoly-scm dagopoly-scm

