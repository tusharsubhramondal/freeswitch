# FreeSWITCH & MySQL (phpMyAdmin) Complete Setup Guide

A complete, step-by-step master guide for building, containerizing, and running **FreeSWITCH (v1.10)** with **MySQL / MariaDB (XAMPP / phpMyAdmin)** on **Debian 12 via Docker on Windows**.

---

## 🏗️ Architecture Overview

```
┌──────────────────────────────────────────────────────────────────────────────────┐
│                             WINDOWS HOST (Your PC)                               │
│  📁 ./src/   ── Mirrors into container (View, browse, & edit in Code Editor)     │
│  📁 ./conf/  ── Mounted to FreeSWITCH XML Dialplans & Configuration              │
│  🗄️ MySQL    ── XAMPP MySQL on port 3306 (phpMyAdmin at http://localhost/phpmyadmin)
└──────────────────────────────────────────────────────────────────────────────────┘
                                         │
                         (Docker Network Bridge: host.docker.internal)
                                         ▼
┌──────────────────────────────────────────────────────────────────────────────────┐
│                          DEBIAN 12 DOCKER CONTAINER                              │
│  📁 /usr/src/             ── Mirrors Windows ./src/ folder                       │
│  📁 /build/               ── Native Linux directory (Fast compilation, no locks) │
│  📁 /usr/local/freeswitch ── Installed FreeSWITCH runtime                        │
│  🔌 unixODBC              ── Communicates with Windows XAMPP MySQL               │
└──────────────────────────────────────────────────────────────────────────────────┘
```

---

## Phase 1: Windows Host Preparation

### 1.1 Start XAMPP MySQL & Create Database
1. Open XAMPP Control Panel and start **MySQL**.
2. Open your browser at **`http://localhost/phpmyadmin`**.
3. Click **New**, name the database **`freeswitch`**, collation `utf8mb4_unicode_ci`, and click **Create**.
4. Go to **SQL** tab and run this table schema (avoids MySQL row-size error `1118`):

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

### 1.2 Start Fresh Docker Container (Windows PowerShell)

In `c:\Users\tusha\Desktop\freeswitch`:

```powershell
# 1. Clean old container
docker compose down

# 2. Build image with ODBC support & launch
docker compose build --no-cache
docker compose up -d

# 3. Enter container shell
docker exec -it freeswitch-learning bash
```

---

## Phase 2: Inside Container — Clone Source Code into `src/`

Run inside the container (files appear immediately in your Windows editor):

```bash
cd /usr/src

# 1. Clone dependencies
git clone https://github.com/signalwire/libks.git
git clone https://github.com/freeswitch/sofia-sip.git
git clone https://github.com/freeswitch/spandsp.git

# 2. Clone FreeSWITCH Core (v1.10)
git clone -b v1.10 https://github.com/signalwire/freeswitch.git
```

---

## Phase 3: Inside Container — Build SignalWire Dependencies

```bash
# 1. Build & install libks
rm -rf /build/libks
cp -a /usr/src/libks /build/
cd /build/libks
cmake . -DCMAKE_INSTALL_PREFIX=/usr -DWITH_LIBATOMIC=ON
make -j$(nproc) && make install && ldconfig

# 2. Build & install sofia-sip
rm -rf /build/sofia-sip
cp -a /usr/src/sofia-sip /build/
cd /build/sofia-sip
./bootstrap.sh && ./configure --prefix=/usr
make -j$(nproc) && make install && ldconfig

# 3. Build & install spandsp
rm -rf /build/spandsp
cp -a /usr/src/spandsp /build/
cd /build/spandsp
./bootstrap.sh && ./configure --prefix=/usr
make -j$(nproc) && make install && ldconfig
```

---

## Phase 4: Inside Container — Build FreeSWITCH with Core ODBC

