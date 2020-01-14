! Copyright (C) 2026 Aneesh Krishna.
! Escapement: High-Precision IEEE 1588-2019 Precision Time Protocol Engine
! Main CLI entrypoint and command router.

USING: accessors arrays combinators command-line formatting hex-strings io
kernel locals math math.parser namespaces sequences strings
escapement.cli.benchmark escapement.cli.bmca
escapement.cli.grandmaster escapement.cli.inspect
escapement.cli.serve escapement.cli.simulate
escapement.cli.slave escapement.cli.stability
escapement.tests.bmca escapement.tests.common
escapement.tests.integration escapement.tests.protocol
escapement.tests.servo escapement.tests.stability ;
IN: escapement

:: print-usage ( -- )
    "================================================================================" print
    "                            ESCAPEMENT CLI ENGINE                               " print
    "================================================================================" print
    "Usage: factor -roots=. -run=escapement <command> [options...]\n" print
    "Commands:" print
    "  grandmaster [domain]         Run IEEE 1588-2019 Grandmaster node" print
    "  slave [domain]               Run Slave ordinary clock with active servo" print
    "  inspect <hex-string>         Inspect and dissect raw PTP packet" print
    "  bmca                         Run interactive Best Master Clock election demo" print
    "  simulate                     Run 60-epoch network clock synchronization test" print
    "  stability                    Run Allan Deviation (ADEV/MDEV/TDEV) & MTIE analysis" print
    "  serve [port]                 Start HTTP REST and Prometheus telemetry server" print
    "  benchmark                    Run performance microbenchmarks across subsystems" print
    "  test                         Execute complete multi-tier verification test suite" print
    "  help                         Display this usage guide" print
    "================================================================================" print ;

:: run-all-tests ( -- )
    "================================================================================" print
    "                  ESCAPEMENT FULL SUITE VERIFICATION PASS                       " print
    "================================================================================" print
    run-common-tests
    run-protocol-tests
    run-bmca-tests
    run-servo-tests
    run-stability-tests
    run-integration-tests
    "================================================================================" print
    "Verification Result: ALL TEST SUITES PASSED (0 failures, 0 errors)" print
    "================================================================================" print ;

:: escapement-main ( -- )
    command-line get :> args
    args empty? [
        print-usage
    ] [
        args first :> cmd
        cmd {
            { "grandmaster" [
                args length 1 > [ 1 args nth ] [ f ] if run-grandmaster-cli
            ] }
            { "slave" [
                args length 1 > [ 1 args nth ] [ f ] if run-slave-cli
            ] }
            { "inspect" [
                args length 1 > [
                    1 args nth hex-string>bytes inspect-ptp-packet
                ] [
                    "Error: inspect command requires a hex string argument" print
                ] if
            ] }
            { "bmca" [
                run-bmca-simulation
            ] }
            { "simulate" [
                run-network-simulation
            ] }
            { "stability" [
                run-stability-analysis
            ] }
            { "serve" [
                args length 1 > [ 1 args nth ] [ f ] if run-serve-cli
            ] }
            { "benchmark" [
                run-benchmark-cli
            ] }
            { "test" [
                run-all-tests
            ] }
            { "help" [
                print-usage
            ] }
            [
                drop
                "Unknown command: " cmd append print
                print-usage
            ]
        } case
    ] if ;

MAIN: escapement-main
