# Chapter 06: Dialplan Deep Dive & Custom Extensions

This chapter teaches you how to write custom XML dialplans, use regular expressions, understand evaluation order, and use core FreeSWITCH applications.

---

## 1. Dialplan Syntax & Structure

Every dialplan extension is defined inside a `<context>` tag in [`conf/dialplan/default.xml`](file:///c:/Users/tusha/Desktop/freeswitch/conf/dialplan/default.xml):

```xml
<include>
  <context name="default">

    <extension name="extension_name">
      <condition field="field_to_test" expression="regex_pattern">
        <!-- Actions run if the condition MATCHES -->
        <action application="app_name" data="arguments"/>
        <!-- Anti-actions run if the condition FAILS -->
        <!-- <anti-action application="app_name" data="arguments"/> -->
      </condition>
    </extension>

  </context>
</include>
```

---

## 2. Common Condition Fields

You can evaluate any channel variable or call property inside `<condition>`:

| Field Name | Description | Example |
| :--- | :--- | :--- |
| `destination_number` | The number dialed by the user. | `^1000$` or `^9196$` |
| `caller_id_number` | The phone number of the person calling. | `^1000$` |
| `caller_id_name` | The display name of the caller. | `^Extension 1000$` |
| `${toll_allow}` | Custom variable attached to the user in the directory. | `^domestic$` |
| `wday` / `hour` | Time-of-day condition (1=Sunday, 2=Monday...; hour=0-23). | `wday="2-6" hour="9-17"` (Mon-Fri 9am-5pm) |

---

## 3. Regular Expressions (Regex) Quick Guide

FreeSWITCH uses Perl-Compatible Regular Expressions (PCRE):

| Pattern | Meaning | Example Match |
| :--- | :--- | :--- |
| `^` | Start of the dialed string. | `^9196` matches numbers starting with 9196 |
| `$` | End of the dialed string. | `9196$` matches numbers ending with 9196 |
| `^9196$` | Exact match only. | Matches `9196` (does NOT match `91960`) |
| `\d` | Any digit (0–9). | `^\d{4}$` matches any 4-digit number |
| `(\d+)` | **Capturing Group** (stores the matched digits into `$1`). | If dialed `1001`, `$1` becomes `1001` |
| `^(10[01][0-9])$` | Range matching. | Matches `1000` through `1019` |
| `^(sales|billing)$` | Pipe / OR operator. | Matches `sales` or `billing` |

---

## 4. Essential Dialplan Applications

| Application | Description | Example |
| :--- | :--- | :--- |
| **`answer`** | Answers the call immediately (sends SIP `200 OK`). | `<action application="answer"/>` |
| **`bridge`** | Connects the caller's audio to another endpoint. | `<action application="bridge" data="user/1001@${domain}"/>` |
| **`playback`** | Plays a pre-recorded `.wav` sound file. | `<action application="playback" data="ivr/ivr-welcome.wav"/>` |
| **`sleep`** | Pauses execution for $N$ milliseconds. | `<action application="sleep" data="2000"/>` (Waits 2 seconds) |
| **`set`** | Sets a channel variable. | `<action application="set" data="call_timeout=20"/>` |
| **`export`** | Sets a channel variable on both legs of a call. | `<action application="export" data="RFC2822_DATE=..."/>` |
| **`transfer`** | Transfers the call to another extension or context. | `<action application="transfer" data="1000 XML default"/>` |
| **`ivr`** | Launches an Interactive Voice Response menu. | `<action application="ivr" data="demo_ivr"/>` |
| **`record_session`**| Records the entire conversation to a `.wav` file. | `<action application="record_session" data="/tmp/call.wav"/>` |
| **`hangup`** | Ends and hangs up the call. | `<action application="hangup"/>` |

---

## 5. Practical Hands-on Examples

### Example 1: Creating a Custom Echo / Voice Test Extension (`9999`)
Add this into [`conf/dialplan/default.xml`](file:///c:/Users/tusha/Desktop/freeswitch/conf/dialplan/default.xml):

```xml
<extension name="custom_echo_test">
  <condition field="destination_number" expression="^9999$">
    <action application="answer"/>
    <action application="sleep" data="500"/>
    <action application="playback" data="tone_stream://%(500,500,440)"/>
    <action application="echo"/>
  </condition>
</extension>
```

---

### Example 2: Call Recording on Extension Dialing
Automatically record any internal call:

```xml
<extension name="recorded_local_call">
  <condition field="destination_number" expression="^(10[01][0-9])$">
    <action application="set" data="RECORD_TITLE=Recording ${caller_id_number} to $1"/>
    <!-- Start recording to recordings folder -->
    <action application="record_session" data="$${recordings_dir}/${caller_id_number}_to_$1_${strftime(%Y-%m-%d-%H-%M-%S)}.wav"/>
    <!-- Bridge the call to the dialed extension -->
    <action application="bridge" data="user/$1@${domain_name}"/>
  </condition>
</extension>
```

---

### Example 3: Office Hours Time-of-Day Routing
Play a closed message after 6:00 PM:

```xml
<extension name="office_hours">
  <!-- Monday to Friday, 9:00 AM to 6:00 PM -->
  <condition wday="2-6" hour="9-17">
    <action application="transfer" data="1000 XML default"/>
    <!-- Anti-action executes if caller calls outside office hours -->
    <anti-action application="answer"/>
    <anti-action application="playback" data="ivr/ivr-office_closed.wav"/>
    <anti-action application="hangup"/>
  </condition>
</extension>
```

---

## 6. How to Apply Dialplan Changes

After saving your edits to `conf/dialplan/default.xml`:

```powershell
docker exec freeswitch-learning /usr/local/freeswitch/bin/fs_cli -x "reloadxml"
```
*(No server restart needed; changes apply immediately!)*
