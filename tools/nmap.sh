source ././INCLUDE.sh

function setScanParams() {
    # $1 -> var out 

    local -n _out=$1
    local scan_params=()

    source ././bascan_configs.sh

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

    _out=("${scan_params[@]}")
}

function nmap_getCPUNetworkUsage() {
    # $1 -> PID
    # $2 -> cache file path

    local progress=$(grep -oE "[0-9]+\.[0-9]+%" "$2" | tail -n 1 | sed -E 's/.* ([0-9]+\.[0-9]+)%.*/\1/')
    local remaining=$(grep -oP '\(\K[^)]+' "$2" | tail -n 1)

    if [[ -n "$progress" ]]; then
        echo -e "${CYAN}$progress${NC} done ($remaining)."
    fi
}

function nmap_perform_vulnerabilities() {
    local file_path="$1"
    local -n vulnerabilitiesCount_out=$2
    vulnerabilitiesCount_out=0

    function registerVulnerability() {
        # $1 -> message
        # $2 -> level (0-warning, 1-error, 2-severe)
        for vulnerability in "${vulnerabilities[@]}"; do
            if [[ "$vulnerability" == "$1" ]]; then
                return 1
            fi
        done
        addVulnerability "$1" "$2"
        vulnerabilitiesCount_out=$((vulnerabilitiesCount_out + 1))
        return 0
    }

    if [[ ! -s "$file_path" ]] || grep -qEi 'failed|error|connection refused' "$file_path"; then
        return 1
    fi

    if grep -qE '22/tcp\s+open' "$file_path"; then
        registerVulnerability "(Nmap) SSH port 22 is open." 1
    fi

    if grep -qE '23/tcp\s+open' "$file_path"; then
        registerVulnerability "(Nmap) Telnet port 23 is open (insecure service)." 2
    fi

    if grep -qE '3389/tcp\s+open' "$file_path"; then
        registerVulnerability "(Nmap) RDP port 3389 is open." 1
    fi

    if grep -qEi 'vsftpd\s+2\.3\.4' "$file_path"; then
        registerVulnerability "(Nmap) vsftpd 2.3.4 detected, known backdoor vulnerability." 2
    fi

    if grep -qEi 'apache.*httpd.*2\.2' "$file_path"; then
        registerVulnerability "(Nmap) Apache HTTPD 2.2 detected, outdated version." 1
    fi

    if grep -qE 'udp open' "$file_path"; then
        registerVulnerability "(Nmap) UDP ports are open, verify for possible vulnerabilities." 0
    fi

    if grep -qE 'open\s+unknown' "$file_path"; then
        registerVulnerability "(Nmap) Open ports with unknown services detected." 0
    fi

    return 0
}

function nmap_perform_result() {
    # $1 -> Cache file path
    # $2 -> Title
    # [optional] $3 -> outputfile

    local status=0
    local readingResult=0
    local outputfile="$3"
    ports_scanned=()

    while read -r line; do
        if [[ "$readingResult" -eq 1 ]]; then
            if [[ -z "$line" ]]; then
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
            utils_message_loading_pid $! "  ${ORANGE}$2${NC} (without verification ping)..." nmap_getCPUNetworkUsage "$1" "$outputfile"
            status=1
            break
        fi

        if [[ "$line" =~ ^PORT && "$line" =~ STATE && "$line" =~ SERVICE ]]; then
            readingResult=1
            continue
        fi
    done < <(cat "$1")

    local found_vulnerabilities=0
    nmap_perform_vulnerabilities "$1" found_vulnerabilities

    if [[ -n "$outputfile" ]]; then
        if [[ "$readingResult" -eq 0 ]]; then
            echo -e " ${RED}No results${NC}." >> "$outputfile"
        elif [[ "$status" -eq 0 ]]; then
            echo -e " ${GREEN}Done${NC}. (${#ports_scanned[@]} results, $found_vulnerabilities vulnerabilities)" >> "$outputfile"
        else
            echo -e " ${RED}Fail${NC}." >> "$outputfile"
        fi
    else
        if [[ "$readingResult" -eq 0 ]]; then
            echo -e " ${RED}No results${NC}."
        elif [[ "$status" -eq 0 ]]; then
            echo -e " ${GREEN}Done${NC}. (${#ports_scanned[@]} results, $found_vulnerabilities vulnerabilities)"
        else
            echo -e " ${RED}Fail${NC}."
        fi
    fi

    return "$status"
}

