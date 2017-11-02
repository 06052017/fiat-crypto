#!/bin/sh
set -eu

gcc -march=native -mtune=native -std=gnu11 -O3 -flto -fomit-frame-pointer -fwrapv -Wno-attributes -Dq_mpz='(1_mpz<<205) - 45*(1_mpz<<198) - 1' -Dmodulus_bytes_val='20.5' "$@"
