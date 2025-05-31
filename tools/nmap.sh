source ././INCLUDE.sh

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
    # [optional] $3 -> outputfile

    local status=0
    local readingResult=0
    local outputfile="$3"

    while read line; do
        if [[ "$readingResult" -eq 1 ]]; then
            if [[ "${#line}" -eq 0 ]]; then
                break
            fi

            ports_scanned+=("$line")
            continue
        fi

        if [[ "$line" =~ try\ -Pn ]]; then
            if [[ -n "$outputfile" ]]; then
                echo -e " ${RED}Fail${NC}." >> "$outputfile"
            else
                echo -e " ${RED}Fail${NC}."
            fi

            nmap "${scan_params[@]}" -Pn "$HOST" &> "$1" &
            ././scripts/pidstat.sh $! "bascan_nmap_pidstat.log" &> /dev/null &
            utils_message_loading_pid $! "  ${ORANGE}$2${NC} (without verification ping)..." nmap_getCPUNetworkUsage "$outputfile"
            status=1
            break
        fi

        if [[ "$line" =~ ^PORT && "$line" =~ STATE && "$line" =~ SERVICE ]]; then
            readingResult=1
            continue
        fi
    done < <(cat "$1")

    if [[ -n "$outputfile" ]]; then
        if [[ "$readingResult" -eq 0 ]]; then
            echo -e " ${RED}No results${NC}." >> "$outputfile"
        elif [[ "$status" -eq 0 ]]; then
            echo -e " ${GREEN}Done${NC}. (${#ports_scanned[@]} results)" >> "$outputfile"
        else
            echo -e " ${RED}Fail${NC}." >> "$outputfile"
        fi
    else
        if [[ "$readingResult" -eq 0 ]]; then
            echo -e " ${RED}No results${NC}."
        elif [[ "$status" -eq 0 ]]; then
            echo -e " ${GREEN}Done${NC}. (${#ports_scanned[@]} results)"
        else
            echo -e " ${RED}Fail${NC}."
        fi
    fi
    
    return "$status"
}

function nmap_fragment() {
    # [optional] $1  -> output
    local outputfile="$1"

    cache_tools_file_create "nmap_logs" "fragments_packets.txt"
    cache_file_path=$(cache_tools_file_getPath "nmap_logs" "fragments_packets.txt")

    source ././bascan_configs.sh

    setScanParams
    scan_params+=("-f")

    local title="Fragments packets"

    nmap "${scan_params[@]}" "$HOST" &> "$cache_file_path" &
    ././scripts/pidstat.sh $! "bascan_nmap_pidstat.log" &> /dev/null &
    utils_message_loading_pid $! "  ${ORANGE}$title${NC}..." nmap_getCPUNetworkUsage "$outputfile"
    
    while nmap_perform_result "$cache_file_path" "$title" "$outputfile"; do
        break
    done
}

function nmap_tcp_ports() {
    # [optional] $1  -> output
    local outputfile="$1"

    cache_tools_file_create "nmap_logs" "ports_tcp.txt"
    cache_file_path=$(cache_tools_file_getPath "nmap_logs" "ports_tcp.txt")

    source ././bascan_configs.sh
    setScanParams

    if [[ "$intensity" == "insane" || "$intensity" == "aggressive" ]]; then
        scan_params+=("-p-")
    fi

    scan_params+=("-sV")
    local title="TCP Ports"

    nmap "${scan_params[@]}" "$HOST" &> "$cache_file_path" &
    ././scripts/pidstat.sh $! "bascan_nmap_pidstat.log" &> /dev/null &
    utils_message_loading_pid $! "  ${ORANGE}$title${NC}..." nmap_getCPUNetworkUsage "$outputfile"

    while nmap_perform_result "$cache_file_path" "$title" "$outputfile"; do
        break
    done
}

function nmap_udp_ports() {
    # [optional] $1  -> output
    local outputfile="$1"

    cache_tools_file_create "nmap_logs" "ports_udp.txt"
    cache_file_path=$(cache_tools_file_getPath "nmap_logs" "ports_udp.txt")

    source ././bascan_configs.sh
    setScanParams

    if [[ "$intensity" == "insane" || "$intensity" == "aggressive" ]]; then
        scan_params+=("-p-")
    fi

    scan_params+=("-sU")
    local title="UDP Ports"

    nmap "${scan_params[@]}" "$HOST" &> "$cache_file_path" &
    ././scripts/pidstat.sh $! "bascan_nmap_pidstat.log" &> /dev/null &
    utils_message_loading_pid $! "  ${ORANGE}$title${NC}..." nmap_getCPUNetworkUsage "$outputfile"

    while nmap_perform_result "$cache_file_path" "$title" "$outputfile"; do
        break
    done
}

function nmap_scan_vulnerabilites() {
    echo ""
}

function start_nmap_scan() {
    echo -e "${YELLOW}[+]${NC} Starting ${CYAN}nmap${NC} scan: ${YELLOW}$HOST${NC}... [PRESS ENTER TO VIEW/UPDATE PROGRESS]"
    
    source ././bascan_configs.sh

    if [[ "$multitrhead" == true ]]; then
        processesPid=()

        cache_tools_file_create "nmap_results" "fragments.txt"
        cache_tools_file_create "nmap_results" "ports_tcp.txt"
        cache_tools_file_create "nmap_results" "ports_udp.txt"
        fragment_cache_file=$(cache_tools_file_getPath "nmap_results" "fragments.txt")
        tcp_ports_cache_file=$(cache_tools_file_getPath "nmap_results" "ports_tcp.txt")
        udp_ports_cache_file=$(cache_tools_file_getPath "nmap_results" "ports_udp.txt")
    
        (nmap_fragment "$fragment_cache_file") &
        processesPid+=($!)

        (nmap_tcp_ports "$tcp_ports_cache_file") &
        processesPid+=($!)

        (nmap_udp_ports "$udp_ports_cache_file") &
        processesPid+=($!)

        function checkProcessesIsRunning() {
            tput rc

            for file in "$fragment_cache_file" "$tcp_ports_cache_file" "$udp_ports_cache_file"; do
                tput el 
                content=$(tail -n 1 "$file")
                
                if [[ -n "$content" ]]; then
                    echo -ne "$content\n"
                else
                    echo
                fi
            done

            for processPid in "${processesPid[@]}"; do
                if kill -0 "$processPid" 2>/dev/null; then
                    return 0
                fi
            done

            return 1
        }

        while checkProcessesIsRunning; do
            sleep 0.1
        done

        return 0
    fi

    nmap_fragment
    nmap_tcp_ports
    nmap_udp_ports
    return 0
}
