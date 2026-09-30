# FreeSWITCH Docker & Build Environment

A complete Dockerized environment and step-by-step setup for compiling, deploying, and running **FreeSWITCH** on **Debian 12 (Bookworm)** with full support for VoIP, WebRTC, SIP signaling, and modern audio/video codecs.

---

## 📌 Repository Overview

This repository provides a production-ready baseline to build and run FreeSWITCH inside Docker or natively on Debian Linux. It comes preconfigured with all essential build toolchains, media libraries (Opus, MP3, Vorbis, SpeexDSP), video transcoding libraries (FFmpeg), and SignalWire foundational dependencies.

### Key Highlights
- 🐳 **Debian 12 Base**: Clean, isolated, and lightweight Linux environment.
- 🎙️ **Rich Codec & DSP Support**: Built-in support for Opus, SpeexDSP, MP3, Ogg Vorbis, and Libsndfile.
- 📹 **Video & Multimedia Ready**: Includes FFmpeg development libraries (`libavformat`, `libswscale`, `libswresample`).
- 🔐 **Secure VoIP**: OpenSSL support for SIP over TLS (SIPS), WebRTC (WSS/DTLS), and SRTP.
- 📜 **Full Documentation**: Dedicated guides for package purposes, manual builds, and Docker orchestration.

---

## 📂 Repository Structure

```text
├── Dockerfile                    # Docker build recipe containing system & build dependencies
├── docker-compose.yml            # Compose configuration with port mappings and volume sync
├── INSTALLATION_GUIDE.md         # 🛠️ Complete FreeSWITCH build & installation guide (Docker & Native)
├── README.md                     # 📌 Project overview and quick start guide
└── learning/                     # 📚 Modular FreeSWITCH Learning Chapters (00–06)
    ├── README.md                 # Master Roadmap & Index
    ├── 00_voip_fundamentals_sip_rtp_udp.md
    ├── 01_installation_and_docker.md
    ├── 02_softphone_and_nat_troubleshoot.md
    ├── 03_cli_commands_and_reloads.md
    ├── 04_core_architecture_3_pillars.md
    ├── 05_call_routing_and_flows.md
    └── 06_dialplan_deep_dive.md
```

---

## 🚀 Quick Start (Docker)

