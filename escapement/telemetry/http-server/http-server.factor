! Copyright (C) 2026 Aneesh Krishna.
! Escapement: IEEE 1588-2019 Precision Time Protocol Engine.
! Lightweight asynchronous HTTP/1.1 REST and Prometheus telemetry server.

USING: accessors byte-arrays combinators formatting io
io.encodings.binary io.encodings.utf8 io.servers io.sockets
kernel locals math math.parser sequences splitting strings
threads escapement.state.engine-state
escapement.telemetry.json ;
IN: escapement.telemetry.http-server

TUPLE: telemetry-server
    { engine engine-state }
    { port integer initial: 8080 } ;

:: <telemetry-server> ( engine port -- srv )
    engine port telemetry-server boa ;

:: handle-http-request ( engine -- )
    readln :> request-line
    request-line [
        ! Read remaining request headers until empty line
        [ readln dup [ empty? not ] when ] [ drop ] while

        request-line " " split :> parts
        parts length 2 >= [
            1 parts nth :> path
            path {
                { "/api/v1/status" [
                    engine engine-state>json :> body
                    body length body
                    "HTTP/1.1 200 OK\r\nContent-Type: application/json\r\nAccess-Control-Allow-Origin: *\r\nContent-Length: %d\r\n\r\n%s"
                    sprintf write
                ] }
                { "/metrics" [
                    engine engine-state>prometheus :> body
                    body length body
                    "HTTP/1.1 200 OK\r\nContent-Type: text/plain; version=0.0.4\r\nAccess-Control-Allow-Origin: *\r\nContent-Length: %d\r\n\r\n%s"
                    sprintf write
                ] }
                [
                    drop
                    "{\"error\":\"Endpoint not found\",\"service\":\"escapement\"}" :> body
                    body length body
                    "HTTP/1.1 404 Not Found\r\nContent-Type: application/json\r\nContent-Length: %d\r\n\r\n%s"
                    sprintf write
                ]
            } case
        ] [
            "HTTP/1.1 400 Bad Request\r\nContent-Length: 0\r\n\r\n" write
        ] if
        flush
    ] when ;

:: start-telemetry-server ( srv -- )
    srv port>> f <inet4> :> addr
    srv engine>> :> eng
    "Starting Escapement Telemetry HTTP server on port %d...\n" srv port>> printf
    addr binary <threaded-server>
        "escapement-telemetry-server" >>name
        [ eng handle-http-request ] >>handler
    start-server drop ;
