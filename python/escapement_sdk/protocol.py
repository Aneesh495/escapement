"""
Escapement IEEE 1588-2019 Binary Protocol Codecs and Dissectors.
Implements Clause 13 common header, event/general message formats, and TLV chaining.
Copyright (C) 2026 Aneesh Krishna. All rights reserved.
"""

from __future__ import annotations
import enum
import struct
from dataclasses import dataclass, field
from typing import List, Tuple, Optional


class MessageType(enum.IntEnum):
    SYNC = 0x0
    DELAY_REQ = 0x1
    PDELAY_REQ = 0x2
    PDELAY_RESP = 0x3
    FOLLOW_UP = 0x8
    DELAY_RESP = 0x9
    PDELAY_RESP_FOLLOW_UP = 0xA
    ANNOUNCE = 0xB
    SIGNALING = 0xC
    MANAGEMENT = 0xD


class ClockClass(enum.IntEnum):
    PRIMARY_REF = 6
    PRC_HOLDOVER = 7
    SYNC_DEFAULT = 248
    SLAVE_ONLY = 255


@dataclass(frozen=True)
class ClockIdentity:
    data: bytes  # 8 octets (EUI-64)

    def __post_init__(self):
        if len(self.data) != 8:
            raise ValueError(f"ClockIdentity must be exactly 8 octets, got {len(self.data)}")

    @classmethod
    def from_string(cls, s: str) -> ClockIdentity:
        cleaned = s.replace(":", "").replace("-", "")
        if len(cleaned) != 16:
            raise ValueError(f"Invalid clock identity string: {s}")
        return cls(bytes.fromhex(cleaned))

    def __str__(self) -> str:
        return ":".join(f"{b:02X}" for b in self.data)


@dataclass(frozen=True)
class PortIdentity:
    clock_id: ClockIdentity
    port_number: int  # uint16

    def __str__(self) -> str:
        return f"{self.clock_id}/{self.port_number}"


@dataclass(frozen=True)
class ClockQuality:
    clock_class: int
    clock_accuracy: int
    offset_scaled_log_variance: int


@dataclass(frozen=True)
class Timestamp:
    seconds: int       # uint48 (0 to 2^48 - 1)
    nanoseconds: int   # uint32 (0 to 999,999,999)

    @classmethod
    def from_float(cls, t_sec: float) -> Timestamp:
        sec = int(t_sec)
        nsec = int((t_sec - sec) * 1e9)
        return cls(sec, nsec)

    def to_float(self) -> float:
        return float(self.seconds) + float(self.nanoseconds) * 1e-9

    def to_nanoseconds(self) -> int:
        return self.seconds * 1_000_000_000 + self.nanoseconds

    def __str__(self) -> str:
        return f"{self.seconds}.{self.nanoseconds:09d}"


