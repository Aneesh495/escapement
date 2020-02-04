"""
Escapement Standards Conformance and Stability Verifiers.
Implements IEEE 1588-2019 BMCA DCA verification and ITU-T G.811 PRC MTIE mask analysis.
Copyright (C) 2026 Aneesh Krishna. All rights reserved.
"""

from __future__ import annotations
import math
from dataclasses import dataclass
from typing import List, Tuple, Dict
from .protocol import ClockIdentity, PortIdentity, ClockQuality


@dataclass
class PriorityVector:
    root_system_identity_priority1: int
    root_system_identity_clock_class: int
    root_system_identity_clock_accuracy: int
    root_system_identity_offset_scaled_log_variance: int
    root_system_identity_priority2: int
    root_system_identity_clock_identity: ClockIdentity
    steps_removed: int
    source_port_identity: PortIdentity


class BmcaValidator:
    """Validates IEEE 1588-2019 Clause 9.3.4 Dataset Comparison Algorithm (DCA)."""

    DCA_A_BETTER = 1
    DCA_B_BETTER = 2
    DCA_IDENTICAL = 3

    @classmethod
    def compare(cls, a: PriorityVector, b: PriorityVector) -> int:
        """Compare two priority vectors following IEEE 1588-2019 Clause 9.3.4."""
        # 1. Priority 1
        if a.root_system_identity_priority1 < b.root_system_identity_priority1:
            return cls.DCA_A_BETTER
        if a.root_system_identity_priority1 > b.root_system_identity_priority1:
            return cls.DCA_B_BETTER

        # 2. Clock Class
        if a.root_system_identity_clock_class < b.root_system_identity_clock_class:
            return cls.DCA_A_BETTER
        if a.root_system_identity_clock_class > b.root_system_identity_clock_class:
            return cls.DCA_B_BETTER

        # 3. Clock Accuracy
        if a.root_system_identity_clock_accuracy < b.root_system_identity_clock_accuracy:
            return cls.DCA_A_BETTER
        if a.root_system_identity_clock_accuracy > b.root_system_identity_clock_accuracy:
            return cls.DCA_B_BETTER

        # 4. Offset Scaled Log Variance
        if a.root_system_identity_offset_scaled_log_variance < b.root_system_identity_offset_scaled_log_variance:
            return cls.DCA_A_BETTER
        if a.root_system_identity_offset_scaled_log_variance > b.root_system_identity_offset_scaled_log_variance:
            return cls.DCA_B_BETTER

        # 5. Priority 2
        if a.root_system_identity_priority2 < b.root_system_identity_priority2:
            return cls.DCA_A_BETTER
        if a.root_system_identity_priority2 > b.root_system_identity_priority2:
            return cls.DCA_B_BETTER

        # 6. Grandmaster Clock Identity (lexicographical)
        if a.root_system_identity_clock_identity.data < b.root_system_identity_clock_identity.data:
            return cls.DCA_A_BETTER
        if a.root_system_identity_clock_identity.data > b.root_system_identity_clock_identity.data:
            return cls.DCA_B_BETTER

        # 7. Steps Removed
        if a.steps_removed < b.steps_removed:
            return cls.DCA_A_BETTER
        if a.steps_removed > b.steps_removed:
            return cls.DCA_B_BETTER

        # 8. Source Port Identity Clock ID
        if a.source_port_identity.clock_id.data < b.source_port_identity.clock_id.data:
            return cls.DCA_A_BETTER
        if a.source_port_identity.clock_id.data > b.source_port_identity.clock_id.data:
            return cls.DCA_B_BETTER

        # 9. Source Port Number
        if a.source_port_identity.port_number < b.source_port_identity.port_number:
            return cls.DCA_A_BETTER
        if a.source_port_identity.port_number > b.source_port_identity.port_number:
            return cls.DCA_B_BETTER

        return cls.DCA_IDENTICAL


@dataclass
class MtiePoint:
    tau_sec: float
    mtie_ns: float
    mask_limit_ns: float
    conforms: bool


class MtieValidator:
    """Evaluates phase wander conformance against ITU-T G.811 Primary Reference Clock (PRC) mask."""

    @staticmethod
    def g811_prc_mask(tau_sec: float) -> float:
        """Computes ITU-T G.811 PRC MTIE mask limit in nanoseconds."""
        if tau_sec <= 0.1:
            return 52.5  # 0.0525 us
        elif tau_sec <= 1000.0:
            # 0.275 * 10^-3 * tau + 0.025 us -> 0.275 * tau + 25.0 ns
            return 0.275 * tau_sec + 25.0
        else:
            return 300.0

    @classmethod
    def evaluate(cls, phase_samples_ns: List[float], tau0_sec: float) -> List[MtiePoint]:
        n = len(phase_samples_ns)
        results = []
        m = 1
        while m * 2 <= n:
            window_size = m
            max_ptp = 0.0
            for i in range(n - window_size):
                window = phase_samples_ns[i : i + window_size]
                ptp = max(window) - min(window)
                if ptp > max_ptp:
                    max_ptp = ptp

            tau = window_size * tau0_sec
            limit = cls.g811_prc_mask(tau)
            results.append(
                MtiePoint(
                    tau_sec=tau,
                    mtie_ns=max_ptp,
                    mask_limit_ns=limit,
                    conforms=max_ptp <= limit,
                )
            )
            m *= 2

        return results
