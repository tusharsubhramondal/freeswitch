# Chapter 01: Installation & Docker Architecture

This chapter explains how FreeSWITCH is built, containerized with Docker on Windows, how networking works, and how your host files synchronize with the container.

---

## 1. Why Run FreeSWITCH in Docker?

FreeSWITCH is natively built for Linux (Debian/Ubuntu). Running FreeSWITCH inside a Debian 12 Docker container gives you:
- **Full Linux Performance & Modules**: Native C/C++ audio processing, Sofia-SIP, Opus, and PostgreSQL modules.
- **Isolated Environment**: No dependency conflicts with your host Windows system.
- **Instant Reproducibility**: Bring up or rebuild the entire telephony PBX with `docker compose up -d`.

---

## 2. Docker Networking Architecture (Windows / Docker Desktop)

On Windows, Docker Desktop runs inside a hidden WSL2 Linux VM. This introduces specific networking characteristics:

```
 ┌────────────────────────────────────────────────────────┐
 │                     WINDOWS HOST                       │
 │  • Softphone (MicroSIP) running on 127.0.0.1           │
 │  • Local IP: 172.20.10.x or 192.168.x.x                │
 └────────────────────────────────────────────────────────┘
                            │
               [Docker Port Forwarding]
               5060/udp, 5080/udp, 8021/tcp, 16384-16484/udp
                            ▼
 ┌────────────────────────────────────────────────────────┐
 │            DOCKER CONTAINER (freeswitch-learning)      │
 │  • Linux Debian 12                                     │
 │  • Container Internal IP: 172.19.0.x                   │
 │  • FreeSWITCH Service listening on 0.0.0.0             │
 └────────────────────────────────────────────────────────┘
```

> **Key Takeaway:** Because `network_mode: host` does NOT publish ports to Windows localhost, you must use **explicit port mapping** in `docker-compose.yml`.

---

## 3. The `docker-compose.yml` Ports Explained

Here is what each published port does:

```yaml
services:
  freeswitch:
    image: my-freeswitch-image:latest
    container_name: freeswitch-learning
    command: /usr/local/freeswitch/bin/freeswitch -nf -nonat

    ports:
      # SIP Signaling (Internal Profile - Port 5060 for Softphones)
      - "5060:5060/tcp"
      - "5060:5060/udp"

      # SIP Signaling (External Profile - Port 5080 for SIP Trunks & Carriers)
      - "5080:5080/tcp"
      - "5080:5080/udp"

      # Event Socket Layer (Port 8021 for fs_cli & Remote Control)
      - "8021:8021/tcp"

      # RTP Media Range (Audio/Video Streams)
      - "16384-16484:16384-16484/udp"
```

| Port | Protocol | Purpose |
| :--- | :--- | :--- |
| **5060** | UDP/TCP | SIP Registration & Call Signaling for softphones (MicroSIP, Zoiper). |
| **5080** | UDP/TCP | SIP Signaling for external telecom carriers, gateways, and PSTN. |
| **8021** | TCP | FreeSWITCH Event Socket Protocol (used by `fs_cli` and Python/Node.js ESL scripts). |
| **16384–16484** | UDP | RTP (Real-Time Transport Protocol) for voice and video payload. |

---

## 4. Volume Mounts & File Synchronization

Docker volume mounts link your Windows project directory to FreeSWITCH inside Linux:

```yaml
    volumes:
      # Configurations (XML dialplans, SIP profiles, users)
      - ./conf:/usr/local/freeswitch/etc/freeswitch

      # Logs (freeswitch.log)
      - ./logs:/usr/local/freeswitch/var/log/freeswitch

      # Sounds (Audio prompts, Music on Hold)
      - ./sounds:/usr/local/freeswitch/share/freeswitch/sounds

      # Call Recordings
      - ./recordings:/usr/local/freeswitch/var/lib/freeswitch/recordings

      # Databases (SQLite core databases)
      - ./db:/usr/local/freeswitch/var/lib/freeswitch/db

      # Voicemail & Storage
      - ./storage:/usr/local/freeswitch/var/lib/freeswitch/storage
```

### Why Compiled Binaries Aren't on Windows:
- The Linux executables (`/usr/local/freeswitch/bin/`) and shared `.so` libraries (`/usr/local/freeswitch/lib/`) stay **inside the container**.
- Your Windows host only holds the **configurations, logs, and media assets** that you actively edit.

---

---

## 6. MySQL / MariaDB Database Integration via ODBC

Instead of using SQLite, FreeSWITCH can store its core channels, calls, interfaces, and Sofia registrations in MySQL (e.g. XAMPP / phpMyAdmin on Windows).

