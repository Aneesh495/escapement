"""
Escapement Python SDK: Client, Protocol Dissector, and Verification Harness.
Copyright (C) 2026 Aneesh Krishna. All rights reserved.
"""

from .protocol import (
    PtpHeader,
    PtpSync,
    PtpFollowUp,
    PtpDelayReq,
    PtpDelayResp,
    PtpPdelayReq,
    PtpPdelayResp,
    PtpPdelayRespFollowUp,
    PtpAnnounce,
    PathTraceTlv,
    MessageType,
    ClockQuality,
    Timestamp,
    PortIdentity,
    ClockIdentity,
)
from .client import EscapementClient, EngineStatus, PortStatus
from .simulator import NetworkSimulator, SimulationResult
from .conformance import BmcaValidator, MtieValidator

__version__ = "1.0.0"
__all__ = [
    "PtpHeader",
    "PtpSync",
    "PtpFollowUp",
    "PtpDelayReq",
    "PtpDelayResp",
    "PtpPdelayReq",
    "PtpPdelayResp",
    "PtpPdelayRespFollowUp",
    "PtpAnnounce",
    "PathTraceTlv",
    "MessageType",
    "ClockQuality",
    "Timestamp",
    "PortIdentity",
    "ClockIdentity",
    "EscapementClient",
    "EngineStatus",
    "PortStatus",
    "NetworkSimulator",
    "SimulationResult",
    "BmcaValidator",
    "MtieValidator",
]
