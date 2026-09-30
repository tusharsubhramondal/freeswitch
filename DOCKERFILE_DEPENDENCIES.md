# FreeSWITCH Docker Dependencies Reference Guide

This document provides a detailed explanation of every package and library installed in the [`Dockerfile`](file:///c:/Users/tusha/Desktop/freeswitch/Dockerfile), categorized by its role in FreeSWITCH compilation and operation.

---

## 1. System Utilities & Tools

| Package | Description | Purpose in FreeSWITCH / Container |
| :--- | :--- | :--- |
| **`git`** | Fast, scalable, distributed revision control system. | Used to clone the FreeSWITCH source code and third-party modules from GitHub/GitLab. |
| **`wget`** | Network utility to retrieve files using HTTP, HTTPS, and FTP. | Used for downloading source archives, tarballs, sound files, and certificates. |
| **`curl`** | Command-line tool for transferring data with URLs. | Used for downloading keys, fetching API data, and testing webhooks. |
| **`sudo`** | Privilege elevation tool. | Allows running administrative commands inside scripts or non-root container users. |
| **`nano`** | Easy-to-use, small CLI text editor. | Quick in-container editing of configuration files (`freeswitch.xml`, `vars.xml`, dialplans). |
| **`vim`** | Powerful advanced CLI text editor. | Editing source code and configuration files inside the container. |
| **`ca-certificates`** | Common CA (Certificate Authority) certificates. | Enables verification of SSL/TLS certificates when downloading files or connecting to secure endpoints. |
| **`gnupg`** | GNU Privacy Guard (GPG key management tool). | Required to import and verify GPG repository signing keys (e.g., SignalWire/Debian repos). |

---

## 2. Build & Compilation Toolchain

These tools form the core environment needed to compile C/C++ source code, configure Makefiles, and build shared libraries.

| Package | Description | Purpose in FreeSWITCH / Container |
| :--- | :--- | :--- |
| **`build-essential`** | Meta-package providing `gcc`, `g++`, `make`, `libc6-dev`, and `dpkg-dev`. | The essential C and C++ compiler toolchain required to compile the FreeSWITCH core and all C/C++ modules. |
| **`pkg-config`** | Helper tool for managing compiler/linker flags for libraries. | Used by `configure` scripts and `cmake` to detect installed libraries and their compiler/linker paths. |
| **`autoconf`** | Tool for producing shell scripts that automatically configure software. | Generates the `./configure` script from `configure.ac` during `bootstrap.sh`. |
| **`automake`** | Tool for automatically generating `Makefile.in` files from `Makefile.am`. | Works alongside `autoconf` to create build Makefiles. |
| **`libtool`** & **`libtool-bin`** | Generic library support script and binary tool. | Simplifies building platform-independent dynamic/static shared libraries (`.so` files) for FreeSWITCH modules. |
| **`cmake`** | Cross-platform, open-source build system generator. | Used to build modern third-party FreeSWITCH dependencies (such as `libks`, `signalwire-c`, and `spandsp`). |
| **`nasm`** | Netwide Assembler (x86/x64 assembly). | Compiles assembly routines for optimized video/audio codecs (e.g., libvpx, libx264, libav). |
| **`yasm`** | Modular assembler based on NASM syntax. | Optimized assembly compiler utilized by media/FFmpeg/codec libraries for hardware acceleration. |

---

## 3. Core FreeSWITCH Runtime & Dialplan Dependencies

These libraries are essential for the fundamental operation of the FreeSWITCH engine, routing logic, encryption, and CLI.

| Package | Description | Purpose in FreeSWITCH / Container |
| :--- | :--- | :--- |
| **`uuid-dev`** | Universally Unique ID Library headers. | Generates unique 128-bit UUIDs for call sessions, channels, CDRs (Call Detail Records), and transactions. |
| **`libpcre3-dev`** | Perl Compatible Regular Expressions library headers. | Used by FreeSWITCH XML Dialplans and routing engines to evaluate regex pattern matches (e.g., matching dialed extension numbers). |
| **`libssl-dev`** | OpenSSL development headers and libraries. | Provides TLS/SSL encryption for SIP over TLS (SIPS), WebRTC (WSS/DTLS), and SRTP (Secure Real-time Transport Protocol). |
| **`libcurl4-openssl-dev`** | Development files for `libcurl` with OpenSSL backend. | Required for `mod_xml_curl` (fetching dynamic dialplans/directory via HTTP), `mod_httapi`, and sending webhook HTTP requests. |
| **`libedit-dev`** | BSD editline and history library. | Provides interactive command line editing, history, and auto-completion for `fs_cli` (FreeSWITCH CLI). |
| **`libsqlite3-dev`** | SQLite 3 development libraries. | Embedded database engine used by default for internal FreeSWITCH state, channel tracking, registrations, and `mod_db`. |
| **`libldns-dev`** | Fast DNS programming library. | Enables asynchronous DNS lookups, ENUM resolution (`mod_enum`), and SRV record lookups for SIP routing. |

---

## 4. Audio Processing, Formats & Codecs

These libraries support audio decoding, encoding, playback, recording, resampling, and digital signal processing.

| Package | Description | Purpose in FreeSWITCH / Container |
| :--- | :--- | :--- |
| **`libopus-dev`** | Opus interactive audio codec development files. | Used for `mod_opus`. Essential for modern VoIP and high-definition WebRTC voice/audio calls. |
| **`libspeexdsp-dev`** | Speex Digital Signal Processing library headers. | Provides acoustic echo cancellation (AEC), noise suppression, voice activity detection (VAD), and audio jitter buffer management. |
| **`libsndfile1-dev`** | Library for reading/writing audio files (WAV, AIFF, FLAC, RAW). | Used by `mod_sndfile` for recording calls, playing IVR prompts, and handling standard audio file formats. |
| **`libmpg123-dev`** | Fast console MPEG audio decoder library headers. | Used for decoding MP3 files (e.g., Music on Hold / MOH, IVR audio prompts). |
| **`libmp3lame-dev`** | MP3 audio encoding library headers. | Used by `mod_shout` and `mod_av` for encoding live calls or streams into MP3 format. |
| **`libshout3-dev`** | Streaming library for Icecast/Shoutcast servers. | Used by `mod_shout` for streaming audio to and from Icecast/Shoutcast servers (e.g., Internet radio as Music on Hold). |
| **`libogg-dev`** | Ogg bitstream library. | Container format support for Ogg Vorbis and Ogg Opus audio files and streams. |
| **`libvorbis-dev`** | Vorbis general audio compression codec. | Audio codec support for playing and recording Ogg/Vorbis audio. |

---

## 5. Video, Imaging & FFmpeg Media Processing

These packages provide video transcoding, image formatting, scaling, and video conferencing capabilities.

| Package | Description | Purpose in FreeSWITCH / Container |
| :--- | :--- | :--- |
| **`libavformat-dev`** | FFmpeg library for audio/video container formats. | Used by `mod_av` for demuxing and muxing various video and audio streaming container formats (MP4, MKV, FLV, etc.). |
| **`libswscale-dev`** | FFmpeg color conversion and scaling library. | Handles video resizing, scaling, and pixel format conversions (e.g., YUV420P to RGB) in video conferences and recordings. |
| **`libavutil-dev`** | FFmpeg utility library. | Utility routines (crypto, memory management, math) used across all FFmpeg/`mod_av` subsystems. |
| **`libswresample-dev`** | FFmpeg audio resampling and rematrixing library. | Handles audio sample rate conversion, channel layout adaptation, and format conversion in multimedia pipelines. |
| **`libjpeg-dev`** | Independent JPEG Group's JPEG runtime and header library. | Used for video snapshot generation, video layout avatar rendering, and conference video stills. |
| **`libtiff-dev`** | Tag Image File Format (TIFF) library. | Required for Fax over IP (T.38 / `mod_spandsp`) for converting incoming and outgoing faxes to/from TIFF images. |
| **`libvpx-dev`** | VP8 and VP9 video codec development headers. | Modern system video codec library replacing the ancient embedded libvpx for video calls and WebRTC. |
| **`libpq-dev`** | PostgreSQL client development libraries and headers. | Required if building `mod_pgsql` for PostgreSQL database integration. |
| **`zlib1g-dev`** | General compression library. | Provides data compression for network packets, media streams, and internal data structures. |

---

## 6. Scripting Languages

| Package | Description | Purpose in FreeSWITCH / Container |
| :--- | :--- | :--- |
| **`liblua5.4-dev`** | Lua 5.4 programming language development headers. | Used to compile `mod_lua`, enabling developers to write high-performance call control scripts and IVR logic in Lua. |

---

## 7. Docker Clean-up Command

```dockerfile
rm -rf /var/lib/apt/lists/*
```
* **Explanation**: Debian stores downloaded package indexes under `/var/lib/apt/lists/`. Once all packages are installed, these index lists are no longer needed. Removing them in the same `RUN` command prevents them from taking up space in the container image layer, significantly reducing the Docker image footprint.