### 6.1 Networking & ODBC Configuration
Inside the container, `unixODBC` connects to Windows MySQL via `host.docker.internal`:

```ini
# /etc/odbc.ini
[freeswitch-mysql]
Description = FreeSWITCH MySQL Database
Driver = MariaDB Unicode
Server = host.docker.internal
Port = 3306
Database = freeswitch
User = root
Password = 
```

### 6.2 FreeSWITCH `switch.conf.xml` Setting:
```xml
<param name="core-db-dsn" value="freeswitch-mysql:root:" />
<param name="odbc-skip-autocommit-flip" value="true" />
<param name="auto-create-schemas" value="true"/>
```

---

## 7. Critical Troubleshooting: MySQL / MariaDB Row Size Gotcha (Error 1118)

### The Issue:
When FreeSWITCH automatically creates tables in MySQL/MariaDB with `utf8mb4` character set, columns with `VARCHAR(4096)` exceed MySQL's maximum row size of 65,535 bytes:
```text
[STATE: 42000 CODE 1118 ERROR: Row size too large. The maximum row size for the used table type, not counting BLOBs, is 65535]
```
This causes FreeSWITCH to freeze in an infinite restart loop and prevents `mod_event_socket` / `fs_cli` from starting.

### The Fix:
Create the tables in MySQL using `TEXT` for large payload columns and `ROW_FORMAT=DYNAMIC`:

```sql
USE freeswitch;

CREATE TABLE IF NOT EXISTS channels (
   uuid  VARCHAR(255),
   direction  VARCHAR(32),
   created  VARCHAR(128),
   created_epoch  INTEGER,
   name  VARCHAR(512),
   state  VARCHAR(64),
   cid_name  VARCHAR(512),
   cid_num  VARCHAR(255),
   ip_addr  VARCHAR(255),
   dest  VARCHAR(512),
   application  VARCHAR(128),
   application_data  TEXT,
   dialplan VARCHAR(128),
   context VARCHAR(128),
   read_codec  VARCHAR(128),
   read_rate  VARCHAR(32),
   read_bit_rate  VARCHAR(32),
   write_codec  VARCHAR(128),
   write_rate  VARCHAR(32),
   write_bit_rate  VARCHAR(32),
   secure VARCHAR(64),
   hostname VARCHAR(255),
   presence_id TEXT,
   presence_data TEXT,
   accountcode VARCHAR(255),
   callstate  VARCHAR(64),
   callee_name  VARCHAR(512),
   callee_num  VARCHAR(255),
   callee_direction  VARCHAR(5),
   call_uuid  VARCHAR(255),
   sent_callee_name  VARCHAR(512),
   sent_callee_num  VARCHAR(255),
   initial_cid_name  VARCHAR(512),
   initial_cid_num  VARCHAR(255),
   initial_ip_addr  VARCHAR(255),
   initial_dest  VARCHAR(512),
   initial_dialplan  VARCHAR(128),
   initial_context  VARCHAR(128)
) ENGINE=InnoDB ROW_FORMAT=DYNAMIC;

CREATE TABLE IF NOT EXISTS calls (
   call_uuid VARCHAR(255),
   call_created VARCHAR(128),
   call_created_epoch INTEGER,
   caller_uuid VARCHAR(255),
   callee_uuid VARCHAR(255),
   hostname VARCHAR(255)
) ENGINE=InnoDB ROW_FORMAT=DYNAMIC;

CREATE TABLE IF NOT EXISTS interfaces (
   type VARCHAR(128),
   name VARCHAR(512),
   description TEXT,
   ikey VARCHAR(512),
   filename TEXT,
   syntax TEXT,
   hostname VARCHAR(255)
) ENGINE=InnoDB ROW_FORMAT=DYNAMIC;

CREATE TABLE IF NOT EXISTS tasks (
   task_id INTEGER,
   task_desc TEXT,
   task_group VARCHAR(512),
   task_sql_manager INTEGER,
   hostname VARCHAR(255)
) ENGINE=InnoDB ROW_FORMAT=DYNAMIC;
```

---

## 8. Controlling the Container

| Action | PowerShell Command |
| :--- | :--- |
| **Start in background** | `docker compose up -d` |
| **Stop container** | `docker compose down` |
| **Restart container** | `docker restart freeswitch-learning` |
| **Enter container shell** | `docker exec -it freeswitch-learning bash` |
| **Open FreeSWITCH CLI** | `docker exec -it freeswitch-learning fs_cli` |

---

👉 Next: Continue to **[Chapter 02: Softphone Setup & NAT Audio Troubleshooting](file:///c:/Users/tusha/Desktop/freeswitch/learning/02_softphone_and_nat_troubleshoot.md)**
