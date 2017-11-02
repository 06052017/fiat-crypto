#!/bin/sh
set -eu

gcc -fno-peephole2 `#GCC BUG 81300` -march=native -mtune=native -std=gnu11 -O3 -flto -fomit-frame-pointer -fwrapv -Wno-attributes -Wno-incompatible-pointer-types -fno-strict-aliasing -Dmodulus_bytes_val='64' -Dlimb_t=uint64_t -Dq_mpz='(1_mpz<<158) - 15' -Dmodulus_limbs='3' -Dlimb_weight_gaps_array='{64,64,64}' -Dmodulus_array='{0x3f,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xf1}' "$@"
