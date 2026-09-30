# Chapter 05: Call Routing & Call Flows

This chapter walks through the complete step-by-step SIP signaling and media call flows for:
1. **Internal Extension-to-Extension Calls** (`1000` $\rightarrow$ `1001`)
2. **Outbound Calls via a Gateway / SIP Trunk** (`1000` $\rightarrow$ Mobile Number)
3. **Inbound Calls from the Public Network / Carrier** (PSTN $\rightarrow$ DID $\rightarrow$ Extension)

---

## 1. Flow 1: Internal Calling (`1000` dials `1001`)

```mermaid
sequenceDiagram
    autonumber
    actor Caller as MicroSIP 1 (User 1000)
    participant Sofia as Sofia Internal (:5060)
    participant Dir as Directory (1000.xml)
    participant DP as Dialplan (default.xml)
    actor Callee as MicroSIP 2 (User 1001)

    Caller->>Sofia: 1. SIP INVITE (destination: 1001)
    Sofia->>Dir: 2. Authenticate User 1000
    Dir-->>Sofia: user_context = "default"
    Sofia->>DP: 3. Search Dialplan context "default"
    DP->>DP: 4. Matches regex ^(10[01][0-9])$
    DP->>Callee: 5. Execute: <action application="bridge" data="user/1001@${domain_name}"/>
    Callee-->>Sofia: 6. 180 Ringing
    Sofia-->>Caller: 7. 180 Ringing
    Callee-->>Sofia: 8. 200 OK (Answered)
    Sofia-->>Caller: 9. 200 OK
    Note over Caller,Callee: 2-Way RTP Audio Stream Established
```

### The XML Dialplan Rule in `default.xml`:
```xml
<extension name="Local_Extension">
  <!-- Matches any 4-digit number between 1000 and 1019 -->
  <condition field="destination_number" expression="^(10[01][0-9])$">
    <!-- 1. Set ringback tone -->
    <action application="set" data="ringback=${us-ring}"/>
    <!-- 2. Set timeout to 30 seconds before going to voicemail -->
    <action application="set" data="call_timeout=30"/>
    <action application="set" data="hangup_after_bridge=true"/>
    <action application="set" data="continue_on_fail=true"/>
    <!-- 3. Bridge the call to the registered contact of the dialed user -->
    <action application="bridge" data="user/$1@${domain_name}"/>
    <!-- 4. If no answer, send to voicemail -->
    <action application="answer"/>
    <action application="sleep" data="1000"/>
    <action application="bridge" data="loopback/app=voicemail:default ${domain_name} $1"/>
  </condition>
</extension>
```

---

## 2. Flow 2: Outbound Calls via SIP Trunk / Gateway

When an employee dials an outside number (e.g. `9876543210`):

```mermaid
sequenceDiagram
    autonumber
    actor Caller as MicroSIP (User 1000)
    participant Sofia as Sofia Internal (:5060)
    participant DP as Dialplan (default.xml)
    participant Trunk as SIP Gateway (Carrier)
    actor Mobile as Mobile Phone / PSTN

    Caller->>Sofia: 1. INVITE sip:9876543210@127.0.0.1
    Sofia->>DP: 2. Match in "default" context
    DP->>DP: 3. Matches Outbound Regex ^(\d{10})$
    DP->>Trunk: 4. Execute: <action application="bridge" data="sofia/gateway/my_provider/9876543210"/>
    Trunk->>Mobile: 5. Telecom carrier sends call to cellular network
    Mobile-->>Caller: 6. Phone rings & connects!
```

### The XML Outbound Rule:
```xml
<extension name="Outbound_PSTN">
  <!-- Matches any 10-digit number -->
  <condition field="destination_number" expression="^(\d{10})$">
    <action application="set" data="effective_caller_id_number=18005550199"/>
    <action application="bridge" data="sofia/gateway/my_carrier_gateway/$1"/>
  </condition>
</extension>
```

---

## 3. Flow 3: Inbound Calls from Outside Carrier (DID / PSTN)

When an outside customer dials your business phone number:

```mermaid
sequenceDiagram
    autonumber
    actor Outside as Outside Caller
    participant ExtProfile as External Profile (:5080)
    participant PublicDP as Public Dialplan (public.xml)
    participant DefaultDP as Default Dialplan (default.xml)
    actor Agent as MicroSIP (User 1000)

    Outside->>ExtProfile: 1. Inbound INVITE to Port 5080 (DID: 18005550199)
    ExtProfile->>PublicDP: 2. Hands call to context="public" (Unauthenticated)
    PublicDP->>PublicDP: 3. Matches DID number 18005550199
    PublicDP->>DefaultDP: 4. Transfer to extension 1000 in "default" context
    DefaultDP->>Agent: 5. Rings MicroSIP on User 1000
```

### The XML Inbound Rule in `public.xml`:
```xml
<extension name="Inbound_DID_Routing">
  <condition field="destination_number" expression="^18005550199$">
    <!-- Route to extension 1000 or to an IVR menu -->
    <action application="transfer" data="1000 XML default"/>
  </condition>
</extension>
```

---

👉 Next: Continue to **[Chapter 06: Dialplan Deep Dive & Custom Extensions](file:///c:/Users/tusha/Desktop/freeswitch/learning/06_dialplan_deep_dive.md)**
