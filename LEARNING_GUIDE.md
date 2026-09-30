# FreeSWITCH Post-Installation & Softphone Connection Guide

This guide documents the exact steps and network fixes required to connect a SIP softphone (such as **MicroSIP** or **Zoiper**) to a newly compiled FreeSWITCH server running in **Docker on Windows**.

---

## 📋 Table of Contents
1. [Overview of the Connection Challenges](#1-overview-of-the-connection-challenges)
2. [Step-by-Step Fixes Applied](#2-step-by-step-fixes-applied)
   - [Fix 1: Docker Desktop Port Mapping](#fix-1-docker-desktop-port-mapping)
   - [Fix 2: Setting the SIP Domain in `vars.xml`](#fix-2-setting-the-sip-domain-in-varsxml)
   - [Fix 3: Event Socket IPv4 Binding](#fix-3-event-socket-ipv4-binding)
3. [MicroSIP Configuration Guide](#3-microsip-configuration-guide)
4. [Testing Your FreeSWITCH Connection](#4-testing-your-freeswitch-connection)
5. [Useful Verification Commands (`fs_cli`)](#5-useful-verification-commands-fs_cli)

---

## 1. Overview of the Connection Challenges

After a fresh FreeSWITCH build inside Docker on Windows, two major hurdles prevent softphones from connecting to `127.0.0.1:5060`:

| Issue | Root Cause | Symptom |
| :--- | :--- | :--- |
| **Docker Host Networking** | On Windows, `network_mode: host` runs inside the hidden WSL2 Linux VM, meaning ports are **not published to Windows localhost**. | Softphones show *"Connection timeout"* / *"Could not connect to server"*. |
| **Domain Auto-Discovery** | FreeSWITCH auto-discovers external/WAN IPs and sets `$${domain}` to that IP instead of `127.0.0.1`. | Softphones get `403 Forbidden` or `404 Not Found` upon SIP registration. |
| **IPv6 Event Socket** | Default `event_socket.conf.xml` binds to `::` (IPv6), causing `fs_cli` connection failures on IPv4-only networks. | `fs_cli` outputs `[ERROR] Error Connecting []`. |

---

## 2. Step-by-Step Fixes Applied

### Fix 1: Docker Desktop Port Mapping
In [`docker-compose.yml`](file:///c:/Users/tusha/Desktop/freeswitch/docker-compose.yml), replace `network_mode: host` with explicit port forwarding so Windows ports map directly into the container:

```yaml
services:
  freeswitch:
    image: my-freeswitch-image:latest
    container_name: freeswitch-learning

    ports:
      # SIP Signaling (Internal - Port 5060 for Softphones)
      - "5060:5060/tcp"
      - "5060:5060/udp"

      # SIP Signaling (External / Trunks - Port 5080)
      - "5080:5080/tcp"
      - "5080:5080/udp"

      # Event Socket Layer (fs_cli - Port 8021)
      - "8021:8021/tcp"

      # RTP Audio/Video Media Ports Range
      - "16384-16484:16384-16484/udp"
```

---

### Fix 2: Setting the SIP Domain in `vars.xml`
In [`conf/vars.xml`](file:///c:/Users/tusha/Desktop/freeswitch/conf/vars.xml), update the domain variables so FreeSWITCH accepts SIP registrations intended for `127.0.0.1`:

```xml
<!-- Set domain to 127.0.0.1 for local softphone registrations -->
<X-PRE-PROCESS cmd="set" data="domain=127.0.0.1"/>
<X-PRE-PROCESS cmd="set" data="domain_name=127.0.0.1"/>
```

---

### Fix 3: Event Socket IPv4 Binding
In [`conf/autoload_configs/event_socket.conf.xml`](file:///c:/Users/tusha/Desktop/freeswitch/conf/autoload_configs/event_socket.conf.xml), update `listen-ip` to bind to all IPv4 interfaces:

```xml
<configuration name="event_socket.conf" description="Socket Client">
  <settings>
    <param name="nat-map" value="false"/>
    <param name="listen-ip" value="0.0.0.0"/>
    <param name="listen-port" value="8021"/>
    <param name="password" value="ClueCon"/>
  </settings>
</configuration>
```

---

## 3. MicroSIP Configuration Guide

Open **MicroSIP**, click the top-right menu **▼** ➡️ **Add Account**, and configure:

| Field | Value | Notes |
| :--- | :--- | :--- |
| **Account Name** | `1000` | Friendly name for the account |
| **SIP Server** | `127.0.0.1:5060` | FreeSWITCH internal SIP port |
| **SIP Proxy** | *(Leave Blank)* | Not needed for direct connection |
| **User** | `1000` | Default pre-configured extension |
| **Domain** | `127.0.0.1` | Must match domain in `vars.xml` |
| **Login / Auth ID** | `1000` | Extension number |
| **Password** | `1234` | Default FreeSWITCH user password |
| **Display Name** | `Extension 1000` | Caller ID name |
| **Media Encryption** | `Disabled` | Set to Disabled for plain RTP |
| **Transport** | `UDP` | Standard VoIP signaling transport |

👉 Click **Save**. The status indicator in the bottom-left will turn **🟢 Online**.

---

## 4. Testing Your FreeSWITCH Connection

Once MicroSIP displays **Online**, dial these built-in test extensions:

### 1. Echo Test (`9196`)
* **Action**: Dial `9196` and press Call.
* **What happens**: The server answers and echoes back whatever you speak into your microphone in real time.
* **Purpose**: Tests bi-directional RTP audio streams and latency.

### 2. Music on Hold (`9198`)
* **Action**: Dial `9198` and press Call.
* **What happens**: Plays high-definition Music on Hold (8kHz/16kHz/32kHz/48kHz audio streams).
* **Purpose**: Verifies audio codec decoding (Opus, PCMU, PCMA).

### 3. Interactive Voice Menu (`5000`)
* **Action**: Dial `5000` and press Call.
* **What happens**: The automated demo IVR welcomes you and invites you to press DTMF digits (`1`, `2`, `3`).
* **Purpose**: Tests IVR routing, DTMF detection, and sound prompt playback.

---

## 5. Useful Verification Commands (`fs_cli`)

Open the FreeSWITCH console:
```bash
docker exec -it freeswitch-learning fs_cli
```

Inside `fs_cli`:

```text
# 1. Verify softphone registration:
show registrations

# 2. View active SIP channels and live calls:
show channels
show calls

# 3. Reload XML configs after editing files:
reloadxml

# 4. Check SIP profile status:
sofia status
```
