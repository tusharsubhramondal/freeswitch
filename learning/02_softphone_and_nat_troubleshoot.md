# Chapter 02: Softphone Setup & NAT Audio Troubleshooting

This chapter details how to connect a softphone (**MicroSIP**) to FreeSWITCH running in Docker, why the "No Voice / 1-Way Audio" bug occurs in Docker, and the exact configuration fixes required to resolve it.

---

## 1. MicroSIP Setup Guide

1. Download and install **[MicroSIP](https://www.microsip.org/)** (or any standard SIP client like Zoiper).
2. Open MicroSIP, click top-right menu **▼** ➡️ **Add Account**.
3. Fill in the following settings:

| Field | Value | Why |
| :--- | :--- | :--- |
| **Account Name** | `1000` | Friendly name for the profile |
| **SIP Server** | `127.0.0.1:5060` | Connects to FreeSWITCH internal SIP port on localhost |
| **SIP Proxy** | *(Leave Blank)* | Not needed for direct connection |
| **User** | `1000` | Pre-configured extension in FreeSWITCH directory |
| **Domain** | `127.0.0.1` | Must match `domain` defined in `vars.xml` |
| **Login / Auth ID** | `1000` | Authorization username |
| **Password** | `1234` | Default user password |
| **Display Name** | `Extension 1000` | Caller ID display name |
| **Media Encryption** | `Disabled` | Uses standard RTP media |
| **Transport** | `UDP` | Standard SIP signaling transport |

4. Click **Save**. The status bar at the bottom-left of MicroSIP will turn **🟢 Online**.

---

## 2. The "No Voice / 1-Way Audio" Bug in Docker

### The Problem:
When you make a call (such as dialing `9196` for Echo Test or `originate user/1000 &echo()`), the call connects, but **no voice is heard** in MicroSIP.

### Root Cause Analysis:
1. **Container Subnet Isolation**: FreeSWITCH inside Docker runs on a virtual bridge IP (e.g. `172.19.0.2`). MicroSIP runs on your Windows host (`127.0.0.1` or Wi-Fi IP `172.20.10.x`).
2. **The SDP IP Mismatch**: By default, FreeSWITCH's `nat.auto` and `localnet.auto` rules treat private RFC1918 IPs as "local LAN". FreeSWITCH wrongly tells MicroSIP in the SDP media answer: *"Send your microphone audio to `c=IN IP4 172.19.0.2`"*.
3. **Packet Dropping**: Windows does not route UDP packets to `172.19.0.2`, so all audio packets are dropped by Windows before leaving your computer.
4. **RTP Port Overflow**: If FreeSWITCH allocates a dynamic RTP port (e.g. `30472`) that falls outside Docker's published port range (`16384-16484`), Docker silently drops the UDP packets.

---

## 3. The 3-Step Permanent Fix

To ensure 100% bidirectional audio for all inbound and outbound calls, apply these 3 fixes:

### Step 1: Lock RTP Port Range in `conf/autoload_configs/switch.conf.xml`
In [`conf/autoload_configs/switch.conf.xml`](file:///c:/Users/tusha/Desktop/freeswitch/conf/autoload_configs/switch.conf.xml), restrict FreeSWITCH core to only allocate ports mapped in Docker:

```xml
<param name="rtp-start-port" value="16384"/>
<param name="rtp-end-port" value="16484"/>
```

---

### Step 2: Set External IPs to Localhost in `conf/vars.xml`
In [`conf/vars.xml`](file:///c:/Users/tusha/Desktop/freeswitch/conf/vars.xml), configure `$${external_rtp_ip}` and `$${external_sip_ip}`:

```xml
<X-PRE-PROCESS cmd="set" data="external_rtp_ip=127.0.0.1"/>
<X-PRE-PROCESS cmd="set" data="external_sip_ip=127.0.0.1"/>
```

---

### Step 3: Override NAT Classification in `conf/sip_profiles/internal.xml`
In [`conf/sip_profiles/internal.xml`](file:///c:/Users/tusha/Desktop/freeswitch/conf/sip_profiles/internal.xml):

```xml
<!-- 1. Disable nat.auto so RFC1918 IPs aren't treated as local container LAN -->
<!-- <param name="apply-nat-acl" value="nat.auto"/> -->

<!-- 2. Point local-network-acl to a non-matching list -->
<param name="local-network-acl" value="localnet"/>

<!-- 3. Enable aggressive NAT detection -->
<param name="aggressive-nat-detection" value="true"/>

<!-- 4. Force rport so audio returns to the forwarded Docker port -->
<param name="NDLB-force-rport" value="true"/>

<!-- 5. Set advertised SDP IPs -->
<param name="ext-rtp-ip" value="$${external_rtp_ip}"/>
<param name="ext-sip-ip" value="$${external_sip_ip}"/>
```

---

## 4. Testing & Verifying Audio

After applying the fixes and running `reloadxml` + `sofia profile internal restart`:

1. **Echo Test (`9196`)**: Dial `9196` in MicroSIP and speak into your microphone. You will hear your own voice echoed back instantly with zero latency.
2. **Milliwatt Tone Test (`9197`)**: Dial `9197` in MicroSIP. It immediately plays a continuous 1004Hz test tone to confirm your speakers/headset receive RTP audio.
3. **Originating from CLI**:
   ```bash
   docker exec -it freeswitch-learning fs_cli -x "originate user/1000 &echo()"
   ```

---

👉 Next: Continue to **[Chapter 03: CLI Commands, Live Logs & Reload Matrix](file:///c:/Users/tusha/Desktop/freeswitch/learning/03_cli_commands_and_reloads.md)**