```bash
# 1. Copy fresh source to native build directory
rm -rf /build/freeswitch
cp -a /usr/src/freeswitch /build/
cd /build/freeswitch

# 2. Set library paths & bootstrap
export PKG_CONFIG_PATH=/usr/lib/pkgconfig:/usr/local/lib/pkgconfig:/usr/lib/x86_64-linux-gnu/pkgconfig:$PKG_CONFIG_PATH
./bootstrap.sh -j

# 3. Disable unsupported Debian 12 modules
sed -i 's|applications/mod_signalwire|#applications/mod_signalwire|g' modules.conf
sed -i 's|applications/mod_spandsp|#applications/mod_spandsp|g' modules.conf
sed -i 's|databases/mod_pgsql|#databases/mod_pgsql|g' modules.conf

# 4. Configure with ODBC support
./configure --prefix=/usr/local/freeswitch \
            --enable-core-odbc-support \
            --enable-core-pgsql-support=no \
            --with-openssl \
            --disable-libvpx

# 5. Build bundled APR & install libraries
cd /build/freeswitch/libs/apr
./configure --prefix=/usr/local/freeswitch
make -j$(nproc)
cp -a /build/freeswitch/libs/apr/.libs/libapr-1* /usr/lib/x86_64-linux-gnu/ 2>/dev/null || true
cp -a /build/freeswitch/libs/apr/.libs/libapr-1* /usr/lib/ 2>/dev/null || true
cp -a /build/freeswitch/libs/apr/.libs/libapr-1* /usr/local/lib/ 2>/dev/null || true
ldconfig

# 6. Build libsrtp & libyuv
cd /build/freeswitch/libs/srtp
CFLAGS="-fPIC" ./configure --prefix=/usr/local/freeswitch
make install
cp -a /build/freeswitch/libs/srtp/.libs/libsrtp* /usr/lib/x86_64-linux-gnu/ 2>/dev/null || true
cp -a /build/freeswitch/libs/srtp/.libs/libsrtp* /usr/lib/ 2>/dev/null || true
cp -a /build/freeswitch/libs/srtp/.libs/libsrtp* /usr/local/lib/ 2>/dev/null || true
ldconfig

cd /build/freeswitch
make libfreeswitch_libyuv.la

# 7. Compile & install FreeSWITCH + all modules
make -j$(nproc)
make install
make -C src/mod install
echo "/usr/local/freeswitch/lib" > /etc/ld.so.conf.d/freeswitch.conf
ln -sf /usr/local/freeswitch/etc/freeswitch /usr/local/freeswitch/conf
ldconfig

# 8. Create CLI symlinks
ln -sf /usr/local/freeswitch/bin/freeswitch /usr/bin/freeswitch
ln -sf /usr/local/freeswitch/bin/fs_cli /usr/bin/fs_cli
```

---

## Phase 5: Inside Container — Configure ODBC & `fs_cli`

```bash
# 1. Driver config
cat << 'EOF' > /etc/odbcinst.ini
[MariaDB Unicode]
Description = MariaDB Connector/ODBC(Unicode)
Driver = libmaodbc.so
Threading = 0
UsageCount = 1
EOF

# 2. DSN config (points to Windows XAMPP MySQL)
cat << 'EOF' > /etc/odbc.ini
[freeswitch-mysql]
Description = FreeSWITCH MySQL Database
Driver = MariaDB Unicode
Server = host.docker.internal
Port = 3306
Database = freeswitch
User = root
Password = 
EOF
chmod 644 /etc/odbc.ini /etc/odbcinst.ini

# 3. Create default fs_cli profile
cat << 'EOF' > /root/.fs_cli_conf
[default]
host => 127.0.0.1
port => 8021
password => ClueCon
debug => 7
EOF

# 4. Test ODBC connection
isql -v freeswitch-mysql root ""
```
*(Should output `Connected!`)*

---

## Phase 6: Verify Configuration & Start FreeSWITCH

### 6.1 Check `conf/autoload_configs/switch.conf.xml`
Ensure lines 184–196 have:
```xml
<param name="core-db-dsn" value="freeswitch-mysql:root:" />
<param name="odbc-skip-autocommit-flip" value="true" />
<param name="auto-create-schemas" value="true"/>
```

### 6.2 Check `conf/autoload_configs/pre_load_modules.conf.xml`
Ensure both are commented out:
```xml
<configuration name="pre_load_modules.conf" description="Modules">
  <modules>
    <!-- <load module="mod_mariadb"/> -->
    <!-- <load module="mod_pgsql"/> -->
  </modules>
</configuration>
```

---

### 6.3 Start FreeSWITCH & Connect to CLI

```bash
# 1. Start FreeSWITCH daemon in background
freeswitch -nc -nonat

# 2. Open CLI
fs_cli
```

Inside `fs_cli`:
```text
status
sofia status
show channels
```

---

## 📋 Common Operational Commands

| Task | Command |
| :--- | :--- |
| **Start FreeSWITCH** | `freeswitch -nc -nonat` |
| **Interactive Foreground** | `freeswitch -c -nonat` |
| **Stop FreeSWITCH** | `freeswitch -stop` or `pkill -9 -f freeswitch` |
| **Open CLI** | `fs_cli` |
| **Reload Dialplans** | `reloadxml` (inside `fs_cli`) |
| **Check Process** | `ps aux \| grep freeswitch` |
| **View Live Logs** | `tail -f /usr/local/freeswitch/var/log/freeswitch/freeswitch.log` |