@dataclass
class PtpHeader:
    """IEEE 1588-2019 Clause 13.3 Common PTP message header (34 octets)."""
    major_sdo_id: int = 0
    message_type: int = MessageType.SYNC
    version: int = 2
    message_length: int = 34
    domain_number: int = 0
    minor_sdo_id: int = 0
    flags: int = 0
    correction_field: int = 0  # int64 scaled-nanoseconds (sub-ns * 65536)
    message_type_specific: int = 0  # uint32
    source_port_id: PortIdentity = field(
        default_factory=lambda: PortIdentity(ClockIdentity(b"\x00" * 8), 1)
    )
    sequence_id: int = 0
    control_field: int = 0
    log_message_interval: int = 0

    HEADER_LENGTH: int = 34

    @property
    def two_step(self) -> bool:
        return bool(self.flags & 0x0200)

    @property
    def unicast(self) -> bool:
        return bool(self.flags & 0x0400)

    def pack(self) -> bytes:
        first_byte = ((self.major_sdo_id & 0x0F) << 4) | (self.message_type & 0x0F)
        second_byte = ((self.minor_sdo_id & 0x0F) << 4) | (self.version & 0x0F)

        # 34 octets:
        # byte 0: major_sdo (4) | msg_type (4)
        # byte 1: minor_sdo (4) | version (4)
        # bytes 2..3: messageLength (uint16)
        # byte 4: domainNumber (uint8)
        # byte 5: minorVersionPTP / reserved (uint8)
        # bytes 6..7: flagField (uint16)
        # bytes 8..15: correctionField (int64)
        # bytes 16..19: messageTypeSpecific (uint32)
        # bytes 20..27: sourcePortIdentity.clockIdentity (8 octets)
        # bytes 28..29: sourcePortIdentity.portNumber (uint16)
        # bytes 30..31: sequenceId (uint16)
        # byte 32: controlField (uint8)
        # byte 33: logMessageInterval (int8)
        buf = bytearray(self.HEADER_LENGTH)
        buf[0] = first_byte
        buf[1] = second_byte
        struct.pack_into(">H", buf, 2, self.message_length)
        buf[4] = self.domain_number & 0xFF
        buf[5] = 0
        struct.pack_into(">H", buf, 6, self.flags)
        struct.pack_into(">q", buf, 8, self.correction_field)
        struct.pack_into(">I", buf, 16, self.message_type_specific)
        buf[20:28] = self.source_port_id.clock_id.data
        struct.pack_into(">H", buf, 28, self.source_port_id.port_number)
        struct.pack_into(">H", buf, 30, self.sequence_id)
        buf[32] = self.control_field & 0xFF
        struct.pack_into(">b", buf, 33, self.log_message_interval)
        return bytes(buf)

    @classmethod
    def unpack(cls, data: bytes) -> PtpHeader:
        if len(data) < cls.HEADER_LENGTH:
            raise ValueError(f"Packet too short for PTP header: {len(data)} < 34")

        first_byte = data[0]
        second_byte = data[1]
        major_sdo = (first_byte >> 4) & 0x0F
        msg_type = first_byte & 0x0F
        minor_sdo = (second_byte >> 4) & 0x0F
        version = second_byte & 0x0F

        msg_len = struct.unpack_from(">H", data, 2)[0]
        domain = data[4]
        flags = struct.unpack_from(">H", data, 6)[0]
        corr = struct.unpack_from(">q", data, 8)[0]
        spec = struct.unpack_from(">I", data, 16)[0]
        cid = ClockIdentity(bytes(data[20:28]))
        port_num = struct.unpack_from(">H", data, 28)[0]
        seq_id = struct.unpack_from(">H", data, 30)[0]
        ctrl = data[32]
        log_interval = struct.unpack_from(">b", data, 33)[0]

        return cls(
            major_sdo_id=major_sdo,
            message_type=msg_type,
            version=version,
            message_length=msg_len,
            domain_number=domain,
            minor_sdo_id=minor_sdo,
            flags=flags,
            correction_field=corr,
            message_type_specific=spec,
            source_port_id=PortIdentity(cid, port_num),
            sequence_id=seq_id,
            control_field=ctrl,
            log_message_interval=log_interval,
        )


def _pack_uint48(val: int) -> bytes:
    high = (val >> 32) & 0xFFFF
    low = val & 0xFFFFFFFF
    return struct.pack(">HI", high, low)


def _unpack_uint48(buf: bytes, offset: int = 0) -> int:
    high, low = struct.unpack_from(">HI", buf, offset)
    return (high << 32) | low


@dataclass
class PtpSync:
    header: PtpHeader
    origin_timestamp: Timestamp

    LENGTH: int = 44

    def pack(self) -> bytes:
        self.header.message_type = MessageType.SYNC
        self.header.message_length = self.LENGTH
        hdr_bytes = self.header.pack()
        ts_bytes = _pack_uint48(self.origin_timestamp.seconds) + struct.pack(
            ">I", self.origin_timestamp.nanoseconds
        )
        return hdr_bytes + ts_bytes

    @classmethod
    def unpack(cls, data: bytes) -> PtpSync:
        if len(data) < cls.LENGTH:
            raise ValueError(f"Packet too short for PTP Sync: {len(data)} < 44")
        hdr = PtpHeader.unpack(data[:34])
        sec = _unpack_uint48(data, 34)
        nsec = struct.unpack_from(">I", data, 40)[0]
        return cls(hdr, Timestamp(sec, nsec))


