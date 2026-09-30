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
├── docker-compose.yml            # Compose configuration with host networking support
├── DOCKERFILE_DEPENDENCIES.md    # Detailed description of every installed package & library
├── INSTALLATION_GUIDE.md         # Comprehensive end-to-end FreeSWITCH build & installation guide
├── MANUAL_INSTALLATION.md        # Step-by-step manual build instructions for Debian 12
└── README.md                     # Project overview and quick start guide
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

## 🛠️ Common FreeSWITCH CLI Commands

Once FreeSWITCH is compiled and running, you can interact with the FreeSWITCH CLI:

```bash
# Connect to FreeSWITCH CLI
fs_cli

# Check FreeSWITCH status
status

# Check loaded SIP profiles
sofia status

# Reload XML configuration
reloadxml

# Show active channels and calls
show channels
show calls
```

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
