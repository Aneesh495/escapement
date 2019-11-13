! Copyright (C) 2026 Aneesh Krishna.
! Escapement: IEEE 1588-2019 Precision Time Protocol Engine.
! Standard PTP profile parameter templates (Default, 802.1AS, G.8275.1, Enterprise).

USING: accessors kernel locals math
escapement.common.constants escapement.state.datasets ;
IN: escapement.profiles

TUPLE: ptp-profile
    { profile-name string }
    { domain-number integer }
    { delay-mechanism integer }
    { two-step? boolean }
    { log-announce-interval integer }
    { announce-receipt-timeout integer }
    { log-sync-interval integer }
    { log-min-delay-req-interval integer }
    { default-priority1 integer }
    { default-priority2 integer } ;

: <ptp-profile> ( name dom mech two-step? ann-int ann-to sync-int dreq-int pri1 pri2 -- prof )
    ptp-profile boa ;

! IEEE 1588-2019 Default End-to-End Profile
: profile-ieee1588-default-e2e ( -- prof )
    "IEEE 1588 Default E2E" 0 DELAY-MECH-E2E t 1 3 0 0 128 128 <ptp-profile> ;

! IEEE 1588-2019 Default Peer-to-Peer Profile
: profile-ieee1588-default-p2p ( -- prof )
    "IEEE 1588 Default P2P" 0 DELAY-MECH-P2P t 1 3 0 0 128 128 <ptp-profile> ;

! IEEE 802.1AS (gPTP Automotive / TSN) Profile
: profile-ieee802-1as ( -- prof )
    "IEEE 802.1AS gPTP" 0 DELAY-MECH-P2P t 0 3 -3 0 246 248 <ptp-profile> ;

! ITU-T G.8275.1 (Telecom Phase/Time Profile)
: profile-g8275-1 ( -- prof )
    "ITU-T G.8275.1 Telecom" 24 DELAY-MECH-E2E t -3 3 -4 -4 128 128 <ptp-profile> ;

! Enterprise Profile
: profile-enterprise ( -- prof )
    "Enterprise PTP" 0 DELAY-MECH-E2E t 1 3 0 0 128 128 <ptp-profile> ;

! Apply profile parameters to an engine port and default data set
:: apply-profile-to-engine ( prof dds port-ds -- )
    dds prof domain-number>> >>domain-number drop
    dds prof default-priority1>> >>priority1 drop
    dds prof default-priority2>> >>priority2 drop
    dds prof two-step?>> >>two-step-flag drop

    port-ds prof delay-mechanism>> >>delay-mechanism drop
    port-ds prof log-announce-interval>> >>log-announce-interval drop
    port-ds prof announce-receipt-timeout>> >>announce-receipt-timeout drop
    port-ds prof log-sync-interval>> >>log-sync-interval drop
    port-ds prof log-min-delay-req-interval>> >>log-min-delay-req-interval drop ;
