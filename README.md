# CYBERCRTA ("Critical Thinking & Recon Toolkit")

[![Version](https://img.shields.io/badge/version-v1.0.0-blue.svg)](cybercrta.sh)
[![Platform](https://img.shields.io/badge/platform-WSL2%20%7C%20Ubuntu-orange.svg)](#target-environment)
[![License](https://img.shields.io/badge/license-MIT-green.svg)](#)

CYBERCRTA is a lightweight, zero-dependency bash terminal reconnaissance and critical thinking toolkit engineered specifically for security practitioners, students, and analysts operating in **WSL2 (Windows Subsystem for Linux - Ubuntu)** and standard Linux environments.

CYBERCRTA unites active/passive reconnaissance tools with structured critical thinking methodologies, providing clear explanations of underlying protocols, defensive heuristics, and potential false positives.

---

## Key Features

- **WSL2 & Cloud-Safe Networking:** Network calls (`ping`, `nmap`, `dig`, `curl`, `nc`) use non-blocking options and strict execution timeouts (1s–60s) to prevent hangs caused by WSL2 virtual NAT adapters or packet filtering.
- **Graceful Dependency Management:** Checks for essential tools upon startup (`nmap`, `dnsutils`, `curl`, `whois`, `netcat-openbsd`). Offers automatic `sudo apt install -y` if missing; never fails hard if a package is absent.
- **Pure Bash & ANSI Styling:** Styled using pure ANSI escape sequences and standard POSIX shell utilities. No external Python, Node, GUI, or `systemd` dependencies required.
- **Educational Learning Hub:** Includes built-in explainers detailing how each tool works under the hood and how to critically analyze scan results.

---

## Target Environment

- **OS / Subsystem:** WSL2 (Ubuntu distribution on Windows 11 / Windows 10) or native Ubuntu / Debian Linux.
- **Shell:** GNU Bash (v4+ / v5+).
- **Filesystem & Privileges:** Standard filesystem conventions (`/usr/bin`, `/etc`). Uses `$HOME` rather than hardcoded usernames. Sudo access is used strictly when installing missing packages via `apt`.
- **Systemd Agnostic:** Does not depend on `systemd` or background system services.

---

## Installation & Setup

1. **Clone the repository:**
   ```bash
   git clone <repository-url>
   cd <repository-directory>
   ```

2. **(Optional) Install all recommended dependencies at once:**
   ```bash
   sudo apt update && sudo apt install -y nmap dnsutils curl whois netcat-openbsd
   ```
   *Note: If any package is missing, CYBERCRTA will detect it on launch and prompt you to install it automatically.*

3. **Make the script executable:**
   ```bash
   chmod +x cybercrta.sh
   ```

---

## How to Run

### Interactive Menu
Launch the interactive toolkit interface:
```bash
./cybercrta.sh
```

### Command Line Flags
CYBERCRTA supports several non-interactive CLI flags:

- Show help and usage instructions:
  ```bash
  ./cybercrta.sh --help
  # or
  ./cybercrta.sh -h
  ```

- Display version information (`v1.0.0`):
  ```bash
  ./cybercrta.sh --version
  # or
  ./cybercrta.sh -v
  ```

- Run non-interactive dependency audit:
  ```bash
  ./cybercrta.sh --check-deps
  ```

---

## Menu Map

```text
CYBERCRTA Main Menu
├── 1) Network Recon
│   ├── 1) Subnet Ping Sweep (fping preferred, parallel ping fallback)
│   ├── 2) Nmap Port Scanner (TCP Connect -sT, Quick/Standard/Version/Custom)
│   ├── 3) Netcat Quick Port Probe & Banner Grab
│   └── 4) Return to Main Menu
├── 2) DNS Lookup
│   ├── 1) Dig DNS Record Lookup (ALL types individually, +trace)
│   ├── 2) Reverse DNS Lookup (PTR via Dig)
│   ├── 3) WHOIS Domain / IP Intelligence (Key fields + raw view)
│   └── 4) Return to Main Menu
├── 3) Web Recon
│   ├── 1) HTTP Header Inspection & Security Header Audit (HSTS, CSP, XFO, etc.)
│   ├── 2) HTTP Redirection & Timing Trace (Status code, redirects, connect timing)
│   ├── 3) Server & Technology Fingerprinting (Server, X-Powered-By, Title)
│   ├── 4) AI Security Analysis (Ollama, local LLM)
│   └── 5) Return to Main Menu
├── 4) Learning Hub
│   ├── 1) Ping & ICMP Architecture (WSL2 considerations)
│   ├── 2) Nmap Port Scanning & Port States
│   ├── 3) DNS Records & Dig Exploration
│   ├── 4) WHOIS Protocol & Registrar Attribution
│   ├── 5) Curl & Web Reconnaissance (Headers & Security)
│   ├── 6) Netcat (The Network Swiss Army Knife)
│   ├── 7) Critical Thinking & Structured Recon Methodology
│   └── 8) Return to Main Menu
├── 5) System Dependencies
│   └── Run live audit and offer 'sudo apt install -y' for missing packages
└── 6) Exit
```

---

## Ollama AI Security Analysis (v1.1.0+)

Web Recon → option 4 pipes captured HTTP headers into a **local** Ollama model
for an AI security audit (missing headers, banner disclosure, risky configs).
Nothing leaves your machine.

Setup:

```bash
curl -fsSL https://ollama.com/install.sh | sh
ollama pull qwen2.5-coder:7b   # or: ollama pull llama3
ollama serve
```

The toolkit auto-detects the daemon at `http://localhost:11434`, lists your
installed models (preferring `qwen2.5-coder:7b` when present), and degrades
gracefully with install instructions if Ollama isn't running. Needs `jq` or
`python3` for JSON handling.

---

## WSL2 Networking Notes

WSL2 runs inside a lightweight Hyper-V virtual machine using virtualized NAT networking by default. This can cause specific quirks:
- **Raw Socket Limitations:** Scans relying on raw sockets (such as `nmap -sS` TCP SYN stealth scans) can fail or hang unless executed with elevated privileges and appropriate kernel support. CYBERCRTA defaults to unprivileged TCP connect scans (`-sT -Pn`) to guarantee reliable results.
- **Timeouts:** All remote network probes include explicit timeout constraints (e.g. `timeout 60s`, `ping -W 1`, `nc -w 3`, `curl --max-time 10`) ensuring that silent packet drops by host firewalls do not block the terminal session.
