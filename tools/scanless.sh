source ././include.sh

function scanless_getCPUNetworkUsage() {
    # $1 -> PID
    # $2 -> cache file path

    echo -e "CPU:${CYAN}$(ps -p $1 -o %cpu=)%${NC} -${ORANGE}$(ps -p $$ -o %cpu=)%${NC} $(head -n 1 bascan_scanless_pidstat.log.bak 2>/dev/null)"
}

function scanless_viewdns() {
    cache_tools_file_create "scanless" "viewdns.txt"
    cache_file_path=$(cache_tools_file_getPath "scanless" "viewdns.txt")

    scanless -s viewdns -t $HOST > $cache_file_path &
    ././scripts/pidstat.sh $! "bascan_scanless_pidstat.log" > /dev/null &
    utils_message_loading_pid $! "  ${ORANGE}Viewdns SCANNER${NC}..." scanless_getCPUNetworkUsage

    readingResult=0

    while read line; do
        if [[ "$readingResult" -eq 1 ]]; then
            if [[ "${#line}" -eq 0 ]]; then
                break
            fi

            ports_scanned+=("$line")
            continue
        fi

        if [[ "$line" =~ ^PORT && "$line" =~ STATE && "$line" =~ SERVICE ]]; then
            readingResult=1
            continue
        fi
    done < <(cat "$cache_file_path")

    echo -e " ${GREEN}Done${NC}. (${#ports_scanned[@]} results)"
}

function scanless_start_scan() {
    echo -e "${YELLOW}[+]${NC} Starting ${CYAN}scanless${NC} scan: ${YELLOW}$HOST${NC}..."
    scanless_viewdns
}
