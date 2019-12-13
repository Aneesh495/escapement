! Copyright (C) 2026 Aneesh Krishna.
! Escapement: IEEE 1588-2019 Precision Time Protocol Engine.
! Inspect subcommand: parses and prints structured breakdown of PTP messages.

USING: accessors byte-arrays combinators formatting io kernel
locals math math.parser sequences strings
escapement.common.constants escapement.common.types
escapement.protocol.header escapement.protocol.messages.announce
escapement.protocol.messages.sync ;
IN: escapement.cli.inspect

:: inspect-ptp-packet ( byte-arr -- )
    "================================================================================" print
    "                         ESCAPEMENT PACKET INSPECTOR                            " print
    "================================================================================" print
    byte-arr length 34 < [
        "Error: Datagram too short for IEEE 1588 header (less than 34 bytes)" print
    ] [
        byte-arr unpack-ptp-header :> hdr
        hdr version>> "PTP Version:         %d\n" printf
        hdr message-type>>
        hdr message-type>> {
            { MSG-SYNC [ "Sync" ] }
            { MSG-DELAY-REQ [ "Delay_Req" ] }
            { MSG-PDELAY-REQ [ "Pdelay_Req" ] }
            { MSG-PDELAY-RESP [ "Pdelay_Resp" ] }
            { MSG-FOLLOW-UP [ "Follow_Up" ] }
            { MSG-DELAY-RESP [ "Delay_Resp" ] }
            { MSG-PDELAY-RESP-FOLLOW-UP [ "Pdelay_Resp_Follow_Up" ] }
            { MSG-ANNOUNCE [ "Announce" ] }
            { MSG-SIGNALING [ "Signaling" ] }
            { MSG-MANAGEMENT [ "Management" ] }
            [ drop "Unknown" ]
        } case
        "Message Type:        0x%X (%s)\n" printf
        hdr message-length>> "Message Length:      %d octets\n" printf
        hdr domain-number>> "Domain Number:       %d\n" printf
        hdr flags>> hdr two-step? [ "yes" ] [ "no" ] if hdr unicast? [ "yes" ] [ "no" ] if
        "Flags:               0x%04X (Two-Step: %s, Unicast: %s)\n" printf
        hdr correction-field>> hdr correction-field>> >float 65536.0 /
        "Correction Field:    %d scaled-ns (%.3f ns)\n" printf
        hdr source-port-id>> port-identity>string
        "Source Port ID:      %s\n" printf
        hdr sequence-id>> "Sequence ID:         %d\n" printf
        hdr log-message-interval>> "Log Message Interval:%d\n" printf
        "================================================================================" print
    ] if ;
