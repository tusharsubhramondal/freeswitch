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

Copy and paste this entire block into your terminal as `root`:

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
    libvorbis-dev \
    libvpx-dev \
    libpq-dev

export PKG_CONFIG_PATH="/usr/lib/pkgconfig:/usr/local/lib/pkgconfig:/usr/lib/x86_64-linux-gnu/pkgconfig:$PKG_CONFIG_PATH"

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

# Adjust module list for clean Debian 12 compilation
sed -i 's|applications/mod_signalwire|#applications/mod_signalwire|g' modules.conf
sed -i 's|applications/mod_spandsp|#applications/mod_spandsp|g' modules.conf
sed -i 's|databases/mod_pgsql|#databases/mod_pgsql|g' modules.conf

./configure --prefix=/usr/local/freeswitch \
            --enable-core-pgsql-support=no \
            --with-openssl \
            --disable-libvpx

make -j$(nproc)
make install
make samples-conf
make cd-sounds-install
make cd-moh-install

echo "=== 6. Setting Up CLI Symlinks ==="
ln -sf /usr/local/freeswitch/bin/freeswitch /usr/bin/freeswitch
ln -sf /usr/local/freeswitch/bin/fs_cli /usr/bin/fs_cli

echo "=== Installation Completed Successfully! ==="
```

---

## 2. Step-by-Step Walkthrough

### Step 1: Update & Install Prerequisites
```bash
apt-get update && apt-get upgrade -y
apt-get install -y \
    git build-essential autoconf automake libtool libtool-bin pkg-config cmake \
    nasm yasm uuid-dev libpcre3-dev libssl-dev libcurl4-openssl-dev libspeexdsp-dev libedit-dev \
    libsqlite3-dev libldns-dev libsndfile1-dev libopus-dev libmpg123-dev \
    libshout3-dev libmp3lame-dev libavformat-dev libswscale-dev libavutil-dev \
    libswresample-dev liblua5.4-dev libjpeg-dev zlib1g-dev libtiff-dev libogg-dev libvorbis-dev \
    libvpx-dev libpq-dev
```

### Step 2: Build & Install `libks`
```bash
cd /usr/src
git clone https://github.com/signalwire/libks.git
cd libks
cmake . -DCMAKE_INSTALL_PREFIX=/usr -DWITH_LIBATOMIC=ON
make -j$(nproc)
make install
ldconfig
```

### Step 3: Build & Install `sofia-sip`
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

### Step 4: Build & Install `spandsp`
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

### Step 5: Download & Compile FreeSWITCH
```bash
cd /usr/src
git clone -b v1.10 https://github.com/signalwire/freeswitch.git
cd freeswitch

export PKG_CONFIG_PATH="/usr/lib/pkgconfig:/usr/local/lib/pkgconfig:/usr/lib/x86_64-linux-gnu/pkgconfig:$PKG_CONFIG_PATH"

./bootstrap.sh -j

sed -i 's|applications/mod_signalwire|#applications/mod_signalwire|g' modules.conf
sed -i 's|applications/mod_spandsp|#applications/mod_spandsp|g' modules.conf
sed -i 's|databases/mod_pgsql|#databases/mod_pgsql|g' modules.conf

./configure --prefix=/usr/local/freeswitch \
            --enable-core-pgsql-support=no \
            --with-openssl \
            --disable-libvpx

make -j$(nproc)
make install
```

### Step 6: Install Sounds & Music-on-Hold (MOH)
```bash
make samples-conf
make cd-sounds-install
make cd-moh-install
```

### Step 7: System Paths & Permissions
```bash
groupadd freeswitch
useradd -r -g freeswitch -s /bin/false -c "FreeSWITCH Telephony Server" -d /usr/local/freeswitch freeswitch
chown -R freeswitch:freeswitch /usr/local/freeswitch
chmod -R u=rwx,g=rx /usr/local/freeswitch

ln -sf /usr/local/freeswitch/bin/freeswitch /usr/bin/freeswitch
ln -sf /usr/local/freeswitch/bin/fs_cli /usr/bin/fs_cli
```

---

## 3. Server Lifecycle & Management

| Action | Location / Shell | Command |
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

## 4. Useful `fs_cli` Commands

Connect to the interactive CLI:
```bash
fs_cli
```

| Command | Action |
| :--- | :--- |
| `status` | Display system uptime, CPU usage, and session stats |
| `sofia status` | List active SIP profiles (internal 5060, external 5080) |
| `sofia status profile internal` | Detailed view of internal SIP profile (port 5060) |
| `reloadxml` | Reload all XML configuration files and dialplans |
| `show registrations` | Display all currently registered SIP user extensions |
| `show channels` | List active calls / channels |
| `fsctl shutdown` | Gracefully shut down the FreeSWITCH daemon |
| `/bye` or `Ctrl + D` | Exit `fs_cli` back to Linux shell |
