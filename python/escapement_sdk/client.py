"""
Escapement HTTP REST and Prometheus Telemetry Client.
Provides client bindings for Escapement telemetry endpoints.
Copyright (C) 2026 Aneesh Krishna. All rights reserved.
"""

from __future__ import annotations
import json
import urllib.request
import urllib.error
from dataclasses import dataclass
from typing import Dict, List, Optional


@dataclass
class PortStatus:
    port_identity: str
    state: str
    delay_mechanism: int
    log_announce_interval: int
    log_sync_interval: int


@dataclass
class EngineStatus:
    clock_identity: str
    domain_number: int
    priority1: int
    priority2: int
    clock_class: int
    offset_nanoseconds: float
    frequency_drift_ppb: float
    ports: List[PortStatus]


class EscapementClient:
    """Client for querying an Escapement PTP daemon."""

    def __init__(self, host: str = "127.0.0.1", port: int = 8080, timeout: float = 3.0):
        self.host = host
        self.port = port
        self.timeout = timeout
        self.base_url = f"http://{host}:{port}"

    def get_status(self) -> EngineStatus:
        """Fetch structured JSON status from /api/v1/status."""
        url = f"{self.base_url}/api/v1/status"
        req = urllib.request.Request(url, headers={"Accept": "application/json"})
        with urllib.request.urlopen(req, timeout=self.timeout) as resp:
            data = json.loads(resp.read().decode("utf-8"))

        ports = [
            PortStatus(
                port_identity=p.get("portIdentity", ""),
                state=p.get("state", "UNKNOWN"),
                delay_mechanism=p.get("delayMechanism", 1),
                log_announce_interval=p.get("logAnnounceInterval", 1),
                log_sync_interval=p.get("logSyncInterval", 0),
            )
            for p in data.get("ports", [])
        ]

        return EngineStatus(
            clock_identity=data.get("clockIdentity", ""),
            domain_number=data.get("domainNumber", 0),
            priority1=data.get("priority1", 128),
            priority2=data.get("priority2", 128),
            clock_class=data.get("clockClass", 248),
            offset_nanoseconds=data.get("offsetNanoseconds", 0.0),
            frequency_drift_ppb=data.get("frequencyDriftPpb", 0.0),
            ports=ports,
        )

    def get_metrics(self) -> Dict[str, float]:
        """Fetch and parse Prometheus metrics from /metrics."""
        url = f"{self.base_url}/metrics"
        req = urllib.request.Request(url, headers={"Accept": "text/plain"})
        with urllib.request.urlopen(req, timeout=self.timeout) as resp:
            text = resp.read().decode("utf-8")

        metrics: Dict[str, float] = {}
        for line in text.splitlines():
            line = line.strip()
            if not line or line.startswith("#"):
                continue
            parts = line.split()
            if len(parts) >= 2:
                metric_name = parts[0].split("{")[0]
                try:
                    metrics[metric_name] = float(parts[1])
                except ValueError:
                    pass
        return metrics

    def is_healthy(self) -> bool:
        """Perform a quick health check against the status endpoint."""
        try:
            self.get_status()
            return True
        except (urllib.error.URLError, TimeoutError, OSError):
            return False
