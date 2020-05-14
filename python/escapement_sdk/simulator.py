"""
Escapement Network and Timing Simulator.
Simulates packet exchange over impaired channels with clock drift and servo tracking.
Copyright (C) 2026 Aneesh Krishna. All rights reserved.
"""

from __future__ import annotations
import math
import random
from dataclasses import dataclass, field
from typing import List, Tuple, Optional


@dataclass
class ChannelConfig:
    fwd_delay_ns: float = 250.0
    rev_delay_ns: float = 290.0
    jitter_stddev_ns: float = 40.0
    burst_probability: float = 0.05
    burst_delay_ns: float = 4000.0
    loss_rate: float = 0.0


@dataclass
class SimulationResult:
    epochs: int
    final_master_time_ns: float
    final_slave_time_ns: float
    final_phase_offset_ns: float
    final_freq_drift_ppb: float
    mean_delay_ns: float
    rms_jitter_ns: float
    peak_phase_error_min_ns: float
    peak_phase_error_max_ns: float
    converged: bool


class NetworkSimulator:
    """Simulates multi-epoch PTP packet exchange between Master and Slave clocks."""

    def __init__(
        self,
        config: Optional[ChannelConfig] = None,
        initial_offset_ns: float = 1500.0,
        initial_drift_ppb: float = 45.0,
        seed: Optional[int] = 42,
    ):
        self.config = config or ChannelConfig()
        self.initial_offset_ns = initial_offset_ns
        self.initial_drift_ppb = initial_drift_ppb
        self.seed = seed

    def run(self, num_epochs: int = 60, epoch_interval_sec: float = 0.125) -> SimulationResult:
        rng = random.Random(self.seed) if self.seed is not None else random.Random()
        # Master clock starts at 0.0 ns, zero drift
        master_time_ns = 0.0

        # Slave clock starts with initial offset and drift
        slave_time_ns = self.initial_offset_ns
        nominal_drift_ppb = self.initial_drift_ppb
        servo_adj_ppb = 0.0

        # Servo state: 2-state Kalman filter
        phase_est = 0.0
        freq_est = 0.0
        p00 = 1000.0
        p01 = 0.0
        p10 = 0.0
        p11 = 100.0
        q_phase = 0.1
        q_freq = 0.01
        r_meas = 50.0

        phase_errors: List[float] = []
        delays: List[float] = []

        for epoch in range(num_epochs):
            dt = epoch_interval_sec
            master_time_ns += dt * 1e9

            effective_ppb = nominal_drift_ppb - servo_adj_ppb
            actual_elapsed_ns = dt * 1e9 * (1.0 + effective_ppb * 1e-9)
            slave_time_ns += actual_elapsed_ns

            # Sample transit delay forward (Master -> Slave)
            fwd_jitter = rng.gauss(0.0, self.config.jitter_stddev_ns)
            fwd_burst = self.config.burst_delay_ns if rng.random() < self.config.burst_probability else 0.0
            t_fwd = max(10.0, self.config.fwd_delay_ns + fwd_jitter + fwd_burst)

            # Sample transit delay reverse (Slave -> Master)
            rev_jitter = rng.gauss(0.0, self.config.jitter_stddev_ns)
            rev_burst = self.config.burst_delay_ns if rng.random() < self.config.burst_probability else 0.0
            t_rev = max(10.0, self.config.rev_delay_ns + rev_jitter + rev_burst)

            # Four PTP timestamps
            t1 = master_time_ns
            t2 = slave_time_ns + t_fwd
            t3 = slave_time_ns + 1000.0
            t4 = master_time_ns + 1000.0 + t_rev

            raw_offset = ((t2 - t1) - (t4 - t3)) / 2.0
            raw_delay = ((t2 - t1) + (t4 - t3)) / 2.0

            phase_errors.append(raw_offset)
            delays.append(raw_delay)

            # Initial epoch phase step if discrepancy exceeds threshold
            if epoch == 0 and abs(raw_offset) > 500.0:
                slave_time_ns -= raw_offset
                raw_offset = 0.0

            # Kalman Filter Time Update (Predict)
            phase_pred = phase_est + freq_est * dt
            freq_pred = freq_est
            p00_pred = p00 + dt * (p10 + p01) + dt * dt * p11 + q_phase
            p01_pred = p01 + dt * p11
            p10_pred = p10 + dt * p11
            p11_pred = p11 + q_freq

            # Kalman Filter Measurement Update (Correct)
            s = p00_pred + r_meas
            k0 = p00_pred / s
            k1 = p10_pred / s
            innov = raw_offset - phase_pred

            phase_est = phase_pred + k0 * innov
            freq_est = freq_pred + k1 * innov

            p00 = (1.0 - k0) * p00_pred
            p01 = (1.0 - k0) * p01_pred
            p10 = -k1 * p00_pred + p10_pred
            p11 = -k1 * p01_pred + p11_pred

            # Servo frequency adjustment output
            servo_adj_ppb = freq_est + 0.25 * phase_est
            servo_adj_ppb = max(-500000.0, min(500000.0, servo_adj_ppb))

        mean_delay = sum(delays) / len(delays)
        variance = sum((d - mean_delay) ** 2 for d in delays) / len(delays)
        rms_jitter = math.sqrt(variance)

        final_err = slave_time_ns - master_time_ns
        converged = abs(phase_est) < 250.0

        return SimulationResult(
            epochs=num_epochs,
            final_master_time_ns=master_time_ns,
            final_slave_time_ns=slave_time_ns,
            final_phase_offset_ns=phase_est,
            final_freq_drift_ppb=freq_est,
            mean_delay_ns=mean_delay,
            rms_jitter_ns=rms_jitter,
            peak_phase_error_min_ns=min(phase_errors),
            peak_phase_error_max_ns=max(phase_errors),
            converged=converged,
        )
