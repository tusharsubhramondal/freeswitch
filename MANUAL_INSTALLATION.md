# FreeSWITCH Manual Installation Guide (Debian 12)

This document provides a complete, step-by-step manual installation guide for compiling and installing **FreeSWITCH 1.10** from source on **Debian 12 (Bookworm)** or inside any Debian 12 Docker/VM environment.

---

## Table of Contents
1. [Quick All-in-One Script](#1-quick-all-in-one-script)
2. [Step-by-Step Walkthrough](#2-step-by-step-walkthrough)
   - [Step 1: Update & Install Prerequisites](#step-1-update--install-prerequisites)
   - [Step 2: Build & Install `libks`](#step-2-build--install-libks)
   - [Step 3: Build & Install `sofia-sip`](#step-3-build--install-sofia-sip)
   - [Step 4: Build & Install `spandsp`](#step-4-build--install-spandsp)
   - [Step 5: Download & Compile FreeSWITCH](#step-5-download--compile-freeswitch)
   - [Step 6: Install Sounds & Music-on-Hold (MOH)](#step-6-install-sounds--music-on-hold-moh)
   - [Step 7: System Paths & Permissions](#step-7-system-paths--permissions)
3. [Starting & Verifying FreeSWITCH](#3-starting--verifying-freeswitch)
4. [Creating a Systemd Service (Optional)](#4-creating-a-systemd-service-optional)
5. [Useful `fs_cli` Commands](#5-useful-fs_cli-commands)

---

## 1. Quick All-in-One Script

If you want to run the entire manual installation sequence automatically, copy and paste this entire block into your terminal as `root`:

```bash
#!/bin/bash
set -e

echo "=== 1. Installing System Dependencies ==="
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
    libvorbis-dev

export PKG_CONFIG_PATH="/usr/lib/pkgconfig:/usr/local/lib/pkgconfig:$PKG_CONFIG_PATH"

echo "=== 2. Building libks ==="
cd /usr/src
rm -rf libks
git clone https://github.com/signalwire/libks.git
cd libks
cmake . -DCMAKE_INSTALL_PREFIX=/usr -DWITH_LIBATOMIC=ON
make -j$(nproc)
make install
ldconfig

echo "=== 3. Building sofia-sip ==="
cd /usr/src
rm -rf sofia-sip
git clone https://github.com/freeswitch/sofia-sip.git
cd sofia-sip
./bootstrap.sh
./configure --prefix=/usr
make -j$(nproc)
make install
ldconfig

echo "=== 4. Building spandsp ==="
cd /usr/src
rm -rf spandsp
git clone https://github.com/freeswitch/spandsp.git
cd spandsp
./bootstrap.sh
./configure --prefix=/usr
make -j$(nproc)
make install
ldconfig

echo "=== 5. Building FreeSWITCH ==="
cd /usr/src
rm -rf freeswitch
git clone -b v1.10 https://github.com/signalwire/freeswitch.git
cd freeswitch
./bootstrap.sh -j
sed -i 's|applications/mod_signalwire|#applications/mod_signalwire|g' modules.conf
./configure --prefix=/usr/local/freeswitch --enable-core-pgsql-support=no --with-openssl
make -j$(nproc)
make install
make cd-sounds-install
make cd-moh-install

echo "=== 6. Setting up symlinks ==="
ln -sf /usr/local/freeswitch/bin/freeswitch /usr/bin/freeswitch
ln -sf /usr/local/freeswitch/bin/fs_cli /usr/bin/fs_cli

echo "=== Installation Completed Successfully! ==="
```

---

## 2. Step-by-Step Walkthrough

If you prefer to run and understand each command individually, follow these steps:

### Step 1: Update & Install Prerequisites
Install all essential build tools, compilers, assemblers, and media codec libraries:

```bash
apt-get update && apt-get upgrade -y
apt-get install -y \
    git build-essential autoconf automake libtool libtool-bin pkg-config cmake \
    nasm yasm uuid-dev libpcre3-dev libssl-dev libcurl4-openssl-dev libspeexdsp-dev \
    libedit-dev libsqlite3-dev libldns-dev libsndfile1-dev libopus-dev libmpg123-dev \
    libshout3-dev libmp3lame-dev libavformat-dev libswscale-dev libavutil-dev \
    libswresample-dev liblua5.4-dev libjpeg-dev zlib1g-dev libtiff-dev libogg-dev libvorbis-dev
```

Set the package configuration path:
```bash
export PKG_CONFIG_PATH="/usr/lib/pkgconfig:/usr/local/lib/pkgconfig:$PKG_CONFIG_PATH"
```

---

### Step 2: Build & Install `libks`
`libks` is SignalWire’s foundational cross-platform C utility library.

```bash
cd /usr/src
git clone https://github.com/signalwire/libks.git
cd libks
cmake . -DCMAKE_INSTALL_PREFIX=/usr -DWITH_LIBATOMIC=ON
make -j$(nproc)
make install
ldconfig
```

---

### Step 3: Build & Install `sofia-sip`
`sofia-sip` provides the RFC-compliant SIP signaling stack used by `mod_sofia`.

```bash
cd /usr/src
git clone https://github.com/freeswitch/sofia-sip.git
cd sofia-sip
./bootstrap.sh
./configure --prefix=/usr
make -j$(nproc)
make install
ldconfig
```

---

### Step 4: Build & Install `spandsp`
`spandsp` provides DSP functions, tone detection, and T.30/T.38 Fax capabilities.

```bash
cd /usr/src
git clone https://github.com/freeswitch/spandsp.git
cd spandsp
./bootstrap.sh
./configure --prefix=/usr
make -j$(nproc)
make install
ldconfig
```

---

### Step 5: Download & Compile FreeSWITCH

#### 5.1 Clone FreeSWITCH v1.10
```bash
cd /usr/src
git clone -b v1.10 https://github.com/signalwire/freeswitch.git
cd freeswitch
```

#### 5.2 Bootstrap Build Scripts
```bash
./bootstrap.sh -j
```

#### 5.3 Disable unnecessary modules (e.g. `mod_signalwire`)
To avoid extra external cloud dependencies, comment out `mod_signalwire` in `modules.conf`:
```bash
sed -i 's|applications/mod_signalwire|#applications/mod_signalwire|g' modules.conf
```

#### 5.4 Configure
```bash
./configure --prefix=/usr/local/freeswitch \
            --enable-core-pgsql-support=no \
            --with-openssl
```

#### 5.5 Compile & Install
```bash
make -j$(nproc)
make install
```

---

### Step 6: Install Sounds & Music-on-Hold (MOH)
Download and install default 8kHz/16kHz/32kHz/48kHz sound prompts and hold music:

```bash
cd /usr/src/freeswitch
make cd-sounds-install
make cd-moh-install
```

---

### Step 7: System Paths & Permissions

#### Create Symlinks for easy global access:
```bash
ln -sf /usr/local/freeswitch/bin/freeswitch /usr/bin/freeswitch
ln -sf /usr/local/freeswitch/bin/fs_cli /usr/bin/fs_cli
```

#### (Optional) Create a dedicated non-root user:
```bash
groupadd freeswitch
useradd -r -g freeswitch -s /bin/false -d /usr/local/freeswitch freeswitch
chown -R freeswitch:freeswitch /usr/local/freeswitch
chmod -R u=rwx,g=rx /usr/local/freeswitch
```

---

## 3. Starting & Verifying FreeSWITCH

### Run in Foreground (Console Mode)
To start FreeSWITCH interactively and see live logs:
```bash
freeswitch -nonat -c
```

### Run in Background (Daemon Mode)
```bash
freeswitch -nonat -nc
```

### Connect to CLI Console
Once running in the background, connect to it using:
```bash
fs_cli
```
*(To exit `fs_cli`, type `/exit` or `...` and press Enter).*

### Stop FreeSWITCH
```bash
freeswitch -stop
```

---

## 4. Creating a Systemd Service (Optional)

If running on a native Linux server / VM (systemd), create `/etc/systemd/system/freeswitch.service`:

```ini
[Unit]
Description=FreeSWITCH Telephony Server
After=syslog.target network.target local-fs.target

[Service]
Type=forking
PIDFile=/usr/local/freeswitch/run/freeswitch.pid
ExecStart=/usr/local/freeswitch/bin/freeswitch -ncwait -nonat
ExecStop=/usr/local/freeswitch/bin/freeswitch -stop
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
```

Reload and start:
```bash
systemctl daemon-reload
systemctl enable freeswitch
systemctl start freeswitch
systemctl status freeswitch
```

---

## 5. Useful `fs_cli` Commands

| Command | Description |
| :--- | :--- |
| `status` | Shows system uptime, current sessions, CPS, and memory load. |
| `sofia status` | Displays all SIP profiles (`internal`, `external`, etc.). |
| `sofia status profile internal` | Detailed view of the internal SIP profile (port 5060). |
| `sofia status profile external` | Detailed view of the external SIP profile (port 5080). |
| `show channels` | Shows all active calls/channels. |
| `show calls` | Shows current call routing state. |
| `reloadxml` | Reloads all XML dialplans, directories, and configs without restarting FreeSWITCH. |
| `version` | Displays installed FreeSWITCH version. |
| `shutdown` | Gracefully terminates FreeSWITCH. |
