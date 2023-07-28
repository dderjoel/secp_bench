#!/usr/bin/env bash

#this script will output a csv like structure to compare the implementations for one machine
#
res="$(hostname)_secpbench.bench.tmp"
paste "$(hostname)/"{default_asm,default_c,fiat_c,fiat_cryptopt}_bench_ecmult.log | tail -n +3 >"${res}"
paste "$(hostname)/"{default_asm,default_c,fiat_c,fiat_cryptopt}_bench_internal.log | tail -n +3 >>"${res}"

(
  printf "%20s,%15s,%15s,%15s,%15s\n" "bench" "asm" "c" "fiat_c" "fiat_cryptopt"
  awk '{printf "%20s", $1; for (i = 5; i<= NF; i+=7) printf ",%15s", $i; printf "\n"; }' "${res}"
) | tee "${res%.*}.csv"

(

  printf "### %s \n\n" "$(hostname)"
  printf "|%20s |%15s |%15s |%15s |%15s |\n" "bench" "asm" "c" "fiat_c" "fiat_cryptopt"
  printf "|---------------------|----------------|----------------|----------------|----------------|----------------|----------------|\n"
  awk '{printf "|%20s ", $1; for (i = 5; i<= NF; i+=7) printf "|%15s ", $i; printf "|\n"; }' "${res}"
) | tee "${res%.*}.md"

rm "${res}"
