# 📚 FreeSWITCH Complete Learning Guide

Welcome to the **FreeSWITCH Modular Learning Guide**! This series of structured guides takes you step-by-step from fresh container setup to advanced call routing, dialplans, and SIP troubleshooting.

---

## 🗺️ Learning Roadmap & Chapters

```
  ┌────────────────────────────────────────────────────────────────────────────────┐
  │                         FREESWITCH LEARNING ROADMAP                            │
  └────────────────────────────────────────────────────────────────────────────────┘
                                          │
       ┌──────────────────────────────────┼──────────────────────────────────┐
       ▼                                  ▼                                  ▼
 [Chapter 00]                       [Chapter 01]                       [Chapter 02]
 VoIP Fundamentals                  Installation & Docker              Softphone & NAT Fix
 ├── SIP vs RTP Streams             ├── Docker Architecture            ├── MicroSIP Setup
 ├── Why UDP over TCP               ├── Ports & Forwarding             ├── Docker NAT Challenges
 └── SDP & Audio Codecs             └── Volume Mounts                  └── Bidirectional Audio Fix
       │                                  │                                  │
       └──────────────────────────────────┼──────────────────────────────────┘
                                          ▼
                                    [Chapter 03]
                               CLI Commands & Reloads
                               ├── fs_cli Console Cheat-Sheet
                               ├── Live Real-Time Logs
                               └── reloadxml vs Restarts
                                          │
       ┌──────────────────────────────────┴──────────────────────────────────┐
       ▼                                                                     ▼
 [Chapter 04]                                                          [Chapter 05]
 The 3 Core Pillars                                                    Call Routing Flows
 ├── 1. SIP Profiles (:5060/:5080)                                     ├── Internal Calling (1000 ➔ 1001)
 ├── 2. Directory (Users & Passwords)                                  ├── Outbound Calling (PSTN Trunk)
 └── 3. Dialplans (Routing Brain)                                      └── Inbound Calling (DIDs / IVR)
                                          │
                                          ▼
                                    [Chapter 06]
                                 Dialplan Deep Dive
                               ├── XML Conditions & Regex
                               ├── Dialplan Applications
                               └── Creating Custom Extensions
```

---

## 📖 Chapter Index

| Chapter | Title | Summary |
| :---: | :--- | :--- |
| **00** | [**VoIP Fundamentals (SIP, RTP, SDP, UDP & Codecs)**](file:///c:/Users/tusha/Desktop/freeswitch/learning/00_voip_fundamentals_sip_rtp_udp.md) | Essential networking theory: SIP signaling vs RTP voice streams, why UDP is used, SDP negotiation, and audio codecs. |
| **01** | [**Installation & Docker Architecture**](file:///c:/Users/tusha/Desktop/freeswitch/learning/01_installation_and_docker.md) | How FreeSWITCH compiles inside Docker, port mappings, and host volume synchronization. |
| **02** | [**Softphone Setup & NAT Audio Troubleshooting**](file:///c:/Users/tusha/Desktop/freeswitch/learning/02_softphone_and_nat_troubleshoot.md) | Configuring MicroSIP, understanding Docker bridge NAT, and fixing the "No Audio / 1-way voice" bug. |
| **03** | [**CLI Commands, Live Logs & Reload Matrix**](file:///c:/Users/tusha/Desktop/freeswitch/learning/03_cli_commands_and_reloads.md) | Mastering `fs_cli`, live streaming logs, and knowing when to use `reloadxml` vs container restarts. |
| **04** | [**Core Architecture: The 3 Pillars**](file:///c:/Users/tusha/Desktop/freeswitch/learning/04_core_architecture_3_pillars.md) | Deep dive into SIP Profiles, Directory Users, and Dialplans with visual diagrams. |
| **05** | [**Call Routing & Call Flows**](file:///c:/Users/tusha/Desktop/freeswitch/learning/05_call_routing_and_flows.md) | Step-by-step sequence diagrams for internal extension-to-extension, outbound trunk, and inbound DID calls. |
| **06** | [**Dialplan Deep Dive & Custom Extensions**](file:///c:/Users/tusha/Desktop/freeswitch/learning/06_dialplan_deep_dive.md) | How to write XML dialplans, regular expressions, execution order, and essential applications (`bridge`, `playback`, `answer`). |

---

## 🚀 Recommended Learning Order

1. Read **Chapter 01 & 02** to understand how your local Docker environment and softphone interact.
2. Keep **Chapter 03** handy as a daily reference whenever you need to reload configs or inspect active calls.
3. Study **Chapters 04, 05, and 06** before creating your own custom extensions, IVR menus, or interconnecting with telecom carriers.
