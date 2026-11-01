#!/usr/bin/env bash
# ==============================================================================
# CYBERCRTA - Critical Thinking & Recon Toolkit
# Version: v1.0.0
#
# Target Environment: Ubuntu on WSL2 / Linux.
# Dependencies: bash, curl, dnsutils, nmap, whois, netcat-openbsd.
# Note: Designed to fail gracefully and never hang with network operations.
# ============================================================================== 

set -o pipefail

VERSION="v1.0.0"
SCRIPT_NAME=$(basename "$0")

# ANSI Color codes (raw escapes for maximum portability without tput dependency)
if [[ -t 1 ]]; then
    COLOR_RESET="\033[0m"
    COLOR_BOLD="\033[1m"
    COLOR_RED="\033[31m"
    COLOR_GREEN="\033[32m"
    COLOR_YELLOW="\033[33m"
    COLOR_BLUE="\033[34m"
    COLOR_CYAN="\033[36m"
    COLOR_WHITE="\033[37m"
    COLOR_GRAY="\033[90m"
else
    COLOR_RESET=""
    COLOR_BOLD=""
    COLOR_RED=""
    COLOR_GREEN=""
    COLOR_YELLOW=""
    COLOR_BLUE=""
    COLOR_CYAN=""
    COLOR_WHITE=""
    COLOR_GRAY=""
fi

# ------------------------------------------------------------------------------
# Banner and UI Helpers
# ------------------------------------------------------------------------------
print_banner() {
    clear 2>/dev/null || true
    echo -e "${COLOR_CYAN}${COLOR_BOLD}"
    cat << "EOF"
  ██████╗██╗   ██╗██████╗ ███████╗██████╗  ██████╗██████╗ ████████╗ █████╗ 
 ██╔════╝╚██╗ ██╔╝██╔══██╗██╔════╝██╔══██╗██╔════╝██╔══██╗╚══██╔══╝██╔══██╗
 ██║      ╚████╔╝ ██████╔╝█████╗  ██████╔╝██║     ██████╔╝   ██║   ███████║
 ██║       ╚██╔╝  ██╔══██╗██╔══╝  ██╔══██╗██║     ██╔══██╗   ██║   ██╔══██║
 ╚██████╗   ██║   ██████╔╝███████╗██║  ██║╚██████╗██║  ██║   ██║   ██║  ██║
  ╚═════╝   ╚═╝   ╚═════╝ ╚══════╝╚═╝  ╚═╝ ╚═════╝╚═╝  ╚═╝   ╚═╝   ╚═╝  ╚═╝
EOF
    echo -e "${COLOR_YELLOW}       Critical Thinking & Recon Toolkit ${COLOR_WHITE}[${VERSION}]${COLOR_RESET}"
    echo -e "${COLOR_GRAY}   WSL2 & Linux Ready | Non-blocking Recon | Modular & Clean${COLOR_RESET}"
    echo
}

pause_prompt() {
    echo
    echo -e "${COLOR_GRAY}Press [Enter] to continue...${COLOR_RESET}"
    read -r _
}

print_header() {
    local title="$1"
    echo -e "\n${COLOR_BLUE}${COLOR_BOLD}=== [ ${title} ] ===${COLOR_RESET}\n"
}

print_info() {
    echo -e "${COLOR_CYAN}[i]${COLOR_RESET} $1"
}

print_success() {
    echo -e "${COLOR_GREEN}[✓]${COLOR_RESET} $1"
}

print_warn() {
    echo -e "${COLOR_YELLOW}[!]${COLOR_RESET} $1"
}

print_error() {
    echo -e "${COLOR_RED}[✗]${COLOR_RESET} $1"
}

# ------------------------------------------------------------------------------
# CLI Help & Version
# ------------------------------------------------------------------------------
show_help() {
    echo -e "${COLOR_BOLD}CYBERCRTA${COLOR_RESET} - Critical Thinking & Recon Toolkit (${VERSION})"
    echo
    echo -e "${COLOR_BOLD}USAGE:${COLOR_RESET}"
    echo "  ${SCRIPT_NAME} [OPTIONS]"
    echo
    echo -e "${COLOR_BOLD}OPTIONS:${COLOR_RESET}"
    echo "  -h, --help       Show this help message and exit"
    echo "  -v, --version    Show version string and exit"
    echo "  --check-deps     Run dependency checks and exit"
    echo
    echo -e "${COLOR_BOLD}DESCRIPTION:${COLOR_RESET}"
    echo "  Interactive terminal reconnaissance toolkit designed for WSL2 and Ubuntu Linux."
    echo "  Features network recon, DNS discovery, web header inspection, and an educational"
    echo "  learning hub explaining recon concepts and critical thinking principles."
}

