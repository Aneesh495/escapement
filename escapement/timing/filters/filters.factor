! Copyright (C) 2026 Aneesh Krishna.
! Escapement: IEEE 1588-2019 Precision Time Protocol Engine.
! Statistical filters, Lucky Packet selector, EMA, and Hampel outlier filter.

USING: accessors arrays kernel locals math math.functions
math.order sequences sorting escapement.common.ring-buffer ;
IN: escapement.timing.filters

! Lucky Packet Filter: tracks lowest network propagation delays over a window
TUPLE: lucky-packet-filter
    { window ring-buffer } ;

:: <lucky-packet-filter> ( capacity -- lpf )
    capacity <ring-buffer> lucky-packet-filter boa ;

:: lpf-update ( delay-ns lpf -- min-delay-ns )
    delay-ns lpf window>> ring-push
    lpf window>> ring-min ;

! Exponential Moving Average (EMA) filter
TUPLE: ema-filter
    { alpha float initial: 0.1 }
    { current-value float initial: 0.0 }
    { initialized? boolean initial: f } ;

:: <ema-filter> ( alpha -- ema )
    alpha 0.0 f ema-filter boa ;

:: ema-update ( sample ema -- filtered-val )
    ema initialized?>> [
        ema alpha>> sample *
        1.0 ema alpha>> - ema current-value>> * + :> val
        ema val >>current-value drop
        val
    ] [
        ema sample >>current-value drop
        ema t >>initialized? drop
        sample
    ] if ;

! Hampel Outlier Filter using Median Absolute Deviation (MAD)
TUPLE: hampel-filter
    { window ring-buffer }
    { threshold-multiplier float initial: 3.0 } ;

:: <hampel-filter> ( capacity multiplier -- hf )
    capacity <ring-buffer> multiplier hampel-filter boa ;

:: hampel-update ( sample hf -- filtered-val is-outlier? )
    hf window>> size>> :> size
    size 3 < [
        sample hf window>> ring-push
        sample f
    ] [
        hf window>> ring-median :> med
        hf window>> ring-to-array :> arr
        arr [| x | x med - abs ] map natural-sort :> abs-diffs
        abs-diffs length 2 /i abs-diffs nth :> mad
        1.4826 mad * :> est-stddev
        est-stddev 1e-12 < [ 1e-12 ] [ est-stddev ] if :> s

        sample med - abs s / :> dev-ratio
        dev-ratio hf threshold-multiplier>> > [
            ! Outlier detected: clamp to median
            med t
        ] [
            sample hf window>> ring-push
            sample f
        ] if
    ] if ;
