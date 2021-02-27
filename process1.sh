#!/bin/bash

VFILE1=a_top_mod_old.sv
VFILE2=a_top_mod_new.sv
DUT=top_mod

echo "firrtl"
./firrtl-1.5-SNAPSHOT \
  --dont-fold div \
  -i a_top_mod.fir \
  -X sverilog \
  -o $VFILE1

echo "firrtl lint"
verilator \
  --top-module top_mod \
  --lint-only \
  $VFILE1

echo "firtool"
../../llvm/circt/build/bin/firtool \
  a_top_mod.fir \
  --lower-to-rtl \
  --enable-lower-types \
  --verilog -o=$VFILE2

echo "firtool lint"
verilator \
  --top-module top_mod \
  --lint-only \
  $VFILE2

echo "yosys 0"
../../YosysHQ/yosys/yosys -q -p "
  read_verilog -sv $VFILE1
  rename $DUT top1
  proc
  memory
  flatten top1
  hierarchy -top top1
  read_verilog -sv $VFILE2
  rename $DUT top2
  proc
  memory
  flatten top2
  equiv_make top1 top2 equiv
  hierarchy -top equiv
  clean -purge
  equiv_simple -short
  equiv_induct -seq 20
  equiv_status -assert
"

echo "yosys 1"
../../YosysHQ/yosys/yosys -q -p "
  read_verilog -sv $VFILE1
  rename $DUT top1
  proc
  memory
  flatten top1
  hierarchy -top top1
  read_verilog -sv $VFILE2
  rename $DUT top2
  proc
  memory
  flatten top2
  equiv_make top1 top2 equiv
  hierarchy -top equiv
  clean -purge
  equiv_simple -short -undef
  equiv_induct -seq 20
  equiv_status -assert
"

echo "yosys 2"
../../YosysHQ/yosys/yosys -q -p "
  read_verilog -sv $VFILE1
  rename $DUT top1
  proc
  memory
  flatten top1
  hierarchy -top top1
  read_verilog -sv $VFILE2
  rename $DUT top2
  proc
  memory
  flatten top2
  equiv_make top1 top2 equiv
  hierarchy -top equiv
  clean -purge
  equiv_simple -short
  equiv_induct -undef -seq 20
  equiv_status -assert
"

echo "yosys 3"
../../YosysHQ/yosys/yosys -q -p "
  read_verilog -sv $VFILE1
  rename $DUT top1
  proc
  memory
  flatten top1
  hierarchy -top top1
  read_verilog -sv $VFILE2
  rename $DUT top2
  proc
  memory
  flatten top2
  clean -purge
  miter -equiv -make_assert -flatten top1 top2 miter
  sat -verify -prove-asserts -enable_undef -show-public miter
"

echo "yosys 4"
../../YosysHQ/yosys/yosys -q -p "
  read_verilog -sv $VFILE1
  rename $DUT top1
  proc
  memory
  flatten top1
  hierarchy -top top1
  read_verilog -sv $VFILE2
  rename $DUT top2
  proc
  memory
  flatten top2
  clean -purge
  miter -equiv -make_assert -flatten top1 top2 miter
  sat -verify -prove-asserts -enable_undef -max_undef -show-public miter
"
