source ././include.sh

declare -g scan_params
declare -g cache_file_path

function setScanParams() {
    source ././bascan_configs.sh
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

    if [[ "$fastmode" == true ]]; then
        scan_params+=("-F")
    fi
}

function nmap_getCPUNetworkUsage() {
    # $1 -> PID

    local progress=$(grep -oE "[0-9]+\.[0-9]+%" "$cache_file_path" | tail -n 1 | sed -E 's/.* ([0-9]+\.[0-9]+)%.*/\1/')
    local remaining=$(grep -oP '\(\K[^)]+' "$cache_file_path" | tail -n 1)

    if [[ -n "$progress" ]]; then
        echo -e "${CYAN}$progress${NC} done ($remaining)."
    fi
}

function nmap_perform_result() {
    # $1 -> Cache file path
    # $2 -> Title

    status=0
    readingResult=0

    while read line; do
        if [[ "$readingResult" -eq 1 ]]; then
            if [[ "${#line}" -eq 0 ]]; then
                break
            fi

            ports_scanned+=("$line")
            continue
        fi

        if [[ "$line" =~ try\ -Pn ]]; then
            echo -e " ${RED}Fail${NC}."
            nmap "${scan_params[@]}" -Pn "$HOST" > "$1" &
            ././scripts/pidstat.sh $! "bascan_nmap_pidstat.log" > /dev/null &
            utils_message_loading_pid $! "  ${ORANGE}$2${NC} (without verification ping)..." nmap_getCPUNetworkUsage
            status=1
            break
        fi

        if [[ "$line" =~ ^PORT && "$line" =~ STATE && "$line" =~ SERVICE ]]; then
            readingResult=1
            continue
        fi
    done < <(cat "$1")

    if [[ "$readingResult" -eq 0 ]]; then
        echo -e " ${RED}No results${NC}."
    elif [[ "$status" -eq 0 ]]; then
        echo -e " ${GREEN}Done${NC}. (${#ports_scanned[@]} results)"
    else
        echo -e " ${RED}Fail${NC}."
    fi
    
    return "$status"
}

function nmap_fragment() {
    cache_tools_file_create "nmap" "fragments_packets.txt"
    cache_file_path=$(cache_tools_file_getPath "nmap" "fragments_packets.txt")

    source ././bascan_configs.sh

    setScanParams
    scan_params+=("-f")

    local title="Fragments packets"

    nmap "${scan_params[@]}" "$HOST" > "$cache_file_path" &
    ././scripts/pidstat.sh $! "bascan_nmap_pidstat.log" > /dev/null &
    utils_message_loading_pid $! "  ${ORANGE}$title${NC}..." nmap_getCPUNetworkUsage
    
    while nmap_perform_result $cache_file_path $title; do
        break
    done
}

function nmap_tcp_ports() {
    cache_tools_file_create "nmap" "ports_tcp.txt"
    cache_file_path=$(cache_tools_file_getPath "nmap" "ports_tcp.txt")

    source ././bascan_configs.sh
    setScanParams

    if [[ "$intensity" == "insane" || "$intensity" == "aggressive" ]]; then
        scan_params+=("-p-")
    fi

    scan_params+=("-sV")
    local title="TCP Ports"

    nmap "${scan_params[@]}" "$HOST" > "$cache_file_path" &
    ././scripts/pidstat.sh $! "bascan_nmap_pidstat.log" > /dev/null &
    utils_message_loading_pid $! "  ${ORANGE}$title${NC}..." nmap_getCPUNetworkUsage

    while nmap_perform_result $cache_file_path $title; do
        break
    done
}

function nmap_udp_ports() {
    cache_tools_file_create "nmap" "ports_udp.txt"
    cache_file_path=$(cache_tools_file_getPath "nmap" "ports_udp.txt")

    source ././bascan_configs.sh
    setScanParams

    if [[ "$intensity" == "insane" || "$intensity" == "aggressive" ]]; then
        scan_params+=("-p-")
    fi

    scan_params+=("-sU")
    local title="UDP Ports"

    nmap "${scan_params[@]}" "$HOST" > "$cache_file_path" &
    ././scripts/pidstat.sh $! "bascan_nmap_pidstat.log" > /dev/null &
    utils_message_loading_pid $! "  ${ORANGE}$title${NC}..." nmap_getCPUNetworkUsage

    while nmap_perform_result $cache_file_path $title; do
        break
    done
}

function nmap_scan_vulnerabilites() {
    cache_tools_file_create "nmap" "vulnerabilities.txt"
    cache_file_path=$(cache_tools_file_getPath "nmap" "vulnerabilities.txt")

    source ././bascan_configs.sh
    setScanParams

    scan_params+=("--script" "vuln")
    local title="Vulnerabilities"

    nmap "${scan_params[@]}" "$HOST" > "$cache_file_path" & 
    ././scripts/pidstat.sh $! "bascan_nmap_pidstat.log" > /dev/null &
    utils_message_loading_pid $! "  ${ORANGE}$title${NC}..." nmap_getCPUNetworkUsage

    local found_vulns=0
    local print_block=0

    echo -e "\n${YELLOW}[+]${NC} ${CYAN}Vulnerabilities Found:${NC}"

    while read -r line; do
        if [[ "$line" =~ ^|_ ]]; then
            if [[ "$print_block" -eq 1 ]]; then
                echo ""
            fi
            print_block=1
            found_vulns=1
            echo -e "${RED}${line}${NC}"
        elif [[ "$print_block" -eq 1 && -n "$line" ]]; then
            echo "$line"
        fi
    done < "$cache_file_path"

    if [[ "$found_vulns" -eq 0 ]]; then
        echo -e " ${GREEN}No vulnerabilities found.${NC}"
    fi
}

function nmap_start_scan() {
    echo -e "${YELLOW}[+]${NC} Starting ${CYAN}nmap${NC} scan: ${YELLOW}$HOST${NC}... [PRESS ENTER TO VIEW/UPDATE PROGRESS]"
    nmap_fragment
    nmap_tcp_ports
    nmap_udp_ports

    if [[ "$intensity" == "insane" || "$intensity" == "aggressive" ]]; then
        nmap_scan_vulnerabilites
    fi
}