show_version() {
    echo "CYBERCRTA version ${VERSION}"
}

# ------------------------------------------------------------------------------
# Dependency Checking & Installation
# ------------------------------------------------------------------------------
# Required command => apt package name
declare -A REQUIRED_TOOLS=(
    ["nmap"]="nmap"
    ["dig"]="dnsutils"
    ["curl"]="curl"
    ["whois"]="whois"
    ["nc"]="netcat-openbsd"
)

is_command_available() {
    local cmd="$1"
    command -v "$cmd" >/dev/null 2>&1
}

install_missing_tool() {
    local pkg="$1"
    echo -e "${COLOR_YELLOW}Attempting to install package '${pkg}' with sudo apt install -y...${COLOR_RESET}"
    if sudo apt update && sudo apt install -y "$pkg"; then
        print_success "Package '${pkg}' installed successfully!"
        return 0
    else
        print_error "Failed to install package '${pkg}'. Please verify your apt sources / sudo access."
        return 1
    fi
}

check_dependencies() {
    local prompt_install="${1:-true}"
    local missing_pkgs=()

    echo -e "${COLOR_BLUE}${COLOR_BOLD}[ Dependency Audit ]${COLOR_RESET}"
    for cmd in "${!REQUIRED_TOOLS[@]}"; do
        local pkg="${REQUIRED_TOOLS[$cmd]}"
        if is_command_available "$cmd"; then
            echo -e "  ${COLOR_GREEN}✓${COLOR_RESET} ${cmd} (${pkg}): ${COLOR_GREEN}Installed${COLOR_RESET}"
        else
            echo -e "  ${COLOR_RED}✗${COLOR_RESET} ${cmd} (${pkg}): ${COLOR_YELLOW}Not installed${COLOR_RESET}"
            missing_pkgs+=("$pkg")
        fi
    done
    echo

    if [[ ${#missing_pkgs[@]} -gt 0 ]]; then
        print_warn "Some recommended tools are currently missing: ${missing_pkgs[*]}"
        print_info "Toolkit functionality requiring missing tools will notify you gracefully."
        if [[ "$prompt_install" == "true" ]]; then
            echo -ne "${COLOR_YELLOW}Would you like to install missing tools via 'sudo apt install -y' now? [y/N]: ${COLOR_RESET}"
            read -r answer
            if [[ "$answer" =~ ^[Yy]$ ]]; then
                for pkg in "${missing_pkgs[@]}"; do
                    install_missing_tool "$pkg"
                done
            else
                print_info "Skipping installation. You can install anytime from the Main Menu or manually."
            fi
        fi
    else
        print_success "All prerequisite tools are installed!"
    fi
}

ensure_tool_or_warn() {
    local cmd="$1"
    local pkg="${REQUIRED_TOOLS[$cmd]:-$cmd}"

    if ! is_command_available "$cmd"; then
        print_error "Tool '${cmd}' is not installed (Package: ${pkg})."
        echo -ne "${COLOR_YELLOW}Would you like to install '${pkg}' now via sudo apt? [y/N]: ${COLOR_RESET}"
        read -r answer
        if [[ "$answer" =~ ^[Yy]$ ]]; then
            if install_missing_tool "$pkg"; then
                return 0
            fi
        fi
        return 1
    fi
    return 0
}

# ------------------------------------------------------------------------------
# Input Validation & Sanitization Helpers
# ------------------------------------------------------------------------------
sanitize_input() {
    # Strip spaces and malicious/control characters
    local input="$1"
    echo "$input" | tr -d ';&|`$><' | xargs
}

validate_host_or_ip() {
    local target="$1"
    # Basic domain or IPv4 validation
    if [[ "$target" =~ ^[a-zA-Z0-9.-]+$ ]]; then
        return 0
    fi
    return 1
}

# ------------------------------------------------------------------------------
# Section 1: Network Recon
# ------------------------------------------------------------------------------
network_ping_sweep() {
    print_header "Network Recon: Subnet Ping Sweep (WSL2-Safe)"
    print_info "WSL2 Note: Raw sockets can be restricted. This sweep uses standard ICMP with tight 1s timeouts."
    echo -e "${COLOR_GRAY}Example subnet base: 192.168.1 or 127.0.0 (scans .1 through .20 by default)${COLOR_RESET}"
    echo -ne "${COLOR_BOLD}Enter subnet prefix (default: 127.0.0): ${COLOR_RESET}"
    read -r subnet_input
    local subnet="${subnet_input:-127.0.0}"
    subnet=$(sanitize_input "$subnet")

    if ! [[ "$subnet" =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
        print_error "Invalid subnet prefix format. Expected format: X.X.X (e.g. 192.168.1)"
        pause_prompt
        return
    fi

    echo -ne "${COLOR_BOLD}Enter scan range end [1-254] (default: 15): ${COLOR_RESET}"
    read -r range_input
    local range_end="${range_input:-15}"
    if ! [[ "$range_end" =~ ^[0-9]+$ ]] || [ "$range_end" -lt 1 ] || [ "$range_end" -gt 254 ]; then
        print_warn "Invalid range end; defaulting to 15."
        range_end=15
    fi

    print_info "Sweeping ${subnet}.1 to ${subnet}.${range_end} (timeout 1s per host)..."
    local active_count=0
    for i in $(seq 1 "$range_end"); do
        local target="${subnet}.${i}"
        # Ping with 1 packet, 1 second deadline/timeout
        if ping -c 1 -W 1 "$target" >/dev/null 2>&1; then
            echo -e "  ${COLOR_GREEN}[ONLINE]${COLOR_RESET}  ${target}"
            ((active_count++))
        else
            echo -e "  ${COLOR_GRAY}[DOWN/NO-RESP]${COLOR_RESET} ${target}"
        fi
    done

    echo
    print_success "Ping sweep completed. Found ${active_count} responsive host(s)."
    pause_prompt
}

network_nmap_scan() {
    print_header "Network Recon: Nmap Port Scan"
    if ! ensure_tool_or_warn "nmap"; then
        pause_prompt
        return
    fi

    echo -ne "${COLOR_BOLD}Enter Target IP or Hostname (default: 127.0.0.1): ${COLOR_RESET}"
    read -r target_input
    local target="${target_input:-127.0.0.1}"
    target=$(sanitize_input "$target")

    if ! validate_host_or_ip "$target"; then
        print_error "Invalid target hostname or IP format."
        pause_prompt
        return
    fi

    echo
    echo "Select Scan Intensity:"
    echo "  1) Quick Top-20 TCP Scan (-sT -Pn -F --host-timeout 20s) [WSL2 Safe]"
    echo "  2) Standard Common Ports Scan (-sT -Pn -p 21,22,25,53,80,110,139,443,445,3000,8080)"
    echo "  3) Service & Version Detection (-sT -Pn -sV --version-light --host-timeout 45s)"
    echo "  4) Custom Port Range Scan"
    echo -ne "${COLOR_BOLD}Choose scan option [1-4] (default: 1): ${COLOR_RESET}"
    read -r scan_opt

    local nmap_flags=("-sT" "-Pn" "--host-timeout" "30s" "--max-retries" "1")

    case "$scan_opt" in
        2)
            nmap_flags+=("-p" "21,22,25,53,80,110,139,443,445,3000,8080")
            ;;
        3)
            nmap_flags+=("-sV" "--version-light" "--host-timeout" "45s" "-F")
            ;;
        4)
            echo -ne "${COLOR_BOLD}Enter port(s) (e.g. 80,443 or 1-1024): ${COLOR_RESET}"
            read -r custom_ports
            custom_ports=$(sanitize_input "$custom_ports")
            if [[ "$custom_ports" =~ ^[0-9,-]+$ ]]; then
                nmap_flags+=("-p" "$custom_ports")
            else
                print_warn "Invalid port syntax. Scanning default fast ports."
                nmap_flags+=("-F")
            fi
            ;;
        *)
            nmap_flags+=("-F")
            ;;
    esac

    print_info "Executing: nmap ${nmap_flags[*]} ${target}"
    print_info "Notice: WSL2 utilizes unprivileged TCP connect scans (-sT) to bypass raw socket limitations."
    echo "------------------------------------------------------------"

    if ! timeout 60s nmap "${nmap_flags[@]}" "$target"; then
        local exit_code=$?
        if [ "$exit_code" -eq 124 ]; then
            print_error "Nmap scan timed out after 60 seconds. WSL2 virtual switch or firewall may be dropping packets."
        else
            print_error "Nmap scan failed or was interrupted (Exit code: ${exit_code})."
        fi
    fi

    echo "------------------------------------------------------------"
    pause_prompt
}

network_nc_probe() {
    print_header "Network Recon: Netcat Port Banner Grab / Probe"
    if ! ensure_tool_or_warn "nc"; then
        pause_prompt
        return
    fi

    echo -ne "${COLOR_BOLD}Enter Target Host or IP (default: 127.0.0.1): ${COLOR_RESET}"
    read -r target_input
    local target="${target_input:-127.0.0.1}"
    target=$(sanitize_input "$target")

    echo -ne "${COLOR_BOLD}Enter Port to probe (default: 80): ${COLOR_RESET}"
    read -r port_input
    local port="${port_input:-80}"
    port=$(sanitize_input "$port")

    if ! [[ "$port" =~ ^[0-9]+$ ]] || [ "$port" -lt 1 ] || [ "$port" -gt 65535 ]; then
        print_error "Invalid port number."
        pause_prompt
        return
    fi

    print_info "Connecting to ${target}:${port} (Timeout: 4 seconds)..."
    echo "------------------------------------------------------------"
    # Try sending a basic generic newline to trigger a banner
    local output
    output=$(timeout 5s nc -v -z -w 3 "$target" "$port" 2>&1)
    local ret=$?

    if [ $ret -eq 0 ]; then
        print_success "Port ${port} is OPEN on ${target}!"
        echo "$output"
        echo
        print_info "Attempting banner grab (sending HEAD / HTTP request)..."
        echo -e "HEAD / HTTP/1.0\r\n\r\n" | timeout 4s nc -w 3 "$target" "$port" 2>/dev/null || true
    else
        print_warn "Port ${port} on ${target} appears CLOSED or FILTERED."
        echo "$output"
    fi
    echo "------------------------------------------------------------"
    pause_prompt
}

menu_network_recon() {
    while true; do
        print_header "Network Reconnaissance Menu"
        echo "  1) Subnet Ping Sweep (WSL2-Safe ICMP)"
        echo "  2) Nmap Port Scanner (Non-blocking TCP Connect)"
        echo "  3) Netcat Quick Port Probe & Banner Grab"
        echo "  4) Return to Main Menu"
        echo
        echo -ne "${COLOR_BOLD}Enter choice [1-4]: ${COLOR_RESET}"
        read -r choice
        case "$choice" in
            1) network_ping_sweep ;;
            2) network_nmap_scan ;;
            3) network_nc_probe ;;
            4) break ;;
            *) print_warn "Invalid selection. Please choose 1-4."; sleep 1 ;;
        esac
    done
}

