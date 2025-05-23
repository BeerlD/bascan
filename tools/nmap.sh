source ././lib/colors.sh
source ././modules/cache.sh
source ././modules/utils.sh

function nmap_fragment() {
    cache_tools_file_create "nmap" "fragments_packets.txt"
    cache_file_path=$(cache_tools_file_getPath "nmap" "fragments_packets.txt")

    nmap -v -f "$1" >> "$cache_file_path" &
    utils_message_loading_pid $! "\t${YELLOW}Fragments packets${NC}..."
    
    function performResult() {
        # $1 -> host
        # $2 -> cache file path

        while read line; do
            if [[ "$line" =~ try\ -Pn ]]; then
                echo -e " ${RED}Fail${NC}."
                nmap -Pn -v -p- -f "$1" >> "$2" &
                utils_message_loading_pid $! "\t${YELLOW}Fragments packets${NC} (without verification ping)..."
                return 1
            fi
        done < <(cat "$2")

        return 0
    }

    while performResult $1 $cache_file_path; do
        cache_tools_file_create "nmap" "fragments_packets.txt"
    done

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
