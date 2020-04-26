! Copyright (C) 2026 Aneesh Krishna.
! Escapement: IEEE 1588-2019 Precision Time Protocol Engine.
! Unit tests for PI/PID servos, 2-state Kalman filter, and linear regression.

USING: accessors arrays io kernel locals math math.functions
math.order sequences escapement.servo.kalman
escapement.servo.linear escapement.servo.pi ;
IN: escapement.tests.servo

:: run-servo-tests ( -- )
    "--- Running Servo & Estimator Unit Tests ---" print

    ! 1. PI Servo Anti-Windup Clamping
    0.1 0.05 0.0 500.0 <pi-servo> :> pi
    ! Apply massive phase error of 100,000 ns to trigger saturation
    100000.0 1.0 pi pi-servo-step :> adj-max
    adj-max 500.0 = [ "pass: pi servo positive clamp" print ] [ "fail: pi clamp" throw ] if

    -100000.0 1.0 pi pi-servo-step :> adj-min
    adj-min -500.0 = [ "pass: pi servo negative clamp" print ] [ "fail: pi clamp neg" throw ] if

    ! 2. 2-State Kalman Filter Convergence
    default-kalman-servo :> kf
    ! Feed 20 iterations of constant 10.0 ns phase error
    20 [| i |
        10.0 0.125 kf kalman-servo-step drop
    ] each-integer
    kf phase-est>> 9.0 >= kf phase-est>> 11.0 <= and
    [ "pass: kalman filter phase convergence" print ] [ "fail: kalman phase" throw ] if

    ! 2b. Kalman Filter Frequency Ramp Estimation
    default-kalman-servo :> kf2
    ! Feed linear phase progression: 50 ns per second (50 ppb drift)
    80 [| i |
        i >float 0.125 * 50.0 * 0.125 kf2 kalman-servo-step drop
    ] each-integer
    kf2 freq-est>> 40.0 >= kf2 freq-est>> 60.0 <= and
    [ "pass: kalman frequency drift tracking" print ] [ "fail: kalman freq tracking" throw ] if

    ! 3. Linear Regression Fit
    10 <linear-drift-estimator> :> est
    0.0 5.0 est estimator-add-sample
    1.0 15.0 est estimator-add-sample
    2.0 25.0 est estimator-add-sample
    est estimator-compute-fit :> ( slope intercept r2 )
    slope 10.0 - abs 1e-6 <
    intercept 5.0 - abs 1e-6 < and
    r2 0.999 >= and
    [ "pass: linear regression exact fit" print ] [ "fail: linear regression" throw ] if

    "All Servo & Estimator unit tests passed successfully." print ;
