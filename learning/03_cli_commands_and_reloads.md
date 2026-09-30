# Chapter 03: CLI Commands, Live Logs & Reload Matrix

This chapter covers how to interact with FreeSWITCH via `fs_cli`, view live real-time logs, and understand the reload matrix (`reloadxml` vs restarts).

---

## 1. Connecting to the FreeSWITCH CLI (`fs_cli`)

`fs_cli` connects to FreeSWITCH's Event Socket on port `8021`.

### To Open the Interactive Shell:
```powershell
docker exec -it freeswitch-learning fs_cli
```

### To Run a Single Command and Exit Immediately:
```powershell
docker exec freeswitch-learning /usr/local/freeswitch/bin/fs_cli -x "status"
```

To exit an active `fs_cli` session: Type `/exit` or `...` or press `Ctrl + C`.

---

## 2. Configuration Reload Matrix

Use this table to know what command to run after modifying any file:

| What File You Modified | Command to Apply | Why / What Happens |
| :--- | :--- | :--- |
| **Dialplans** (`default.xml`, `public.xml`) | `reloadxml` | Re-parses XML dialplan rules in memory without dropping any active calls. |
| **Users / Directory** (`1000.xml`, `1001.xml`) | `reloadxml` | Updates credentials, authorization passwords, and user context mappings. |
| **SIP Profiles & Gateways** (`internal.xml`, `external.xml`) | `reloadxml`<br>then `sofia profile internal restart` | Reloads XML, then restarts the Sofia SIP listener to apply new ports, IPs, or NAT flags. |
| **ACL Network Lists** (`acl.conf.xml`) | `reloadxml`<br>then `reloadacl` | Rebuilds IP access control whitelist/blacklist tables. |
| **Core Switch Settings** (`switch.conf.xml`, RTP port ranges) | `docker restart freeswitch-learning` | Core engine port ranges are allocated during initial boot; requires container restart. |

---

## 3. Essential `fs_cli` Cheat-Sheet

### User Registrations & Channels:
```text
show registrations                       # Lists all registered softphones (User, IP, Port, Status)
show channels                            # Shows all active call channels currently open
show calls                               # Shows detailed call count, legs, and duration
```

### SIP Stack Inspection (Sofia):
```text
sofia status                             # Lists all loaded SIP profiles and their bind ports
sofia status profile internal            # Shows internal profile details (IP, Codecs, NAT, Calls count)
sofia status profile internal reg        # Shows all softphones registered to the internal profile
sofia profile internal restart           # Restarts the internal SIP profile listener
```

### SIP Packet Debugging:
```text
sofia profile internal siptrace on       # Prints all raw SIP INVITE, 200 OK, ACK packets in console
sofia profile internal siptrace off      # Turns off raw SIP packet debugging
```

### Controlling Console Log Levels:
```text
log 7                                    # Debug Level (Shows everything including RTP, state machine)
log 6                                    # Info Level (Clean standard logs, call start/stop)
log 4                                    # Warning Level
log 3                                    # Error Level
log 0                                    # Mutes all logs in the console
```

---

## 4. How to Continuously Watch Live Logs

You have 3 ways to live stream logs on Windows:

### Option 1: Interactive Console (Recommended)
```powershell
docker exec -it freeswitch-learning fs_cli
```

### Option 2: Live File Tail in PowerShell
Because `./logs/` is mounted to Windows, you can stream the log file directly:
```powershell
Get-Content -Path .\logs\freeswitch.log -Wait -Tail 50
```

### Option 3: Docker Log Stream
```powershell
docker compose logs -f
```

---

👉 Next: Continue to **[Chapter 04: Core Architecture - The 3 Pillars](file:///c:/Users/tusha/Desktop/freeswitch/learning/04_core_architecture_3_pillars.md)**
