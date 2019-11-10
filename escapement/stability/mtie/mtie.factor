! Copyright (C) 2026 Aneesh Krishna.
! Escapement: IEEE 1588-2019 Precision Time Protocol Engine.
! Maximum Time Interval Error (MTIE) calculation and ITU-T mask verification.

USING: accessors arrays kernel locals math math.functions
math.order sequences ;
IN: escapement.stability.mtie

TUPLE: mtie-point
    { tau float }
    { mtie float } ! Nanoseconds
    { prc-mask-limit float }
    { pass? boolean } ;

: <mtie-point> ( tau mtie limit pass? -- pt )
    mtie-point boa ;

! Compute MTIE for a single observation window length k samples
:: compute-mtie-at-window ( x-array k -- mtie-val )
    x-array length :> n
    k n > [ 0.0 ] [
        n k - 1 + :> windows
        0.0 :> max-peak-to-peak!
        windows [| i |
            -1e18 :> win-max!
            1e18 :> win-min!
            k [| j |
                i j + x-array nth :> val
                val win-max max win-max!
                val win-min min win-min!
            ] each-integer
            win-max win-min - :> p2p
            p2p max-peak-to-peak max max-peak-to-peak!
        ] each-integer
        max-peak-to-peak
    ] if ;

! ITU-T G.811 Primary Reference Clock (PRC) MTIE Mask in nanoseconds
:: g811-prc-mask-ns ( tau-sec -- limit-ns )
    tau-sec 0.1 < [
        25.0 ! 0.025 microseconds = 25 ns
    ] [
        tau-sec 100.0 < [
            0.275 tau-sec * 1000.0 * 25.0 +
        ] [
            tau-sec 1000.0 < [
                0.275 tau-sec * 1000.0 *
            ] [
                10000.0 ! 10 microseconds clamp
            ] if
        ] if
    ] if ;

! Compute MTIE curve across octaves k = 1, 2, 4, 8, ...
:: compute-mtie-curve ( x-array tau0 -- mtie-points )
    x-array length :> n
    V{ } clone :> acc
    1 :> k!
    [ k n 2 /i <= ] [
        k >float tau0 * :> tau
        x-array k compute-mtie-at-window :> mtie-ns
        tau g811-prc-mask-ns :> limit-ns
        mtie-ns limit-ns <= :> pass?
        tau mtie-ns limit-ns pass? <mtie-point> acc push
        k 2 * k!
    ] while
    acc >array ;
