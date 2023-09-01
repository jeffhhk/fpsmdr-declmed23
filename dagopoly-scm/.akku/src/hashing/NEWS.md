# Version 1.2.0 (SemVer)

## Bit-oriented CRCs

The (hashing crc) library now exports define-bit-oriented-crc, which
is used to define CRCs that operate on bits rather than bytes. The
syntax and procedures are the same as for define-crc, but each byte in
the input represents a single bit.

## More readable define-*-crc syntax

The define-*-crc macros also have a new more verbose version that
names each field (think: define-record-type). See the comments at the
top of crc.scm.

# Version 1.1.0 (SemVer)

## The ->string procedures always return lower case strings

The md5->string, sha-1->string, etc procedures previously returned
either upper or lower case strings depending on the host Scheme's
number->string procedure. Now they return lower case strings (and are
also 10-15 times faster).

## Improved speed

The MD5, SHA-1 and SHA-256 algorithms now run around ten times faster
on 64-bit machines.

# Version 1.0.0 (SemVer)

Initial version since the extraction from Industria.
