#!/bin/bash

FIRTOOL=../circt/build/bin/firtool
FIRRTL=../firrtl/utils/bin/firrtl
VFILE1=top_mod.v
VFILE2=top_mod_m.v
DUT=top_mod

echo "
<script src=\"main.js\"></script>
<style>
table { width: 100%; border-collapse: collapse; }
table, th, td { border: 1px solid black; }
th, td { padding: 6px; }
td { white-space: pre; }
</style>
<table id=\"log\">
<row>
<th>seed</th>
<th>firrtl</th>
<th>lint</th>
<th>mlir</th>
<th>lint</th>
<th>yosys</th>
<th>avg time</th>
</row>"

for (( s=1; s<=10000; s++ ))
do
  START_TIME=$SECONDS
  echo "<tr>"

  echo "<td>$s</td>"
  ./bin/cli.js \
    --seed $s \
    --max-width 20 \
    --max-inputs 20 \
    --max-ops 50 \
    --verif false \
    fir > top_mod.fir
    # -L false \
  echo "<td>"
  $FIRRTL -i top_mod.fir -o $VFILE1
  echo "</td>"
 
  echo "<td>"
  if [[ ! -e $VFILE1 ]]
  then
    echo "N/A"
  else
    verilator --lint-only $VFILE1
  fi
  echo "</td>"

  echo "<td>"
  LLVM_PROFILE_FILE="raw_profiles/seed_${s}.profraw" $FIRTOOL \
    top_mod.fir \
    --verilog -o=$VFILE2
  echo "</td>"

  echo "<td>"
  if [[ ! -e $VFILE2 ]]
  then
    echo "N/A"
  else
    verilator --lint-only $VFILE2
  fi
  echo "</td>"


  echo "<td>"
  if [[ (! -e $VFILE1) || (! -e $VFILE2) ]]
  then
    echo "N/A"
  else
    yosys -q -p "
      read_verilog $VFILE1
      rename $DUT top1
      proc
      memory
      flatten top1
      hierarchy -top top1
      async2sync
      read_verilog $VFILE2
      rename $DUT top2
      proc
      memory
      flatten top2
      equiv_make top1 top2 equiv
      hierarchy -top equiv
      async2sync
      clean -purge
      equiv_simple -short
      equiv_induct
      equiv_status -assert
    "
  fi
  echo "</td>"

  echo "<td>"
  ELAPSED_TIME=$(( SECONDS - START_TIME ))
  echo $ELAPSED_TIME
  echo "</td>"
  echo "</tr>"
  if [[ -e $VFILE1 ]]
  then
    rm "$VFILE1"
  fi
  if [[ -e $VFILE2 ]]
  then
    rm "$VFILE2"
  fi
done
