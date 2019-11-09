! Copyright (C) 2026 Aneesh Krishna.
! Escapement: IEEE 1588-2019 Precision Time Protocol Engine.
! 2-State Discrete Kalman Filter Servo for phase and frequency drift tracking.

USING: accessors arrays kernel locals math math.functions
math.order sequences ;
IN: escapement.servo.kalman

TUPLE: kalman-servo
    { phase-est float initial: 0.0 }       ! State[0]: Phase error in ns
    { freq-est float initial: 0.0 }        ! State[1]: Frequency drift in ppb
    { p00 float initial: 100.0 }           ! Covariance matrix P
    { p01 float initial: 0.0 }
    { p10 float initial: 0.0 }
    { p11 float initial: 1.0 }
    { q-phase float initial: 0.01 }        ! Process noise Q_phase (ns^2)
    { q-freq float initial: 0.001 }        ! Process noise Q_freq (ppb^2)
    { r-meas float initial: 4.0 }          ! Measurement noise R (ns^2)
    { max-ppb float initial: 500000.0 } ;

:: <kalman-servo> ( q-phase q-freq r-meas max-ppb -- servo )
    0.0 0.0 100.0 0.0 0.0 1.0 q-phase q-freq r-meas max-ppb kalman-servo boa ;

:: default-kalman-servo ( -- servo )
    0.05 0.002 5.0 500000.0 <kalman-servo> ;

! Pure Factor 2-State Discrete Kalman Filter step
:: kalman-servo-step ( meas-phase-ns dt-sec servo -- adj-ppb )
    dt-sec 0.0 <= [ 1.0 ] [ dt-sec ] if :> dt

    ! 1. State Prediction: x_prior = F * x
    ! F = [ [1, dt], [0, 1] ]
    servo phase-est>> dt servo freq-est>> * + :> x0_prior
    servo freq-est>> :> x1_prior

    ! 2. Covariance Prediction: P_prior = F * P * F^T + Q
    servo p00>> :> p00
    servo p01>> :> p01
    servo p10>> :> p10
    servo p11>> :> p11

    p00 dt p10 p01 + * + dt dt * p11 * + servo q-phase>> + :> p_prior_00
    p01 dt p11 * + :> p_prior_01
    p10 dt p11 * + :> p_prior_10
    p11 servo q-freq>> + :> p_prior_11

    ! 3. Innovation: y = z - H * x_prior  (H = [1, 0])
    meas-phase-ns x0_prior - :> innovation

    ! 4. Innovation Covariance: S = H * P_prior * H^T + R = P_prior_00 + R
    p_prior_00 servo r-meas>> + :> s
    s abs 1e-15 < [ 1e-15 ] [ s ] if :> s_safe

    ! 5. Kalman Gain: K = P_prior * H^T / S
    p_prior_00 s_safe / :> k0
    p_prior_10 s_safe / :> k1

    ! 6. State Update: x_post = x_prior + K * innovation
    x0_prior k0 innovation * + :> x0_post
    x1_prior k1 innovation * + :> x1_post

    ! 7. Covariance Update: P_post = (I - K * H) * P_prior
    p_prior_00 k0 p_prior_00 * - :> p_post_00
    p_prior_01 k0 p_prior_01 * - :> p_post_01
    p_prior_10 k1 p_prior_00 * - :> p_post_10
    p_prior_11 k1 p_prior_01 * - :> p_post_11

    ! Save updated state into servo tuple
    servo x0_post >>phase-est drop
    servo x1_post >>freq-est drop
    servo p_post_00 >>p00 drop
    servo p_post_01 >>p01 drop
    servo p_post_10 >>p10 drop
    servo p_post_11 >>p11 drop

    ! Proportional steering toward zero phase offset combined with estimated drift
    x0_post 0.5 * x1_post + :> adj
    adj servo max-ppb>> neg servo max-ppb>> clamp ;

:: kalman-servo-reset ( servo -- )
    servo 0.0 >>phase-est drop
    servo 0.0 >>freq-est drop
    servo 100.0 >>p00 drop
    servo 0.0 >>p01 drop
    servo 0.0 >>p10 drop
    servo 1.0 >>p11 drop ;
