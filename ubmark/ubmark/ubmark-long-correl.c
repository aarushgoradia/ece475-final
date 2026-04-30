//========================================================================
// ubmark-long-correl
//========================================================================
// Demonstrates long-range branch correlation separated by noise.
// An anchor branch sets a flag, followed by a series of noisy branches
// that pollute short global history registers. The final branch
// correlates perfectly with the anchor. 
// Dramatic win for TAGE with long history lengths over Gshare/Bimodal.

#include "ubmark.h"
#include "ubmark-long-correl.dat"

//------------------------------------------------------------------------
// long_correl_scalar
//------------------------------------------------------------------------

__attribute__ ((noinline, optimize("O1")))
int long_correl_scalar( int *src, int *noise, int size )
{
  volatile int *vsrc = src;
  volatile int *vnoise = noise;
  int sum = 0;
  int i, j;

  for ( i = 0; i < size; i++ ) {
    int flag = 0;

    // 1. The Anchor Branch
    // Highly unpredictable on its own (randomized in the .dat file)
    if ( vsrc[i] > 0 ) {
      flag = 1;
    }

    // 2. The History Polluter (Noise)
    // 12 noisy branches to completely flush out a typical 8-to-12 bit GHR
    for ( j = 0; j < 12; j++ ) {
      if ( vnoise[i*12 + j] % 2 == 0 ) {
        sum += 1;
      } else {
        sum -= 1;
      }
    }

    // 3. The Correlated Branch
    // Outcome is 100% determined by the Anchor Branch.
    // TAGE's longer history captures the anchor; Gshare only sees the noise.
    if ( flag ) {
      sum += 10;
    } else {
      sum -= 10;
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
  // Using 1000 outer loop iterations to ensure predictors have time to train
  int size = 1000; 

  int temp = 0;
  test_stats_on( temp );
  int result = long_correl_scalar( src, noise, size );
  test_stats_off( temp );

  verify_results( result, ref );
  return 0;
}