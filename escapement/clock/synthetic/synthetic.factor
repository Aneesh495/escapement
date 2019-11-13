! Copyright (C) 2026 Aneesh Krishna.
! Escapement: IEEE 1588-2019 Precision Time Protocol Engine.
! High-fidelity synthetic hardware clock oscillator simulation.

USING: accessors kernel locals math math.functions math.order
escapement.common.types escapement.timing.timestamps ;
IN: escapement.clock.synthetic

TUPLE: synthetic-clock
    { current-time-ns float initial: 0.0 }
    { freq-offset-ppb float initial: 0.0 }
    { servo-adj-ppb float initial: 0.0 }
    { aging-rate-ppb-per-sec float initial: 0.0001 }
    { temp-wander-ppb float initial: 0.0 }
    { phase-noise-std-ns float initial: 0.5 } ;

:: <synthetic-clock> ( init-time-ns init-freq-ppb -- clk )
    init-time-ns init-freq-ppb 0.0 0.0001 0.0 0.5 synthetic-clock boa ;

:: default-synthetic-clock ( -- clk )
    0.0 25.0 <synthetic-clock> ; ! 25 ppb initial oscillator offset

! Read current clock time as timestamp
:: clock-read-timestamp ( clk -- ts )
    clk current-time-ns>> floor >integer nanoseconds>timestamp ;

! Adjust clock frequency via servo control (in ppb)
:: clock-adjust-freq ( adj-ppb clk -- )
    clk adj-ppb >>servo-adj-ppb drop ;

! Step clock phase discretely (in nanoseconds)
:: clock-step-phase ( step-ns clk -- )
    clk current-time-ns>> step-ns + :> new-t
    clk new-t >>current-time-ns drop ;

! Advance physical elapsed time by dt-sec, updating accumulated drift
:: clock-advance ( dt-sec clk -- )
    dt-sec 0.0 <= [ ] [
        clk freq-offset-ppb>>
        clk servo-adj-ppb>> -
        clk temp-wander-ppb>> + :> effective-ppb

        ! Drift in nanoseconds over dt-sec
        dt-sec 1e9 * :> ideal-elapsed-ns
        ideal-elapsed-ns 1.0 effective-ppb 1e-9 * + * :> actual-elapsed-ns

        clk current-time-ns>> actual-elapsed-ns + :> new-t
        clk new-t >>current-time-ns drop

        ! Accumulate slight crystal aging
        clk freq-offset-ppb>> clk aging-rate-ppb-per-sec>> dt-sec * + :> new-aging
        clk new-aging >>freq-offset-ppb drop
    ] if ;
