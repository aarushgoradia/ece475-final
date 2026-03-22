//=========================================================================
// riscv-waw-hazard.S
//=========================================================================

#include "riscv-macros.h"

    TEST_RISCV_BEGIN
    
    li x1, 4
    li x2, 5
    li x3, 3

    .align 3

    addi x4, x2, 3
    addi x4, x1, 2

    TEST_CHECK_EQ( x4, 6 )

    // test no waw hazard to make sure both pipes work

    .align 3
    addi x5, x2, 3
    addi x6, x3, 4

    TEST_CHECK_EQ( x5, 8 )
    TEST_CHECK_EQ( x6, 7 )



    TEST_RISCV_END