@dataclass
class PtpFollowUp:
    header: PtpHeader
    precise_origin_timestamp: Timestamp

    LENGTH: int = 44

    def pack(self) -> bytes:
        self.header.message_type = MessageType.FOLLOW_UP
        self.header.message_length = self.LENGTH
        hdr_bytes = self.header.pack()
        ts_bytes = _pack_uint48(self.precise_origin_timestamp.seconds) + struct.pack(
            ">I", self.precise_origin_timestamp.nanoseconds
        )
        return hdr_bytes + ts_bytes

    @classmethod
    def unpack(cls, data: bytes) -> PtpFollowUp:
        if len(data) < cls.LENGTH:
            raise ValueError(f"Packet too short for PTP Follow_Up: {len(data)} < 44")
        hdr = PtpHeader.unpack(data[:34])
        sec = _unpack_uint48(data, 34)
        nsec = struct.unpack_from(">I", data, 40)[0]
        return cls(hdr, Timestamp(sec, nsec))


@dataclass
class PtpDelayReq:
    header: PtpHeader
    origin_timestamp: Timestamp

    LENGTH: int = 44

    def pack(self) -> bytes:
        self.header.message_type = MessageType.DELAY_REQ
        self.header.message_length = self.LENGTH
        hdr_bytes = self.header.pack()
        ts_bytes = _pack_uint48(self.origin_timestamp.seconds) + struct.pack(
            ">I", self.origin_timestamp.nanoseconds
        )
        return hdr_bytes + ts_bytes

    @classmethod
    def unpack(cls, data: bytes) -> PtpDelayReq:
        if len(data) < cls.LENGTH:
            raise ValueError(f"Packet too short for PTP Delay_Req: {len(data)} < 44")
        hdr = PtpHeader.unpack(data[:34])
        sec = _unpack_uint48(data, 34)
        nsec = struct.unpack_from(">I", data, 40)[0]
        return cls(hdr, Timestamp(sec, nsec))


@dataclass
class PtpDelayResp:
    header: PtpHeader
    receive_timestamp: Timestamp
    requesting_port_id: PortIdentity

    LENGTH: int = 54

    def pack(self) -> bytes:
        self.header.message_type = MessageType.DELAY_RESP
        self.header.message_length = self.LENGTH
        hdr_bytes = self.header.pack()
        ts_bytes = _pack_uint48(self.receive_timestamp.seconds) + struct.pack(
            ">I", self.receive_timestamp.nanoseconds
        )
        port_bytes = self.requesting_port_id.clock_id.data + struct.pack(
            ">H", self.requesting_port_id.port_number
        )
        return hdr_bytes + ts_bytes + port_bytes

    @classmethod
    def unpack(cls, data: bytes) -> PtpDelayResp:
        if len(data) < cls.LENGTH:
            raise ValueError(f"Packet too short for PTP Delay_Resp: {len(data)} < 54")
        hdr = PtpHeader.unpack(data[:34])
        sec = _unpack_uint48(data, 34)
        nsec = struct.unpack_from(">I", data, 40)[0]
        cid = ClockIdentity(bytes(data[44:52]))
        port_num = struct.unpack_from(">H", data, 52)[0]
        return cls(hdr, Timestamp(sec, nsec), PortIdentity(cid, port_num))


