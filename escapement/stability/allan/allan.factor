! Copyright (C) 2026 Aneesh Krishna.
! Escapement: IEEE 1588-2019 Precision Time Protocol Engine.
! Allan Deviation (ADEV), Modified Allan Deviation (MDEV), and Time Deviation (TDEV).

USING: accessors arrays kernel locals math math.functions
math.order sequences ;
IN: escapement.stability.allan

TUPLE: allan-point
    { tau float }
    { adev float }
    { mdev float }
    { tdev float } ;

: <allan-point> ( tau adev mdev tdev -- pt )
    allan-point boa ;

! Standard Allan Variance over fractional frequency deviations
! y: array of double, m: stride / octave factor
:: compute-allan-variance ( y-array m -- avar )
    y-array length :> n
    n m /i :> effective-n
    effective-n 2 < [
        0.0
    ] [
        0.0 :> sum-sq!
        effective-n 1 - :> pairs
        pairs [| i |
            i 1 + m * y-array nth
            i m * y-array nth - :> diff
            diff diff * sum-sq + sum-sq!
        ] each-integer
        sum-sq 2.0 pairs >float * /
    ] if ;

! Standard Allan Deviation: sqrt(avar)
:: compute-allan-deviation ( y-array m -- adev )
    y-array m compute-allan-variance sqrt ;

! Overlapping Allan Deviation computed directly from phase data x (seconds)
! tau0: sampling period, m: integer multiplier for tau = m * tau0
:: compute-overlapping-allan-deviation ( x-array tau0 m -- oadev )
    x-array length :> n
    n 2 m * <= [
        0.0
    ] [
        n 2 m * - :> terms
        0.0 :> sum-sq!
        terms [| i |
            i 2 m * + x-array nth
            2.0 i m + x-array nth * -
            i x-array nth + :> d
            d d * sum-sq + sum-sq!
        ] each-integer
        m >float tau0 * :> tau
        2.0 tau tau * * terms >float * :> denom
        sum-sq denom / sqrt
    ] if ;

! Modified Allan Variance (MVAR) from phase data x (seconds)
:: compute-modified-allan-variance ( x-array tau0 m -- mvar )
    x-array length :> n
    n 3 m * < [
        0.0
    ] [
        n 3 m * - 1 + :> n-outer
        0.0 :> total-sum!
        n-outer [| j |
            0.0 :> sum-inner!
            m [| k |
                j k + :> i
                i 2 m * + x-array nth
                2.0 i m + x-array nth * -
                i x-array nth + sum-inner + sum-inner!
            ] each-integer
            sum-inner sum-inner * total-sum + total-sum!
        ] each-integer
        m >float :> mf
        2.0 mf mf * * mf mf * * tau0 tau0 * * n-outer >float * :> denom
        total-sum denom /
    ] if ;

:: compute-modified-allan-deviation ( x-array tau0 m -- mdev )
    x-array tau0 m compute-modified-allan-variance sqrt ;

! Time Deviation (TDEV): tau / sqrt(3) * MDEV
:: compute-time-deviation ( x-array tau0 m -- tdev )
    m >float tau0 * :> tau
    tau 3.0 sqrt / x-array tau0 m compute-modified-allan-deviation * ;

! Multi-tau stability curve generator: scans octaves m = 1, 2, 4, 8, ...
:: compute-stability-curve ( x-array tau0 -- points )
    x-array length :> n
    V{ } clone :> acc
    1 :> m!
    [ n 3 m * >= ] [
        m tau0 * :> tau
        x-array tau0 m compute-overlapping-allan-deviation :> adev
        x-array tau0 m compute-modified-allan-deviation :> mdev
        x-array tau0 m compute-time-deviation :> tdev
        tau adev mdev tdev <allan-point> acc push
        m 2 * m!
    ] while
    acc >array ;
