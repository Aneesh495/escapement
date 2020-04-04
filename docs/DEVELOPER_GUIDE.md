# Escapement Developer and Contributor Guide

This guide covers building the project, running the verification suite, extending Factor vocabularies, adding C FFI bindings, and debugging stack effect signatures.

## Prerequisites
- **Factor**: Version 0.102 or later installed at `/Applications/factor/factor` or on system PATH.
- **C Compiler**: Clang (macOS) or GCC (Linux) with C99 support.
- **Python**: Python 3.9 or later (for the compliance test harness).
- **GNU Make**: Version 3.81 or later.

## Quickstart

### 1. Build the C99 Acceleration Library
```bash
make build
```
This compiles `c_src/escapement_simd.c` into `libescapement_simd.dylib` (or `.so` on Linux) and builds `c_src/bench_simd`.

### 2. Run the Verification Suite
```bash
make test
```
Executes all three tiers:
1. C SIMD microbenchmarks and unit tests
2. Factor native test suites (Common, Protocol, BMCA, Servo, Stability, Integration)
3. Python SDK and conformance test suite

### 3. Run Microbenchmarks
```bash
make bench
```

### 4. Run Interactive Showcase
```bash
make demo
```

## Factor Development Patterns

### Vocabulary Conventions
Factor organizes code into vocabularies corresponding to directory hierarchies. For example, the vocabulary `escapement.bmca.dataset-comparison` lives in `escapement/bmca/dataset-comparison/dataset-comparison.factor`.

Each file begins with imports and vocabulary declaration:
```factor
USING: accessors arrays byte-arrays formatting io kernel locals math sequences ;
IN: escapement.my-feature
```

### Stack Effect Signatures
Every word definition must declare its exact stack effect:
```factor
:: compute-offset ( t1 t2 t3 t4 -- offset-ns )
    t2 t1 - t4 t3 - - 2.0 / ;
```
In lexical local words (`::`), inputs are named after the word name in parentheses, followed by `--`, and outputs.

### Parse-Time C FFI Bindings
Foreign function declarations must execute at parse-time using `<< ... >>` so that the shared library is loaded before word compilation:
```factor
<< "escapement_simd" "libescapement_simd.dylib" "cdecl" add-library >>
LIBRARY: escapement_simd
FUNCTION: int escapement_simd_validate_header ( uchar* buf, int len ) ;
```

### Checking for Disallowed Characters
Before committing any changes, run the strict character verification script:
```bash
./scripts/check_no_em_dash.sh
```
This ensures no em dashes or en dashes enter comments, documentation, or code.