function nmap_scan_mode() {
    # $1 -> mode (fragment, tcp, udp, quick, full_tcp, full_udp, os_detect)
    # [optional] $2 -> outputfile

    local mode="$1"
    local outputfile="$2"
    local title=""
    local scan_file=""
    local -a scan_params=()

    cache_tools_file_create "nmap" "${mode}.log"
    local cache_file_path=$(cache_tools_file_getPath "nmap" "${mode}.log")

    source ././bascan_configs.sh
    setScanParams scan_params

    case "$mode" in
        fragment)
            title="Fragment Packets"
            scan_params+=("-f")
            ;;

        tcp)
            title="TCP Ports"
            if [[ "$intensity" == "insane" || "$intensity" == "aggressive" ]]; then
                scan_params+=("-p-")
            fi
            scan_params+=("-sV")
            ;;

        udp)
            title="UDP Ports"
            if [[ "$intensity" == "insane" || "$intensity" == "aggressive" ]]; then
                scan_params+=("-p-")
            fi
            scan_params+=("-sU")
            ;;

        quick)
            title="Quick Scan"
            scan_params+=("-T4" "-F" "-sV")
            ;;

        full_tcp)
            title="Full TCP Scan"
            scan_params+=("-p-" "-sV" "-T4")
            ;;

        full_udp)
            title="Full UDP Scan"
            scan_params+=("-p-" "-sU" "-T4")
            ;;

        os_detect)
            title="OS Detection"
            scan_params+=("-O" "-T4")
            ;;

        *)
            echo "Unknown nmap scan mode: $mode"
            return 1
            ;;
    esac

    nmap "${scan_params[@]}" "$HOST" &> "$cache_file_path" &
    ././scripts/pidstat.sh $! "bascan_nmap_pidstat.log" &> /dev/null &
    utils_message_loading_pid $! "  ${ORANGE}$title${NC}..." nmap_getCPUNetworkUsage "$cache_file_path" "$outputfile"

    while nmap_perform_result "$cache_file_path" "$title" "$outputfile"; do
        break
    done
}

function start_nmap_scan() {
    echo -e "${YELLOW}[+]${NC} Starting ${CYAN}nmap${NC} scan: ${YELLOW}$HOST${NC}... [PRESS ENTER TO VIEW/UPDATE PROGRESS]"

    source ././bascan_configs.sh

    local modes=("fragment" "tcp" "udp" "quick" "full_tcp" "full_udp" "os_detect")

    if [[ "$multitrhead" == true ]]; then
        processesPid=()

        for mode in "${modes[@]}"; do
            cache_tools_file_create "nmap" "${mode}.log.bak"
        done

        declare -A cache_files
        
        for mode in "${modes[@]}"; do
            cache_files[$mode]=$(cache_tools_file_getPath "nmap" "${mode}.log.bak")
        done

        for mode in "${modes[@]}"; do
            (nmap_scan_mode "$mode" "${cache_files[$mode]}") &
            processesPid+=($!)
        done

        function checkProcessesIsRunning() {
            tput rc

            for mode in "${modes[@]}"; do
                tput el
                content=$(tail -n 1 "${cache_files[$mode]}")

                if [[ -n "$content" ]]; then
                    echo -ne "$content\n"
                else
                    echo
                fi
            done

            for pid in "${processesPid[@]}"; do
                if kill -0 "$pid" 2>/dev/null; then
                    return 0
                fi
            done

            return 1
        }

        tput sc

        while checkProcessesIsRunning; do
            sleep 0.1
        done

        checkProcessesIsRunning

        for mode in "${modes[@]}"; do
            rm -f "${cache_files[$mode]}"
        done

        return 0
    fi

    for mode in "${modes[@]}"; do
        nmap_scan_mode "$mode"
    done

    return 0
}
