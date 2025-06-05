source "$SCRIPT_DIR/lib/colors.sh"

utils_message_loading_pid() {
    # $1 -> pid
    # $2 -> message
    # $3 -> function
    # $4 -> cache file path
    # [optional] $5 -> outputfile

    local chars=("/" "-" "\\" "|")
    local charIndex=0
    local outputfile="$5"

    while ps -p "$1" > /dev/null 2>&1; do
        if [[ "${#}" -ge 3 ]] && declare -F "$3" > /dev/null; then
            func=$3

            if [[ -n "$outputfile" ]]; then
                echo -ne "\r$2 [${chars[$charIndex]}] $($func "$1" "$4")$(tput el)" > "$outputfile"
            else
                echo -ne "\r$2 [${chars[$charIndex]}] $($func "$1" "$4")$(tput el)"
            fi
        else
            if [[ -n "$outputfile" ]]; then
                echo -ne "\r$2 [${chars[$charIndex]}]$(tput el)" > "$outputfile"
            else
                echo -ne "\r$2 [${chars[$charIndex]}]$(tput el)"
            fi
        fi
        
        ((charIndex++))
        sleep 0.2

        if [[ "$charIndex" -eq 4 ]]; then
            charIndex=0
        fi
    done

    if [[ -n "$outputfile" ]]; then
        echo -ne "\r$2$(tput el)" > "$outputfile"
    else
        echo -ne "\r$2$(tput el)"
    fi
}
