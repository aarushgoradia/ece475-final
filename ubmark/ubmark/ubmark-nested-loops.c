//========================================================================
// ubmark-nested-loops
//========================================================================
// Dominated by nested loop backedges, all of which are highly biased
// toward taken. Every iteration of the inner loop has the predict-not-
// taken pipeline mispredicting (2-cycle penalty). Bimodal trains in
// one iteration and predicts correctly thereafter (1-cycle penalty for
// correct-taken). Dramatic win for any dynamic predictor.

#include "ubmark.h"
#include "ubmark-nested-loops.dat"

//------------------------------------------------------------------------
// nested-loops-scalar
//------------------------------------------------------------------------

__attribute__ ((noinline, optimize("O1")))
int nested_loops_scalar( int *src, int size )
{
  volatile int *vsrc = src;
  int sum = 0;
  int i, j, k;

  for ( i = 0; i < size; i++ ) {
    for ( j = 0; j < 10; j++ ) {
      for ( k = 0; k < 10; k++ ) {
        sum += vsrc[i] + j + k;
      }
    }
  }

  return sum;
}

//------------------------------------------------------------------------
// verify_results
//------------------------------------------------------------------------

void verify_results( int actual, int expected )
{
  int temp = 0;
  if ( !( actual == expected ) ) {
    test_fail( temp );
  }
  test_pass( temp );
}

//------------------------------------------------------------------------
// Test Harness
//------------------------------------------------------------------------

int main( int argc, char* argv[] )
{
  int size = 50;

  int temp = 0;
  test_stats_on( temp );
  int result = nested_loops_scalar( src, size );
  test_stats_off( temp );

  verify_results( result, ref );
  return 0;
}