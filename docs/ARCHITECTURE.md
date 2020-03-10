# Escapement Subsystem Architecture

Escapement is a high-precision IEEE 1588-2019 (PTPv2.1) and IEEE 802.1AS (gPTP) network synchronization engine written in Factor, with low-level C99 SIMD acceleration and an interoperable Python compliance harness.

```
+-----------------------------------------------------------------------------------+
|                                  ESCAPEMENT CLI                                   |
|   grandmaster | slave | bmca | simulate | stability | serve | inspect | benchmark  |
+-----------------------------------------+-----------------------------------------+
                                          |
                      +-------------------+-------------------+
                      |                                       |
+---------------------v---------------------+   +-------------v---------------------+
|      PROTOCOL & CODEC SUBSYSTEM           |   |       STATE & BMCA SUBSYSTEM      |
|  - 34-byte Clause 13 common header pack   |   |  - Clause 9.3.4 DCA (dataset comp)|
|  - Event: Sync, Delay_Req, Pdelay_Req/Resp|   |  - Clause 9.3.3 SDA (state dec)   |
|  - General: Follow_Up, Delay_Resp, Announce|   |  - Clause 9.2 Port State Machine  |
|  - TLV Chaining (PathTrace TLV 0x0008)    |   |  - Default/Current/Parent Datasets|
+---------------------+---------------------+   +-------------+---------------------+
                      |                                       |
+---------------------v---------------------+   +-------------v---------------------+
|       TIMING & DELAY SOLVERS              |   |       SERVO DYNAMICS SUBSYSTEM    |
|  - E2E Mean Path Delay: ((t2-t1)+(t4-t3))/2|   |  - Proportional-Integral (PI/PID) |
|  - P2P Link Delay: ((t4-t1)-(t3-t2))/2    |   |  - Anti-windup clamping           |
|  - Peer rate ratio compensation (RR)      |   |  - 2-state Discrete Kalman Filter |
|  - Lucky Packet minimum delay filter      |   |  - Linear drift estimator         |
+---------------------+---------------------+   +-------------+---------------------+
                      |                                       |
+---------------------v---------------------+   +-------------v---------------------+
|      STABILITY & FREQUENCY METROLOGY      |   |    SYNTHETIC CLOCK & NETWORK LINK |
|  - Allan Deviation (ADEV, sigma_y(tau))   |   |  - Synthetic crystal oscillator   |
|  - Overlapping Allan Deviation (OADEV)    |   |  - Thermal wander and aging drift |
|  - Modified Allan Deviation (MDEV)        |   |  - Asymmetric link transit delay  |
|  - Time Deviation (TDEV)                  |   |  - Gaussian jitter generator      |
|  - ITU-T G.810 MTIE and G.811 PRC Mask    |   |  - Burst queuing emulation        |
+---------------------+---------------------+   +-------------+---------------------+
                      |                                       |
+---------------------v---------------------------------------v---------------------+
|                       C99 SIMD VECTOR ACCELERATION                                |
|  - ARM NEON / x86 AVX2 vector SIMD validation for 34-byte packet headers          |
|  - Parallelized multi-tau Allan variance reduction kernel                        |
|  - Matrix multiplication and Riccati state update for Kalman filter               |
|  - Sub-nanosecond hardware timestamp capture via clock_gettime(CLOCK_MONOTONIC_RAW)|
+-----------------------------------------------------------------------------------+
```

## Subsystem Decomposition

### 1. Protocol and Binary Codecs (`escapement/protocol/`)
The protocol subsystem implements bit-exact binary serialization and deserialization for IEEE 1588-2019 messages according to Clause 13.

