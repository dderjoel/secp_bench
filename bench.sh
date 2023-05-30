#!/usr/bin/env bash

set -e # die on error

# base is the upsteam project but ecmult does not run _all_ the benchmarks

default_asm() {
  # we compile to use the hand written asembly
  dir=default_asm
  rm -rf "${dir}"
  cp -r ../base "${dir}"
  pushd "${dir}"
  ./autogen.sh
  ./configure --with-asm=x86_64
  make -j bench_internal bench_ecmult

}

default_c() {
  # we compile to use the upsteam C version which contains 810
  dir=default_c
  rm -rf "${dir}"
  cp -r ../base "${dir}"
  pushd "${dir}"
  ./autogen.sh
  ./configure --with-asm=no
  make -j bench_internal bench_ecmult

  popd
}

default_c52() {
  # we compile to use the C version which does not contain 810 by reverting the patch
  dir=default_c52
  rm -rf "${dir}"
  cp -r ../base "${dir}"
  cp ../field_5x52_asm_impl_before_810.h "${dir}"/src/field_5x52_int128_impl.h
  pushd "${dir}"

  ./autogen.sh
  ./configure --with-asm=no
  make -j bench_internal bench_ecmult

  popd
}

fiat_c() {
  # we replace the C versions.
  dir=fiat_c
  rm -rf "${dir}"
  cp -r ../base "${dir}"
  cp ../secp256k1_dettman_64.c "${dir}"/src

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
}

fiat_cryptopt() {
  # with the replaced asm version, copying from fork dderjoel/secp256k1
  dir=fiat_cryptopt
  rm -rf "${dir}"
  cp -r ../secp256k1 "${dir}"
  pushd "${dir}"

  ./autogen.sh
  ./configure --with-asm=x86_64
  make -j bench_internal bench_ecmult

  popd
}

wd="$(hostname)"
mkdir -p "${wd}"
pushd "${wd}"

default_asm &
default_c &
default_c52 &
fiat_c &
fiat_cryptopt &

wait

for dir in $(ls | grep -v base); do
  test ! -d "${dir}" && continue
  "./${dir}/bench_internal" field | tee "./${dir}_bench_internal.log"
  "./${dir}/bench_ecmult" | tee "./${dir}_bench_ecmult.log"
done

popd
./eval.sh
#
# clean() {
# rm -rf "$(hostname)"{asm,c,c52,fiat_c,fiat_cryptopt}
# rm -r -- "$(hostname)"{asm,c,c52,fiat_c,fiat_cryptopt}*.log
# }
