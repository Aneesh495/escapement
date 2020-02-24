#!/usr/bin/env bash
# Escapement Interactive Showcase Demo.
# Demonstrates BMCA election, network simulation, and stability analysis.
# Copyright (C) 2026 Aneesh Krishna. All rights reserved.

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

FACTOR_BIN="/Applications/factor/factor"
if [ ! -f "$FACTOR_BIN" ]; then
    FACTOR_BIN="$(command -v factor || true)"
fi

echo "================================================================================"
echo "                     ESCAPEMENT INTERACTIVE SHOWCASE                            "
echo "================================================================================"

echo ""
echo ">>> STEP 1: Best Master Clock Algorithm (BMCA) Election Demo"
"$FACTOR_BIN" -roots=. -run=escapement bmca

echo ""
echo ">>> STEP 2: Multi-Node Network Synchronization Simulation"
"$FACTOR_BIN" -roots=. -run=escapement simulate

echo ""
echo ">>> STEP 3: Allan Deviation (ADEV/MDEV/TDEV) & MTIE Stability Analysis"
"$FACTOR_BIN" -roots=. -run=escapement stability

echo ""
echo ">>> STEP 4: Raw Wire Packet Dissection (IEEE 1588 Sync Message)"
"$FACTOR_BIN" -roots=. -run=escapement inspect 0002002c000000000000000000000000000000000102030405060708000100010000

echo ""
echo "================================================================================"
echo "Demonstration complete. For daemon mode, run: make serve or make grandmaster"
echo "================================================================================"