@dataclass
class PtpPdelayReq:
    header: PtpHeader
    origin_timestamp: Timestamp

    LENGTH: int = 54

    def pack(self) -> bytes:
        self.header.message_type = MessageType.PDELAY_REQ
        self.header.message_length = self.LENGTH
        hdr_bytes = self.header.pack()
        ts_bytes = _pack_uint48(self.origin_timestamp.seconds) + struct.pack(
            ">I", self.origin_timestamp.nanoseconds
        )
        reserved = b"\x00" * 10
        return hdr_bytes + ts_bytes + reserved

    @classmethod
    def unpack(cls, data: bytes) -> PtpPdelayReq:
        if len(data) < cls.LENGTH:
            raise ValueError(f"Packet too short for PTP Pdelay_Req: {len(data)} < 54")
        hdr = PtpHeader.unpack(data[:34])
        sec = _unpack_uint48(data, 34)
        nsec = struct.unpack_from(">I", data, 40)[0]
        return cls(hdr, Timestamp(sec, nsec))


@dataclass
class PtpPdelayResp:
    header: PtpHeader
    request_receipt_timestamp: Timestamp
    requesting_port_id: PortIdentity

    LENGTH: int = 54

    def pack(self) -> bytes:
        self.header.message_type = MessageType.PDELAY_RESP
        self.header.message_length = self.LENGTH
        hdr_bytes = self.header.pack()
        ts_bytes = _pack_uint48(self.request_receipt_timestamp.seconds) + struct.pack(
            ">I", self.request_receipt_timestamp.nanoseconds
        )
        port_bytes = self.requesting_port_id.clock_id.data + struct.pack(
            ">H", self.requesting_port_id.port_number
        )
        return hdr_bytes + ts_bytes + port_bytes

    @classmethod
    def unpack(cls, data: bytes) -> PtpPdelayResp:
        if len(data) < cls.LENGTH:
            raise ValueError(f"Packet too short for PTP Pdelay_Resp: {len(data)} < 54")
        hdr = PtpHeader.unpack(data[:34])
        sec = _unpack_uint48(data, 34)
        nsec = struct.unpack_from(">I", data, 40)[0]
        cid = ClockIdentity(bytes(data[44:52]))
        port_num = struct.unpack_from(">H", data, 52)[0]
        return cls(hdr, Timestamp(sec, nsec), PortIdentity(cid, port_num))


@dataclass
class PtpPdelayRespFollowUp:
    header: PtpHeader
    response_origin_timestamp: Timestamp
    requesting_port_id: PortIdentity

    LENGTH: int = 54

    def pack(self) -> bytes:
        self.header.message_type = MessageType.PDELAY_RESP_FOLLOW_UP
        self.header.message_length = self.LENGTH
        hdr_bytes = self.header.pack()
        ts_bytes = _pack_uint48(self.response_origin_timestamp.seconds) + struct.pack(
            ">I", self.response_origin_timestamp.nanoseconds
        )
        port_bytes = self.requesting_port_id.clock_id.data + struct.pack(
            ">H", self.requesting_port_id.port_number
        )
        return hdr_bytes + ts_bytes + port_bytes

    @classmethod
    def unpack(cls, data: bytes) -> PtpPdelayRespFollowUp:
        if len(data) < cls.LENGTH:
            raise ValueError(f"Packet too short for PTP Pdelay_Resp_Follow_Up: {len(data)} < 54")
        hdr = PtpHeader.unpack(data[:34])
        sec = _unpack_uint48(data, 34)
        nsec = struct.unpack_from(">I", data, 40)[0]
        cid = ClockIdentity(bytes(data[44:52]))
        port_num = struct.unpack_from(">H", data, 52)[0]
        return cls(hdr, Timestamp(sec, nsec), PortIdentity(cid, port_num))


