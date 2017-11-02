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

void force_inline femul(uint64_t* out, uint64_t x12, uint64_t x13, uint64_t x11, uint64_t x9, uint64_t x7, uint64_t x5, uint64_t x22, uint64_t x23, uint64_t x21, uint64_t x19, uint64_t x17, uint64_t x15)
{  ℤ x24 = (((uint64_t)x5 * x22) +ℤ (((uint64_t)x7 * x23) + (((uint64_t)x9 * x21) + (((uint64_t)x11 * x19) + (((uint64_t)x13 * x17) + ((uint64_t)x12 * x15))))));
{  ℤ x25 = ((((uint64_t)x5 * x23) + (((uint64_t)x7 * x21) + (((uint64_t)x9 * x19) + (((uint64_t)x11 * x17) + ((uint64_t)x13 * x15))))) +ℤ (0x3 * ((uint64_t)x12 * x22)));
{  ℤ x26 = ((((uint64_t)x5 * x21) + (((uint64_t)x7 * x19) + (((uint64_t)x9 * x17) + ((uint64_t)x11 * x15)))) +ℤ (0x3 *ℤ (((uint64_t)x13 * x22) + ((uint64_t)x12 * x23))));
{  ℤ x27 = ((((uint64_t)x5 * x19) + (((uint64_t)x7 * x17) + ((uint64_t)x9 * x15))) +ℤ (0x3 *ℤ (((uint64_t)x11 * x22) + (((uint64_t)x13 * x23) + ((uint64_t)x12 * x21)))));
{  ℤ x28 = ((((uint64_t)x5 * x17) + ((uint64_t)x7 * x15)) +ℤ (0x3 *ℤ (((uint64_t)x9 * x22) + (((uint64_t)x11 * x23) + (((uint64_t)x13 * x21) + ((uint64_t)x12 * x19))))));
{  ℤ x29 = (((uint64_t)x5 * x15) +ℤ (0x3 *ℤ (((uint64_t)x7 * x22) + (((uint64_t)x9 * x23) + (((uint64_t)x11 * x21) + (((uint64_t)x13 * x19) + ((uint64_t)x12 * x17)))))));
{  uint64_t x30 = (x29 >> 0x1d);
{  uint32_t x31 = (x29 & 0x1fffffff);
{  ℤ x32 = (x30 +ℤ x28);
{  uint64_t x33 = (x32 >> 0x1d);
{  uint32_t x34 = (x32 & 0x1fffffff);
{  ℤ x35 = (x33 +ℤ x27);
{  uint64_t x36 = (x35 >> 0x1d);
{  uint32_t x37 = (x35 & 0x1fffffff);
{  ℤ x38 = (x36 +ℤ x26);
{  uint64_t x39 = (x38 >> 0x1d);
{  uint32_t x40 = (x38 & 0x1fffffff);
{  ℤ x41 = (x39 +ℤ x25);
{  uint64_t x42 = (x41 >> 0x1d);
{  uint32_t x43 = (x41 & 0x1fffffff);
{  ℤ x44 = (x42 +ℤ x24);
{  uint64_t x45 = (x44 >> 0x1d);
{  uint32_t x46 = (x44 & 0x1fffffff);
{  uint64_t x47 = (x31 + (0x3 * x45));
{  uint32_t x48 = (uint32_t) (x47 >> 0x1d);
{  uint32_t x49 = ((uint32_t)x47 & 0x1fffffff);
{  uint32_t x50 = (x48 + x34);
{  uint32_t x51 = (x50 >> 0x1d);
{  uint32_t x52 = (x50 & 0x1fffffff);
out[0] = x46;
out[1] = x43;
out[2] = x40;
out[3] = x51 + x37;
out[4] = x52;
out[5] = x49;
}}}}}}}}}}}}}}}}}}}}}}}}}}}}}
// caller: uint64_t out[6];
