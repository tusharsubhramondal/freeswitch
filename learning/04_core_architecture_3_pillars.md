# Chapter 04: Core Architecture - The 3 Pillars

To master FreeSWITCH, you only need to understand how **3 core building blocks** interact with each other:

```
 ┌───────────────────────────┐      ┌───────────────────────────┐      ┌───────────────────────────┐
 │     1. SIP PROFILES       │      │       2. DIRECTORY        │      │       3. DIALPLAN         │
 │  (Doors / Interfaces)     │ ───► │  (Users / Accounts)       │ ───► │  (Brain / Routing Logic)  │
 │  conf/sip_profiles/       │      │  conf/directory/          │      │  conf/dialplan/           │
 └───────────────────────────┘      └───────────────────────────┘      └───────────────────────────┘
```

---

## 1. Pillar 1: SIP Profiles (`conf/sip_profiles/`)

A **SIP Profile** is a network listener (SIP User Agent) running on a specific IP address and port. Think of it as an **entrance door** to FreeSWITCH.

FreeSWITCH ships with two default SIP profiles:

| Profile | File Path | Default Port | Purpose | Default Context |
| :--- | :--- | :---: | :--- | :--- |
| **Internal** | [`conf/sip_profiles/internal.xml`](file:///c:/Users/tusha/Desktop/freeswitch/conf/sip_profiles/internal.xml) | **5060** | Softphones, local IP phones, authenticated office users | `public` (transferred to `default` upon auth) |
| **External** | [`conf/sip_profiles/external.xml`](file:///c:/Users/tusha/Desktop/freeswitch/conf/sip_profiles/external.xml) | **5080** | SIP Trunks, telecom carriers, PSTN gateways | `public` |

### Key Settings inside a SIP Profile:
- `<param name="sip-port" value="5060"/>`: Listening port.
- `<param name="sip-ip" value="$${local_ip_v4}"/>`: IP interface to bind SIP signaling.
- `<param name="rtp-ip" value="$${local_ip_v4}"/>`: IP interface to bind RTP voice media.
- `<param name="context" value="public"/>`: Which dialplan context unauthenticated calls enter.

---

## 2. Pillar 2: Directory (`conf/directory/`)

The **Directory** is the user database. It defines user extensions, passwords, caller ID information, and permissions.

User files live in [`conf/directory/default/`](file:///c:/Users/tusha/Desktop/freeswitch/conf/directory/default/):
- `1000.xml`, `1001.xml`, `1002.xml`, etc.

### Anatomy of a User File (`1000.xml`):
```xml
<include>
  <user id="1000">
    <!-- 1. Authentication Credentials -->
    <params>
      <param name="password" value="$${default_password}"/>  <!-- Default: 1234 -->
      <param name="vm-password" value="1000"/>              <!-- Voicemail PIN -->
    </params>

    <!-- 2. Channel Variables & Permissions -->
    <variables>
      <variable name="user_context" value="default"/>       <!-- Which Dialplan context this user accesses! -->
      <variable name="effective_caller_id_name" value="Extension 1000"/>
      <variable name="effective_caller_id_number" value="1000"/>
      <variable name="outbound_caller_id_name" value="$${outbound_caller_name}"/>
      <variable name="outbound_caller_id_number" value="$${outbound_caller_id}"/>
      <variable name="callgroup" value="techsupport"/>
    </variables>
  </user>
</include>
```

> **Crucial Concept:** The line `<variable name="user_context" value="default"/>` connects the User to the **Default Dialplan**. When user 1000 dials a number, FreeSWITCH searches for routing rules inside the `default` dialplan context!

---

## 3. Pillar 3: Dialplans (`conf/dialplan/`)

The **Dialplan** is the switchboard and brain of FreeSWITCH. It tells FreeSWITCH what application to run when a number is dialed.

Dialplans are organized into **Contexts**:

| Context File | Context Name | Who uses it? |
| :--- | :--- | :--- |
| [`conf/dialplan/default.xml`](file:///c:/Users/tusha/Desktop/freeswitch/conf/dialplan/default.xml) | **`default`** | Authenticated internal softphones/users (Allowed to make outbound calls, ring other extensions, call IVRs). |
| [`conf/dialplan/public.xml`](file:///c:/Users/tusha/Desktop/freeswitch/conf/dialplan/public.xml) | **`public`** | Unauthenticated callers from outside/telecom carriers (Restricted security sandbox). |

### Anatomy of a Dialplan Extension:
```xml
<extension name="My_Echo_Test">
  <!-- Condition: Checks what number was dialed -->
  <condition field="destination_number" expression="^9196$">
    <!-- Actions: Executed sequentially if condition matches -->
    <action application="answer"/>
    <action application="echo"/>
  </condition>
</extension>
```

---

## 4. How the 3 Pillars Connect Together

```
1. Softphone sends INVITE 9196 
   └──► Enters SIP Profile: [internal.xml (Port 5060)]
        │
2. Sofia verifies User credentials 
   └──► Matches User: [1000.xml] 
        └──► Finds: user_context = "default"
             │
3. FreeSWITCH executes Dialplan 
   └──► Matches rule in: [default.xml] 
        └──► Executes: <action application="echo"/>
```

---

👉 Next: Continue to **[Chapter 05: Call Routing & Call Flows](file:///c:/Users/tusha/Desktop/freeswitch/learning/05_call_routing_and_flows.md)**
