#=========================================================================
# riscvbt Subpackage
#=========================================================================

riscvbt_deps = \
  vc \
  imuldiv \

riscvbt_srcs = \
  riscvbt-CoreDpath.v \
  riscvbt-CoreDpathRegfile.v \
  riscvbt-CoreDpathAlu.v \
  riscvbt-CoreCtrl.v \
  riscvbt-Core.v \
  riscvbt-InstMsg.v \
  riscvbt-CoreDpathPipeMulDiv.v \

riscvbt_test_srcs = \
  riscvbt-InstMsg.t.v \
  riscvbt-CoreDpathPipeMulDiv.t.v \

riscvbt_prog_srcs = \
  riscvbt-sim.v \
  riscvbt-randdelay-sim.v \

