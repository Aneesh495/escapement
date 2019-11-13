! Copyright (C) 2026 Aneesh Krishna.
! Escapement: IEEE 1588-2019 Precision Time Protocol Engine.
! JSON serialization primitives for PTP telemetry and REST APIs.

USING: accessors arrays assocs byte-arrays formatting kernel
locals math math.parser sequences strings
escapement.common.types escapement.state.datasets
escapement.state.engine-state escapement.state.port-state
escapement.stability.allan escapement.stability.mtie ;
IN: escapement.telemetry.json

! Convert basic types to JSON fragments
: json-number ( n -- str )
    number>string ;

: json-string ( str -- json-str )
    "\"" swap "\"" surround ;

: json-boolean ( ? -- str )
    [ "true" ] [ "false" ] if ;

! Serialize engine status and port datasets into JSON
:: engine-state>json ( st -- json-str )
    st default-ds>> :> dds
    st current-ds>> :> cds
    st parent-ds>> :> pds

    dds clock-id>> clock-identity>string :> cid-str
    dds domain-number>> :> dom
    dds priority1>> :> p1
    dds priority2>> :> p2
    dds quality>> clock-class>> :> cclass
    st clock-offset-ns>> :> offset-ns
    st frequency-drift-ppb>> :> drift-ppb

    st ports>> [| port |
        port port-id>> port-identity>string :> pid-str
        port port-state>> port-state>string :> ps-str
        port delay-mechanism>> :> dm
        port log-announce-interval>> :> lai
        port log-sync-interval>> :> lsi
        "{\"portIdentity\":\"%s\",\"state\":\"%s\",\"delayMechanism\":%d,\"logAnnounceInterval\":%d,\"logSyncInterval\":%d}"
        { pid-str ps-str dm lai lsi } sprintf
    ] map "," join :> ports-json

    "{\"clockIdentity\":\"%s\",\"domainNumber\":%d,\"priority1\":%d,\"priority2\":%d,\"clockClass\":%d,\"offsetNanoseconds\":%.3f,\"frequencyDriftPpb\":%.3f,\"ports\":[%s]}"
    { cid-str dom p1 p2 cclass offset-ns drift-ppb ports-json } sprintf ;

! Serialize array of allan-point into JSON
:: allan-points>json ( pts -- json-str )
    pts [| pt |
        "{\"tau\":%.4f,\"adev\":%.6e,\"mdev\":%.6e,\"tdev\":%.6e}"
        { pt tau>> pt adev>> pt mdev>> pt tdev>> } sprintf
    ] map "," join :> items
    "[" items "]" surround ;

! Serialize array of mtie-point into JSON
:: mtie-points>json ( pts -- json-str )
    pts [| pt |
        pt pass?>> json-boolean :> p-str
        "{\"tau\":%.4f,\"mtieNs\":%.3f,\"limitNs\":%.3f,\"pass\":%s}"
        { pt tau>> pt mtie>> pt prc-mask-limit>> p-str } sprintf
    ] map "," join :> items
    "[" items "]" surround ;

! Prometheus format metrics exporter
:: engine-state>prometheus ( st -- prom-text )
    st default-ds>> clock-id>> clock-identity>string :> cid
    st clock-offset-ns>> :> offset
    st frequency-drift-ppb>> :> drift
    st ports>> first port-state>> :> ps

    "# HELP ptp_offset_nanoseconds Current master clock offset in nanoseconds\n"
    "# TYPE ptp_offset_nanoseconds gauge\n"
    "ptp_offset_nanoseconds{clock_id=\"%s\"} %.3f\n"
    "# HELP ptp_frequency_adjustment_ppb Current servo frequency adjustment in parts-per-billion\n"
    "# TYPE ptp_frequency_adjustment_ppb gauge\n"
    "ptp_frequency_adjustment_ppb{clock_id=\"%s\"} %.3f\n"
    "# HELP ptp_port_state IEEE 1588 port state enum\n"
    "# TYPE ptp_port_state gauge\n"
    "ptp_port_state{clock_id=\"%s\",port=\"1\"} %d\n"
    { cid offset cid drift cid ps } sprintf ;
