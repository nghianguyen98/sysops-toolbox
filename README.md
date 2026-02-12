# SysOps Toolbox 🛠️

![Swift 6.0](https://img.shields.io/badge/Swift-6.0-orange.svg)
![Platform](https://img.shields.io/badge/Platform-macOS_14.0+-000000.svg?style=flat&logo=apple)
![License](https://img.shields.io/badge/License-MIT-blue.svg)
[![Website](https://img.shields.io/badge/Website-app.sysops.asia-blueviolet)](https://app.sysops.asia)

**SysOps Toolbox** is a comprehensive, native macOS application designed for System Administrators, DevOps Engineers, and Network Professionals. It consolidates scattered CLI commands and web tools into a single, high-performance interface—**100% offline, privacy-focused, and built for speed.**

![Main Interface](assets/screenshot.png)

## ⚡ Features

### 📡 Network Mastery
*   **Latency Monitor**: Real-time graph of packet loss and jitter to critical endpoints (Google, Gateway, etc.).
*   **Visual Traceroute**: Map network hops with geolocation data (Country/ISP).
*   **Port & LAN Scanner**: Rapidly discover devices and open ports on your local subnet.
*   **My IP Dashboard**: Instant view of Bandwidth, Local/Public IP, and MAC address.

### ☁️ DevOps Automation
*   **Docker Converter**: Paste a complex `docker run` command and get a clean `docker-compose.yml` instantly.
*   **SSH Tunnel Builder**: Visual interface for Local (`-L`), Remote (`-R`), and Dynamic (`-D`) port forwarding.
*   **Config Generators**: Generate error-free `systemd` service units and `cron` schedules.

### 🛠️ Utilities & Security
*   **SSL Inspector**: Check certificate chains, issuers, and expiry dates without using OpenSSL commands.
*   **Calculators**: Visual Subnet (CIDR) divider and RAID storage efficiency estimates.
*   **API Tester**: Lightweight, native REST client for quick endpoint validation.

---

## 🔮 Roadmap: What's Next?

We are building the ultimate cross-platform toolkit. Here is what we are working on:

- [ ] **Windows & Linux Port**: A native version for Windows 11 and Linux (GTK) is in active development.
- [ ] **Cloud Manager**: Reboot EC2 instances or check S3 buckets directly from the sidebar.
- [ ] **AI Log Analyst**: Drag & drop a log file to get an AI-powered summary of errors and root causes.
- [ ] **Packet Sniffer**: Simple `.pcap` capture and analysis UI (wireshark-lite).
- [ ] **Plugin System**: Write your own tools in simple Lua or JS scripts.

---

## 💻 Tech Stack

*   **Language**: Swift 6.0
*   **Architectur**: MVVM + Clean Architecture
*   **UI**: SwiftUI (macOS 14+)
*   **Performance**: Zero Electron. ~20MB App Size.

## 🚀 Download & Install

### Option 1: Pre-built Binary
Get the latest version from the **[Releases Page](https://github.com/nghianguyen98/sysops-toolbox/releases)**.

> **Note**: If you see "App is damaged" (due to lack of Apple notarization), run:
> `xattr -cr /Applications/SysOpsToolbox.app`

### Option 2: Build from Source
```bash
git clone https://github.com/nghianguyen98/sysops-toolbox.git
cd sysops-toolbox/SysOpsToolbox
open SysOpsToolbox.xcodeproj
# Cmd + R to run
```
