
# Prerequisites

Chez Scheme.  Tested with Chez Scheme v9.5 on Ubuntu 20.

# How to: initial setup

The Akka package manager is required for chez-srfi, json and sha-1 support.

Akka supports various (https://gitlab.com/akkuscm/akku#installation)[installation mechanisms].  Since dagopoly is currently chez-only, the chez-hosted version of akka is probably easiest.

    curl -L -O https://gitlab.com/akkuscm/akku/uploads/9d23bb6ec47dd2d7ee41802115cd7d80/akku-1.1.0.src.tar.xz
    tar -xf akku-1.1.0.src.tar.xz
    cd akku-1.1.0.src
    ./install.sh

In akku, package installation is local to the project you are working on.  After cloning into .../dagopoly-scm,

    cd .../dagopoly-scm
    akku install

This will create the .akku/ subdirectory and associated scripts.

# How to: run

The script chezscheme.sh the "scheme" binary of chez scheme with appropriate configuration.  Read the script comments for details.  For example:

    ./chezscheme.sh
    Chez Scheme Version 9.5
    Copyright 1984-2017 Cisco Systems, Inc.

    >

# How to: run tests

    bash ./run-tests.sh
    bash ./run-tests-ipc.sh

# How to: run new code

    mkdir -p storage/exogenous
    echo -e "foo\nbar\nbaz\n" > storage/exogenous/hello.txt
    ./chezscheme.sh

Then in the REPL:

    (import (micro dagopoly) (micro fs) (micro stream))
    (activate-defaults)
    (define hello (block-external "hello.txt"))
    (s->list (block-get hello))

Which will evaluate to:

    (foo bar baz)

