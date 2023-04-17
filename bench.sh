#!/usr/bin/env bash

set -e # die on error

# base is the upsteam project
#
clean() {
  rm -rf asm c c52 fiat_c fiat_cryptopt
  rm -- *.log
}

default_asm() {
  # we compile to use the hand written asembly

  dir=asm
  cp -r ./base "${dir}"
  pushd "${dir}"
  ./autogen.sh
  ./configure --with-asm=x86_64
  make -j bench_internal bench_ecmult

  popd

  ./${dir}/bench_internal >./${dir}_bench_internal.log
  ./${dir}/bench_ecmult >./${dir}_bench_ecmult.log
}

default_c() {
  # we compile to use the upsteam C version which contains 810
  dir=c
  cp -r ./base "${dir}"
  pushd "${dir}"
  ./autogen.sh
  ./configure --with-asm=no
  make -j bench_internal bench_ecmult

  popd

  ./${dir}/bench_internal >./${dir}_bench_internal.log
  ./${dir}/bench_ecmult >./${dir}_bench_ecmult.log
}

default_c52() {
  # we compile to use the C version which does not contain 810 by reverting the patch
  dir=c52
  cp -r ./base "${dir}"
  cp ./field_5x52_asm_impl_before_810.h "${dir}"/src/field_5x52_int128_impl.h
  pushd "${dir}"

  ./autogen.sh
  ./configure --with-asm=no
  make -j bench_internal bench_ecmult

  popd

  ./${dir}/bench_internal >./${dir}_bench_internal.log
  ./${dir}/bench_ecmult >./${dir}_bench_ecmult.log

}

fiat_c() {
  # we replace the C versions.
  dir=fiat_c
  cp -r ./base "${dir}"
  cp ./secp256k1_dettman_64.c "${dir}"/src

  cat >"${dir}/src/field_5x52_int128_impl.h" <<EOF

#ifndef SECP256K1_FIELD_INNER5X52_IMPL_H
#define SECP256K1_FIELD_INNER5X52_IMPL_H

#include <stdint.h>

#include "secp256k1_dettman_64.c"

SECP256K1_INLINE static void
secp256k1_fe_mul_inner(uint64_t *r, const uint64_t *a,
                       const uint64_t *SECP256K1_RESTRICT b) {
  fiat_secp256k1_dettman_mul(r, a, b);
}

SECP256K1_INLINE static void secp256k1_fe_sqr_inner(uint64_t *r,
                                                    const uint64_t *a) {
  fiat_secp256k1_dettman_square(r, a);
}

#endif /* SECP256K1_FIELD_INNER5X52_IMPL_H */
EOF

  pushd "${dir}"
  ./autogen.sh
  ./configure --with-asm=no
  make -j bench_internal bench_ecmult

  popd

  ./${dir}/bench_internal >./${dir}_bench_internal.log
  ./${dir}/bench_ecmult >./${dir}_bench_ecmult.log

}

fiat_cryptopt() {
  # we replace the C versions.
  dir=fiat_cryptopt
  cp -r ./base "${dir}"
  cp ./field_5x52_asm_impl_cryptopt.h ./field_5x52_asm_impl_cryptopt.c "${dir}"/src
  pushd "${dir}"

  sed -i -e 's@#include "field_5x52_asm_impl.h"@#include "field_5x52_asm_impl_cryptopt.h"@' ./src/field_5x52_impl.h
  sed -i ./Makefile.am \
    -e 's@libsecp256k1_la_SOURCES = src/secp256k1.c@\0 ./src/field_5x52_asm_impl_cryptopt.c@' \
    -e 's@bench_SOURCES = src/bench.c@\0 ./src/field_5x52_asm_impl_cryptopt.c@' \
    -e 's@bench_internal_SOURCES = src/bench_internal.c@\0 ./src/field_5x52_asm_impl_cryptopt.c@' \
    -e 's@bench_ecmult_SOURCES = src/bench_ecmult.c@\0 ./src/field_5x52_asm_impl_cryptopt.c@'

  ./autogen.sh
  ./configure --with-asm=x86_64
  make -j bench_internal bench_ecmult

  popd

  ./${dir}/bench_internal >./${dir}_bench_internal.log
  ./${dir}/bench_ecmult >./${dir}_bench_ecmult.log

}

clean
default_c
default_c52
default_asm
fiat_c
fiat_cryptopt

./eval.sh
