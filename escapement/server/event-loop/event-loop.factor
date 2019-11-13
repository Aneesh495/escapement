! Copyright (C) 2026 Aneesh Krishna.
! Escapement: IEEE 1588-2019 Precision Time Protocol Engine.
! Asynchronous event loop, UDP datagram socket dispatcher, and message routing.

USING: accessors byte-arrays combinators formatting io
io.encodings.binary io.sockets kernel locals math math.parser
sequences strings threads
escapement.bmca.dataset-comparison escapement.bmca.priority-vector
escapement.bmca.state-decision escapement.clock.synthetic
escapement.common.constants escapement.common.types
escapement.protocol.header escapement.protocol.messages.announce
escapement.protocol.messages.delay-req
escapement.protocol.messages.delay-resp
escapement.protocol.messages.follow-up
escapement.protocol.messages.sync escapement.servo.kalman
escapement.servo.pi escapement.simd
escapement.state.engine-state escapement.state.port-state
escapement.timing.delay escapement.timing.timestamps ;
IN: escapement.server.event-loop

TUPLE: ptp-daemon
    { engine engine-state }
    { clock synthetic-clock }
    { pi-servo pi-servo }
    { kalman-servo kalman-servo }
    { running? boolean initial: f }
    { sync-sequence integer initial: 0 }
    { announce-sequence integer initial: 0 } ;

:: <ptp-daemon> ( engine clock -- daemon )
    engine clock default-pi-servo default-kalman-servo f 0 0 ptp-daemon boa ;

! Dispatch inbound PTP datagram buffer to appropriate message parser and state handler
:: dispatch-inbound-packet ( buf daemon -- )
    buf fast-validate-header [
        buf unpack-ptp-header :> hdr
        hdr message-type>> {
            ! 1. Announce Message
            { MSG-ANNOUNCE [
                buf unpack-ptp-announce :> ann
                ann grandmaster-priority1>>
                ann grandmaster-clock-quality>> clock-class>>
                ann grandmaster-clock-quality>> clock-accuracy>>
                ann grandmaster-clock-quality>> offset-scaled-log-variance>>
                ann grandmaster-priority2>>
                ann grandmaster-identity>>
                ann steps-removed>>
                ann header>> source-port-id>>
                1 ! Port 1
                <priority-vector> :> pv
                daemon engine>> 0 pv handle-foreign-announce
            ] }

            ! 2. Sync Message
            { MSG-SYNC [
                buf unpack-ptp-sync :> sync-msg
                daemon clock>> clock-read-timestamp :> t2
                ! In two-step mode, wait for Follow_Up to get precise t1
            ] }

            ! 3. Follow_Up Message
            { MSG-FOLLOW-UP [
                buf unpack-ptp-follow-up :> fup
                ! Extract t1 precise origin timestamp
            ] }

            ! 4. Delay_Resp Message
            { MSG-DELAY-RESP [
                buf unpack-ptp-delay-resp :> dresp
                ! t4 receive timestamp on master
            ] }

            [ drop ]
        } case
    ] when ;
