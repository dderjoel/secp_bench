#!/usr/bin/env bash

root=./
tmp=/tmp/eval_x_

for impl in default_asm default_c default_c52 fiat_c fiat_cryptopt; do
  nummachines=0

  while read -r machine; do
    nummachines=$((nummachines + 1))

    r="${tmp}${impl}_part_$(basename "${machine}")"
    awk '{printf "%20s %15s\n", $1, $5}' "${machine}/${impl}_bench_ecmult.log" | tail -n +3 >"${r}"
    awk '{printf "%20s %15s\n", $1, $5}' "${machine}/${impl}_bench_internal.log" | tail -n +3 >>"${r}"

  done < <(find ${root} -mindepth 1 -maxdepth 1 -type d -not -name '.git' -and -not -name 'base' | sort)

  paste ${tmp}${impl}_part_* |
    # awk '{sum=1; num=0; printf "%20s", $1; for (i =2; i<= NF; i+=2){ printf ",%15s", $i; sum*=$i; num++}; printf " %15s %2s %15s\n", sum, num, sum ** (1/num); }' | #(this one writes the avgs' per machine, product, count and geometric mean)
    awk '{sum=1; num=0; printf "%20s", $1; for (i =2; i<= NF; i+=2){ sum *= $i; num++ }; printf "%15s\n", sum ** ( 1 / num ) }' |
    tee ${impl}.gm
  rm ${tmp}${impl}_part_*
done

(
  printf "|%20s |%15s |%15s |%15s |%15s |%15s |\n" "implementation" "default_asm" "default_c" "default_c52" "fiat_c" "fiat_cryptopt"
  printf "|---------------------|----------------|----------------|----------------|----------------|----------------|\n"
  paste ./{default_asm,default_c,default_c52,fiat_c,fiat_cryptopt}.gm |
    awk '{printf "|%20s ", $1; for (i =2; i<= NF; i+=2) printf "|%15s ", $i; printf "|\n"  }'
) | tee geometic_mean.md

rm ./*.gm
