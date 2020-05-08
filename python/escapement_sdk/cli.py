"""
Escapement Python Command-Line Interface.
Provides command-line utilities for packet inspection, simulations, and daemon queries.
Copyright (C) 2026 Aneesh Krishna. All rights reserved.
"""

from __future__ import annotations
import sys
import argparse
from .protocol import PtpHeader, PtpSync, PtpAnnounce, MessageType
from .client import EscapementClient
from .simulator import NetworkSimulator


def main():
    parser = argparse.ArgumentParser(
        prog="escapement-cli",
        description="Escapement IEEE 1588-2019 Python Utility CLI",
    )
    subparsers = parser.add_subparsers(dest="subcommand", required=True)

    # Subcommand: inspect
    inspect_parser = subparsers.add_parser("inspect", help="Dissect raw hex PTP packet")
    inspect_parser.add_argument("hex_string", type=str, help="Raw packet hex string")

    # Subcommand: simulate
    sim_parser = subparsers.add_parser("simulate", help="Run network timing simulation")
    sim_parser.add_argument("--epochs", type=int, default=60, help="Number of epochs (default 60)")
    sim_parser.add_argument("--offset", type=float, default=1500.0, help="Initial offset ns (default 1500)")
    sim_parser.add_argument("--drift", type=float, default=45.0, help="Initial drift ppb (default 45)")

    # Subcommand: status
    status_parser = subparsers.add_parser("status", help="Query status from running daemon")
    status_parser.add_argument("--host", type=str, default="127.0.0.1", help="Daemon host")
    status_parser.add_argument("--port", type=int, default=8080, help="Daemon port")

    # Subcommand: metrics
    metrics_parser = subparsers.add_parser("metrics", help="Query Prometheus metrics from daemon")
    metrics_parser.add_argument("--host", type=str, default="127.0.0.1", help="Daemon host")
    metrics_parser.add_argument("--port", type=int, default=8080, help="Daemon port")

    args = parser.parse_args()

    if args.subcommand == "inspect":
        raw = bytes.fromhex(args.hex_string.strip())
        hdr = PtpHeader.unpack(raw)
        print("================================================================================")
        print("                    ESCAPEMENT PYTHON PACKET DISSECTOR                          ")
        print("================================================================================")
        print(f"PTP Version:          {hdr.version}")
        print(f"Message Type:         0x{hdr.message_type:X} ({MessageType(hdr.message_type).name})")
        print(f"Message Length:       {hdr.message_length} octets")
        print(f"Domain Number:        {hdr.domain_number}")
        print(f"Flags:                0x{hdr.flags:04X} (Two-Step: {hdr.two_step}, Unicast: {hdr.unicast})")
        print(f"Correction Field:     {hdr.correction_field} scaled-ns ({hdr.correction_field / 65536.0:.3f} ns)")
        print(f"Source Port Identity: {hdr.source_port_id}")
        print(f"Sequence ID:          {hdr.sequence_id}")
        print("================================================================================")

    elif args.subcommand == "simulate":
        print("Running network timing simulation...")
        sim = NetworkSimulator(initial_offset_ns=args.offset, initial_drift_ppb=args.drift)
        res = sim.run(num_epochs=args.epochs)
        print("================================================================================")
        print("                      SIMULATION RESULTS SUMMARY                                ")
        print("================================================================================")
        print(f"Epochs Run:                  {res.epochs}")
        print(f"Final Residual Phase Offset: {res.final_phase_offset_ns:.2f} ns")
        print(f"Final Frequency Drift Est:   {res.final_freq_drift_ppb:.3f} ppb")
        print(f"Mean Path Delay:             {res.mean_delay_ns:.2f} ns")
        print(f"RMS Jitter (StdDev):         {res.rms_jitter_ns:.2f} ns")
        print(f"Converged:                   {res.converged}")
        print("================================================================================")

    elif args.subcommand == "status":
        client = EscapementClient(host=args.host, port=args.port)
        status = client.get_status()
        print(f"Clock Identity:      {status.clock_identity}")
        print(f"Domain Number:       {status.domain_number}")
        print(f"Clock Class:         {status.clock_class}")
        print(f"Clock Offset:        {status.offset_nanoseconds:.3f} ns")
        print(f"Frequency Drift:     {status.frequency_drift_ppb:.3f} ppb")
        print(f"Active Ports:        {len(status.ports)}")
        for i, p in enumerate(status.ports):
            print(f"  Port {i+1}: {p.port_identity} [{p.state}]")

    elif args.subcommand == "metrics":
        client = EscapementClient(host=args.host, port=args.port)
        metrics = client.get_metrics()
        for k, v in sorted(metrics.items()):
            print(f"{k}: {v}")


if __name__ == "__main__":
    main()
