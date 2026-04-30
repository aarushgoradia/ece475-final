//========================================================================
// ubmark-correlated
//========================================================================
// Tests global-history correlation. Two branches in the inner loop both
// depend on the same loaded value (x > 0), so they are perfectly
// correlated. gShare and TAGE should outperform bimodal here because
// the GHR captures the outcome of the first branch, allowing the second
// to be predicted perfectly. Random data ensures bimodal cannot rely
// on per-PC bias.
//
// Uses volatile loads + optimize("O1") to prevent the compiler from
// fusing the two correlated branches into a single comparison.

#include "ubmark.h"
#include "ubmark-correlated.dat"

//------------------------------------------------------------------------
// correlated-scalar
//------------------------------------------------------------------------

__attribute__ ((noinline, optimize("O1")))
void correlated_scalar( int *dest, int *src, int size )
{
  volatile int *vsrc = src;  // force re-load each access, prevent CSE/fusion

  int i;
  for ( i = 0; i < size; i++ ) {
    int x_a = vsrc[i];   // load 1 — drives branch A
    int x_b = vsrc[i];   // load 2 — drives branch B (separate load!)
    int val = 0;

    // Branch A
    if ( x_a > 0 ) {
      val = val + x_a;
    }

    // Branch B — same data but compiler can't prove it's the same value
    if ( x_b > 0 ) {
      val = val * 2;
    }

    dest[i] = val;
  }
}

//------------------------------------------------------------------------
// verify_results
//------------------------------------------------------------------------

void verify_results( int dest[], int ref[], int size )
{
  int temp = 0;
  int i;
  for ( i = 0; i < size; i++ ) {
    if ( !( dest[i] == ref[i] ) ) {
      test_fail( temp );
    }
  }
  test_pass( temp );
}

//------------------------------------------------------------------------
// Test Harness
//------------------------------------------------------------------------

int dest[500];   // file-scope to avoid blowing the stack with N=500

int main( int argc, char* argv[] )
{
  int size = 500;
  int i;
  for ( i = 0; i < size; i++ )
    dest[i] = 0;

  int temp = 0;
  test_stats_on( temp );
  correlated_scalar( dest, src, size );
  test_stats_off( temp );

  verify_results( dest, ref, size );
  return 0;
}