# ------------------------------------------------------------------------------
# Section 2: DNS Lookup
# ------------------------------------------------------------------------------
dns_dig_lookup() {
    print_header "DNS Lookup: Dig Query"
    if ! ensure_tool_or_warn "dig"; then
        pause_prompt
        return
    fi

    echo -ne "${COLOR_BOLD}Enter Domain Name (e.g. example.com): ${COLOR_RESET}"
    read -r domain
    domain=$(sanitize_input "$domain")

    if ! validate_host_or_ip "$domain" || [ -z "$domain" ]; then
        print_error "Invalid domain name."
        pause_prompt
        return
    fi

    echo
    echo "Select Record Type:"
    echo "  1) ANY (A, AAAA, MX, TXT, NS)"
    echo "  2) A (IPv4 Address)"
    echo "  3) AAAA (IPv6 Address)"
    echo "  4) MX (Mail Exchange)"
    echo "  5) TXT (SPF, Verification strings)"
    echo "  6) NS (Name Servers)"
    echo "  7) Trace DNS Resolution (+trace)"
    echo -ne "${COLOR_BOLD}Choose record [1-7] (default: 1): ${COLOR_RESET}"
    read -r rtype_opt

    local qtype="ANY"
    local extra_flags="+time=3 +tries=2"

    case "$rtype_opt" in
        2) qtype="A" ;;
        3) qtype="AAAA" ;;
        4) qtype="MX" ;;
        5) qtype="TXT" ;;
        6) qtype="NS" ;;
        7) qtype="A"; extra_flags="+trace +nodnssec +time=3 +tries=1" ;;
        *) qtype="ANY" ;;
    esac

    print_info "Running: dig ${domain} ${qtype} ${extra_flags}"
    echo "------------------------------------------------------------"
    # shellcheck disable=SC2086
    if ! timeout 15s dig "$domain" $qtype $extra_flags +noall +answer +comments 2>&1; then
        print_error "DNS query timed out or failed. WSL2 /etc/resolv.conf might need checking."
    fi
    echo "------------------------------------------------------------"
    pause_prompt
}

