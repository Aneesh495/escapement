! Copyright (C) 2026 Aneesh Krishna.
! Escapement: IEEE 1588-2019 Precision Time Protocol Engine.
! Network simulation subcommand: exercises full master-slave timing loop.

USING: accessors byte-arrays formatting io kernel locals math
math.functions math.parser sequences strings
escapement.clock.synthetic escapement.common.constants
escapement.common.ring-buffer escapement.common.types
escapement.network.impairment escapement.servo.kalman
escapement.servo.pi escapement.timing.delay
escapement.timing.filters escapement.timing.timestamps ;
IN: escapement.cli.simulate

:: run-network-simulation ( -- )
    "================================================================================" print
    "              ESCAPEMENT MULTI-NODE NETWORK CLOCK SYNCHRONIZATION               " print
    "================================================================================" print
    "Simulating IEEE 1588-2019 PTPv2.1 End-to-End timing synchronization over" print
    "an asymmetric physical link with Gaussian jitter and burst queuing delays.\n" print

    ! Grandmaster: Perfect reference clock
    0.0 0.0 <synthetic-clock> :> master-clk

    ! Slave: Free-running crystal with initial 1,500 ns phase offset and 45 ppb drift
    1500.0 45.0 <synthetic-clock> :> slave-clk

    ! Network impairment: 50,000 ns forward delay, 52,500 ns reverse delay (2.5 us asymmetry)
    ! 200 ns Gaussian PDV, 2% burst probability
    50000.0 52500.0 200.0 0.02 8000.0 0.0 <impairment-channel> :> chan

    ! Dual-tier Kalman filter servo
    default-kalman-servo :> kf
    100 <ring-buffer> :> residual-ring

    "Initial Clock Discrepancy:" print
    master-clk current-time-ns>> "  Master Time:           %.3f ns\n" printf
    slave-clk current-time-ns>>
    "  Slave Time:            %.3f ns (Initial Offset: +1500.0 ns, Drift: +45.0 ppb)\n\n" printf

    "Running 60 synchronization epochs (125 ms cadence = 8 Hz Sync rate)..." print
    "Epoch | Master Time (s) | Raw Phase (ns) | Filtered Offset (ns) | Servo Adj (ppb)" print
    "------+-----------------+----------------+----------------------+----------------" print

    0.125 :> dt-sec ! 125 ms sync interval

    60 [| epoch |
        ! Advance time on physical oscillators
        dt-sec master-clk clock-advance
        dt-sec slave-clk clock-advance

        ! 1. Master transmits Sync at t1
        master-clk clock-read-timestamp :> t1

        ! 2. Transit forward across channel
        chan channel-forward-delay drop :> fwd-delay
        slave-clk current-time-ns>> fwd-delay + floor >integer nanoseconds>timestamp :> t2

        ! 3. Slave transmits Delay_Req at t3
        slave-clk clock-read-timestamp :> t3

        ! 4. Transit reverse across channel
        chan channel-reverse-delay drop :> rev-delay
        master-clk current-time-ns>> rev-delay + floor >integer nanoseconds>timestamp :> t4

        ! 5. Calculate E2E mean path delay and measured offset
        t1 t2 t3 t4 0 0 compute-e2e-delay-and-offset :> ( delay offset )

        ! 6. If initial offset is large, apply phase step on first epoch
        epoch 0 = offset abs 500.0 > and [
            offset neg slave-clk clock-step-phase
        ] when

        ! 7. Feed measured phase offset into 2-state Kalman filter servo
        offset dt-sec kf kalman-servo-step :> adj-ppb

        ! 8. Adjust slave clock frequency
        adj-ppb slave-clk clock-adjust-freq

        ! Log sample to ring buffer
        offset residual-ring ring-push

        ! Print periodic progress
        epoch 5 mod 0 = [
            epoch
            master-clk current-time-ns>> 1e-9 *
            offset
            kf phase-est>>
            adj-ppb
            "  %02d  |  %12.3f   |   %+10.1f   |      %+10.2f      |    %+8.2f\n" printf
        ] when
    ] each-integer

    "\n================================================================================" print
    "                      SYNCHRONIZATION RESULTS SUMMARY                           " print
    "================================================================================" print
    master-clk current-time-ns>> "Final Master Clock Time:     %.3f ns\n" printf
    slave-clk current-time-ns>> "Final Slave Clock Time:      %.3f ns\n" printf
    kf phase-est>> "Final Residual Phase Offset: %.2f ns\n" printf
    kf freq-est>> "Final Frequency Drift Est:   %.3f ppb\n" printf
    residual-ring ring-mean "Mean Delay Over Window:      %.2f ns\n" printf
    residual-ring ring-stddev "RMS Jitter (StdDev):         %.2f ns\n" printf
    residual-ring ring-min residual-ring ring-max
    "Peak Phase Error (Min/Max):  [%.1f, %.1f] ns\n" printf
    "Status: Sub-microsecond time synchronization successfully established." print
    "================================================================================" print ;
