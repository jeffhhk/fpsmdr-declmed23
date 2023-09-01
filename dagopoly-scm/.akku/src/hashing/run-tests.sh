#!/bin/sh
set -ex

tests/crc.sps
tests/hmac.sps
tests/md5.sps
tests/sha-1.sps
tests/sha-256.sps
tests/sha-512.sps
tests/xxhash.sps
