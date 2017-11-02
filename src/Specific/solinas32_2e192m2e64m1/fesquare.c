#include <stdint.h>
#include <stdbool.h>
#include <x86intrin.h>
#include "liblow.h"

#include "fesquare.h"

typedef unsigned int uint128_t __attribute__((mode(TI)));

#if (defined(__GNUC__) || defined(__GNUG__)) && !(defined(__clang__)||defined(__INTEL_COMPILER))
// https://gcc.gnu.org/bugzilla/show_bug.cgi?id=81294
#define _subborrow_u32 __builtin_ia32_sbb_u32
#define _subborrow_u64 __builtin_ia32_sbb_u64
#endif

#undef force_inline
#define force_inline __attribute__((always_inline))

void force_inline fesquare(uint64_t* out, uint64_t x13, uint64_t x14, uint64_t x12, uint64_t x10, uint64_t x8, uint64_t x6, uint64_t x4, uint64_t x2)
{  ℤ x15 = ((((uint64_t)x2 * x13) + (((uint64_t)x4 * x14) + (((uint64_t)x6 * x12) + (((uint64_t)x8 * x10) + (((uint64_t)x10 * x8) + (((uint64_t)x12 * x6) + (((uint64_t)x14 * x4) + ((uint64_t)x13 * x2)))))))) +ℤ ((0x10000 *ℤ (((uint64_t)x14 * x13) + ((uint64_t)x13 * x14))) +ℤ (0x10000000000 *ℤ ((uint64_t)x13 * x13))));
{  ℤ x16 = ((((uint64_t)x2 * x14) + (((uint64_t)x4 * x12) + (((uint64_t)x6 * x10) + (((uint64_t)x8 * x8) + (((uint64_t)x10 * x6) + (((uint64_t)x12 * x4) + ((uint64_t)x14 * x2))))))) +ℤ (((uint64_t)x13 * x13) +ℤ (0x10000 *ℤ (((uint64_t)x12 * x13) + (((uint64_t)x14 * x14) + ((uint64_t)x13 * x12))))));
{  ℤ x17 = ((((uint64_t)x2 * x12) + (((uint64_t)x4 * x10) + (((uint64_t)x6 * x8) + (((uint64_t)x8 * x6) + (((uint64_t)x10 * x4) + ((uint64_t)x12 * x2)))))) +ℤ ((((uint64_t)x14 * x13) + ((uint64_t)x13 * x14)) +ℤ (0x10000 *ℤ (((uint64_t)x10 * x13) + (((uint64_t)x12 * x14) + (((uint64_t)x14 * x12) + ((uint64_t)x13 * x10)))))));
{  ℤ x18 = ((((uint64_t)x2 * x10) + (((uint64_t)x4 * x8) + (((uint64_t)x6 * x6) + (((uint64_t)x8 * x4) + ((uint64_t)x10 * x2))))) +ℤ ((((uint64_t)x12 * x13) + (((uint64_t)x14 * x14) + ((uint64_t)x13 * x12))) +ℤ (0x10000 *ℤ (((uint64_t)x8 * x13) + (((uint64_t)x10 * x14) + (((uint64_t)x12 * x12) + (((uint64_t)x14 * x10) + ((uint64_t)x13 * x8))))))));
{  ℤ x19 = ((((uint64_t)x2 * x8) + (((uint64_t)x4 * x6) + (((uint64_t)x6 * x4) + ((uint64_t)x8 * x2)))) +ℤ ((((uint64_t)x10 * x13) + (((uint64_t)x12 * x14) + (((uint64_t)x14 * x12) + ((uint64_t)x13 * x10)))) +ℤ (0x10000 *ℤ (((uint64_t)x6 * x13) + (((uint64_t)x8 * x14) + (((uint64_t)x10 * x12) + (((uint64_t)x12 * x10) + (((uint64_t)x14 * x8) + ((uint64_t)x13 * x6)))))))));
{  ℤ x20 = ((((uint64_t)x2 * x6) + (((uint64_t)x4 * x4) + ((uint64_t)x6 * x2))) +ℤ ((((uint64_t)x8 * x13) + (((uint64_t)x10 * x14) + (((uint64_t)x12 * x12) + (((uint64_t)x14 * x10) + ((uint64_t)x13 * x8))))) +ℤ (0x10000 *ℤ (((uint64_t)x4 * x13) + (((uint64_t)x6 * x14) + (((uint64_t)x8 * x12) + (((uint64_t)x10 * x10) + (((uint64_t)x12 * x8) + (((uint64_t)x14 * x6) + ((uint64_t)x13 * x4))))))))));
{  uint64_t x21 = ((((uint64_t)x2 * x4) + ((uint64_t)x4 * x2)) + (((uint64_t)x6 * x13) + (((uint64_t)x8 * x14) + (((uint64_t)x10 * x12) + (((uint64_t)x12 * x10) + (((uint64_t)x14 * x8) + ((uint64_t)x13 * x6)))))));
{  uint64_t x22 = (((uint64_t)x2 * x2) + (((uint64_t)x4 * x13) + (((uint64_t)x6 * x14) + (((uint64_t)x8 * x12) + (((uint64_t)x10 * x10) + (((uint64_t)x12 * x8) + (((uint64_t)x14 * x6) + ((uint64_t)x13 * x4))))))));
{  uint32_t x23 = (uint32_t) (x21 >> 0x18);
{  uint32_t x24 = ((uint32_t)x21 & 0xffffff);
{  ℤ x25 = (x15 >>ℤ 0x18);
{  uint32_t x26 = (x15 & 0xffffff);
{  ℤ x27 = ((0x1000000 *ℤ x25) +ℤ x26);
{  ℤ x28 = (x27 >>ℤ 0x18);
{  uint32_t x29 = (x27 & 0xffffff);
{  ℤ x30 = ((x23 +ℤ x20) +ℤ (0x10000 *ℤ x28));
{  uint64_t x31 = (x30 >> 0x18);
{  uint32_t x32 = (x30 & 0xffffff);
{  ℤ x33 = (x22 +ℤ x28);
{  uint64_t x34 = (x33 >> 0x18);
{  uint32_t x35 = (x33 & 0xffffff);
{  ℤ x36 = (x31 +ℤ x19);
{  uint64_t x37 = (x36 >> 0x18);
{  uint32_t x38 = (x36 & 0xffffff);
{  uint64_t x39 = (x34 + x24);
{  uint32_t x40 = (uint32_t) (x39 >> 0x18);
{  uint32_t x41 = ((uint32_t)x39 & 0xffffff);
{  ℤ x42 = (x37 +ℤ x18);
{  uint64_t x43 = (x42 >> 0x18);
{  uint32_t x44 = (x42 & 0xffffff);
{  ℤ x45 = (x43 +ℤ x17);
{  uint64_t x46 = (x45 >> 0x18);
{  uint32_t x47 = (x45 & 0xffffff);
{  ℤ x48 = (x46 +ℤ x16);
{  uint64_t x49 = (x48 >> 0x18);
{  uint32_t x50 = (x48 & 0xffffff);
{  uint64_t x51 = (x49 + x29);
{  uint32_t x52 = (uint32_t) (x51 >> 0x18);
{  uint32_t x53 = ((uint32_t)x51 & 0xffffff);
{  uint64_t x54 = (((uint64_t)0x1000000 * x52) + x53);
{  uint32_t x55 = (uint32_t) (x54 >> 0x18);
{  uint32_t x56 = ((uint32_t)x54 & 0xffffff);
{  uint64_t x57 = ((x40 + x32) + ((uint64_t)0x10000 * x55));
{  uint32_t x58 = (uint32_t) (x57 >> 0x18);
{  uint32_t x59 = ((uint32_t)x57 & 0xffffff);
{  uint32_t x60 = (x35 + x55);
{  uint32_t x61 = (x60 >> 0x18);
{  uint32_t x62 = (x60 & 0xffffff);
out[0] = x56;
out[1] = x50;
out[2] = x47;
out[3] = x44;
out[4] = x58 + x38;
out[5] = x59;
out[6] = x61 + x41;
out[7] = x62;
}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}
// caller: uint64_t out[8];