dns_reverse_lookup() {
    print_header "DNS Lookup: Reverse IP / Hostname (PTR)"
    if ! ensure_tool_or_warn "dig"; then
        pause_prompt
        return
    fi

    echo -ne "${COLOR_BOLD}Enter IP address for reverse lookup (e.g. 8.8.8.8): ${COLOR_RESET}"
    read -r ip
    ip=$(sanitize_input "$ip")

    if [ -z "$ip" ]; then
        print_error "IP address cannot be empty."
        pause_prompt
        return
    fi

    print_info "Querying PTR record for ${ip}..."
    echo "------------------------------------------------------------"
    if ! timeout 6s dig -x "$ip" +short +time=3 +tries=2 2>&1; then
        print_error "Reverse DNS lookup failed or timed out."
    fi
    echo "------------------------------------------------------------"
    pause_prompt
}

dns_whois_lookup() {
    print_header "DNS / IP Recon: Whois Query"
    if ! ensure_tool_or_warn "whois"; then
        pause_prompt
        return
    fi

    echo -ne "${COLOR_BOLD}Enter Domain or IP to lookup (e.g. example.com): ${COLOR_RESET}"
    read -r target
    target=$(sanitize_input "$target")

    if [ -z "$target" ]; then
        print_error "Target cannot be empty."
        pause_prompt
        return
    fi

    print_info "Querying Whois registration data for ${target} (Timeout 10s)..."
    echo "------------------------------------------------------------"
    local raw_whois
    if raw_whois=$(timeout 10s whois "$target" 2>&1); then
        # Filter down common key fields to keep terminal readable, or display full
        echo -e "${COLOR_GREEN}Key Extracted Fields:${COLOR_RESET}"
        echo "$raw_whois" | grep -Ei "^\s*(Domain Name|Registry Domain ID|Registrar:|Creation Date|Updated Date|Registry Expiry Date|Name Server|Organization|OrgName|NetRange|CIDR):" | head -n 30 || true
        echo
        echo -ne "${COLOR_YELLOW}Display full raw WHOIS output? [y/N]: ${COLOR_RESET}"
        read -r view_all
        if [[ "$view_all" =~ ^[Yy]$ ]]; then
            echo "$raw_whois"
        fi
    else
        print_error "Whois lookup timed out or failed to reach whois server."
    fi
    echo "------------------------------------------------------------"
    pause_prompt
}

