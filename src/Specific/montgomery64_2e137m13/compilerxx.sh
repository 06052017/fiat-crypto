#!/bin/sh
set -eu

g++ -fno-peephole2 `#GCC BUG 81300` -march=native -mtune=native -std=gnu++11 -O3 -flto -fomit-frame-pointer -fwrapv -Wno-attributes -fno-strict-aliasing -Dmodulus_bytes_val='64' -Dlimb_t=uint64_t -Dq_mpz='(1_mpz<<137) - 13' -Dmodulus_limbs='3' -Dlimb_weight_gaps_array='{64,64,64}' -Dmodulus_array='{0x01,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xf3}' "$@"
