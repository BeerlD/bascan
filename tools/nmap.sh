source ././lib/colors.sh
source ././modules/cache.sh
source ././modules/utils.sh

declare -g scan_params
declare -h HOST
declare -h RM_PLACEHOLDER

HOST=$1
RM_PLACEHOLDER="                                                                       "
scan_params=()

case "$intensity" in
    "slowly") scan_params+=("-T0" "--max-rate" "5") ;;
    "low") scan_params+=("-T1" "--max-rate" "50") ;;
    "middle") scan_params+=("-T2" "--max-rate" "100") ;;
    "normal") scan_params+=("-T3" "--max-rate" "500") ;;
    "aggressive") scan_params+=("-T4" "--max-rate" "1000") ;;
    "insane") scan_params+=("-T5" "--max-rate" "5000") ;;
    *) scan_params+=("-T3" "--max-rate" "500") ;;
esac

function getCPUNetworkUsage() {
    echo -e "CPU:${CYAN}$(ps -p $1 -o %cpu=)%${NC} -${ORANGE}$(ps -p $$ -o %cpu=)%${NC} $(head -n 1 bascan_nmap_pidstat.log.bak 2>/dev/null)                      "
}

function nmap_fragment() {
    cache_tools_file_create "nmap" "fragments_packets.txt"
    cache_file_path=$(cache_tools_file_getPath "nmap" "fragments_packets.txt")

    source ././bascan_configs.sh 
    scan_params+=("-f")

    nmap "${scan_params[@]}" "$HOST" > "$cache_file_path" &
    ././scripts/pidstat.sh $! "bascan_nmap_pidstat.log" > /dev/null &
    utils_message_loading_pid $! "  ${ORANGE}Fragments packets${NC}..." getCPUNetworkUsage
    
    function performResult() {
        # $1 -> host
        # $2 -> cache file path

        status=0

        while read line; do
            if [[ "$line" =~ try\ -Pn ]]; then
                echo -e " ${RED}Fail${NC}.$RM_PLACEHOLDER"
                nmap "${scan_params[@]}" -Pn "$HOST" > "$1" &
                ././scripts/pidstat.sh $! "bascan_nmap_pidstat.log" > /dev/null &
                utils_message_loading_pid $! "  ${ORANGE}Fragments packets${NC} (without verification ping)..." getCPUNetworkUsage
                status=1
                break
            fi

            if [[ "${#line}" -eq 0 ]]; then
                echo -e " ${RED}No results${NC}.$RM_PLACEHOLDER"
                status=1
                break
            fi
        done < <(cat "$1")

        if [[ "$status" -eq 0 ]]; then
            echo -e " ${GREEN}Done${NC}.$RM_PLACEHOLDER"
        fi
        
        return "$status"
    }


    while performResult $cache_file_path; do
        break
    done

    unset -f performReseult
}

function nmap_ports() {
    cache_tools_file_create "nmap" "ports.txt"
    cache_file_path=$(cache_tools_file_getPath "nmap" "ports.txt")

    source ././bascan_configs.sh 
    scan_params+=("-p-")

    nmap "${scan_params[@]}" "$HOST" > "$cache_file_path" &
    ././scripts/pidstat.sh $! "bascan_nmap_pidstat.log" > /dev/null &
    utils_message_loading_pid $! "  ${ORANGE}Ports${NC}..." getCPUNetworkUsage
    
    function performResult() {
        # $1 -> host
        # $2 -> cache file path

        status=0

        while read line; do
            if [[ "$line" =~ try\ -Pn ]]; then
                echo -e " ${RED}Fail${NC}.$RM_PLACEHOLDER"
                nmap "${scan_params[@]}" -Pn "$HOST" > "$1" &
                ././scripts/pidstat.sh $! "bascan_nmap_pidstat.log" > /dev/null &
                utils_message_loading_pid $! "  ${ORANGE}Ports${NC} (without verification ping)..." getCPUNetworkUsage
                status=1
                break
            fi

            if [[ "${#line}" -eq 0 ]]; then
                echo -e " ${RED}No results${NC}.$RM_PLACEHOLDER"
                status=1
                break
            fi
        done < <(cat "$1")

        if [[ "$status" -eq 0 ]]; then
            echo -e " ${GREEN}Done${NC}.$RM_PLACEHOLDER"
        fi
        
        return "$status"
    }


    while performResult $cache_file_path; do
        break
    done

    unset -f performReseult
}

#function nmap_services
#function nmap_devices
#function namp_bruteforce()

function nmap_start_scan() {
    echo -e "${YELLOW}[+]${NC} Starting ${CYAN}nmap${NC} scan: ${YELLOW}$HOST${NC}..."
    nmap_ports
    nmap_fragment
    #nmap_services
    #nmap_devices
}
