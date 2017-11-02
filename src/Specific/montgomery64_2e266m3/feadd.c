#include <stdint.h>
#include <stdbool.h>
#include <x86intrin.h>
#include "liblow.h"

#include "feadd.h"

typedef unsigned int uint128_t __attribute__((mode(TI)));

#if (defined(__GNUC__) || defined(__GNUG__)) && !(defined(__clang__)||defined(__INTEL_COMPILER))
// https://gcc.gnu.org/bugzilla/show_bug.cgi?id=81294
#define _subborrow_u32 __builtin_ia32_sbb_u32
#define _subborrow_u64 __builtin_ia32_sbb_u64
#endif

#undef force_inline
#define force_inline __attribute__((always_inline))

void force_inline feadd(uint64_t* out, uint64_t x10, uint64_t x11, uint64_t x9, uint64_t x7, uint64_t x5, uint64_t x18, uint64_t x19, uint64_t x17, uint64_t x15, uint64_t x13)
{  uint64_t x21; uint8_t x22 = _addcarryx_u64(0x0, x5, x13, &x21);
{  uint64_t x24; uint8_t x25 = _addcarryx_u64(x22, x7, x15, &x24);
{  uint64_t x27; uint8_t x28 = _addcarryx_u64(x25, x9, x17, &x27);
{  uint64_t x30; uint8_t x31 = _addcarryx_u64(x28, x11, x19, &x30);
{  uint64_t x33; uint8_t x34 = _addcarryx_u64(x31, x10, x18, &x33);
{  uint64_t x36; uint8_t x37 = _subborrow_u64(0x0, x21, 0xfffffffffffffffdL, &x36);
{  uint64_t x39; uint8_t x40 = _subborrow_u64(x37, x24, 0xffffffffffffffffL, &x39);
{  uint64_t x42; uint8_t x43 = _subborrow_u64(x40, x27, 0xffffffffffffffffL, &x42);
{  uint64_t x45; uint8_t x46 = _subborrow_u64(x43, x30, 0xffffffffffffffffL, &x45);
{  uint64_t x48; uint8_t x49 = _subborrow_u64(x46, x33, 0x3ff, &x48);
{  uint64_t _; uint8_t x52 = _subborrow_u64(x49, x34, 0x0, &_);
{  uint64_t x53 = cmovznz(x52, x48, x33);
{  uint64_t x54 = cmovznz(x52, x45, x30);
{  uint64_t x55 = cmovznz(x52, x42, x27);
{  uint64_t x56 = cmovznz(x52, x39, x24);
{  uint64_t x57 = cmovznz(x52, x36, x21);
out[0] = x53;
out[1] = x54;
out[2] = x55;
out[3] = x56;
out[4] = x57;
}}}}}}}}}}}}}}}}
// caller: uint64_t out[5];
