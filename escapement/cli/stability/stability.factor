! Copyright (C) 2026 Aneesh Krishna.
! Escapement: IEEE 1588-2019 Precision Time Protocol Engine.
! Stability analysis CLI: computes Allan deviation (ADEV, MDEV, TDEV) and MTIE.

USING: accessors arrays formatting io kernel locals math
math.functions math.parser sequences strings
escapement.stability.allan escapement.stability.mtie ;
IN: escapement.cli.stability

:: run-stability-analysis ( -- )
    "================================================================================" print
    "              ESCAPEMENT ALLAN DEVIATION & MTIE STABILITY ENGINE                " print
    "================================================================================" print
    "Analyzing frequency stability and phase wander across observation intervals...\n" print

    ! Generate 200 synthetic phase error samples at 0.1s cadence with white PM and flicker FM
    200 :> n
    0.1 :> tau0
    n f <array> :> xs

    n [| i |
        i >float 0.05 * sin 15.0 *
        i >float 0.01 * 2.0 * +
        i xs set-nth
    ] each-integer

    n tau0 "Sample dataset: %d phase measurements at tau0 = %.2f s\n\n" printf

    "================================================================================" print
    "                 ALLAN DEVIATION (ADEV, MDEV, TDEV) SUMMARY                     " print
    "================================================================================" print
    "    Tau (s)   |     ADEV (sigma_y)    |     MDEV (mod_sig)    |     TDEV (s)    " print
    "--------------+-----------------------+-----------------------+-----------------" print

    xs tau0 compute-stability-curve :> allan-pts
    allan-pts [| pt |
        pt tau>> pt adev>> pt mdev>> pt tdev>>
        "  %9.3f   |    %14.6e     |    %14.6e     |   %12.6e\n" printf
    ] each

    "\n================================================================================" print
    "             ITU-T G.811 PRIMARY REFERENCE CLOCK (PRC) MTIE MASK                " print
    "================================================================================" print
    "    Tau (s)   |     Measured MTIE     |    G.811 Mask Limit   |   Conformance   " print
    "--------------+-----------------------+-----------------------+-----------------" print

    xs tau0 compute-mtie-curve :> mtie-pts
    t :> all-pass!
    mtie-pts [| pt |
        pt pass?>> [ ] [ f all-pass! ] if
        pt tau>> pt mtie>> pt prc-mask-limit>> pt pass?>> [ "PASS" ] [ "FAIL" ] if
        "  %9.3f   |    %11.3f ns     |    %11.3f ns     |      %s\n" printf
    ] each

    "================================================================================" print
    all-pass [
        "Conformance Verdict: PASS - Device satisfies ITU-T G.811 PRC network limits." print
    ] [
        "Conformance Verdict: FAIL - Wander exceeded maximum permitted MTIE boundary." print
    ] if
    "================================================================================" print ;
