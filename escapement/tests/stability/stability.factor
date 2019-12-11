! Copyright (C) 2026 Aneesh Krishna.
! Escapement: IEEE 1588-2019 Precision Time Protocol Engine.
! Unit tests for Allan Deviation (ADEV, MDEV, TDEV) and MTIE.

USING: accessors arrays io kernel locals math math.functions
sequences escapement.stability.allan escapement.stability.mtie ;
IN: escapement.tests.stability

:: run-stability-tests ( -- )
    "--- Running Stability Analysis Unit Tests ---" print

    ! 1. Constant frequency deviation series should yield near-zero Allan variance
    100 f <array> :> const-freqs
    100 [| i | 1e-9 i const-freqs set-nth ] each-integer
    const-freqs 1 compute-allan-variance :> avar-zero
    avar-zero 1e-25 < [ "pass: zero variance on constant signal" print ] [ "fail: zero avar" throw ] if

    ! 2. Alternating signal +1, -1, +1, -1
    50 f <array> :> alt-freqs
    50 [| i | i 2 mod 1 = 1.0 -1.0 ? i alt-freqs set-nth ] each-integer
    alt-freqs 1 compute-allan-variance :> avar-alt
    avar-alt 0.0 > [ "pass: positive avar on alternating signal" print ] [ "fail: alt avar" throw ] if

    ! 3. Stability curve on smooth phase signal
    100 f <array> :> phase-samples
    100 [| i | i >float 0.1 * sin 5.0 * i phase-samples set-nth ] each-integer
    phase-samples 0.1 compute-stability-curve :> pts
    pts length 0 > [ "pass: stability curve generation" print ] [ "fail: curve" throw ] if

    ! 4. MTIE peak-to-peak calculation
    phase-samples 10 compute-mtie-at-window :> mtie-10
    mtie-10 0.0 > [ "pass: mtie peak-to-peak positive" print ] [ "fail: mtie" throw ] if

    "All Stability Analysis unit tests passed successfully." print ;
