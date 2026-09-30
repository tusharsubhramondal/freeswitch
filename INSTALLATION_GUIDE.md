# FreeSWITCH Installation & Build Guide

A complete, step-by-step guide to installing, building, and running FreeSWITCH on **Debian 12 (Bookworm)** natively and inside **Docker**.

---

## Table of Contents
1. [Overview & Prerequisites](#1-overview--prerequisites)
2. [Dependency Reference](#2-dependency-reference)
3. [Step-by-Step Native Build (Debian 12)](#3-step-by-step-native-build-debian-12)
   - [Step 1: Install System Dependencies](#step-1-install-system-dependencies)
   - [Step 2: Build SignalWire Dependencies (`libks` & `sofia-sip`)](#step-2-build-signalwire-dependencies-libks--sofia-sip)
   - [Step 3: Build & Install `spandsp`](#step-3-build--install-spandsp)
   - [Step 4: Download & Build FreeSWITCH](#step-4-download--build-freeswitch)
   - [Step 5: Install Sound Prompts & Music on Hold (MOH)](#step-5-install-sound-prompts--music-on-hold-moh)
   - [Step 6: User Permissions & Systemd Service](#step-6-user-permissions--systemd-service)
4. [Dockerized Setup (Recommended)](#4-dockerized-setup-recommended)
   - [Complete Dockerfile](#complete-dockerfile)
   - [Docker Compose Configuration](#docker-compose-configuration)
   - [Building & Running with Docker](#building--running-with-docker)
5. [Basic Verification & CLI Usage](#5-basic-verification--cli-usage)
6. [Troubleshooting & Common Errors](#6-troubleshooting--common-errors)

---

## 1. Overview & Prerequisites

FreeSWITCH is a modular, scalable open-source telephony platform supporting WebRTC, SIP, audio/video transcoding, and call routing.

### System Requirements:
- **OS**: Debian 12 (Bookworm) / Ubuntu 22.04+ (or Docker Engine)
- **CPU**: 2+ Cores (4+ Cores recommended for media transcoding / compilation)
- **RAM**: 2 GB Minimum (4 GB+ recommended during compilation)
- **Disk Space**: At least 10 GB free space

---

## 2. Dependency Reference

FreeSWITCH requires core build tools, cryptographic libraries, database drivers, audio/video codecs, and SignalWire foundational libraries (`sofia-sip`, `libks`).

```bash
apt-get update && apt-get install -y \
    git \
    build-essential \
    autoconf \
    automake \
    libtool \
    libtool-bin \
    pkg-config \
    cmake \
    nasm \
    yasm \
    uuid-dev \
    libpcre3-dev \
    libssl-dev \
    libcurl4-openssl-dev \
    libspeexdsp-dev \
    libedit-dev \
    libsqlite3-dev \
    libldns-dev \
    libsndfile1-dev \
    libopus-dev \
    libmpg123-dev \
    libshout3-dev \
    libmp3lame-dev \
    libavformat-dev \
    libswscale-dev \
    libavutil-dev \
    libswresample-dev \
    liblua5.4-dev \
    libjpeg-dev \
    zlib1g-dev \
    libtiff-dev \
    libogg-dev \
    libvorbis-dev
```

---

## 3. Step-by-Step Native Build (Debian 12)

### Step 1: Install System Dependencies
Update system packages and install all the prerequisites listed above.

```bash
sudo apt-get update && sudo apt-get upgrade -y
sudo apt-get install -y \
    git build-essential autoconf automake libtool libtool-bin pkg-config cmake \
    nasm yasm uuid-dev libpcre3-dev libssl-dev libcurl4-openssl-dev libspeexdsp-dev libedit-dev \
    libsqlite3-dev libldns-dev libsndfile1-dev libopus-dev libmpg123-dev \
    libshout3-dev libmp3lame-dev libavformat-dev libswscale-dev libavutil-dev \
    libswresample-dev liblua5.4-dev libjpeg-dev zlib1g-dev libtiff-dev libogg-dev libvorbis-dev
```

---

### Step 2: Build SignalWire Dependencies (`libks` & `sofia-sip`)

Modern FreeSWITCH versions require SignalWire's `libks` (foundational C library) and `sofia-sip` (SIP signaling stack).

#### 2.1 Build `libks`
```bash
cd /usr/src
sudo git clone https://github.com/signalwire/libks.git
cd libks
sudo cmake . -DCMAKE_INSTALL_PREFIX=/usr -DWITH_LIBATOMIC=ON
sudo make -j$(nproc)
sudo make install
sudo ldconfig
```

#### 2.2 Build `sofia-sip`
```bash
cd /usr/src
sudo git clone https://github.com/freeswitch/sofia-sip.git
cd sofia-sip
sudo ./bootstrap.sh
sudo ./configure --prefix=/usr
sudo make -j$(nproc)
sudo make install
sudo ldconfig
```

---

### Step 3: Build & Install `spandsp`
Required for DSP, tones, and T.38 / Fax processing (`mod_spandsp`).

```bash
cd /usr/src
sudo git clone https://github.com/freeswitch/spandsp.git
cd spandsp
sudo ./bootstrap.sh
sudo ./configure --prefix=/usr
sudo make -j$(nproc)
sudo make install
sudo ldconfig
```

---

### Step 4: Download & Build FreeSWITCH

#### 4.1 Clone Repository
```bash
cd /usr/src
sudo git clone -b v1.10 https://github.com/signalwire/freeswitch.git
cd freeswitch
```

#### 4.2 Bootstrap & Configure Modules
```bash
# Export library paths
export PKG_CONFIG_PATH=/usr/lib/pkgconfig:/usr/local/lib/pkgconfig:$PKG_CONFIG_PATH

# Generate build scripts
sudo ./bootstrap.sh -j

# Disable mod_signalwire (avoids signalwire-c dependency)
sudo sed -i 's|applications/mod_signalwire|#applications/mod_signalwire|g' modules.conf

# Configure the build
sudo ./configure --prefix=/usr/local/freeswitch \
                 --enable-core-pgsql-support=no \
                 --with-openssl
```

#### 4.3 Compile & Install
```bash
# Compile using all available CPU cores
sudo make -j$(nproc)

# Install binaries to /usr/local/freeswitch
sudo make install
```

---

### Step 5: Install Sound Prompts & Music on Hold (MOH)
FreeSWITCH includes automated targets to download standard voice prompts and audio:

```bash
cd /usr/src/freeswitch
sudo make cd-sounds-install
sudo make cd-moh-install
```

---

### Step 6: User Permissions & Systemd Service

#### 6.1 Create Dedicated FreeSWITCH User
```bash
sudo groupadd freeswitch
sudo useradd -r -g freeswitch -s /bin/false -c "FreeSWITCH Telephony Engine" -d /usr/local/freeswitch freeswitch
sudo chown -R freeswitch:freeswitch /usr/local/freeswitch
sudo chmod -R u=rwx,g=rx /usr/local/freeswitch
```

#### 6.2 Create Symlinks for CLI Access
```bash
sudo ln -sf /usr/local/freeswitch/bin/freeswitch /usr/bin/freeswitch
sudo ln -sf /usr/local/freeswitch/bin/fs_cli /usr/bin/fs_cli
```

#### 6.3 Setup Systemd Service
Create `/etc/systemd/system/freeswitch.service`:

```ini
[Unit]
Description=FreeSWITCH Telephony Server
After=syslog.target network.target local-fs.target

[Service]
Type=forking
PIDFile=/usr/local/freeswitch/run/freeswitch.pid
User=freeswitch
Group=freeswitch
ExecStart=/usr/local/freeswitch/bin/freeswitch -u freeswitch -g freeswitch -ncwait -nonat
ExecStop=/usr/local/freeswitch/bin/freeswitch -stop
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
```

Enable and start the service:
```bash
sudo systemctl daemon-reload
sudo systemctl enable freeswitch
sudo systemctl start freeswitch
```

---

## 4. Dockerized Setup (Recommended)

Docker provides an isolated, reproducible container without polluting your host operating system.

### Complete Dockerfile
Save as `Dockerfile`:

```dockerfile
FROM debian:12-slim

ENV DEBIAN_FRONTEND=noninteractive

# 1. Install prerequisites
RUN apt-get update && apt-get install -y \
    git \
    wget \
    curl \
    sudo \
    nano \
    vim \
    ca-certificates \
    gnupg \
    build-essential \
    pkg-config \
    autoconf \
    automake \
    libtool \
    libtool-bin \
    cmake \
    libssl-dev \
    libcurl4-openssl-dev \
    libpcre2-dev \
    libspeexdsp-dev \
    libedit-dev \
    libsqlite3-dev \
    libldns-dev \
    libsndfile1-dev \
    libopus-dev \
    libmpg123-dev \
    libshout3-dev \
    libmp3lame-dev \
    libavformat-dev \
    libswscale-dev \
    libavutil-dev \
    libswresample-dev \
    liblua5.4-dev \
    libjpeg-dev \
    zlib1g-dev \
    libtiff-dev \
    libogg-dev \
    libvorbis-dev \
    && rm -rf /var/lib/apt/lists/*

# 2. Build libks
WORKDIR /usr/src
RUN git clone https://github.com/signalwire/libks.git && \
    cd libks && \
    cmake . -DCMAKE_INSTALL_PREFIX=/usr -DWITH_LIBATOMIC=ON && \
    make -j$(nproc) && \
    make install

# 3. Build sofia-sip
WORKDIR /usr/src
RUN git clone https://github.com/freeswitch/sofia-sip.git && \
    cd sofia-sip && \
    ./bootstrap.sh && \
    ./configure --prefix=/usr && \
    make -j$(nproc) && \
    make install

# 4. Build spandsp
WORKDIR /usr/src
RUN git clone https://github.com/freeswitch/spandsp.git && \
    cd spandsp && \
    ./bootstrap.sh && \
    ./configure --prefix=/usr && \
    make -j$(nproc) && \
    make install && \
    ldconfig

# 5. Build FreeSWITCH
WORKDIR /usr/src
RUN git clone -b v1.10 https://github.com/signalwire/freeswitch.git && \
    cd freeswitch && \
    ./bootstrap.sh -j && \
    ./configure --prefix=/usr/local/freeswitch --enable-core-pgsql-support=no --with-openssl && \
    make -j$(nproc) && \
    make install && \
    make cd-sounds-install && \
    make cd-moh-install

# 6. Setup Path & Environment
ENV PATH="/usr/local/freeswitch/bin:${PATH}"

WORKDIR /usr/local/freeswitch

EXPOSE 5060/tcp 5060/udp 5080/tcp 5080/udp 8021/tcp 16384-32768/udp

CMD ["freeswitch", "-nonat", "-c"]
```

---

### Docker Compose Configuration
Save as `docker-compose.yml`:

```yaml
services:
  freeswitch:
    image: my-freeswitch-image:latest
    build:
      context: .
      dockerfile: Dockerfile
    container_name: freeswitch-learning
    network_mode: host
    restart: unless-stopped
    tty: true
    stdin_open: true
```

---

### Building & Running with Docker

```bash
# 1. Build the Docker image
docker compose build

# 2. Run container in detached mode
docker compose up -d

# 3. Check logs
docker compose logs -f

# 4. Access FreeSWITCH CLI inside the container
docker exec -it freeswitch-learning fs_cli
```

---

## 5. Basic Verification & CLI Usage

### Accessing FreeSWITCH Console
Run `fs_cli` to enter the interactive console:
```bash
fs_cli
```

### Useful CLI Commands:
| Command | Action |
| :--- | :--- |
| `status` | Shows server uptime, current sessions, and CPU load. |
| `sofia status` | Lists active SIP profiles (e.g. `internal`, `external`). |
| `sofia status profile internal` | Detailed view of internal SIP profile (port 5060). |
| `show channels` | Shows active active calls / channels. |
| `reloadxml` | Reloads XML configuration (dialplans, directory, profiles) without restart. |
| `version` | Displays compiled FreeSWITCH version. |
| `...` or `exit` / `quit` | Exits `fs_cli`. |

---

## 6. Troubleshooting & Common Errors

### 1. `sofia-sip` or `libks` not found during `./configure`
Ensure you ran `sudo ldconfig` after installing `libks` and `sofia-sip`. Also check `pkg-config --modversion sofia-sip-ua`.

### 2. Port Conflicts (5060 / 5080)
If FreeSWITCH fails to bind to port 5060, check if another service (like Asterisk or an existing FreeSWITCH instance) is using the port:
```bash
sudo netstat -tulpn | grep -E '5060|5080'
```

### 3. File Permissions
If FreeSWITCH cannot write logs or read recordings:
```bash
sudo chown -R freeswitch:freeswitch /usr/local/freeswitch
```
