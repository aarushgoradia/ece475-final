#!/bin/bash
# Aggregate branch predictor stats from all benchmark output files.

BENCHMARKS=(vvadd cmplx-mult bin-search masked-filter correlated nested-loops long-correl)
PREDICTORS=(long bt gshare tage)

# CSV header
echo "benchmark,predictor,cycles,instructions,cond_branches,taken_branches,mispredicts,ipc,mispredict_rate"

for bm in "${BENCHMARKS[@]}"; do
  for pred in "${PREDICTORS[@]}"; do
    f="ubmark-${bm}-${pred}.out"
    if [[ ! -f "$f" ]]; then
      echo "WARNING: $f not found" >&2
      continue
    fi

    cycles=$(grep "num_cycles"         "$f" | awk '{print $NF}')
    inst=$(  grep "num_inst "          "$f" | awk '{print $NF}')
    cb=$(    grep "num_cond_branches"  "$f" | awk '{print $NF}')
    tb=$(    grep "num_taken_branches" "$f" | awk '{print $NF}')
    mp=$(    grep "num_mispredicts"    "$f" | awk '{print $NF}')
    ipc=$(   grep " ipc"               "$f" | awk '{print $NF}')
    rate=$(  grep "mispredict_rate"    "$f" | awk '{print $NF}')

    echo "$bm,$pred,$cycles,$inst,$cb,$tb,$mp,$ipc,$rate"
  done
done