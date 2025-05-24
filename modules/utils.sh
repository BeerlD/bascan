source ././lib/colors.sh

utils_message_loading_pid() {
    chars=("/" "-" "\\" "|")
    charIndex=0

    while ps -p "$1" > /dev/null 2>&1; do
        if [[ "${#}" -eq 3 ]]; then
            func=$3
            echo -ne "$2 [${chars[$charIndex]}] $($func $1)\r"
        else
            echo -ne "$2 [${chars[$charIndex]}]\r"
        fi
        
        ((charIndex++))
        sleep 0.2

        if [[ "$charIndex" -eq 4 ]]; then
            charIndex=0
        fi
    done

    echo -ne "\r$2"
}
