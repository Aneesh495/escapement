! Copyright (C) 2026 Aneesh Krishna.
! Escapement: IEEE 1588-2019 Precision Time Protocol Engine.
! Announce message structure (64+ octets), packing, unpacking, and validation.

USING: accessors arrays byte-arrays kernel locals math sequences
escapement.common.constants escapement.common.endian
escapement.common.types escapement.protocol.header ;
IN: escapement.protocol.messages.announce

TUPLE: ptp-announce
    { header ptp-header }
    { origin-timestamp timestamp }
    { current-utc-offset integer initial: 37 }
    { grandmaster-priority1 integer initial: 128 }
    { grandmaster-clock-quality clock-quality }
    { grandmaster-priority2 integer initial: 128 }
    { grandmaster-identity clock-identity }
    { steps-removed integer initial: 0 }
    { time-source integer initial: 0x20 } ! GNSS default
    { tlvs array initial: { } } ;

:: <ptp-announce> ( domain flags port-id seq-id ts utc-off pri1 qual pri2 gm-id steps src -- ann-msg )
    MSG-ANNOUNCE PTP-ANNOUNCE-BASE-LENGTH domain flags port-id seq-id <ptp-header>
    ts utc-off pri1 qual pri2 gm-id steps src { } ptp-announce boa ;

:: pack-ptp-announce ( ann-msg -- byte-arr )
    PTP-ANNOUNCE-BASE-LENGTH <byte-array> :> buf
    ann-msg header>> pack-ptp-header :> hdr-bytes
    34 [| i | i hdr-bytes nth i buf set-nth ] each-integer
    ann-msg origin-timestamp>> :> ts
    ts seconds>> buf 34 set-be-uint48
    ts nanoseconds>> buf 40 set-be-uint32
    ann-msg current-utc-offset>> buf 44 set-be-uint16
    0 buf 46 set-be-uint8 ! reserved
    ann-msg grandmaster-priority1>> buf 47 set-be-uint8
    ann-msg grandmaster-clock-quality>> :> qual
    qual clock-class>> buf 48 set-be-uint8
    qual clock-accuracy>> buf 49 set-be-uint8
    qual offset-scaled-log-variance>> buf 50 set-be-uint16
    ann-msg grandmaster-priority2>> buf 52 set-be-uint8
    ann-msg grandmaster-identity>> data>> :> gm-bytes
    8 [| i | i gm-bytes nth 53 i + buf set-nth ] each-integer
    ann-msg steps-removed>> buf 61 set-be-uint16
    ann-msg time-source>> buf 63 set-be-uint8
    buf ;

:: unpack-ptp-announce ( buf -- ann-msg )
    buf length 64 < [ "Buffer too short for PTP Announce message" throw ] when
    buf unpack-ptp-header :> hdr
    buf 34 get-be-uint48 :> sec
    buf 40 get-be-uint32 :> nsec
    sec nsec <timestamp> :> ts
    buf 44 get-be-int16 :> utc-off
    buf 47 get-be-uint8 :> pri1
    buf 48 get-be-uint8 :> cclass
    buf 49 get-be-uint8 :> cacc
    buf 50 get-be-uint16 :> cvar
    cclass cacc cvar <clock-quality> :> qual
    buf 52 get-be-uint8 :> pri2
    8 <byte-array> :> gm-buf
    8 [| i | 53 i + buf nth i gm-buf set-nth ] each-integer
    gm-buf <clock-identity> :> gm-id
    buf 61 get-be-uint16 :> steps
    buf 63 get-be-uint8 :> src
    hdr ts utc-off pri1 qual pri2 gm-id steps src { } ptp-announce boa ;
