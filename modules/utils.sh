source ././lib/colors.sh

utils_message_loading_pid() {
    chars=("/" "-" "\\" "|")
    charIndex=0

    while ps -p "$1" > /dev/null 2>&1; do
        echo -ne "$2 [${chars[$charIndex]}]\r"
        ((charIndex++))
        sleep 0.2

        if [[ "$charIndex" -eq 4 ]]; then
            charIndex=0
        fi
    done

    echo -ne "\r$2"
}