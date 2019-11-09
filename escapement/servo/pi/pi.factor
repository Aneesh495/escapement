! Copyright (C) 2026 Aneesh Krishna.
! Escapement: IEEE 1588-2019 Precision Time Protocol Engine.
! Proportional-Integral (PI/PID) clock servo with anti-windup clamping.

USING: accessors kernel locals math math.functions math.order ;
IN: escapement.servo.pi

TUPLE: pi-servo
    { kp float initial: 0.1 }
    { ki float initial: 0.001 }
    { kd float initial: 0.0 }
    { max-ppb float initial: 500000.0 }
    { integral-accumulator float initial: 0.0 }
    { prev-error float initial: 0.0 }
    { initialized? boolean initial: f } ;

:: <pi-servo> ( kp ki kd max-ppb -- servo )
    kp ki kd max-ppb 0.0 0.0 f pi-servo boa ;

:: default-pi-servo ( -- servo )
    0.2 0.005 0.001 500000.0 <pi-servo> ;

:: pi-servo-step ( phase-offset-ns dt-sec servo -- adj-ppb )
    dt-sec 0.0 <= [ 1.0 ] [ dt-sec ] if :> dt
    phase-offset-ns :> err

    servo kp>> err * :> p_term

    ! Derivative term
    servo initialized?>> [
        servo kd>> err servo prev-error>> - dt / *
    ] [
        0.0
    ] if :> d_term

    ! Candidate integral update
    servo integral-accumulator>> servo ki>> err dt * * + :> cand_i

    ! Anti-windup clamp on integral term
    cand_i servo max-ppb>> neg servo max-ppb>> clamp :> clamped_i
    servo clamped_i >>integral-accumulator drop

    ! Total control effort
    p_term clamped_i + d_term + :> total_adj
    total_adj servo max-ppb>> neg servo max-ppb>> clamp :> clamped_adj

    servo err >>prev-error drop
    servo t >>initialized? drop

    clamped_adj ;

:: pi-servo-reset ( servo -- )
    servo 0.0 >>integral-accumulator drop
    servo 0.0 >>prev-error drop
    servo f >>initialized? drop ;
