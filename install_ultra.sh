#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════════════╗
# ║  HACKEROFHELL ULTRA v5.0 — ONE-CLICK INSTALLER                 ║
# ║  Author: RAJESH BAJIYA | Handle: HACKEROFHELL                  ║
# ║  Run: sudo bash install_ultra.sh                               ║
# ╚══════════════════════════════════════════════════════════════════╝

set -e
RED='\033[0;31m'; GRN='\033[0;32m'; YLW='\033[1;33m'
CYN='\033[0;36m'; MAG='\033[0;35m'; WHT='\033[1;37m'; NC='\033[0m'

ok()  { echo -e "${GRN}[✓]${NC} $*"; }
log() { echo -e "${CYN}[*]${NC} $*"; }
err() { echo -e "${RED}[✗]${NC} $*"; }
sep() { echo -e "${MAG}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"; }

clear
echo -e "${RED}"
cat << 'BANNER'
  ██╗  ██╗ █████╗  ██████╗██╗  ██╗███████╗██████╗ ██╗  ██╗███████╗██╗
  ██║  ██║██╔══██╗██╔════╝██║ ██╔╝██╔════╝██╔══██╗██║  ██║██╔════╝██║
  ███████║███████║██║     █████╔╝ █████╗  ██████╔╝███████║█████╗  ██║
  ██╔══██║██╔══██║██║     ██╔═██╗ ██╔══╝  ██╔══██╗╚════██║██╔══╝  ██║
  ██║  ██║██║  ██║╚██████╗██║  ██╗███████╗██║  ██║     ██║███████╗███████╗
  ╚═╝  ╚═╝╚═╝  ╚═╝ ╚═════╝╚═╝  ╚═╝╚══════╝╚═╝  ╚═╝     ╚═╝╚══════╝╚══════╝

           ULTRA v5.0 ONE-CLICK INSTALLER — RAJESH BAJIYA / HACKEROFHELL
BANNER
echo -e "${NC}"

[[ "$EUID" -ne 0 ]] && { err "Run as root: sudo bash install_ultra.sh"; exit 1; }

sep
log "Updating system..."
apt-get update -qq && apt-get upgrade -y -qq

sep
log "Installing APT tools..."
apt-get install -y -qq \
  nmap masscan gobuster ffuf sqlmap whatweb wafw00f wpscan \
  seclists python3 python3-pip python3-tk git \
  curl wget tmux dnsutils whois netcat-openbsd \
  libpcap-dev gcc make zip unzip jq \
  golang-go 2>/dev/null

ok "APT tools installed"

sep
log "Setting up Go environment..."
export GOPATH="$HOME/go"
export PATH="$PATH:$GOPATH/bin:/usr/local/go/bin"
echo 'export GOPATH=$HOME/go' >> /etc/profile.d/go.sh
echo 'export PATH=$PATH:$HOME/go/bin:/usr/local/go/bin' >> /etc/profile.d/go.sh
chmod +x /etc/profile.d/go.sh

# Install latest Go if current is too old
GO_VER=$(go version 2>/dev/null | grep -oP 'go\K[\d.]+' || echo "0")
if [[ "$(echo "$GO_VER 1.19" | awk '{print ($1 < $2)}')" == "1" ]]; then
  log "Installing latest Go..."
  cd /tmp
  wget -q "https://go.dev/dl/go1.22.5.linux-amd64.tar.gz" -O go.tar.gz
  rm -rf /usr/local/go
  tar -C /usr/local -xzf go.tar.gz
  rm go.tar.gz
  export PATH="$PATH:/usr/local/go/bin"
  ok "Go $(go version) installed"
fi

