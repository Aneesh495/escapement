#!/usr/bin/env python3
"""
Escapement PTP PCAP Generator.
Generates standard libpcap packet capture files containing valid IEEE 1588-2019
datagrams (Sync, Follow_Up, Delay_Req, Delay_Resp, Announce) over UDP/IPv4.
Copyright (C) 2026 Aneesh Krishna. All rights reserved.
"""

import sys
import struct
import time
from escapement_sdk.protocol import (
    PtpHeader,
    PtpSync,
    PtpFollowUp,
    PtpDelayReq,
    PtpDelayResp,
    PtpAnnounce,
    MessageType,
    ClockIdentity,
    PortIdentity,
    ClockQuality,
    Timestamp,
)

# Standard libpcap global header (24 bytes)
# magic_number (0xa1b2c3d4), version_major (2), version_minor (4),
# thiszone (0), sigfigs (0), snaplen (65535), network (1 = Ethernet)
PCAP_GLOBAL_HEADER = struct.pack(">IHHiIII", 0xA1B2C3D4, 2, 4, 0, 0, 65535, 1)


def build_ethernet_ip_udp(payload: bytes, dst_port: int = 319) -> bytes:
    """Encapsulates payload into Ethernet II / IPv4 / UDP frame."""
    # Ethernet Header (14 bytes)
    # Dst MAC: 01-00-5E-00-01-81 (IPv4 multicast for 224.0.1.129)
    # Src MAC: 00-11-22-33-44-55
    # EtherType: 0x0800 (IPv4)
    eth = bytes([0x01, 0x00, 0x5E, 0x00, 0x01, 0x81, 0x00, 0x11, 0x22, 0x33, 0x44, 0x55, 0x08, 0x00])

    # IPv4 Header (20 bytes)
    ip_total_len = 20 + 8 + len(payload)
    ip_header = struct.pack(
        ">BBHHHBBHII",
        0x45, 0x00, ip_total_len, 0x1234, 0x0000, 64, 17, 0x0000,
        0xC0A80101,  # 192.168.1.1
        0xE0000181,  # 224.0.1.129
    )

    # UDP Header (8 bytes)
    udp_len = 8 + len(payload)
    udp_header = struct.pack(">HHHH", 319, dst_port, udp_len, 0x0000)

    return eth + ip_header + udp_header + payload


def write_pcap_packet(f, packet_bytes: bytes, sec: int, usec: int):
    """Writes a single packet record into a pcap file."""
    # pcap packet record header (16 bytes)
    rec_hdr = struct.pack(">IIII", sec, usec, len(packet_bytes), len(packet_bytes))
    f.write(rec_hdr)
    f.write(packet_bytes)


def main():
    out_file = sys.argv[1] if len(sys.argv) > 1 else "ptp_sample.pcap"
    print(f"Generating synthetic IEEE 1588-2019 pcap packet trace to {out_file}...")

    cid_gm = ClockIdentity(bytes([0x00, 0x11, 0x22, 0xFF, 0xFE, 0x33, 0x44, 0x55]))
    cid_slave = ClockIdentity(bytes([0x00, 0xAA, 0xBB, 0xFF, 0xFE, 0xCC, 0xDD, 0xEE]))
    pid_gm = PortIdentity(cid_gm, 1)
    pid_slave = PortIdentity(cid_slave, 1)

    with open(out_file, "wb") as f:
        f.write(PCAP_GLOBAL_HEADER)
        t_base = int(time.time())

        for seq in range(1, 11):
            t_sec = t_base + seq
            t_usec = seq * 125000

            # 1. Announce message
            hdr_ann = PtpHeader(
                message_type=MessageType.ANNOUNCE,
                sequence_id=seq,
                source_port_id=pid_gm,
                flags=0x0000,
            )
            ann = PtpAnnounce(
                header=hdr_ann,
                origin_timestamp=Timestamp(t_sec, 0),
                current_utc_offset=37,
                grandmaster_priority1=128,
                grandmaster_clock_quality=ClockQuality(6, 0x20, 0x1000),
                grandmaster_priority2=128,
                grandmaster_identity=cid_gm,
                steps_removed=0,
                time_source=0x20,
            )
            pkt_ann = build_ethernet_ip_udp(ann.pack(), dst_port=320)
            write_pcap_packet(f, pkt_ann, t_sec, t_usec)

            # 2. Sync message (event, port 319)
            hdr_sync = PtpHeader(
                message_type=MessageType.SYNC,
                sequence_id=seq,
                source_port_id=pid_gm,
                flags=0x0200,  # two-step
            )
            sync = PtpSync(header=hdr_sync, origin_timestamp=Timestamp(t_sec, 1000000))
            pkt_sync = build_ethernet_ip_udp(sync.pack(), dst_port=319)
            write_pcap_packet(f, pkt_sync, t_sec, t_usec + 100)

            # 3. Follow_Up message (general, port 320)
            hdr_fu = PtpHeader(
                message_type=MessageType.FOLLOW_UP,
                sequence_id=seq,
                source_port_id=pid_gm,
                flags=0x0000,
            )
            fu = PtpFollowUp(header=hdr_fu, precise_origin_timestamp=Timestamp(t_sec, 1000000))
            pkt_fu = build_ethernet_ip_udp(fu.pack(), dst_port=320)
            write_pcap_packet(f, pkt_fu, t_sec, t_usec + 200)

            # 4. Delay_Req message from slave (event, port 319)
            hdr_dreq = PtpHeader(
                message_type=MessageType.DELAY_REQ,
                sequence_id=seq,
                source_port_id=pid_slave,
                flags=0x0000,
            )
            dreq = PtpDelayReq(header=hdr_dreq, origin_timestamp=Timestamp(t_sec, 2000000))
            pkt_dreq = build_ethernet_ip_udp(dreq.pack(), dst_port=319)
            write_pcap_packet(f, pkt_dreq, t_sec, t_usec + 1500)

            # 5. Delay_Resp message from master (general, port 320)
            hdr_dresp = PtpHeader(
                message_type=MessageType.DELAY_RESP,
                sequence_id=seq,
                source_port_id=pid_gm,
                flags=0x0000,
            )
            dresp = PtpDelayResp(
                header=hdr_dresp,
                receive_timestamp=Timestamp(t_sec, 2000250),
                requesting_port_id=pid_slave,
            )
            pkt_dresp = build_ethernet_ip_udp(dresp.pack(), dst_port=320)
            write_pcap_packet(f, pkt_dresp, t_sec, t_usec + 1700)

    print(f"Successfully wrote 50 PTP packets (10 epochs) to {out_file}")


if __name__ == "__main__":
    main()
