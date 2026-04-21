#=========================================================================
# riscvgshare Subpackage
#=========================================================================

riscvgshare_deps = \
  vc \
  imuldiv \

riscvgshare_srcs = \
  riscvgshare-CoreDpath.v \
  riscvgshare-CoreDpathRegfile.v \
  riscvgshare-CoreDpathAlu.v \
  riscvgshare-CoreCtrl.v \
  riscvgshare-Core.v \
  riscvgshare-InstMsg.v \
  riscvgshare-CoreDpathPipeMulDiv.v \
  riscvgshare-gshare.v

riscvgshare_test_srcs = \
  riscvgshare-InstMsg.t.v \
  riscvgshare-CoreDpathPipeMulDiv.t.v \

riscvgshare_prog_srcs = \
  riscvgshare-sim.v \
  riscvgshare-randdelay-sim.v \

