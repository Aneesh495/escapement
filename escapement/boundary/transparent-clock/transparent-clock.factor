! Copyright (C) 2026 Aneesh Krishna.
! Escapement: IEEE 1588-2019 Precision Time Protocol Engine.
! Transparent Clock (TC) residence time and correctionField accumulation.

USING: accessors kernel locals math
escapement.common.types escapement.protocol.header
escapement.timing.delay escapement.timing.timestamps ;
IN: escapement.boundary.transparent-clock

TUPLE: transparent-clock
    { clock-id clock-identity }
    { is-p2p? boolean initial: f }
    { peer-link-delay-ns float initial: 0.0 } ;

:: <e2e-transparent-clock> ( clock-id -- tc )
    clock-id f 0.0 transparent-clock boa ;

:: <p2p-transparent-clock> ( clock-id peer-delay-ns -- tc )
    clock-id t peer-delay-ns transparent-clock boa ;

! Update message header correctionField with bridge transit residence time
! t_ingress: packet arrival timestamp at ingress port
! t_egress: packet transmission timestamp at egress port
:: tc-update-header-correction ( hdr t-ingress t-egress tc -- )
    t-egress t-ingress timestamp-diff-ns :> residence-ns
    tc is-p2p?>> [ tc peer-link-delay-ns>> + ] when :> total-added-ns

    hdr correction-field>> scaled-ns>ns :> curr-corr-ns
    curr-corr-ns total-added-ns + ns>scaled-ns :> new-corr-scaled

    hdr new-corr-scaled >>correction-field drop ;