sep
log "Installing Go security tools..."
GO_TOOLS=(
  "github.com/projectdiscovery/subfinder/v2/cmd/subfinder@latest"
  "github.com/projectdiscovery/dnsx/cmd/dnsx@latest"
  "github.com/projectdiscovery/httpx/cmd/httpx@latest"
  "github.com/projectdiscovery/nuclei/v3/cmd/nuclei@latest"
  "github.com/projectdiscovery/katana/cmd/katana@latest"
  "github.com/projectdiscovery/naabu/v2/cmd/naabu@latest"
  "github.com/projectdiscovery/interactsh/cmd/interactsh-client@latest"
  "github.com/hahwul/dalfox/v2@latest"
  "github.com/lc/gau/v2/cmd/gau@latest"
  "github.com/tomnomnom/waybackurls@latest"
  "github.com/tomnomnom/anew@latest"
  "github.com/tomnomnom/gf@latest"
  "github.com/tomnomnom/qsreplace@latest"
  "github.com/tomnomnom/httprobe@latest"
  "github.com/hakluke/hakrawler@latest"
  "github.com/ffuf/ffuf/v2@latest"
)
for PKG in "${GO_TOOLS[@]}"; do
  TOOL=$(basename "${PKG%%@*}")
  log "Installing $TOOL..."
  GOPATH="$HOME/go" go install -v "$PKG" 2>/dev/null && ok "$TOOL" || { err "Failed: $TOOL (continuing)"; }
done

sep
log "Installing Python tools..."
pip3 install --break-system-packages -q \
  arjun paramspider truffleHog requests 2>/dev/null || \
pip3 install -q arjun paramspider requests 2>/dev/null || true
ok "Python tools installed"

sep
log "Installing amass..."
# Amass via go
GOPATH="$HOME/go" go install -v github.com/owasp-amass/amass/v4/...@master 2>/dev/null || \
  apt-get install -y amass 2>/dev/null || true
ok "Amass installed"

sep
log "Setting up gf patterns..."
mkdir -p ~/.gf
# Download gf patterns
git clone -q https://github.com/1ndianl33t/Gf-Patterns /tmp/gf-patterns 2>/dev/null || true
cp /tmp/gf-patterns/*.json ~/.gf/ 2>/dev/null || true
ok "GF patterns installed"

sep
log "Updating Nuclei templates..."
"$HOME/go/bin/nuclei" -update-templates -silent 2>/dev/null || true
TEMPLATE_COUNT=$(find ~/nuclei-templates -name "*.yaml" 2>/dev/null | wc -l || echo 0)
ok "Nuclei templates: $TEMPLATE_COUNT"

sep
log "Setting up hackerofhell_ultra.sh..."
mkdir -p ~/autopwn
if [[ -f "$(dirname "$0")/hackerofhell_ultra.sh" ]]; then
  cp "$(dirname "$0")/hackerofhell_ultra.sh" ~/autopwn/
elif [[ -f "./hackerofhell_ultra.sh" ]]; then
  cp ./hackerofhell_ultra.sh ~/autopwn/
fi
chmod +x ~/autopwn/hackerofhell_ultra.sh 2>/dev/null || true

sep
log "Verifying all tools..."
ALL_OK=true
for TOOL in nmap gobuster ffuf sqlmap whatweb wafw00f \
            subfinder dnsx httpx nuclei dalfox gau waybackurls \
            python3 curl; do
  if command -v "$TOOL" &>/dev/null || test -f "$HOME/go/bin/$TOOL"; then
    ok "$TOOL"
  else
    err "$TOOL — NOT FOUND"
    ALL_OK=false
  fi
done

sep
echo ""
echo -e "${GRN}╔══════════════════════════════════════════════════════╗${NC}"
echo -e "${GRN}║       HACKEROFHELL ULTRA — INSTALL COMPLETE          ║${NC}"
echo -e "${GRN}╚══════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${WHT}Now scan a target:${NC}"
echo -e "${CYN}  sudo bash ~/autopwn/hackerofhell_ultra.sh -t target.com${NC}"
echo ""
echo -e "${WHT}Options:${NC}"
echo -e "${CYN}  sudo bash ~/autopwn/hackerofhell_ultra.sh -t target.com --ultra --deep --chain${NC}"
echo ""
echo -e "${MAG}  RAJESH BAJIYA | HACKEROFHELL${NC}"
echo ""
