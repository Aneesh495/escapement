! Copyright (C) 2026 Aneesh Krishna.
! Escapement: IEEE 1588-2019 Precision Time Protocol Engine.
! Linear regression clock drift estimator and moving-window phase predictor.

USING: accessors arrays kernel locals math math.functions
sequences escapement.common.ring-buffer ;
IN: escapement.servo.linear

TUPLE: linear-drift-estimator
    { time-samples ring-buffer }
    { phase-samples ring-buffer } ;

:: <linear-drift-estimator> ( capacity -- est )
    capacity <ring-buffer>
    capacity <ring-buffer>
    linear-drift-estimator boa ;

:: estimator-add-sample ( t-sec phase-ns est -- )
    t-sec est time-samples>> ring-push
    phase-ns est phase-samples>> ring-push ;

! Computes linear regression: phase = slope * t + intercept
! Returns: ( slope-ppb intercept-ns r2-correlation )
:: estimator-compute-fit ( est -- slope intercept r2 )
    est time-samples>> size>> :> n
    n 2 < [
        0.0 0.0 0.0
    ] [
        est time-samples>> ring-to-array :> ts
        est phase-samples>> ring-to-array :> ps

        0.0 :> sum-t!
        0.0 :> sum-p!
        0.0 :> sum-tt!
        0.0 :> sum-tp!
        0.0 :> sum-pp!

        n [| i |
            i ts nth :> t
            i ps nth :> p
            sum-t t + sum-t!
            sum-p p + sum-p!
            sum-tt t t * + sum-tt!
            sum-tp t p * + sum-tp!
            sum-pp p p * + sum-pp!
        ] each-integer

        n >float sum-tt * sum-t sum-t * - :> denom_t
        denom_t abs 1e-15 < [
            0.0 0.0 0.0
        ] [
            n >float sum-tp * sum-t sum-p * - denom_t / :> m
            sum-p m sum-t * - n >float / :> b

            ! R^2 computation
            n >float sum-pp * sum-p sum-p * - :> denom_p
            denom_p abs 1e-15 < [ 1.0 ] [
                n >float sum-tp * sum-t sum-p * - dup *
                denom_t denom_p * /
            ] if :> r_sq

            m b r_sq
        ] if
    ] if ;
