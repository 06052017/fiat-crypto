#include <stdint.h>
#include <stdbool.h>
#include <x86intrin.h>
#include "liblow.h"

#include "femul.h"

typedef unsigned int uint128_t __attribute__((mode(TI)));

#if (defined(__GNUC__) || defined(__GNUG__)) && !(defined(__clang__)||defined(__INTEL_COMPILER))
// https://gcc.gnu.org/bugzilla/show_bug.cgi?id=81294
#define _subborrow_u32 __builtin_ia32_sbb_u32
#define _subborrow_u64 __builtin_ia32_sbb_u64
#endif

#undef force_inline
#define force_inline __attribute__((always_inline))

void force_inline femul(uint64_t* out, uint64_t x10, uint64_t x11, uint64_t x9, uint64_t x7, uint64_t x5, uint64_t x18, uint64_t x19, uint64_t x17, uint64_t x15, uint64_t x13)
{  uint128_t x20 = (((uint128_t)x5 * x18) + (((uint128_t)x7 * x19) + (((uint128_t)x9 * x17) + (((uint128_t)x11 * x15) + ((uint128_t)x10 * x13)))));
{  uint128_t x21 = ((((uint128_t)x5 * x19) + (((uint128_t)x7 * x17) + (((uint128_t)x9 * x15) + ((uint128_t)x11 * x13)))) + (((uint128_t)x10 * x18) + ((0x2 * ((uint128_t)x10 * x18)) + (0x10 * ((uint128_t)x10 * x18)))));
{  uint128_t x22 = ((((uint128_t)x5 * x17) + (((uint128_t)x7 * x15) + ((uint128_t)x9 * x13))) + ((((uint128_t)x11 * x18) + ((uint128_t)x10 * x19)) + ((0x2 * (((uint128_t)x11 * x18) + ((uint128_t)x10 * x19))) + (0x10 * (((uint128_t)x11 * x18) + ((uint128_t)x10 * x19))))));
{  uint128_t x23 = ((((uint128_t)x5 * x15) + ((uint128_t)x7 * x13)) + ((((uint128_t)x9 * x18) + (((uint128_t)x11 * x19) + ((uint128_t)x10 * x17))) + ((0x2 * (((uint128_t)x9 * x18) + (((uint128_t)x11 * x19) + ((uint128_t)x10 * x17)))) + (0x10 * (((uint128_t)x9 * x18) + (((uint128_t)x11 * x19) + ((uint128_t)x10 * x17)))))));
{  uint128_t x24 = (((uint128_t)x5 * x13) + ((((uint128_t)x7 * x18) + (((uint128_t)x9 * x19) + (((uint128_t)x11 * x17) + ((uint128_t)x10 * x15)))) + ((0x2 * (((uint128_t)x7 * x18) + (((uint128_t)x9 * x19) + (((uint128_t)x11 * x17) + ((uint128_t)x10 * x15))))) + (0x10 * (((uint128_t)x7 * x18) + (((uint128_t)x9 * x19) + (((uint128_t)x11 * x17) + ((uint128_t)x10 * x15))))))));
{  uint64_t x25 = (uint64_t) (x20 >> 0x33);
{  uint64_t x26 = ((uint64_t)x20 & 0x7ffffffffffff);
{  uint128_t x27 = (((uint128_t)0x8000000000000 * x25) + x26);
{  uint64_t x28 = (uint64_t) (x27 >> 0x33);
{  uint64_t x29 = ((uint64_t)x27 & 0x7ffffffffffff);
{  uint128_t x30 = (((uint128_t)0x8000000000000 * x28) + x29);
{  uint64_t x31 = (uint64_t) (x30 >> 0x33);
{  uint64_t x32 = ((uint64_t)x30 & 0x7ffffffffffff);
{  uint128_t x33 = (((uint128_t)0x8000000000000 * x31) + x32);
{  uint64_t x34 = (uint64_t) (x33 >> 0x33);
{  uint64_t x35 = ((uint64_t)x33 & 0x7ffffffffffff);
{  uint128_t x36 = (x24 + (x34 + ((0x2 * x34) + (0x10 * x34))));
{  uint64_t x37 = (uint64_t) (x36 >> 0x33);
{  uint64_t x38 = ((uint64_t)x36 & 0x7ffffffffffff);
{  uint128_t x39 = (x37 + x23);
{  uint64_t x40 = (uint64_t) (x39 >> 0x33);
{  uint64_t x41 = ((uint64_t)x39 & 0x7ffffffffffff);
{  uint128_t x42 = (x40 + x22);
{  uint64_t x43 = (uint64_t) (x42 >> 0x33);
{  uint64_t x44 = ((uint64_t)x42 & 0x7ffffffffffff);
{  uint128_t x45 = (x43 + x21);
{  uint64_t x46 = (uint64_t) (x45 >> 0x33);
{  uint64_t x47 = ((uint64_t)x45 & 0x7ffffffffffff);
{  uint64_t x48 = (x46 + x35);
{  uint64_t x49 = (x48 >> 0x33);
{  uint64_t x50 = (x48 & 0x7ffffffffffff);
{  uint64_t x51 = (x38 + (x49 + ((0x2 * x49) + (0x10 * x49))));
{  uint64_t x52 = (x51 >> 0x33);
{  uint64_t x53 = (x51 & 0x7ffffffffffff);
{  uint64_t x54 = (x53 >> 0x33);
{  uint64_t x55 = (x53 & 0x7ffffffffffff);
{  uint64_t x56 = (x55 >> 0x33);
{  uint64_t x57 = (x55 & 0x7ffffffffffff);
out[0] = x50;
out[1] = x47;
out[2] = x44;
out[3] = x56 + x54 + x52 + x41;
out[4] = x57;
}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}
// caller: uint64_t out[5];