menu_dns_recon() {
    while true; do
        print_header "DNS Reconnaissance Menu"
        echo "  1) Dig DNS Record Lookup (A, AAAA, MX, TXT, NS, Trace)"
        echo "  2) Reverse DNS Lookup (PTR via Dig)"
        echo "  3) WHOIS Domain / IP Intelligence"
        echo "  4) Return to Main Menu"
        echo
        echo -ne "${COLOR_BOLD}Enter choice [1-4]: ${COLOR_RESET}"
        read -r choice
        case "$choice" in
            1) dns_dig_lookup ;;
            2) dns_reverse_lookup ;;
            3) dns_whois_lookup ;;
            4) break ;;
            *) print_warn "Invalid selection. Please choose 1-4."; sleep 1 ;;
        esac
    done
}

# ------------------------------------------------------------------------------
# Section 3: Web Recon
# ------------------------------------------------------------------------------
web_headers_inspection() {
    print_header "Web Recon: HTTP Header Inspection"
    if ! ensure_tool_or_warn "curl"; then
        pause_prompt
        return
    fi

    echo -ne "${COLOR_BOLD}Enter URL or Domain (e.g. https://example.com or localhost:8080): ${COLOR_RESET}"
    read -r target
    target=$(sanitize_input "$target")

    if [ -z "$target" ]; then
        print_error "Target URL cannot be empty."
        pause_prompt
        return
    fi

    # Prepend http:// if protocol not specified
    if ! [[ "$target" =~ ^https?:// ]]; then
        target="http://${target}"
    fi

    print_info "Fetching response headers from ${target} (max-time 10s)..."
    echo "------------------------------------------------------------"
    local headers
    if headers=$(curl -sSL -D - -o /dev/null --max-time 10 -A "Mozilla/5.0 (Windows NT 10.0; Win64; x64) CYBERCRTA/1.0" "$target" 2>&1); then
        echo -e "${COLOR_GREEN}${headers}${COLOR_RESET}"
        echo
        print_info "Security Header Checks:"
        # Quick heuristic security checks
        local sec_headers=("Strict-Transport-Security" "Content-Security-Policy" "X-Frame-Options" "X-Content-Type-Options" "Referrer-Policy")
        for sh in "${sec_headers[@]}"; do
            if echo "$headers" | grep -iq "^${sh}:"; then
                echo -e "  ${COLOR_GREEN}✓ Present:${COLOR_RESET} ${sh}"
            else
                echo -e "  ${COLOR_RED}✗ Missing:${COLOR_RESET} ${sh}"
            fi
        done
    else
        print_error "Curl failed to connect to ${target}. Connection timed out or host unreachable."
    fi
    echo "------------------------------------------------------------"
    pause_prompt
}

web_redirect_trace() {
    print_header "Web Recon: HTTP Redirection & Response Path"
    if ! ensure_tool_or_warn "curl"; then
        pause_prompt
        return
    fi

    echo -ne "${COLOR_BOLD}Enter URL to trace (e.g. http://google.com): ${COLOR_RESET}"
    read -r target
    target=$(sanitize_input "$target")

    if [ -z "$target" ]; then
        print_error "Target URL cannot be empty."
        pause_prompt
        return
    fi

    if ! [[ "$target" =~ ^https?:// ]]; then
        target="http://${target}"
    fi

    print_info "Tracing redirection chain for ${target}..."
    echo "------------------------------------------------------------"
    local trace_output
    trace_output=$(curl -sS -o /dev/null -w "Final URL: %{url_effective}\nHTTP Status: %{http_code}\nRedirects: %{num_redirects}\nConnect Time: %{time_connect}s\nTotal Time: %{time_total}s\n" --max-time 15 -L "$target" 2>&1)
    local ret=$?

    if [ $ret -eq 0 ]; then
        echo -e "${COLOR_CYAN}${trace_output}${COLOR_RESET}"
    else
        print_error "Request timed out or encountered an error."
        echo "$trace_output"
    fi
    echo "------------------------------------------------------------"
    pause_prompt
}

web_tech_fingerprint() {
    print_header "Web Recon: Server & Tech Fingerprinting"
    if ! ensure_tool_or_warn "curl"; then
        pause_prompt
        return
    fi

    echo -ne "${COLOR_BOLD}Enter URL to inspect (e.g. https://example.com): ${COLOR_RESET}"
    read -r target
    target=$(sanitize_input "$target")

    if [ -z "$target" ]; then
        print_error "Target cannot be empty."
        pause_prompt
        return
    fi

    if ! [[ "$target" =~ ^https?:// ]]; then
        target="http://${target}"
    fi

    print_info "Inspecting response headers and HTML metadata on ${target}..."
    echo "------------------------------------------------------------"
    local raw_head
    raw_head=$(curl -s -I --max-time 10 "$target" 2>&1)

    local server_header
    server_header=$(echo "$raw_head" | grep -i "^Server:" || echo "Server: Not disclosed")
    local powered_by
    powered_by=$(echo "$raw_head" | grep -i "^X-Powered-By:" || echo "X-Powered-By: Not disclosed")

    echo -e "${COLOR_BOLD}Server Banner:${COLOR_RESET}   ${server_header}"
    echo -e "${COLOR_BOLD}Backend Engine:${COLOR_RESET}  ${powered_by}"

    local page_title
    page_title=$(curl -sL --max-time 10 "$target" 2>/dev/null | grep -ioP '(?<=<title>)(.*)(?=</title>)' | head -n 1)
    if [ -n "$page_title" ]; then
        echo -e "${COLOR_BOLD}Page Title:${COLOR_RESET}      ${page_title}"
    fi

    echo "------------------------------------------------------------"
    pause_prompt
}

menu_web_recon() {
    while true; do
        print_header "Web Reconnaissance Menu"
        echo "  1) HTTP Header Inspection & Security Header Audit"
        echo "  2) HTTP Redirection & Timing Trace"
        echo "  3) Server & Technology Fingerprinting"
        echo "  4) Return to Main Menu"
        echo
        echo -ne "${COLOR_BOLD}Enter choice [1-4]: ${COLOR_RESET}"
        read -r choice
        case "$choice" in
            1) web_headers_inspection ;;
            2) web_redirect_trace ;;
            3) web_tech_fingerprint ;;
            4) break ;;
            *) print_warn "Invalid selection. Please choose 1-4."; sleep 1 ;;
        esac
    done
}

# ------------------------------------------------------------------------------
# Section 4: Learning Section
# ------------------------------------------------------------------------------
show_tool_explainer() {
    local tool="$1"
    case "$tool" in
        "ping")
            print_header "Explainer: Ping & ICMP Echo"
            echo -e "${COLOR_BOLD}What is it?${COLOR_RESET}"
            echo "  Ping sends Internet Control Message Protocol (ICMP) Echo Request packets"
            echo "  to target hosts and waits for ICMP Echo Reply packets."
            echo
            echo -e "${COLOR_BOLD}Recon & Critical Thinking Context:${COLOR_RESET}"
            echo "  - An absence of reply DOES NOT always mean the machine is offline. Many firewalls"
            echo "    (and cloud providers) silently drop ICMP Echo requests."
            echo "  - WSL2 Insight: WSL2 virtualized networking NAT layers can occasionally drop"
            echo "    or filter ICMP packets. Always corroborate host availability using TCP SYN/connect probes."
            echo "  - Measure RTT (Round Trip Time) variance to identify potential geolocations or proxy hops."
            ;;
        "nmap")
            print_header "Explainer: Nmap (Network Mapper)"
            echo -e "${COLOR_BOLD}What is it?${COLOR_RESET}"
            echo "  Nmap is an industry-standard network exploration and port scanning tool."
            echo "  It discovers live hosts, open TCP/UDP ports, services, and OS fingerprints."
            echo
            echo -e "${COLOR_BOLD}Recon & Critical Thinking Context:${COLOR_RESET}"
            echo "  - Port states: Open (app listening), Closed (RST received), Filtered (packet dropped by firewall)."
            echo "  - Scanning in WSL2: SYN scans (-sS) require raw socket capabilities that WSL2"
            echo "    virtual adapters don't always fully expose or require administrator privileges."
            echo "    Using TCP Connect scan (-sT) with non-ping (-Pn) is the most reliable baseline on WSL2."
            echo "  - Critical Thinking: Just because port 80/443 is open doesn't mean it is standard Apache/Nginx;"
            echo "    attack surfaces often lurk in alternative ports (8080, 8443, 3000, 9000)."
            ;;
        "dig")
            print_header "Explainer: Dig (Domain Information Groper)"
            echo -e "${COLOR_BOLD}What is it?${COLOR_RESET}"
            echo "  Dig is a flexible CLI DNS lookup utility provided by the dnsutils/bind9 package."
            echo
            echo -e "${COLOR_BOLD}Recon & Critical Thinking Context:${COLOR_RESET}"
            echo "  - DNS is the phonebook of the internet. Examining records exposes infrastructure:"
            echo "    * A / AAAA: Hosting infrastructure and CDN IP addresses."
            echo "    * MX: Mail providers (Google Workspace, Microsoft 365, proofpoint)."
            echo "    * TXT: SPF records, domain ownership proofs, and SaaS integrations."
            echo "    * NS: Authoritative DNS servers (Cloudflare, Route53, Akamai)."
            echo "  - Digging with +trace demonstrates hierarchical DNS delegation from Root -> TLD -> Authoritative."
            ;;
        "whois")
            print_header "Explainer: WHOIS Intelligence"
            echo -e "${COLOR_BOLD}What is it?${COLOR_RESET}"
            echo "  WHOIS is a query and response protocol used for querying databases that store"
            echo "  the registered assignees or assignees of an Internet resource (domains, IP blocks, ASNs)."
            echo
            echo -e "${COLOR_BOLD}Recon & Critical Thinking Context:${COLOR_RESET}"
            echo "  - Identifies domain age (recently created domains are frequently malicious/throwaways)."
            echo "  - Reveals registrar info, name servers, and organizational ownership/CIDRs."
            echo "  - GDPR / Privacy Guard: Many modern domains mask registrant details; however,"
            echo "    historical records, registrar names, and Autonomous System Numbers (ASN) remain invaluable."
            ;;
        "curl")
            print_header "Explainer: Curl & Web Header Analysis"
            echo -e "${COLOR_BOLD}What is it?${COLOR_RESET}"
            echo "  Curl is a command-line tool for transferring data using various network protocols,"
            echo "  predominantly HTTP/HTTPS."
            echo
            echo -e "${COLOR_BOLD}Recon & Critical Thinking Context:${COLOR_RESET}"
            echo "  - Response headers leak technology stacks (Server, X-Powered-By, Set-Cookie formats)."
            echo "  - Inspecting Security Headers: Absence of HSTS, CSP, or X-Frame-Options signals"
            echo "    potential vulnerability to clickjacking, MITM downgrade, or cross-site scripting."
            echo "  - Redirect status codes (301, 302, 307, 308) reveal canonical domains and routing proxies."
            ;;
        "nc")
            print_header "Explainer: Netcat (The Swiss Army Knife)"
            echo -e "${COLOR_BOLD}What is it?${COLOR_RESET}"
            echo "  Netcat (nc) reads and writes data across network connections using TCP or UDP."
            echo
            echo -e "${COLOR_BOLD}Recon & Critical Thinking Context:${COLOR_RESET}"
            echo "  - Netcat excels at lightweight service probing, banner grabbing, and verifying port reachability"
            echo "    without the overhead of heavier scanning tools."
            echo "  - In scripted recon, netcat banner grabs can immediately disclose software version strings"
            echo "    upon connection (e.g., SSH-2.0-OpenSSH, SMTP Exim banners, FTP banners)."
            ;;
        "methodology")
            print_header "Explainer: Critical Thinking & Recon Methodology"
            echo -e "${COLOR_BOLD}The Reconnaissance Philosophy:${COLOR_RESET}"
            echo "  1. Passive vs. Active Reconnaissance:"
            echo "     - Passive (Whois, public DNS, OSINT): Gathers intel without directly interacting with target systems."
            echo "     - Active (Ping sweeps, Nmap port scanning, Web probing): Directly sends packets to the target."
            echo
            echo "  2. The Critical Thinking Loop:"
            echo "     - Observe: What data did the tool return? (e.g. Open port 8080 with header Server: Werkzeug)."
            echo "     - Question: Why is this exposed? Is Werkzeug a Python Flask development server mistakenly left live?"
            echo "     - Correlate: Cross-reference DNS names, IP blocks, and HTTP banners to map the target attack surface."
            echo "     - Verify: Confirm findings with secondary tools before drawing conclusions."
            ;;
    esac
    pause_prompt
}

