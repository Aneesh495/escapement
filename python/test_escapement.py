"""
Escapement Python SDK & Conformance Verification Suite.
Validates protocol roundtrips, BMCA dataset comparisons, simulator convergence, and MTIE masks.
Copyright (C) 2026 Aneesh Krishna. All rights reserved.
"""

import unittest
from escapement_sdk import (
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
    ClockIdentity,
    PortIdentity,
    ClockQuality,
    Timestamp,
    NetworkSimulator,
    BmcaValidator,
    MtieValidator,
)
from escapement_sdk.conformance import PriorityVector


class TestProtocolCodecs(unittest.TestCase):
    def setUp(self):
        self.cid1 = ClockIdentity(bytes([0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07, 0x08]))
        self.cid2 = ClockIdentity(bytes([0x0A, 0x0B, 0x0C, 0x0D, 0x0E, 0x0F, 0x10, 0x11]))
        self.pid1 = PortIdentity(self.cid1, 1)
        self.pid2 = PortIdentity(self.cid2, 2)
        self.ts = Timestamp(1700000000, 123456789)
        self.hdr = PtpHeader(
            major_sdo_id=0,
            message_type=MessageType.SYNC,
            version=2,
            message_length=44,
            domain_number=0,
            minor_sdo_id=0,
            flags=0x0200,  # two-step
            correction_field=65536 * 10,  # +10.0 ns
            source_port_id=self.pid1,
            sequence_id=42,
            control_field=0,
            log_message_interval=0,
        )

    def test_header_roundtrip(self):
        raw = self.hdr.pack()
        self.assertEqual(len(raw), 34)
        unpacked = PtpHeader.unpack(raw)
        self.assertEqual(unpacked.version, 2)
        self.assertEqual(unpacked.message_type, MessageType.SYNC)
        self.assertEqual(unpacked.message_length, 44)
        self.assertTrue(unpacked.two_step)
        self.assertEqual(unpacked.correction_field, 65536 * 10)
        self.assertEqual(unpacked.source_port_id.clock_id, self.cid1)
        self.assertEqual(unpacked.source_port_id.port_number, 1)
        self.assertEqual(unpacked.sequence_id, 42)

    def test_sync_roundtrip(self):
        sync = PtpSync(header=self.hdr, origin_timestamp=self.ts)
        raw = sync.pack()
        self.assertEqual(len(raw), 44)
        unpacked = PtpSync.unpack(raw)
        self.assertEqual(unpacked.header.message_type, MessageType.SYNC)
        self.assertEqual(unpacked.origin_timestamp.seconds, 1700000000)
        self.assertEqual(unpacked.origin_timestamp.nanoseconds, 123456789)

    def test_follow_up_roundtrip(self):
        fu = PtpFollowUp(header=self.hdr, precise_origin_timestamp=self.ts)
        raw = fu.pack()
        self.assertEqual(len(raw), 44)
        unpacked = PtpFollowUp.unpack(raw)
        self.assertEqual(unpacked.header.message_type, MessageType.FOLLOW_UP)
        self.assertEqual(unpacked.precise_origin_timestamp.seconds, 1700000000)
        self.assertEqual(unpacked.precise_origin_timestamp.nanoseconds, 123456789)

    def test_delay_req_roundtrip(self):
        dreq = PtpDelayReq(header=self.hdr, origin_timestamp=self.ts)
        raw = dreq.pack()
        self.assertEqual(len(raw), 44)
        unpacked = PtpDelayReq.unpack(raw)
        self.assertEqual(unpacked.header.message_type, MessageType.DELAY_REQ)
        self.assertEqual(unpacked.origin_timestamp.seconds, 1700000000)
        self.assertEqual(unpacked.origin_timestamp.nanoseconds, 123456789)

    def test_delay_resp_roundtrip(self):
        dresp = PtpDelayResp(header=self.hdr, receive_timestamp=self.ts, requesting_port_id=self.pid2)
        raw = dresp.pack()
        self.assertEqual(len(raw), 54)
        unpacked = PtpDelayResp.unpack(raw)
        self.assertEqual(unpacked.header.message_type, MessageType.DELAY_RESP)
        self.assertEqual(unpacked.receive_timestamp.seconds, 1700000000)
        self.assertEqual(unpacked.receive_timestamp.nanoseconds, 123456789)
        self.assertEqual(unpacked.requesting_port_id.clock_id, self.cid2)
        self.assertEqual(unpacked.requesting_port_id.port_number, 2)

    def test_pdelay_req_roundtrip(self):
        preq = PtpPdelayReq(header=self.hdr, origin_timestamp=self.ts)
        raw = preq.pack()
        self.assertEqual(len(raw), 54)
        unpacked = PtpPdelayReq.unpack(raw)
        self.assertEqual(unpacked.header.message_type, MessageType.PDELAY_REQ)
        self.assertEqual(unpacked.origin_timestamp.seconds, 1700000000)
        self.assertEqual(unpacked.origin_timestamp.nanoseconds, 123456789)

    def test_pdelay_resp_roundtrip(self):
        presp = PtpPdelayResp(header=self.hdr, request_receipt_timestamp=self.ts, requesting_port_id=self.pid2)
        raw = presp.pack()
        self.assertEqual(len(raw), 54)
        unpacked = PtpPdelayResp.unpack(raw)
        self.assertEqual(unpacked.header.message_type, MessageType.PDELAY_RESP)
        self.assertEqual(unpacked.request_receipt_timestamp.seconds, 1700000000)
        self.assertEqual(unpacked.request_receipt_timestamp.nanoseconds, 123456789)
        self.assertEqual(unpacked.requesting_port_id.clock_id, self.cid2)

    def test_announce_with_tlv_roundtrip(self):
        tlv = PathTraceTlv([self.cid1, self.cid2])
        tlv_raw = tlv.pack()
        ann = PtpAnnounce(
            header=self.hdr,
            origin_timestamp=self.ts,
            current_utc_offset=37,
            grandmaster_priority1=128,
            grandmaster_clock_quality=ClockQuality(6, 0x20, 0x1000),
            grandmaster_priority2=128,
            grandmaster_identity=self.cid1,
            steps_removed=0,
            time_source=0x20,
            tlvs=[tlv_raw],
        )
        raw = ann.pack()
        self.assertEqual(len(raw), 64 + len(tlv_raw))
        unpacked = PtpAnnounce.unpack(raw)
        self.assertEqual(unpacked.header.message_type, MessageType.ANNOUNCE)
        self.assertEqual(unpacked.current_utc_offset, 37)
        self.assertEqual(unpacked.grandmaster_priority1, 128)
        self.assertEqual(unpacked.grandmaster_clock_quality.clock_class, 6)
        self.assertEqual(unpacked.grandmaster_identity, self.cid1)
        self.assertEqual(len(unpacked.tlvs), 1)

        unpacked_tlv = PathTraceTlv.unpack(unpacked.tlvs[0])
        self.assertEqual(len(unpacked_tlv.path_sequence), 2)
        self.assertEqual(unpacked_tlv.path_sequence[0], self.cid1)
        self.assertEqual(unpacked_tlv.path_sequence[1], self.cid2)