@dataclass
class PtpAnnounce:
    header: PtpHeader
    origin_timestamp: Timestamp
    current_utc_offset: int
    grandmaster_priority1: int
    grandmaster_clock_quality: ClockQuality
    grandmaster_priority2: int
    grandmaster_identity: ClockIdentity
    steps_removed: int
    time_source: int
    tlvs: List[bytes] = field(default_factory=list)

    BASE_LENGTH: int = 64

    def pack(self) -> bytes:
        tlv_bytes = b"".join(self.tlvs)
        self.header.message_type = MessageType.ANNOUNCE
        self.header.message_length = self.BASE_LENGTH + len(tlv_bytes)
        hdr_bytes = self.header.pack()

        body = bytearray(30)
        body[0:6] = _pack_uint48(self.origin_timestamp.seconds)
        struct.pack_into(">I", body, 6, self.origin_timestamp.nanoseconds)
        struct.pack_into(">h", body, 10, self.current_utc_offset)
        body[12] = 0  # reserved
        body[13] = self.grandmaster_priority1 & 0xFF
        body[14] = self.grandmaster_clock_quality.clock_class & 0xFF
        body[15] = self.grandmaster_clock_quality.clock_accuracy & 0xFF
        struct.pack_into(">H", body, 16, self.grandmaster_clock_quality.offset_scaled_log_variance)
        body[18] = self.grandmaster_priority2 & 0xFF
        body[19:27] = self.grandmaster_identity.data
        struct.pack_into(">H", body, 27, self.steps_removed)
        body[29] = self.time_source & 0xFF

        return hdr_bytes + bytes(body) + tlv_bytes

    @classmethod
    def unpack(cls, data: bytes) -> PtpAnnounce:
        if len(data) < cls.BASE_LENGTH:
            raise ValueError(f"Packet too short for PTP Announce: {len(data)} < 64")
        hdr = PtpHeader.unpack(data[:34])
        sec = _unpack_uint48(data, 34)
        nsec = struct.unpack_from(">I", data, 40)[0]
        utc_off = struct.unpack_from(">h", data, 44)[0]
        pri1 = data[47]
        cclass = data[48]
        cacc = data[49]
        cvar = struct.unpack_from(">H", data, 50)[0]
        pri2 = data[52]
        gm_id = ClockIdentity(bytes(data[53:61]))
        steps = struct.unpack_from(">H", data, 61)[0]
        src = data[63]

        tlvs = []
        offset = 64
        while offset + 4 <= len(data):
            tlv_type, tlv_len = struct.unpack_from(">HH", data, offset)
            tlv_total = 4 + tlv_len
            if offset + tlv_total > len(data):
                break
            tlvs.append(bytes(data[offset : offset + tlv_total]))
            offset += tlv_total

        return cls(
            header=hdr,
            origin_timestamp=Timestamp(sec, nsec),
            current_utc_offset=utc_off,
            grandmaster_priority1=pri1,
            grandmaster_clock_quality=ClockQuality(cclass, cacc, cvar),
            grandmaster_priority2=pri2,
            grandmaster_identity=gm_id,
            steps_removed=steps,
            time_source=src,
            tlvs=tlvs,
        )


@dataclass
class PathTraceTlv:
    """IEEE 1588-2019 Clause 16.2 PATH_TRACE TLV (type 0x0008)."""
    path_sequence: List[ClockIdentity]

    TLV_TYPE: int = 0x0008

    def pack(self) -> bytes:
        length_field = len(self.path_sequence) * 8
        buf = bytearray(4 + length_field)
        struct.pack_into(">HH", buf, 0, self.TLV_TYPE, length_field)
        for i, cid in enumerate(self.path_sequence):
            buf[4 + i * 8 : 4 + (i + 1) * 8] = cid.data
        return bytes(buf)

    @classmethod
    def unpack(cls, data: bytes) -> PathTraceTlv:
        if len(data) < 4:
            raise ValueError(f"TLV too short: {len(data)} < 4")
        tlv_type, length_field = struct.unpack_from(">HH", data, 0)
        if tlv_type != cls.TLV_TYPE:
            raise ValueError(f"Expected PATH_TRACE TLV type 0x0008, got 0x{tlv_type:04X}")
        cids = []
        for i in range(0, length_field, 8):
            cids.append(ClockIdentity(bytes(data[4 + i : 4 + i + 8])))
        return cls(cids)
