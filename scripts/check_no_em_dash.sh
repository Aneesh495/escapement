#!/usr/bin/env bash
# Verification script: ensures zero em dashes or en dashes exist in the codebase.
# Copyright (C) 2026 Aneesh Krishna. All rights reserved.

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

echo "Checking for em dashes and en dashes across all files..."
FOUND=0

# Search for Unicode em dash (U+2014, \xe2\x80\x94) and en dash (U+2013, \xe2\x80\x93)
if grep -rn --exclude-dir=".git" -P "[\x{2014}\x{2013}]" . 2>/dev/null; then
    echo "ERROR: Disallowed em dash or en dash found in codebase."
    FOUND=1
else
    # Fallback search if grep -P is not available
    if LC_ALL=C grep -rn --exclude-dir=".git" $'\xe2\x80\x94' . 2>/dev/null || LC_ALL=C grep -rn --exclude-dir=".git" $'\xe2\x80\x93' . 2>/dev/null; then
        echo "ERROR: Disallowed em dash or en dash found in codebase."
        FOUND=1
    fi
fi

if [ "$FOUND" -eq 0 ]; then
    echo "SUCCESS: Zero em dashes and zero en dashes detected across all files."
    exit 0
else
    exit 1
fi
