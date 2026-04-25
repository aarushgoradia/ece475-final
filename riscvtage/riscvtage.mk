#=========================================================================
# riscvtage Subpackage
#=========================================================================

riscvtage_deps = \
  vc \
  imuldiv \

riscvtage_srcs = \
  riscvtage-CoreDpath.v \
  riscvtage-CoreDpathRegfile.v \
  riscvtage-CoreDpathAlu.v \
  riscvtage-CoreCtrl.v \
  riscvtage-Core.v \
  riscvtage-InstMsg.v \
  riscvtage-CoreDpathPipeMulDiv.v \
  riscvtage-tage.v

riscvtage_test_srcs = \
  riscvtage-InstMsg.t.v \
  riscvtage-CoreDpathPipeMulDiv.t.v \

riscvtage_prog_srcs = \
  riscvtage-sim.v \
  riscvtage-randdelay-sim.v \