- `header.factor`: The 34-octet common PTP header. All PTP messages start with this structure. It encapsulates the message type, version, length, domain number, flags (including two-step and unicast indicators), correction field (64-bit signed fixed-point scaled nanoseconds with 16 fractional bits), source port identity (8-octet clock identity and 2-octet port number), sequence ID, and log message interval.
- `messages/`: Individual message codecs for event messages (Sync, Delay_Req, Pdelay_Req, Pdelay_Resp) and general messages (Follow_Up, Delay_Resp, Pdelay_Resp_Follow_Up, Announce, Signaling, Management).
- `tlv/tlv.factor`: Type-Length-Value parsing engine that chains standard TLVs, including the PATH_TRACE TLV (0x0008) used for detecting master loops in distributed networks.

### 2. Best Master Clock Algorithm (`escapement/bmca/`)
The BMCA implements distributed master election without central coordination:

- `priority-vector/`: Constructs the system priority vector $d_0$ and foreign master vectors $E_{\text{rbest}}$.
- `dataset-comparison/`: Implements the Clause 9.3.4 Dataset Comparison Algorithm (DCA). Compares two priority vectors using strict hierarchical precedence:
  1. Priority 1 (lower numerical value is better)
  2. Clock Class (atomic standard vs internal oscillator)
  3. Clock Accuracy (time accuracy category)
  4. Offset Scaled Log Variance (short-term stability estimate)
  5. Priority 2 (fine-grained tie-breaking)
  6. Clock Identity (lexicographical MAC/EUI-64 order)
  7. Steps Removed (hop count distance)
  8. Source Port Identity (port number tie-breaker)
- `state-decision/`: Implements Clause 9.3.3 State Decision Algorithm (SDA). Recommends master, slave, or passive states for each port based on local priority versus foreign vectors.

### 3. Timing and Delay Solvers (`escapement/timing/`)
Calculates sub-nanosecond clock offset and one-way transit delay:

- `timestamps/`: 48-bit seconds and 32-bit nanoseconds arithmetic, normalization, and difference calculation.
- `delay/`: Implements both End-to-End (E2E) and Peer-to-Peer (P2P) delay calculation:
  - E2E Delay: $d_{\text{mean}} = \frac{(t_2 - t_1) + (t_4 - t_3) - c_{\text{sync}} - c_{\text{delay\_req}}}{2}$
  - E2E Offset: $\theta = \frac{(t_2 - t_1) - (t_4 - t_3) - c_{\text{sync}} + c_{\text{delay\_req}}}{2}$
  - P2P Link Delay: $d_{\text{link}} = \frac{(t_4 - t_1) - (t_3 - t_2) - c_{\text{pdelay\_resp}} - c_{\text{pdelay\_resp\_fu}}}{2}$
- `filters/`: Includes the Lucky Packet minimum delay filter, Exponential Moving Average (EMA), and Hampel Median Absolute Deviation (MAD) outlier rejection.

### 4. Servo Dynamics (`escapement/servo/`)
Compensates for frequency drift and phase offset:

- `pi/`: Proportional-Integral (PI/PID) servo with anti-windup clamping to prevent integrator saturation during network delay spikes.
- `kalman/`: 2-state discrete Kalman filter estimating both clock phase offset $\theta_k$ and frequency drift $\omega_k$ under Gaussian process and measurement noise.
- `linear/`: Least-squares linear regression over sliding observation windows.

### 5. Stability Analysis (`escapement/stability/`)
Frequency stability and wander characterization according to telecommunications standards:

- `allan/`: Computes Allan Deviation (ADEV, $\sigma_y(\tau)$), Overlapping Allan Deviation (OADEV), Modified Allan Deviation (MDEV), and Time Deviation (TDEV) across octave observation intervals.
- `mtie/`: Computes Maximum Time Interval Error (MTIE) over sliding windows and verifies conformance against ITU-T G.811 Primary Reference Clock (PRC) network limits.

### 6. C99 SIMD Acceleration Bridge (`c_src/` and `escapement/simd/`)
High-throughput SIMD kernel loaded dynamically via Factor parse-time hooks (`<< ... >>`):

- 128-bit NEON / 256-bit AVX2 vector validation for 34-byte packet headers.
- Multi-tau Allan variance vector reduction operating at over 1 billion samples per second.
- Matrix update operations for the discrete Kalman filter.
