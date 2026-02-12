# SysOps Toolbox 🛠️

![Swift 5](https://img.shields.io/badge/Swift-5.0-orange.svg)
![Platform](https://img.shields.io/badge/Platform-macOS_14.0+-000000.svg?style=flat&logo=apple)
![License](https://img.shields.io/badge/License-MIT-blue.svg)

> **Requirement**: macOS 14.0 (Sonoma) or newer.

![Main Interface](assets/screenshot.png)

## Why SysOps Toolbox?

I built **SysOps Toolbox** because I was tired of opening 10 browser tabs just to check my public IP, test a port, or calculate a subnet. I wanted something **native, fast, and private** that lived right on my Mac.

No ads, no tracking, just the tools we use every day as DevOps & Network Engineers, packaged in a clean SwiftUI interface.

---

## 🚀 What's Inside?

### 1. Network Dashboard (The "Command Center")
Everything you need to know about your connection, right now.
*   **Real-time Bandwidth**: See your download/upload speeds instantly with a smooth visual chart.
*   **Connectivity Health**: A rolling 60-second history log. Green is good, Red means packet loss.
*   **Process Monitor**: Spot exactly which app is eating your bandwidth.

![Network Monitor](assets/screenshot_monitor.png)

### 2. The "Swiss Army Knife" Tools

| Tool | What it does |
| :--- | :--- |
| **Docker Converter** | **Stop writing Compose files by hand.** Paste a `docker run` command, get a clean `docker-compose.yml` back instantly. |
| **SSH Tunneling** | Visual SSH forwarding. No more memorizing `-L` or `-R` flags. Just fill the boxes and connect. |
| **SSL Inspector** | Paste a domain, get the full cert chain and expiry date. Never let a cert expire again. |
| **Subnet Calc** | Visualizes CIDR blocks so you don't cut a subnet too small. |

| **Docker Magic** | **Tunnel Builder** |
| :---: | :---: |
| ![Docker Converter](assets/screenshot_docker.png) | ![SSH Tunnel](assets/screenshot_ssh.png) |

---

### 🛡️ Security & Utilities
Small but mighty tools included:
*   **RAID Calculator**: Planning a storage server? Calculate usable space for ZFS or RAID 5/6/10.
*   **Password Gen**: Generate cryptographically secure passwords locally.
*   **Visual Traceroute**: (Coming Soon) Map your packets across the globe.

---

## 📦 How to Install

### Option 1: The Easy Way (Recommended)
Download the latest ready-to-use app (`.dmg` or `.app`) from the **[Releases Page](https://github.com/nghianguyen98/sysops-toolbox/releases)**.

*Note: If macOS complains the app is "damaged" (because I haven't paid Apple $99/year yet 😅), just run this one-liner in Terminal:*
```bash
xattr -cr /Applications/SysOpsToolbox.app
```

### Option 2: Build it Yourself
If you want to poke around the code (it's open source!):

1.  **Clone it**:
    ```bash
    git clone https://github.com/nghianguyen98/sysops-toolbox.git
    cd sysops-toolbox/SysOpsToolbox
    ```
2.  **Open in Xcode**:
    ```bash
    open SysOpsToolbox.xcodeproj
    ```
3.  **Hit Run** (`Cmd + R`).

---

## 🔮 What's Next?
I'm actively working on:
- [ ] **Windows Version**: Native port is in the works!
- [ ] **Cloud Manager**: Quick EC2/Droplet rebooter.
- [ ] **Packet Sniffer**: Simple `.pcap` capture UI.

## 🤝 Contributing
Found a bug? Have a cool idea? Feel free to open an Issue or PR. I'm always open to feedback!

---
*Crafted with ☕ and Swift by Nghia Nguyen.*
