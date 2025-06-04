source ././INCLUDE.sh

function whois_perform_result() {
    local file_path="$1"
    local -n vulnerabilitiesCount_out=$2
    vulnerabilitiesCount_out=0

    function registerVulnerability() {
        for vulnerability in "${vulnerabilities[@]}"; do
            if [[ "$vulnerability" == "$1" ]]; then
                return 1
            fi
        done

        addVulnerability "$1" "$2"
        vulnerabilitiesCount_out=$(( $vulnerabilitiesCount_out + 1 ))
        return 0
    }

    exp_date=$(grep -iE 'Expiry Date:|Expiration Date:' "$file_path" | head -n1 | awk '{print $NF}')

    if [[ -n "$exp_date" ]]; then
        exp_seconds=$(date -d "$exp_date" +%s 2>/dev/null)
        now_seconds=$(date +%s)
        days_left=$(( (exp_seconds - now_seconds) / 86400 ))

        if (( days_left < 90 )); then
            registerVulnerability "(Domain) Expiration approaching: $days_left days remaining."
        fi
    fi

    if ! grep -qi 'DNSSEC: signed' "$file_path"; then
        registerVulnerability "(Domain) DNSSEC missing or not enabled."
    fi

    if grep -qi 'Registrant Name:' "$file_path"; then
        if ! grep -qi 'Not Disclosed\|REDACTED' "$file_path"; then
            registerVulnerability "(Domain) Registrant information visible (no privacy protection)."
        fi
    fi

    if grep -qiE 'redemptionPeriod|pendingDelete|clientHold' "$file_path"; then
        registerVulnerability "(Domain) Status indicates possible inactivity or legal issues."
    fi

    if ! grep -qiE 'Registrar: (GoDaddy|CSC|MarkMonitor|NameCheap|Google)' "$file_path"; then
        registerVulnerability "(Domain) Registrar may not be recognized as trustworthy."
    fi
}

function run_whois_mode() {
    local mode_name="$1"
    local whois_args="$2"

    cache_tools_file_create "whois" "$mode_name.log"
    local cache_file_path=$(cache_tools_file_getPath "whois" "$mode_name.log")

    whois $whois_args "$HOST" &> "$cache_file_path" &
    ././scripts/pidstat.sh $! "bascan_whois_pidstat.log" &> /dev/null &
    utils_message_loading_pid $! "  ${ORANGE}Domain Info (${mode_name})${NC}..."

    if grep -qEi 'No whois server is known for this kind of object|No match for|NOT FOUND|No entries found|Object does not exist|Status: free|Domain Status: available|No Data Found' "$cache_file_path"; then
        echo -e " ${RED}No results${NC}."
        return 1
    fi

    local found_vulnerabilities=0
    whois_perform_result "$cache_file_path" found_vulnerabilities

    if [[ "$found_vulnerabilities" -eq 0 ]]; then
        echo -e " ${RED}No results${NC}."
        return 1
    fi

    echo -e " ${GREEN}Done${NC} ($found_vulnerabilities results)."
    return 0
}

function start_whois_scan() {
    echo -e "${YELLOW}[+]${NC} Starting ${CYAN}whois${NC} scan: ${YELLOW}$HOST${NC}..."

    run_whois_mode "default" ""
    run_whois_mode "without_header" "-H"
    run_whois_mode "without_banners" "-B"
    run_whois_mode "thin" "-Q"
    run_whois_mode "no_recursion" "--no-recursion"
    run_whois_mode "combined_HB" "-H -B"
    run_whois_mode "combined_HQ" "-H -Q"
    run_whois_mode "combined_BQ" "-B -Q"
    run_whois_mode "combined_HBQ" "-H -B -Q"
    run_whois_mode "verisign" "--host whois.verisign-grs.com"
    run_whois_mode "iana" "--host whois.iana.org"

    if [[ "$intensity" == "aggressive" || "$intensity" == "insane" ]]; then
        run_whois_mode "country_code_us" "-c us"
        run_whois_mode "country_code_br" "-c br"
    fi
}
