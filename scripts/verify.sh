#!/usr/bin/env bash
# Escapement Automated End-to-End Verification Harness.
# Compiles C99 SIMD core, runs Factor unit/integration suites, Factor benchmarks,
# Python SDK tests, network simulation, and stability analysis.
# Copyright (C) 2026 Aneesh Krishna. All rights reserved.

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

FACTOR_BIN="/Applications/factor/factor"
if [ ! -f "$FACTOR_BIN" ]; then
    FACTOR_BIN="$(command -v factor || true)"
fi

if [ -z "$FACTOR_BIN" ]; then
    echo "Error: Factor binary not found at /Applications/factor/factor or on PATH"
    exit 1
fi

echo "================================================================================"
echo "                   ESCAPEMENT AUTOMATED VERIFICATION PASS                       "
echo "================================================================================"

echo ""
echo "[1/7] Checking for em dashes and en dashes..."
./scripts/check_no_em_dash.sh

echo ""
echo "[2/7] Compiling C99 SIMD acceleration library..."
make -C c_src clean all

echo ""
echo "[3/7] Running C99 SIMD microbenchmarks..."
./c_src/bench_simd

echo ""
echo "[4/7] Running Factor full unit and integration test suite..."
"$FACTOR_BIN" -roots=. -run=escapement test

echo ""
echo "[5/7] Running Factor subsystem microbenchmarks..."
"$FACTOR_BIN" -roots=. -run=escapement.benchmarks

echo ""
echo "[6/7] Running Python SDK and protocol conformance tests..."
PYTHONPATH=python python3 python/test_escapement.py

echo ""
echo "[7/7] Running end-to-end network clock synchronization simulation..."
"$FACTOR_BIN" -roots=. -run=escapement simulate

echo ""
echo "================================================================================"
echo "VERIFICATION PASSED: ALL 7 STAGES COMPLETED CLEANLY WITH ZERO ERRORS"
echo "================================================================================"
