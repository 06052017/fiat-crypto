#include <stdint.h>

#undef force_inline
#define force_inline __attribute__((always_inline))

void force_inline fesub(uint64_t* out, uint64_t x8, uint64_t x9, uint64_t x7, uint64_t x5, uint64_t x14, uint64_t x15, uint64_t x13, uint64_t x11);
