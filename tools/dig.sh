source ././INCLUDE.sh

declare -g scan_params
declare -g cache_file_path

function start_dig_scan() {
    echo -e "${YELLOW}[+]${NC} Starting ${CYAN}dig${NC} scan: ${YELLOW}$HOST${NC}..."

    cache_tools_file_create_without_folder "dig.txt"
    cache_file_path=$(cache_tools_file_getPath "" "dig.txt")

    dig "$HOST" "any +noall +answer" &> "$cache_file_path" &
    ././scripts/pidstat.sh $! "bascan_dig_pidstat.log" &> /dev/null &
    utils_message_loading_pid $! "  ${ORANGE}DNS Records${NC}..."

    echo -e " ${GREEN}Done${NC}."
}
