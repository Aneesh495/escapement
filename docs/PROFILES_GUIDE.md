# PTP Profiles Guide: IEEE 1588, IEEE 802.1AS, and ITU-T G.8275.1

This guide describes the timing profiles supported by Escapement, detailing parameter constraints, delay mechanisms, transport layers, and network topologies.

## 1. IEEE 1588-2019 Default Profile (Annex I)

The default profile defines standard parameters for local area network synchronization:

- **Delay Mechanism**: End-to-End (E2E) or Peer-to-Peer (P2P).
- **Transport**: UDP over IPv4 (multicast addresses `224.0.1.129` for event, `224.0.1.130` for general) or UDP over IPv6.
- **Domain Number**: 0.
- **Sync Cadence**: 1 packet per second ($\log_2 \text{interval} = 0$).
- **Announce Cadence**: 1 packet every 2 seconds ($\log_2 \text{interval} = 1$).
- **Announce Timeout**: 3 missed messages.
- **BMCA Rules**: Standard Clause 9.3 state machine with priority1 and priority2 default 128.

## 2. IEEE 802.1AS-2020 (gPTP) Profile

IEEE 802.1AS is the generalized Precision Time Protocol (gPTP) used in Time-Sensitive Networking (TSN), automotive Ethernet, and professional Audio-Video Bridging (AVB):

- **Delay Mechanism**: Peer-to-Peer (P2P) mandatory.
- **Transport**: IEEE 802.3 Ethernet Layer 2 direct (EtherType `0x88F7`, multicast MAC `01-80-C2-00-00-0E`).
- **Domain Number**: 0.
- **Sync Cadence**: 8 packets per second ($\log_2 \text{interval} = -3$).
- **Pdelay Cadence**: 1 packet per second ($\log_2 \text{interval} = 0$).
- **Neighbor Propagation Delay Threshold**: Typically 800 nanoseconds. Links exceeding this threshold are marked non-asCapable.
- **Rate Ratio Tracking**: Continuous computation of neighbor frequency offset using peer delay message timestamps.
- **PathTrace TLV**: Mandatory on all Announce frames to immediately drop circular loops.

## 3. ITU-T G.8275.1 Telecom Profile

Designed for 5G cellular base station time and phase synchronization with full timing support from the network:

- **Delay Mechanism**: End-to-End (E2E) mandatory.
- **Transport**: IEEE 802.3 Ethernet Layer 2 multicast (`01-19-A7-00-00-00` non-forwardable).
- **Domain Number**: 24 (default 24 to 43).
- **Sync Cadence**: 16 packets per second ($\log_2 \text{interval} = -4$).
- **Announce Cadence**: 8 packets per second ($\log_2 \text{interval} = -3$).
- **Delay_Req Cadence**: 16 packets per second ($\log_2 \text{interval} = -4$).
- **Boundary Clock Topology**: Every intermediate switch in the synchronization path must operate as a Telecom Boundary Clock (T-BC) with time error budget under 30 nanoseconds per node (Class C).
- **Clock Classes**: Primary Reference Time Clock (PRTC) operates at Class 6 with accuracy under 25 nanoseconds.

## 4. Profile Selection in Escapement

Profiles are selected via configuration JSON files or programmatic initialization:

```factor
! Load IEEE 802.1AS profile
"configs/ieee802_1as_gptp.json" load-profile-config
```
