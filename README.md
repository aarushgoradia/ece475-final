# riscv-branch-predictors

Three dynamic branch predictors (bimodal, gshare and TAGE-lite) dropped into a 5-stage RV32IM pipeline in Verilog, then raced against a static not-taken baseline on seven microbenchmarks.

Final project for ECE 475 (Computer Architecture) at Princeton, built with Janardhan Raghunathan.

<picture>
  <source media="(prefers-color-scheme: dark)" srcset="docs/mispredicts-dark.svg">
  <img alt="Grouped bar chart of mispredict rate for four predictors across seven benchmarks" src="docs/mispredicts-light.svg">
</picture>

## TL;DR

- **Gshare takes `nested-loops` from 90.6% mispredicts to 3.8%.** Bimodal gets `masked-filter` from 49.3% to 7.9%.
- **IPC barely moves:** +1.8% on `nested-loops`, and +4.6% at best (`bin-search`).
- On `long-correl` the predictors miss *less* than the baseline (46.5% vs. 54.1%) and still run 2.4% *slower*.

All three come from the same thing: where the prediction happens.

## Where the guess happens

<picture>
  <source media="(prefers-color-scheme: dark)" srcset="docs/pipeline-dark.svg">
  <img alt="Five pipeline stages with the predictor feeding decode; correct taken guesses redirect from decode with one bubble, mispredicts flush fetch and decode with two" src="docs/pipeline-light.svg">
</picture>

There's no BTB, so the branch target isn't known until **decode**. The predictor is read in D, and a "taken" guess redirects the PC from there. That costs one bubble even when the guess is right. Branches resolve in X, so a wrong guess flushes F and D for two bubbles.

```math
\text{bubbles} = 1 \cdot N_{\text{correct taken guesses}} + 2 \cdot N_{\text{mispredicts}}
```

The baseline guesses not-taken, which is free when it's right and costs 2 cycles when the branch is taken. So a predictor saves at most **1 cycle per taken branch, not 2**. On `nested-loops`, gshare removes 478 mispredicts and saves 477 cycles, almost exactly 1 cycle each.

It's also why `long-correl` gets slower. Its branches are close to coin flips, and every wrong "taken" guess now costs 2 cycles where the baseline's not-taken guess cost 0. Fetch-stage prediction with a BTB is the obvious next step.

## The predictors

| Predictor | State | Index |
| --- | --- | --- |
| Static not-taken (`riscvlong`) | None | n/a |
| Bimodal (`riscvbt`) | 1024 × 2-bit counters | $\text{pc}[11{:}2]$ |
| Gshare (`riscvgshare`) | 1024 × 2-bit counters + 10-bit GHR | $\text{pc}[11{:}2] \oplus \text{ghr}$ |
| TAGE-lite (`riscvtage`) | 256-entry bimodal T0 + 256-entry tagged T1 (3-bit counters, 8-bit tags, a useful bit) + 8-bit GHR | T1: $\text{pc}[9{:}2] \oplus \text{ghr}$, tag: $\text{pc}[17{:}10] \oplus \text{rot}(\text{ghr})$ |

All counters reset to weakly not-taken. TAGE-lite predicts from T1 when its tag matches and falls back to T0 otherwise. On a mispredict it allocates into T1 unless the entry is marked useful, in which case it clears the useful bit first.

Two results I didn't expect:

- **TAGE-lite ties bimodal on 5 of 7 benchmarks.** On runs this short, T1 rarely gets a confident hit, so T0 (a plain bimodal table) makes nearly every call.
- **Gshare loses on `correlated`**, the benchmark written to make it win (56.8% vs. bimodal's 43.2%). The data is random, so 10 bits of history mostly spread each branch across counters that never get enough samples to train.

## All the numbers

| Benchmark | Static not-taken | Bimodal | Gshare | TAGE-lite | Best IPC vs. baseline |
| --- | ---: | ---: | ---: | ---: | ---: |
| vvadd | 90.0% | **20.0%** | 90.0% | **20.0%** | 0.962 → 0.974 |
| cmplx-mult | 92.6% | **11.1%** | 44.4% | **11.1%** | 0.725 → 0.732 |
| bin-search | 54.5% | **21.1%** | 35.0% | **21.1%** | 0.720 → 0.753 |
| masked-filter | 49.3% | **7.9%** | 10.0% | **7.9%** | 0.782 → 0.814 |
| correlated | 62.5% | **43.2%** | 56.8% | 44.0% | 0.848 → 0.846 |
| nested-loops | 90.6% | 9.6% | **3.8%** | 9.6% | 0.775 → 0.790 |
| long-correl | 54.1% | **46.5%** | 50.0% | 46.6% | 0.690 → 0.673 |

Raw counts (cycles, instructions, branches, mispredicts) are in [`build/results.csv`](build/results.csv).

## Running it

Requires [Icarus Verilog](https://steveicarus.github.io/iverilog/). The test and benchmark images are prebuilt, so you don't need a RISC-V toolchain.

```bash
cd build
make check-asm-riscvgshare     # RISC-V ISA tests on the gshare core
make run-bmark-riscvgshare     # the seven microbenchmarks
./gather-stats.sh > results.csv
```

Swap `gshare` for `bt`, `tage` or `long` to run the other cores. The benchmark sources (and the Python scripts that generate `nested-loops`, `long-correl` and `correlated`) are in [`ubmark/ubmark/`](ubmark/ubmark).

## Repository layout

| Path | Contents |
| --- | --- |
| `riscvlong/` | Baseline 5-stage bypassed pipeline with pipelined mul/div, static not-taken |
| `riscvbt/` | + bimodal predictor (`riscvbt-BHT.v`) |
| `riscvgshare/` | + gshare (`riscvgshare-gshare.v`) |
| `riscvtage/` | + TAGE-lite (`riscvtage-tage.v`) |
| `riscvstall/`, `riscvbyp/`, `riscvdualfetch/`, `riscvssc/` | Earlier pipelines from the course: stall-only, bypassing, dual fetch, 2-wide superscalar |
| `ubmark/` | Microbenchmarks |
| `tests/` | RISC-V assembly tests |
| `build/` | Makefile, stats script, results |

Janardhan wrote the TAGE-lite table and much of the superscalar scoreboard. I did bimodal, gshare, the benchmarks and the stats pipeline.
