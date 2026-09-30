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
   - [Step 5: Install Configurations, Sound Prompts & MOH](#step-5-install-configurations-sound-prompts--moh)
   - [Step 6: User Permissions & Systemd Service](#step-6-user-permissions--systemd-service)
4. [Dockerized Setup (Recommended)](#4-dockerized-setup-recommended)
   - [Docker Volume Strategy & Windows NTFS Gotcha](#docker-volume-strategy--windows-ntfs-gotcha)
   - [Docker Compose Configuration](#docker-compose-configuration)
   - [Building & Running with Docker](#building--running-with-docker)
5. [Basic Verification & CLI Usage](#5-basic-verification--cli-usage)
6. [Troubleshooting & Common Errors](#6-troubleshooting--common-errors)

---

## 1. Overview & Prerequisites

FreeSWITCH is a modular, scalable open-source telephony platform supporting WebRTC, SIP, audio/video transcoding, and call routing.

### System Requirements:
- **OS**: Debian 12 (Bookworm) / Ubuntu 22.04+ (or Docker Engine)
- **CPU**: 2+ Cores (4+ Cores recommended for parallel compilation)
- **RAM**: 2 GB Minimum (4 GB+ recommended during compilation)
- **Disk Space**: At least 10 GB free space

---

## 2. Dependency Reference

FreeSWITCH requires core build tools, cryptographic libraries, database drivers, audio/video codecs, and SignalWire foundational libraries (`sofia-sip`, `libks`).

```bash
apt-get update && apt-get install -y \
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
    libvorbis-dev \
    libvpx-dev \
    libpq-dev
```

---

## 3. Step-by-Step Native Build (Debian 12)

### Step 1: Install System Dependencies
Update system packages and install all prerequisites:

```bash
sudo apt-get update && sudo apt-get upgrade -y
sudo apt-get install -y \
    git build-essential autoconf automake libtool libtool-bin pkg-config cmake \
    nasm yasm uuid-dev libpcre3-dev libssl-dev libcurl4-openssl-dev libspeexdsp-dev libedit-dev \
    libsqlite3-dev libldns-dev libsndfile1-dev libopus-dev libmpg123-dev \
    libshout3-dev libmp3lame-dev libavformat-dev libswscale-dev libavutil-dev \
    libswresample-dev liblua5.4-dev libjpeg-dev zlib1g-dev libtiff-dev libogg-dev libvorbis-dev \
    libvpx-dev libpq-dev
```

---

### Step 2: Build SignalWire Dependencies (`libks` & `sofia-sip`)

Modern FreeSWITCH versions require SignalWire's `libks` (foundational C library) and `sofia-sip` (SIP signaling stack).

#### 2.1 Build & Install `libks`
```bash
cd /usr/src
sudo git clone https://github.com/signalwire/libks.git
cd libks
sudo cmake . -DCMAKE_INSTALL_PREFIX=/usr -DWITH_LIBATOMIC=ON
sudo make -j$(nproc)
sudo make install
sudo ldconfig
```

#### 2.2 Build & Install `sofia-sip`
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

### Step 3: Build & Install `spandsp` (DSP / Fax Library)

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
# Export library paths (including multiarch path for Debian 12)
export PKG_CONFIG_PATH=/usr/lib/pkgconfig:/usr/local/lib/pkgconfig:/usr/lib/x86_64-linux-gnu/pkgconfig:$PKG_CONFIG_PATH

# Generate build scripts
sudo ./bootstrap.sh -j

# Adjust modules.conf for clean Debian 12 build:
sudo sed -i 's|applications/mod_signalwire|#applications/mod_signalwire|g' modules.conf
sudo sed -i 's|applications/mod_spandsp|#applications/mod_spandsp|g' modules.conf
sudo sed -i 's|databases/mod_pgsql|#databases/mod_pgsql|g' modules.conf

# Configure FreeSWITCH build
sudo ./configure --prefix=/usr/local/freeswitch \
                 --enable-core-pgsql-support=no \
                 --with-openssl \
                 --disable-libvpx
```

#### 4.3 Compile & Install
```bash
# Compile using all available CPU cores in parallel
sudo make -j$(nproc)

# Install binaries to /usr/local/freeswitch
sudo make install
```

---

### Step 5: Install Configurations, Sound Prompts & MOH

```bash
cd /usr/src/freeswitch

# Install standard XML dialplans and configuration
sudo make samples-conf

# Install HD audio sound prompts (Callie) & Music on Hold (MOH)
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

### Docker Volume Strategy & Windows NTFS Gotcha

> [!IMPORTANT]
> When running Docker on Windows, compiling thousands of C files directly inside a Windows bind-mounted folder (`./src:/usr/src`) causes file-locking delays and permission errors on `mv` operations.
> 
> **Best Practice**: Copy source code to the container's native Linux filesystem (`/build/freeswitch`) for compilation, while keeping `./conf`, `./sounds`, `./logs`, and `./db` mounted to your host.

```bash
# Inside running container:
mkdir -p /build
cp -a /usr/src/freeswitch /build/
cd /build/freeswitch
./configure --prefix=/usr/local/freeswitch --enable-core-pgsql-support=no --with-openssl --disable-libvpx
make -j$(nproc)
make install
make samples-conf
make cd-sounds-install cd-moh-install
```

### Docker Compose Configuration
See [`docker-compose.yml`](file:///c:/Users/tusha/Desktop/freeswitch/docker-compose.yml) for full container definition with persistent host volumes.

---

## 5. Server Lifecycle & CLI Usage

### 5.1 Starting & Stopping FreeSWITCH

| Action | Where to Run | Command |
| :--- | :--- | :--- |
| **Start Server** | Linux Terminal | `freeswitch -nc` |
| **Stop Server** | Linux Terminal | `freeswitch -stop` |
| **Stop Server** | Inside `fs_cli` | `fsctl shutdown` |
| **Stop Server** | Windows PowerShell / CMD | `docker exec freeswitch-learning freeswitch -stop` |
| **Restart Server** | Linux Terminal | `freeswitch -stop && freeswitch -nc` |
| **Force Kill** | Linux Terminal | `pkill -9 -f freeswitch` |
| **Check Process** | Linux Terminal | `ps aux \| grep freeswitch` |
| **View Live Logs** | Linux Terminal | `tail -f /usr/local/freeswitch/var/log/freeswitch/freeswitch.log` |

---

### 5.2 Connecting to `fs_cli`

```bash
# Connect to FreeSWITCH CLI
fs_cli

# Inside fs_cli:
status                              # Check server uptime and load
sofia status                        # List active SIP profiles (internal 5060, external 5080)
sofia status profile internal       # Detailed view of internal SIP profile
reloadxml                           # Reload XML configuration without restarting
show registrations                  # List active registered softphones
show channels                       # List active calls
fsctl shutdown                      # Gracefully stop the FreeSWITCH server
/bye                                # Exit fs_cli back to shell
```

---

## 6. Troubleshooting & Common Errors

1. **`make[800]: Entering directory ...` (Recursive Make Loop)**
   - *Cause*: Running `make install` before running `make -j$(nproc)` causes `src/mod/Makefile` to loop infinitely looking for `libs/apr/config.status`.
   - *Fix*: Stop the build with `Ctrl+C`, run `make -j$(nproc)` first, and only then run `make install`.

2. **`vpx_scale/generic/vpx_scale.c.o Error 1`**
   - *Cause*: Older bundled `libvpx` is incompatible with newer GCC 12/13 on Debian 12.
   - *Fix*: Install `libvpx-dev` and pass `--disable-libvpx` to `./configure`.

3. **`You must install libpq-dev to build mod_pgsql`**
   - *Cause*: `mod_pgsql` is enabled by default in `modules.conf`.
   - *Fix*: Run `apt-get install -y libpq-dev` or comment out `databases/mod_pgsql` in `modules.conf`.

4. **`v18_init: too few arguments` in `mod_spandsp`**
   - *Cause*: API function signature change in the latest upstream SpanDSP repository.
   - *Fix*: Comment out `applications/mod_spandsp` in `modules.conf`.
