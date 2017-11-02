#include <stdint.h>
#include <stdbool.h>
#include <x86intrin.h>
#include "liblow.h"

#include "fenz.h"

typedef unsigned int uint128_t __attribute__((mode(TI)));

#if (defined(__GNUC__) || defined(__GNUG__)) && !(defined(__clang__)||defined(__INTEL_COMPILER))
// https://gcc.gnu.org/bugzilla/show_bug.cgi?id=81294
#define _subborrow_u32 __builtin_ia32_sbb_u32
#define _subborrow_u64 __builtin_ia32_sbb_u64
#endif

#undef force_inline
#define force_inline __attribute__((always_inline))

void force_inline fenz(uint64_t* out, uint64_t x5, uint64_t x6, uint64_t x4, uint64_t x2)
{  uint32_t x7 = (x6 | x5);
{  uint32_t x8 = (x4 | x7);
{  uint32_t x9 = (x2 | x8);
out[0] = x9;
}}}
// caller: uint64_t out[1];
