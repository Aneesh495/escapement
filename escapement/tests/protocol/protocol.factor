! Copyright (C) 2026 Aneesh Krishna.
! Escapement: IEEE 1588-2019 Precision Time Protocol Engine.
! Unit tests for IEEE 1588 message codecs and TLV encoders.

USING: accessors arrays byte-arrays io kernel locals math
sequences escapement.common.constants escapement.common.types
escapement.protocol.header
escapement.protocol.messages.announce
escapement.protocol.messages.delay-req
escapement.protocol.messages.delay-resp
escapement.protocol.messages.follow-up
escapement.protocol.messages.pdelay-follow-up
escapement.protocol.messages.pdelay-req
escapement.protocol.messages.pdelay-resp
escapement.protocol.messages.signaling
escapement.protocol.messages.sync escapement.protocol.tlv ;
IN: escapement.tests.protocol

:: run-protocol-tests ( -- )
    "--- Running Protocol & Codec Unit Tests ---" print

    ! 1. Header pack and unpack
    { 0xAA 0xBB 0xCC 0xDD 0xEE 0xFF 0x00 0x11 } >byte-array <clock-identity> :> cid
    cid 1 <port-identity> :> pid
    0 44 0 0 pid 100 <ptp-header> :> hdr
    hdr pack-ptp-header unpack-ptp-header :> hdr2
    hdr2 message-type>> 0 =
    hdr2 sequence-id>> 100 = and
    hdr2 source-port-id>> port-identity>string pid port-identity>string = and
    [ "pass: header roundtrip" print ] [ "fail: header roundtrip" throw ] if

    ! 2. Sync message
    1234 5678 <timestamp> :> ts
    0 0 pid 101 ts <ptp-sync> pack-ptp-sync unpack-ptp-sync :> sync2
    sync2 origin-timestamp>> seconds>> 1234 =
    sync2 origin-timestamp>> nanoseconds>> 5678 = and
    [ "pass: sync roundtrip" print ] [ "fail: sync roundtrip" throw ] if

    ! 3. Follow_Up message
    0 0 pid 102 ts <ptp-follow-up> pack-ptp-follow-up unpack-ptp-follow-up :> fup2
    fup2 precise-origin-timestamp>> seconds>> 1234 =
    [ "pass: follow-up roundtrip" print ] [ "fail: follow-up roundtrip" throw ] if

    ! 4. Delay_Req and Delay_Resp
    0 0 pid 103 ts <ptp-delay-req> pack-ptp-delay-req unpack-ptp-delay-req :> dreq2
    dreq2 origin-timestamp>> nanoseconds>> 5678 =
    [ "pass: delay-req roundtrip" print ] [ "fail: delay-req roundtrip" throw ] if

    0 0 pid 104 ts pid <ptp-delay-resp> pack-ptp-delay-resp unpack-ptp-delay-resp :> dresp2
    dresp2 receive-timestamp>> seconds>> 1234 =
    dresp2 requesting-port-id>> port-identity>string pid port-identity>string = and
    [ "pass: delay-resp roundtrip" print ] [ "fail: delay-resp roundtrip" throw ] if

    ! 5. Announce message
    248 0x21 0xFFFF <clock-quality> :> cq
    0 0 pid 105 ts 37 128 cq 128 cid 0 0x20 <ptp-announce> pack-ptp-announce unpack-ptp-announce :> ann2
    ann2 current-utc-offset>> 37 =
    ann2 grandmaster-priority1>> 128 = and
    ann2 grandmaster-clock-quality>> clock-class>> 248 = and
    [ "pass: announce roundtrip" print ] [ "fail: announce roundtrip" throw ] if

    ! 6. PathTrace TLV
    cid 1array <path-trace-tlv> pack-ptp-tlv 0 unpack-ptp-tlv drop unpack-path-trace-tlv :> cids
    cids length 1 =
    cids first clock-identity>string cid clock-identity>string = and
    [ "pass: path-trace tlv roundtrip" print ] [ "fail: path-trace tlv" throw ] if

    "All Protocol & Codec unit tests passed successfully." print ;