menu_learning_section() {
    while true; do
        print_header "CYBERCRTA Learning & Recon Fundamentals"
        echo "  1) Ping & ICMP Architecture (WSL2 considerations)"
        echo "  2) Nmap Port Scanning & Port States"
        echo "  3) DNS Records & Dig Exploration"
        echo "  4) WHOIS Protocol & Registrar Attribution"
        echo "  5) Curl & Web Reconnaissance (Headers & Security)"
        echo "  6) Netcat (The Network Swiss Army Knife)"
        echo "  7) Critical Thinking & Structured Recon Methodology"
        echo "  8) Return to Main Menu"
        echo
        echo -ne "${COLOR_BOLD}Select a topic to learn [1-8]: ${COLOR_RESET}"
        read -r choice
        case "$choice" in
            1) show_tool_explainer "ping" ;;
            2) show_tool_explainer "nmap" ;;
            3) show_tool_explainer "dig" ;;
            4) show_tool_explainer "whois" ;;
            5) show_tool_explainer "curl" ;;
            6) show_tool_explainer "nc" ;;
            7) show_tool_explainer "methodology" ;;
            8) break ;;
            *) print_warn "Invalid selection. Please choose 1-8."; sleep 1 ;;
        esac
    done
}

# ------------------------------------------------------------------------------
# Main Menu & Interactive Driver
# ------------------------------------------------------------------------------
main_menu() {
    while true; do
        print_banner
        echo -e "${COLOR_BOLD}MAIN NAVIGATION:${COLOR_RESET}"
        echo -e "  ${COLOR_CYAN}1)${COLOR_RESET} Network Recon       ${COLOR_GRAY}(Ping Sweep, Nmap Port Scan, Netcat Probe)${COLOR_RESET}"
        echo -e "  ${COLOR_CYAN}2)${COLOR_RESET} DNS Lookup          ${COLOR_GRAY}(Dig Records, Reverse PTR, WHOIS Intelligence)${COLOR_RESET}"
        echo -e "  ${COLOR_CYAN}3)${COLOR_RESET} Web Recon           ${COLOR_GRAY}(HTTP Headers, Redirect Trace, Tech Fingerprint)${COLOR_RESET}"
        echo -e "  ${COLOR_CYAN}4)${COLOR_RESET} Learning Hub        ${COLOR_GRAY}(Tool Explainers, Recon Logic & Methodologies)${COLOR_RESET}"
        echo -e "  ${COLOR_CYAN}5)${COLOR_RESET} System Dependencies ${COLOR_GRAY}(Audit and Install Missing Packages)${COLOR_RESET}"
        echo -e "  ${COLOR_CYAN}6)${COLOR_RESET} Exit"
        echo
        echo -ne "${COLOR_BOLD}Enter choice [1-6]: ${COLOR_RESET}"
        read -r option

        case "$option" in
            1) menu_network_recon ;;
            2) menu_dns_recon ;;
            3) menu_web_recon ;;
            4) menu_learning_section ;;
            5)
                print_header "System Dependency Check"
                check_dependencies true
                pause_prompt
                ;;
            6|q|Q|exit)
                echo -e "\n${COLOR_GREEN}Thank you for using CYBERCRTA. Stay curious and hack responsibly!${COLOR_RESET}\n"
                exit 0
                ;;
            *)
                print_warn "Invalid option. Please choose between 1 and 6."
                sleep 1
                ;;
        esac
    done
}

# ------------------------------------------------------------------------------
# Entrypoint Logic
# ------------------------------------------------------------------------------
case "${1:-}" in
    -h|--help)
        show_help
        exit 0
        ;;
    -v|--version)
        show_version
        exit 0
        ;;
    --check-deps)
        check_dependencies false
        exit 0
        ;;
    "")
        # Launch startup dependency check passively
        print_banner
        check_dependencies true
        pause_prompt
        main_menu
        ;;
    *)
        echo -e "${COLOR_RED}Error: Unknown option '$1'${COLOR_RESET}" >&2
        echo "Run '${SCRIPT_NAME} --help' for usage details." >&2
        exit 1
        ;;
esac
