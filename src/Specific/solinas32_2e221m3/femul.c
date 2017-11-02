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

void force_inline femul(uint64_t* out, uint64_t x20, uint64_t x21, uint64_t x19, uint64_t x17, uint64_t x15, uint64_t x13, uint64_t x11, uint64_t x9, uint64_t x7, uint64_t x5, uint64_t x38, uint64_t x39, uint64_t x37, uint64_t x35, uint64_t x33, uint64_t x31, uint64_t x29, uint64_t x27, uint64_t x25, uint64_t x23)
{  uint64_t x40 = (((uint64_t)x5 * x38) + ((0x2 * ((uint64_t)x7 * x39)) + ((0x2 * ((uint64_t)x9 * x37)) + ((0x2 * ((uint64_t)x11 * x35)) + ((0x2 * ((uint64_t)x13 * x33)) + ((0x2 * ((uint64_t)x15 * x31)) + ((0x2 * ((uint64_t)x17 * x29)) + ((0x2 * ((uint64_t)x19 * x27)) + ((0x2 * ((uint64_t)x21 * x25)) + ((uint64_t)x20 * x23))))))))));
{  uint64_t x41 = ((((uint64_t)x5 * x39) + ((0x2 * ((uint64_t)x7 * x37)) + ((0x2 * ((uint64_t)x9 * x35)) + ((0x2 * ((uint64_t)x11 * x33)) + ((0x2 * ((uint64_t)x13 * x31)) + ((0x2 * ((uint64_t)x15 * x29)) + ((0x2 * ((uint64_t)x17 * x27)) + ((0x2 * ((uint64_t)x19 * x25)) + ((uint64_t)x21 * x23))))))))) + (0x3 * ((uint64_t)x20 * x38)));
{  uint64_t x42 = ((((uint64_t)x5 * x37) + ((0x2 * ((uint64_t)x7 * x35)) + ((0x2 * ((uint64_t)x9 * x33)) + ((0x2 * ((uint64_t)x11 * x31)) + ((0x2 * ((uint64_t)x13 * x29)) + ((0x2 * ((uint64_t)x15 * x27)) + ((0x2 * ((uint64_t)x17 * x25)) + ((uint64_t)x19 * x23)))))))) + (0x3 * (((uint64_t)x21 * x38) + ((uint64_t)x20 * x39))));
{  uint64_t x43 = ((((uint64_t)x5 * x35) + ((0x2 * ((uint64_t)x7 * x33)) + ((0x2 * ((uint64_t)x9 * x31)) + ((0x2 * ((uint64_t)x11 * x29)) + ((0x2 * ((uint64_t)x13 * x27)) + ((0x2 * ((uint64_t)x15 * x25)) + ((uint64_t)x17 * x23))))))) + (0x3 * (((uint64_t)x19 * x38) + (((uint64_t)x21 * x39) + ((uint64_t)x20 * x37)))));
{  uint64_t x44 = ((((uint64_t)x5 * x33) + ((0x2 * ((uint64_t)x7 * x31)) + ((0x2 * ((uint64_t)x9 * x29)) + ((0x2 * ((uint64_t)x11 * x27)) + ((0x2 * ((uint64_t)x13 * x25)) + ((uint64_t)x15 * x23)))))) + (0x3 * (((uint64_t)x17 * x38) + (((uint64_t)x19 * x39) + (((uint64_t)x21 * x37) + ((uint64_t)x20 * x35))))));
{  uint64_t x45 = ((((uint64_t)x5 * x31) + ((0x2 * ((uint64_t)x7 * x29)) + ((0x2 * ((uint64_t)x9 * x27)) + ((0x2 * ((uint64_t)x11 * x25)) + ((uint64_t)x13 * x23))))) + (0x3 * (((uint64_t)x15 * x38) + (((uint64_t)x17 * x39) + (((uint64_t)x19 * x37) + (((uint64_t)x21 * x35) + ((uint64_t)x20 * x33)))))));
{  uint64_t x46 = ((((uint64_t)x5 * x29) + ((0x2 * ((uint64_t)x7 * x27)) + ((0x2 * ((uint64_t)x9 * x25)) + ((uint64_t)x11 * x23)))) + (0x3 * (((uint64_t)x13 * x38) + (((uint64_t)x15 * x39) + (((uint64_t)x17 * x37) + (((uint64_t)x19 * x35) + (((uint64_t)x21 * x33) + ((uint64_t)x20 * x31))))))));
{  uint64_t x47 = ((((uint64_t)x5 * x27) + ((0x2 * ((uint64_t)x7 * x25)) + ((uint64_t)x9 * x23))) + (0x3 * (((uint64_t)x11 * x38) + (((uint64_t)x13 * x39) + (((uint64_t)x15 * x37) + (((uint64_t)x17 * x35) + (((uint64_t)x19 * x33) + (((uint64_t)x21 * x31) + ((uint64_t)x20 * x29)))))))));
{  uint64_t x48 = ((((uint64_t)x5 * x25) + ((uint64_t)x7 * x23)) + (0x3 * (((uint64_t)x9 * x38) + (((uint64_t)x11 * x39) + (((uint64_t)x13 * x37) + (((uint64_t)x15 * x35) + (((uint64_t)x17 * x33) + (((uint64_t)x19 * x31) + (((uint64_t)x21 * x29) + ((uint64_t)x20 * x27))))))))));
{  uint64_t x49 = (((uint64_t)x5 * x23) + (0x3 * ((0x2 * ((uint64_t)x7 * x38)) + ((0x2 * ((uint64_t)x9 * x39)) + ((0x2 * ((uint64_t)x11 * x37)) + ((0x2 * ((uint64_t)x13 * x35)) + ((0x2 * ((uint64_t)x15 * x33)) + ((0x2 * ((uint64_t)x17 * x31)) + ((0x2 * ((uint64_t)x19 * x29)) + ((0x2 * ((uint64_t)x21 * x27)) + (0x2 * ((uint64_t)x20 * x25))))))))))));
{  uint32_t x50 = (uint32_t) (x49 >> 0x17);
{  uint32_t x51 = ((uint32_t)x49 & 0x7fffff);
{  uint64_t x52 = (x50 + x48);
{  uint32_t x53 = (uint32_t) (x52 >> 0x16);
{  uint32_t x54 = ((uint32_t)x52 & 0x3fffff);
{  uint64_t x55 = (x53 + x47);
{  uint32_t x56 = (uint32_t) (x55 >> 0x16);
{  uint32_t x57 = ((uint32_t)x55 & 0x3fffff);
{  uint64_t x58 = (x56 + x46);
{  uint32_t x59 = (uint32_t) (x58 >> 0x16);
{  uint32_t x60 = ((uint32_t)x58 & 0x3fffff);
{  uint64_t x61 = (x59 + x45);
{  uint32_t x62 = (uint32_t) (x61 >> 0x16);
{  uint32_t x63 = ((uint32_t)x61 & 0x3fffff);
{  uint64_t x64 = (x62 + x44);
{  uint32_t x65 = (uint32_t) (x64 >> 0x16);
{  uint32_t x66 = ((uint32_t)x64 & 0x3fffff);
{  uint64_t x67 = (x65 + x43);
{  uint32_t x68 = (uint32_t) (x67 >> 0x16);
{  uint32_t x69 = ((uint32_t)x67 & 0x3fffff);
{  uint64_t x70 = (x68 + x42);
{  uint32_t x71 = (uint32_t) (x70 >> 0x16);
{  uint32_t x72 = ((uint32_t)x70 & 0x3fffff);
{  uint64_t x73 = (x71 + x41);
{  uint32_t x74 = (uint32_t) (x73 >> 0x16);
{  uint32_t x75 = ((uint32_t)x73 & 0x3fffff);
{  uint64_t x76 = (x74 + x40);
{  uint32_t x77 = (uint32_t) (x76 >> 0x16);
{  uint32_t x78 = ((uint32_t)x76 & 0x3fffff);
{  uint32_t x79 = (x51 + (0x3 * x77));
{  uint32_t x80 = (x79 >> 0x17);
{  uint32_t x81 = (x79 & 0x7fffff);
{  uint32_t x82 = (x80 + x54);
{  uint32_t x83 = (x82 >> 0x16);
{  uint32_t x84 = (x82 & 0x3fffff);
out[0] = x78;
out[1] = x75;
out[2] = x72;
out[3] = x69;
out[4] = x66;
out[5] = x63;
out[6] = x60;
out[7] = x83 + x57;
out[8] = x84;
out[9] = x81;
}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}
// caller: uint64_t out[10];
