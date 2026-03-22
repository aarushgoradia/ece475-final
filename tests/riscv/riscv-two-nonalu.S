//=========================================================================
// riscv-two-nonalu.S
//=========================================================================

#include "riscv-macros.h"

    TEST_RISCV_BEGIN
    
    li x1, 4
    li x2, 5
    li x3, 2

    .align 3

    mul x4, x2, x3
    div x5, x1, x3

    TEST_CHECK_EQ( x4, 10 )
    TEST_CHECK_EQ( x5, 2 )

    TEST_RISCV_END

