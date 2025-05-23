source ././lib/colors.sh
source ././modules/cache.sh
source ././modules/utils.sh

function nmap_fragment() {
    nmap -f "$1" &
    utils_message_loading_pid $! "\t${YELLOW}Fragments packets${NC}..."
    echo -e " ${GREEN}Done${NC}."
}

function nmap_start_scan() {
    echo -e "${YELLOW}[+]${NC} Starting ${CYAN}nmap${NC} scan: ${YELLOW}$1${NC}..."
    nmap_fragment "$1"
}

#nmap_scan_udp
#nmap_scan_tcp
#nmap_scan_
#nmap_scan_
#nmap_scan_
#nmap_scan_
#nmap_scan_
#nmap_scan_
