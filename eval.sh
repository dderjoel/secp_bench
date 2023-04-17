#!/usr/bin/env bash

res="$(hostname)_secpbench"
paste {asm,c,c52,fiat_c,fiat_cryptopt}_bench_ecmult.log | head -n10 | tail -n+3 >"${res}"
paste {asm,c,c52,fiat_c,fiat_cryptopt}_bench_internal.log | grep -e 'field_sqr' -e 'field_mul' >>"${res}"

printf "%20s,%10s,%10s,%10s,%10s,%10s\n" "bench" "asm" "c" "c52" "fiat_c" "fiat_cryptopt"
awk '{printf "%20s", $1; for (i =5; i<= NF; i+=7) printf ",%10s", $i; printf "\n"; }' "${res}"

# awk '{printf "%s %s (", $1, $2; for (i =3; i<= NF; i+=4) printf "%s*", $i; printf "1)^(1/10)\n"; }' ecmult
# awk ' {print $3}' <merge_calc.bench | calc -p >evaled.bench
# paste merge_calc.bench evaled.bench | awk ' { printf "%s %s %s\n", $1, $2, $4;}' | sort --key=3g >gm.sorted.bench
# sort -u -k2,2 gm.sorted.bench >fastest.bench
#
# cat fastest.bench
