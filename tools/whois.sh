source ././INCLUDE.sh

declare -g scan_params
declare -g cache_file_path

function start_whois_scan() {
    echo -e "${YELLOW}[+]${NC} Starting ${CYAN}whois${NC} scan: ${YELLOW}$HOST${NC}..."
    cache_tools_file_create_without_folder "whois.txt"
    cache_file_path=$(cache_tools_file_getPath "" "whois.txt")

    whois "$HOST" &> "$cache_file_path" &
    ././scripts/pidstat.sh $! "bascan_whois_pidstat.log" &> /dev/null &
    utils_message_loading_pid $! "  ${ORANGE}Domain Info${NC}..."

    if [[ "$(head -n 1 "$cache_file_path")" == "No whois server is known for this kind of object." ]]; then
        echo -e " ${RED}No results${NC}."
    else
        echo -e " ${GREEN}Done${NC}."
    fi
}

