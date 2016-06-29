Here is an incomplete list of defects in cryptographic implementations. We
should make sure our verification rules out the possibility of similar mistakes
appearing in our code.

| Reference                                                           | Specification               | Implementation              | Defect        |
| ------------------------------------------------------------------- | --------------------------- | --------------------------- | ------------- |
| [openssl#3607](https://rt.openssl.org/Ticket/Display.html?id=3607)  | P256 field element squaring | 64-bit Montgomery form, AMD64 | limb overflow |
| [go#13515](https://github.com/golang/go/issues/13515)               | Modular exponentiation      | uintptr-sized Montgomery form, Go | carry handling |
| [NaCl ed25519 (p. 2)](https://tweetnacl.cr.yp.to/tweetnacl-20131229.pdf) | F25519 mul, square          | 64-bit pseudo-Mersenne, AMD64     | carry handling |
| [openssl#0c687d7e](https://git.openssl.org/gitweb/?p=openssl.git;a=commitdiff;h=dc3c5067cd90f3f2159e5d53c57b92730c687d7e;ds=sidebyside) | Poly1305 | 32-bit pseudo-Mersenne, x86 and ARM | bad truncation |