### 1. Prerequisites
- [Docker Engine](https://docs.docker.com/engine/install/) (v20.10+)
- [Docker Compose](https://docs.docker.com/compose/) (v2.0+)

### 2. Build the Docker Image
To build the image using the provided [Dockerfile](file:///c:/Users/tusha/Desktop/freeswitch/Dockerfile):

```bash
docker compose build
```
*(Or manually via `docker build -t my-freeswitch-image:latest .`)*

### 3. Start the Container
Start the container in interactive/background mode:

```bash
docker compose up -d
```

### 4. Access the Container Shell
```bash
docker exec -it freeswitch-learning bash
```

---

## 📖 Documentation Index

| Document | Description |
| :--- | :--- |
| 📄 **[LEARNING_GUIDE.md](file:///c:/Users/tusha/Desktop/freeswitch/LEARNING_GUIDE.md)** | Step-by-step post-installation guide, network fixes, MicroSIP softphone setup, and test extensions. |
| 📄 **[DOCKERFILE_DEPENDENCIES.md](file:///c:/Users/tusha/Desktop/freeswitch/DOCKERFILE_DEPENDENCIES.md)** | Full breakdown of every utility, build tool, codec, and database library installed in the `Dockerfile`. |
| 📄 **[INSTALLATION_GUIDE.md](file:///c:/Users/tusha/Desktop/freeswitch/INSTALLATION_GUIDE.md)** | Comprehensive guide covering dependency compilation (`libks`, `sofia-sip`, `spandsp`), sound prompt setup, and systemd service creation. |
| 📄 **[MANUAL_INSTALLATION.md](file:///c:/Users/tusha/Desktop/freeswitch/MANUAL_INSTALLATION.md)** | Direct CLI instructions to manually compile and install FreeSWITCH from Git source on Debian 12. |

---

## ⚙️ Installed Package Categories

Inside the Docker environment, dependencies are grouped into the following functional areas:

* **Build Tools**: `build-essential`, `cmake`, `autoconf`, `automake`, `libtool`, `pkg-config`, `nasm`, `yasm`
* **Core Runtime**: `uuid-dev`, `libpcre3-dev`, `libssl-dev`, `libedit-dev`, `libsqlite3-dev`, `libldns-dev`
* **Networking & HTTP**: `curl`, `wget`, `libcurl4-openssl-dev`, `ca-certificates`
* **Audio & Codecs**: `libopus-dev`, `libspeexdsp-dev`, `libsndfile1-dev`, `libmpg123-dev`, `libmp3lame-dev`, `libshout3-dev`, `libogg-dev`, `libvorbis-dev`
* **Video & Images**: `libavformat-dev`, `libswscale-dev`, `libavutil-dev`, `libswresample-dev`, `libjpeg-dev`, `libtiff-dev`, `zlib1g-dev`
* **Scripting**: `liblua5.4-dev` (`mod_lua`)

> For the detailed breakdown of what each specific library does, refer to [DOCKERFILE_DEPENDENCIES.md](file:///c:/Users/tusha/Desktop/freeswitch/DOCKERFILE_DEPENDENCIES.md).

---

## 🛠️ Server Lifecycle & CLI Management Commands

### 1. Starting, Stopping & Restarting FreeSWITCH

| Action | Location / Shell | Command |
| :--- | :--- | :--- |
| **Start Server** (Background) | Inside Container Bash | `freeswitch -nc` |
| **Stop Server** (Graceful) | Inside Container Bash | `freeswitch -stop` |
| **Stop Server** | Inside `fs_cli` | `fsctl shutdown` |
| **Stop Server** (From Host) | Windows PowerShell / CMD | `docker exec freeswitch-learning freeswitch -stop` |
| **Restart Server** | Inside Container Bash | `freeswitch -stop && freeswitch -nc` |
| **Force Kill** (Unresponsive) | Inside Container Bash | `pkill -9 -f freeswitch` |
| **Check Process Status** | Inside Container Bash | `ps aux \| grep freeswitch` |
| **View Live Logs** | Inside Container Bash | `tail -f /usr/local/freeswitch/var/log/freeswitch/freeswitch.log` |

---

### 2. Common Interactive CLI Commands (`fs_cli`)

Connect to the interactive CLI:
```bash
# Inside container
fs_cli

# Or from Windows host
docker exec -it freeswitch-learning fs_cli
```

Inside `fs_cli`, use these commands:

| Command | Description |
| :--- | :--- |
| **`status`** | Display server uptime, memory usage, and performance stats |
| **`sofia status`** | View all active SIP profiles (`internal`, `external`) |
| **`sofia status profile internal`** | View details and IP bindings of the internal SIP profile (port 5060) |
| **`reloadxml`** | Reload XML configurations & dialplans immediately without restarting |
| **`show registrations`** | View all registered SIP softphones/extensions |
| **`show channels`** | List active calls and channels |
| **`show calls`** | Display active call count and details |
| **`fsctl shutdown`** | Gracefully stop the FreeSWITCH server |
| **`/bye`** or **`Ctrl + D`** | Exit `fs_cli` back to Linux shell (server keeps running) |

---

## 🌐 Network Ports Reference

When exposing FreeSWITCH outside the container (or when using `network_mode: host`):

| Port | Protocol | Purpose |
| :--- | :--- | :--- |
| **5060** | UDP / TCP | SIP Signaling (Internal Profile) |
| **5061** | TCP | SIP TLS (Encrypted Signaling) |
| **5080** | UDP / TCP | SIP Signaling (External / Gateway Profile) |
| **8021** | TCP | Event Socket Layer (ESL / `fs_cli`) |
| **5066 / 7443** | TCP / WSS | WebRTC SIP Signaling (WebSocket / Secure WebSocket) |
| **16384 - 32768** | UDP | RTP Media Streams (Audio / Video) |

---

## 📄 License
This repository is open for personal learning and development. FreeSWITCH itself is licensed under the [Mozilla Public License 1.1 (MPL)](https://freeswitch.org/).
