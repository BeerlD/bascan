source ././INCLUDE.sh

function dig_perform_result() {
    local file_path="$1"
    local -n vulnerabilitiesCount_out=$2
    vulnerabilitiesCount_out=0

    function registerVulnerability() {
        # $1 -> message
        # $2 -> level
        #   0 -> warning
        #   1 -> error
        #   2 -> severe vulnerability
        
        for vulnerability in "${vulnerabilities[@]}"; do
            if [[ "$vulnerability" == "$1" ]]; then
                return 1
            fi
        done

        addVulnerability "$1" "$2"
        vulnerabilitiesCount_out=$((vulnerabilitiesCount_out + 1))
        return 0
    }

    if [[ ! -s "$file_path" ]] || grep -qEi 'no servers could be reached|connection.*failed' "$file_path"; then
        return 1
    fi

    local has_records=$(grep -v '^;' "$file_path" | grep -cE 'IN\s+(A|AAAA|MX|TXT|CNAME|NS|SOA)')
    
    if [[ "$has_records" -eq 0 ]]; then
        registerVulnerability "(DNS) No DNS records found in dig output." 1
    fi

    local ttl_zero_count=$(awk '/IN/ && $2 == 0' "$file_path" | wc -l)
    
    if (( ttl_zero_count > 0 )); then
        registerVulnerability "(DNS) TTL is zero for some records (not recommended)." 1
    fi

    if grep -qE 'IN\s+TXT' "$file_path"; then
        if grep -qE 'v=spf1\s+~all' "$file_path"; then
            registerVulnerability "(DNS) SPF record uses ~all (softfail), consider using -all (fail)." 0
        fi
    fi

    if grep -qE 'IN\s+MX' "$file_path"; then
        local mx_records=$(grep -E 'IN\s+MX' "$file_path" | awk '{print $NF}')
        for mx in $mx_records; do
            if [[ "$mx" == *"gmail.com." || "$mx" == *"outlook.com." ]]; then
                registerVulnerability "(DNS) MX record points to public email provider ($mx)." 0
            fi
        done
    fi
}

function start_dig_scan() {
    echo -e "${YELLOW}[+]${NC} Starting ${CYAN}dig${NC} scan: ${YELLOW}$HOST${NC}..."

    local types=("ANY" "A" "AAAA" "MX" "NS" "TXT" "SOA" "CNAME")
    local found_total=0

    for type in "${types[@]}"; do
        local filename="${type}.log"
        cache_tools_file_create "dig" "$filename"
        local cache_file_path=$(cache_tools_file_getPath "dig" "$filename")

        dig "$HOST" "$type" +noall +answer &> "$cache_file_path" &
        ././scripts/pidstat.sh $! "bascan_dig_pidstat_${type}.log" &> /dev/null &
        utils_message_loading_pid $! "  ${ORANGE}DNS ($type)${NC}..."

        local found=0
        dig_perform_result "$cache_file_path" found

        if [[ "$found" -eq 0 ]]; then
            echo -e " ${RED}No results${NC}."
        else
            echo -e " ${GREEN}Done${NC} (${found} results)."
        fi

        found_total=$((found_total + found))
    done
}
