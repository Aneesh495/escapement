# IEEE 1588-2019 Protocol Specification Reference

This document details the wire layouts, timestamp semantics, correction field arithmetic, and delay measurement equations implemented in Escapement.

## 1. Common Message Header Layout (Clause 13.3)

Every PTP message begins with a 34-octet common header formatted in network byte order (big-endian):

```
 0                   1                   2                   3
 0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1
+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
| majorSdoId|msgType|minorSdoId |versionPTP     | messageLength |
+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
| domainNumber  |minorVer/res   |            flags              |
+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
|                                                               |
+                    correctionField (int64)                    +
|                                                               |
+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
|                     messageTypeSpecific                       |
+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
|                                                               |
+             sourcePortIdentity.clockIdentity (8 octets)       +
|                                                               |
+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
|   sourcePortIdentity.portNum  |          sequenceId           |
+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
|  controlField | logMsgInterval|
+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
```

### Field Definitions
- `majorSdoId` (4 bits): Standard Organization Domain Sub-field.
- `messageType` (4 bits):
  - `0x0`: Sync (Event)
  - `0x1`: Delay_Req (Event)
  - `0x2`: Pdelay_Req (Event)
  - `0x3`: Pdelay_Resp (Event)
  - `0x8`: Follow_Up (General)
  - `0x9`: Delay_Resp (General)
  - `0xA`: Pdelay_Resp_Follow_Up (General)
  - `0xB`: Announce (General)
  - `0xC`: Signaling (General)
  - `0xD`: Management (General)
- `versionPTP` (4 bits): Protocol version (must be 2 for IEEE 1588-2008 and IEEE 1588-2019).
- `messageLength` (16 bits): Total message length in octets including header, body, and TLVs.
- `domainNumber` (8 bits): Clock domain (default 0).
- `flags` (16 bits): Bitmask controlling protocol options:
  - Bit 1 (0x0200): `twoStepFlag` (indicates whether origin timestamp is provided in Follow_Up).
  - Bit 2 (0x0400): `unicastFlag` (indicates point-to-point unicast transport).
- `correctionField` (64 bits): Sub-nanosecond time correction expressed in units of $2^{-16}$ nanoseconds (scaled nanoseconds). Each integer count represents $1/65536 \approx 15.26$ femtoseconds.
- `sourcePortIdentity` (10 octets): Unique source port identifier consisting of an 8-octet EUI-64 ClockIdentity and a 2-octet unsigned port number.
- `sequenceId` (16 bits): Monotonically incrementing sequence counter per message type.
- `controlField` (8 bits): Legacy IEEE 1588-2002 compatibility field.
- `logMessageInterval` (8 bits): Signed logarithmic mean transmission period in seconds ($2^{\text{logMessageInterval}}$).

## 2. Delay Measurement Mechanisms

### End-to-End (E2E) Delay Mechanism (Clause 11.3)
Measures the round-trip transit delay between Master and Slave across all intermediate network hops:

```
    Master                                              Slave
      |                                                   |
 (t1) +----------------- Sync Message ------------------>| (t2)
      |                                                   |
      +-------------- Follow_Up (if two-step) ----------->|
      |                                                   |
 (t4) |<--------------- Delay_Req Message ----------------+ (t3)
      |                                                   |
      +--------------- Delay_Resp Message --------------->|
      |                                                   |
```

1. Master transmits Sync at local hardware time $t_1$.
2. Slave receives Sync at local hardware time $t_2$.
3. Slave transmits Delay_Req at local hardware time $t_3$.
4. Master receives Delay_Req at local hardware time $t_4$.
5. Master transmits Delay_Resp containing $t_4$ back to Slave.

Equations:
$$\text{Mean Path Delay} = \frac{(t_2 - t_1) + (t_4 - t_3) - c_{\text{sync}} - c_{\text{delay\_req}}}{2}$$
$$\text{Clock Offset} = \frac{(t_2 - t_1) - (t_4 - t_3) - c_{\text{sync}} + c_{\text{delay\_req}}}{2}$$

### Peer-to-Peer (P2P) Delay Mechanism (Clause 11.4)
Measures link delay between directly connected neighbor ports, independent of network topology:

```
    Port 1                                              Port 2
      |                                                   |
 (t1) +--------------- Pdelay_Req Message --------------->| (t2)
      |                                                   |
 (t4) |<-------------- Pdelay_Resp Message ---------------+ (t3)
      |                                                   |
      |<--------- Pdelay_Resp_Follow_Up (if two-step) ----+
      |                                                   |
```

$$\text{Peer Mean Path Delay} = \frac{(t_4 - t_1) - (t_3 - t_2) - c_{\text{resp}} - c_{\text{resp\_fu}}}{2}$$

Neighbor Rate Ratio calculation:
$$\text{Rate Ratio} = \frac{(t_{3,\text{curr}} - t_{3,\text{prev}})}{(t_{4,\text{curr}} - t_{4,\text{prev}})}$$
