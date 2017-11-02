#include <stdint.h>
#include <stdbool.h>
#include <x86intrin.h>
#include "liblow.h"

#include "freeze.h"

typedef unsigned int uint128_t __attribute__((mode(TI)));

#if (defined(__GNUC__) || defined(__GNUG__)) && !(defined(__clang__)||defined(__INTEL_COMPILER))
// https://gcc.gnu.org/bugzilla/show_bug.cgi?id=81294
#define _subborrow_u32 __builtin_ia32_sbb_u32
#define _subborrow_u64 __builtin_ia32_sbb_u64
#endif

#undef force_inline
#define force_inline __attribute__((always_inline))

void force_inline freeze(uint64_t* out, uint64_t x7, uint64_t x8, uint64_t x6, uint64_t x4, uint64_t x2)
{  uint64_t x10; uint8_t x11 = _subborrow_u51(0x0, x2, 0x7fffffffffff7, &x10);
out[0] = uint64_t x13;
out[1] = uint8_t x14 = Op Syntax.SubWithGetBorrow 50 Syntax.TWord 3 Syntax.TWord 6 Syntax.TWord 6 Syntax.TWord 6 Syntax.TWord 3  x11;
out[2] = x4;
out[3] = 0x3ffffffffffff;;
}
// caller: uint64_t out[4];
