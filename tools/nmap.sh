source ././lib/colors.sh
source ././modules/cache.sh
source ././modules/utils.sh

declare -g scan_params
declare -g scan_params_without_ping

function nmap_fragment() {
    cache_tools_file_create "nmap" "fragments_packets.txt"
    cache_file_path=$(cache_tools_file_getPath "nmap" "fragments_packets.txt")

    source ././bascan_configs.sh 
    scan_params=("-v" "-f")
    scan_params_without_ping=("-Pn")

    case "$intensity" in
        "slowly") scan_params+=("-T0 --max-rate 5") ;;
        "low") scan_params+=("-T1 --max-rate 50") ;;
        "middle") scan_params+=("-T2 --max-rate 100") ;;
        "normal") scan_params+=("-T3 -p- --max-rate 500") ;;
        "aggressive") scan_params+=("-T4 -p- --max-rate 1000") ;;
        "insane") scan_params+=("-T5 -p- --max-rate 5000") ;;
        *) scan_params+=("-T3 -p- --max-rate 500") ;;
    esac

    nmap "${scan_params[@]}" "$1" > "$cache_file_path" &
    utils_message_loading_pid $! "  ${YELLOW}Fragments packets${NC}..."
    
    function performResult() {
        # $1 -> host
        # $2 -> cache file path

        status=0

        while read line; do
            if [[ "$line" =~ try\ -Pn ]]; then
                echo -e " ${RED}Fail${NC}."
                nmap "${scan_params[@]}" "${scan_params_without_ping[@]}" "$1" > "$2" &
                utils_message_loading_pid $! "  ${YELLOW}Fragments packets${NC} (without verification ping)..."
                status=1
                break
            fi

            if [[ "${#line}" -eq 0 ]]; then
                echo -e " ${RED}No ports found${NC}."
                status=1
                break
            fi
        done < <(cat "$2")

        if [[ "$status" -eq 0 ]]; then
            echo -e " ${GREEN}Done${NC}."
        fi

        return "$status"
    }


    while performResult $1 $cache_file_path; do
        break
    done
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