class TestBmcaConformance(unittest.TestCase):
    def setUp(self):
        self.cid1 = ClockIdentity(bytes([1, 2, 3, 4, 5, 6, 7, 8]))
        self.cid2 = ClockIdentity(bytes([1, 2, 3, 4, 5, 6, 7, 9]))
        self.pid1 = PortIdentity(self.cid1, 1)
        self.pid2 = PortIdentity(self.cid2, 1)

    def test_priority1_comparison(self):
        v1 = PriorityVector(100, 248, 0x20, 0xFFFF, 128, self.cid1, 0, self.pid1)
        v2 = PriorityVector(128, 6, 0x20, 0x1000, 128, self.cid2, 0, self.pid2)
        res = BmcaValidator.compare(v1, v2)
        self.assertEqual(res, BmcaValidator.DCA_A_BETTER)

    def test_clock_class_comparison(self):
        v1 = PriorityVector(128, 6, 0x21, 0x2000, 128, self.cid1, 0, self.pid1)
        v2 = PriorityVector(128, 7, 0x20, 0x1000, 128, self.cid2, 0, self.pid2)
        res = BmcaValidator.compare(v1, v2)
        self.assertEqual(res, BmcaValidator.DCA_A_BETTER)

    def test_steps_removed_comparison(self):
        v1 = PriorityVector(128, 6, 0x20, 0x1000, 128, self.cid1, 0, self.pid1)
        v2 = PriorityVector(128, 6, 0x20, 0x1000, 128, self.cid1, 1, self.pid2)
        res = BmcaValidator.compare(v1, v2)
        self.assertEqual(res, BmcaValidator.DCA_A_BETTER)

    def test_clock_identity_tiebreaker(self):
        v1 = PriorityVector(128, 6, 0x20, 0x1000, 128, self.cid1, 0, self.pid1)
        v2 = PriorityVector(128, 6, 0x20, 0x1000, 128, self.cid2, 0, self.pid2)
        res = BmcaValidator.compare(v1, v2)
        self.assertEqual(res, BmcaValidator.DCA_A_BETTER)


class TestSimulator(unittest.TestCase):
    def test_simulator_convergence(self):
        sim = NetworkSimulator(initial_offset_ns=1500.0, initial_drift_ppb=45.0)
        res = sim.run(num_epochs=60)
        self.assertTrue(res.converged)
        self.assertLess(abs(res.final_phase_offset_ns), 250.0)
        self.assertGreater(res.mean_delay_ns, 200.0)


class TestMtieValidator(unittest.TestCase):
    def test_g811_mask_limits(self):
        self.assertEqual(MtieValidator.g811_prc_mask(0.05), 52.5)
        self.assertEqual(MtieValidator.g811_prc_mask(1.0), 25.275)

    def test_mtie_conformance_evaluation(self):
        # 100 constant samples should produce 0 MTIE and conform
        samples = [10.0] * 100
        pts = MtieValidator.evaluate(samples, tau0_sec=0.1)
        self.assertTrue(all(p.conforms for p in pts))
        self.assertEqual(pts[0].mtie_ns, 0.0)


if __name__ == "__main__":
    unittest.main()
