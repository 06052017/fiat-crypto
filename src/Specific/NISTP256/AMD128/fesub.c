#include <stdint.h>
#include <stdbool.h>
#include <x86intrin.h>
#include "liblow.h"

#include "fesub.h"

typedef unsigned int uint128_t __attribute__((mode(TI)));

#if (defined(__GNUC__) || defined(__GNUG__)) && !(defined(__clang__)||defined(__INTEL_COMPILER))
// https://gcc.gnu.org/bugzilla/show_bug.cgi?id=81294
#define _subborrow_u32 __builtin_ia32_sbb_u32
#define _subborrow_u64 __builtin_ia32_sbb_u64
#endif

#undef force_inline
#define force_inline __attribute__((always_inline))

void force_inline fesub(uint64_t* out, uint64_t x4, uint64_t x5, uint64_t x6, uint64_t x7)
{  uint128_t x9; uint8_t/*bool*/ x10 = _subborrow_u128(0x0, x5, x7, &x9);
{  uint128_t x12; uint8_t/*bool*/ x13 = _subborrow_u128(x10, x4, x6, &x12);
{  uint128_t x14 = cmovznz128(x13, 0x0, 0xffffffffffffffffffffffffffffffffL);
{  uint128_t x15 = (x14 & 0xffffffffffffffffffffffffL);
{  uint128_t x17; uint8_t/*bool*/ x18 = _addcarryx_u128(0x0, x9, x15, &x17);
{  uint128_t x19 = (x14 & 0xffffffff000000010000000000000000L);
{  uint128_t x21; uint8_t/*bool*/ _ = _addcarryx_u128(x18, x12, x19, &x21);
out[0] = x21;
out[1] = x17;
}}}}}}}
// caller: uint64_t out[2];
