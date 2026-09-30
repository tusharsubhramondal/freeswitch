# Chapter 00: VoIP Fundamentals (SIP, RTP, SDP, UDP & Codecs)

Before diving into FreeSWITCH configuration, this foundational guide explains how internet telephony works under the hood: how human voice is digitized, how calls are initiated, and why VoIP uses specific network protocols.

---

## 📋 Table of Contents
1. [The Two Parallel Streams of Every Phone Call](#1-the-two-parallel-streams-of-every-phone-call)
2. [Transport Protocols: Why UDP over TCP?](#2-transport-protocols-why-udp-over-tcp)
3. [SIP (Session Initiation Protocol) Explained](#3-sip-session-initiation-protocol-explained)
4. [SDP (Session Description Protocol) Explained](#4-sdp-session-description-protocol-explained)
5. [RTP & RTCP (Real-Time Voice Media)](#5-rtp--rtcp-real-time-voice-media)
6. [Audio Codecs: How Voice is Encoded](#6-audio-codecs-how-voice-is-encoded)
7. [NAT: The #1 Challenge in VoIP](#7-nat-the-1-challenge-in-voip)
8. [Summary & Cheat-Sheet](#8-summary--cheat-sheet)

---

## 1. The Two Parallel Streams of Every Phone Call

Every VoIP call consists of **two completely separate network connections** running at the same time:

```
  ┌──────────────────┐                               ┌──────────────────┐
  │                  │ ────── 1. SIP Signaling ─────►│                  │
  │                  │    (Port 5060 - INVITE, BYE)  │                  │
  │    Softphone     │                               │    FreeSWITCH    │
  │   (MicroSIP)     │ ◄───── 2. RTP Voice Media ───►│     (Server)     │
  │                  │   (Ports 16384-16484 - Audio) │                  │
  └──────────────────┘                               └──────────────────┘
```

| Stream | Protocol | Default Ports | What it Does |
| :--- | :--- | :---: | :--- |
| **1. Signaling Plane** | **SIP** (Session Initiation Protocol) | `5060`, `5080` | Handles the *call setup*: Dialing, Ringing, Answering, Authentication, and Hangup. (Like dialing a number and waiting for someone to pick up). |
| **2. Media Plane** | **RTP** (Real-time Transport Protocol) | `16384–16484` | Carries the *actual voice audio packets* back and forth in real-time once the call connects. |

---

## 2. Transport Protocols: Why UDP over TCP?

In standard web browsing (HTTP/HTTPS), computers use **TCP** (Transmission Control Protocol) to ensure 100% of data packets arrive without error. If a packet is lost, TCP pauses and retransmits it.

In VoIP, **UDP** (User Datagram Protocol) is preferred for voice media:

```
  TCP (Websites/Downloads)           UDP (Live Voice & Video)
  ┌────────┐     ┌────────┐          ┌────────┐     ┌────────┐
  │ Sender │────►│Receiver│          │ Sender │────►│Receiver│
  │        │◄────│  ACK   │          │        │────►│ (Next) │
  │ (Wait) │────►│ Data 2 │          │ (Fast) │────►│ Data 2 │
  └────────┘     └────────┘          └────────┘     └────────┘
  Guarantees 100% Delivery           Zero Delay (Lowest Latency)
  Causes audio lag/buffering         Late packet is discarded
```

### Why VoIP uses UDP:
1. **Real-time Latency**: A human conversation requires audio delay below **150 milliseconds**. If an audio packet drops, retransmitting it 300ms later is useless because the conversation has already moved on.
2. **Speed & Efficiency**: UDP headers have no handshakes, acknowledgments, or sequence re-ordering overhead.

---

## 3. SIP (Session Initiation Protocol) Explained

SIP is an ASCII text-based protocol modeled after HTTP. It uses **Requests** (Methods) and **Responses** (Status Codes).

### Common SIP Methods (Requests):
- **`REGISTER`**: Softphone announces its presence, IP, and port to FreeSWITCH so the server knows where to reach it.
- **`INVITE`**: Initiates a new call session.
- **`ACK`**: Confirms the final response to an INVITE was received.
- **`BYE`**: Terminates an active call (hang up).
- **`CANCEL`**: Cancels a pending call before it is answered.
- **`OPTIONS`**: Heartbeat ping to check if a server/gateway is alive.

### Common SIP Status Codes:
| Code Range | Category | Common Examples |
| :---: | :--- | :--- |
| **`1xx`** | **Provisional / Informational** | `100 Trying` (Server received request)<br>`180 Ringing` (Phone is ringing)<br>`183 Session Progress` (Early audio / ringback tone) |
| **`2xx`** | **Success** | `200 OK` (Call answered, registration accepted) |
| **`4xx`** | **Client Errors** | `401 Unauthorized` (Password needed)<br>`407 Proxy Authentication Required`<br>`404 Not Found` (Extension doesn't exist)<br>`486 Busy Here` (User on another call) |
| **`5xx`** | **Server Errors** | `500 Server Internal Error`<br>`503 Service Unavailable` |
| **`6xx`** | **Global Failure** | `603 Decline` (Call rejected by user) |

### Anatomy of a SIP Message:
```http
INVITE sip:1000@127.0.0.1:5060 SIP/2.0
Via: SIP/2.0/UDP 172.20.10.9:52786;branch=z9hG4bK-abc123
From: "Alice" <sip:1001@127.0.0.1>;tag=98765
To: <sip:1000@127.0.0.1>
Call-ID: a84b4c76-32ef@172.20.10.9
CSeq: 1 INVITE
Contact: <sip:1001@172.20.10.9:52786>
Content-Type: application/sdp
Content-Length: 215

[... SDP Payload Attached Below ...]
```

---

## 4. SDP (Session Description Protocol) Explained

SIP itself does not transport audio; instead, SIP carries an **SDP body** inside the `INVITE` and `200 OK` messages. 

SDP acts like a **contract negotiation** where both sides agree on:
1. **Media IP Address (`c=`)**: Where to send RTP voice packets.
2. **Media Port (`m=`)**: Which UDP port to send voice packets to.
3. **Supported Audio Codecs (`a=rtpmap:`)**: e.g., Opus, PCMU, PCMA.

### Example SDP Payload:
```text
v=0                                          <-- SDP Version (0)
o=FreeSWITCH 1790738234 1790738235 IN IP4 127.0.0.1 <-- Originator ID & Session IP
s=FreeSWITCH                                 <-- Session Name
c=IN IP4 127.0.0.1                           <-- CONNECTION IP: Send audio here!
t=0 0                                        <-- Timing (Start/Stop)
m=audio 16398 RTP/AVP 0 8 101                <-- Port: 16398, Supported Payload IDs
a=rtpmap:0 PCMU/8000                         <-- Payload 0 = G.711 u-Law (8kHz)
a=rtpmap:8 PCMA/8000                         <-- Payload 8 = G.711 A-Law (8kHz)
a=rtpmap:101 telephone-event/8000            <-- Payload 101 = DTMF keypad tones (RFC2833)
a=ptime:20                                   <-- Packetization: 20ms of audio per packet
```

---

## 5. RTP & RTCP (Real-Time Voice Media)

### What is RTP?
Once the SIP handshake completes, your microphone audio is cut into small slices (typically **20 milliseconds** per packet = **50 packets per second**), wrapped in an RTP header, and streamed over UDP.

An RTP packet contains:
- **Sequence Number**: Allows the receiver to detect lost or out-of-order packets.
- **Timestamp**: Allows the receiver to play back audio smoothly at the exact right pace (eliminating *jitter*).
- **Payload Type**: Identifies the audio codec used (e.g. `0` for PCMU, `102` for Opus).

### What is RTCP?
**RTCP** (RTP Control Protocol) runs alongside RTP on an odd port number (e.g. if RTP is on `16398`, RTCP is on `16399`). It periodically reports call quality statistics:
- Packet Loss percentage
- Jitter (variation in packet arrival times)
- Round-Trip Time (RTT latency)

---

## 6. Audio Codecs: How Voice is Encoded

An audio **codec** (coder-decoder) converts analog microphone waves into digital bits and compresses them for transmission:

| Codec Name | Standard / Alias | Sampling Rate | Bitrate | Quality | Usage |
| :--- | :--- | :---: | :---: | :--- | :--- |
| **PCMU** | G.711 $\mu$-law | 8 kHz | 64 kbps | Standard Landline Quality | Universal standard in North America & Japan. No CPU compression overhead. |
| **PCMA** | G.711 A-law | 8 kHz | 64 kbps | Standard Landline Quality | Universal standard in Europe and the rest of the world. |
| **Opus** | RFC 6716 | 8–48 kHz | 6–510 kbps | **Ultra HD / Studio Quality** | The modern standard for WebRTC and mobile softphones. Automatically adapts to bandwidth. |
| **G.722** | Wideband | 16 kHz | 64 kbps | **HD Voice** | Crystal clear office telephone audio. |
| **G.729** | Low Bandwidth | 8 kHz | 8 kbps | High Compression | Used over slow or cellular connections. |

---

## 7. NAT: The #1 Challenge in VoIP

**NAT** (Network Address Translation) is used by home and office Wi-Fi routers and Docker bridges to allow multiple devices to share one IP.

```
 [MicroSIP on Laptop]                  [Router / Docker Bridge]             [FreeSWITCH Server]
 Private IP: 192.168.1.50   ─────►    Public/Gateway IP: 103.24.56.78   ───► 127.0.0.1
```

### Why NAT breaks VoIP:
- MicroSIP's microphone encodes its private IP (`192.168.1.50`) into the SDP header: `c=IN IP4 192.168.1.50`.
- When FreeSWITCH receives this packet, it cannot send audio back to `192.168.1.50` because that private IP is unreachable across the network!
- **The Solution:** 
  1. Setting `external_rtp_ip=127.0.0.1` and `NDLB-force-rport=true` in FreeSWITCH.
  2. FreeSWITCH ignores the internal SDP private IP and sends audio back to the **source IP and port** from which the packet was actually received (*Auto-NAT / Symmetric RTP*).

---

## 8. Summary & Cheat-Sheet

```
           VOIP PROTOCOL STACK
 ┌──────────────────────────────────────┐
 │     SIP (Signaling - Port 5060)      │ ──► "Call User 1000"
 ├──────────────────────────────────────┤
 │     SDP (Negotiation inside SIP)     │ ──► "Send Audio to IP 127.0.0.1:16398 with Opus"
 ├──────────────────────────────────────┤
 │     RTP (Audio Media - Port 16398)   │ ──► Actual voice sound chunks (20ms)
 ├──────────────────────────────────────┤
 │     UDP (Transport Layer)            │ ──► Fast, connectionless delivery
 ├──────────────────────────────────────┤
 │     IP (Network Layer)               │ ──► Routing across subnets & internet
 └──────────────────────────────────────┘
```

---

👉 Next: Continue to **[Chapter 01: Installation & Docker Architecture](file:///c:/Users/tusha/Desktop/freeswitch/learning/01_installation_and_docker.md)**
