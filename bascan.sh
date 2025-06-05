#!/bin/bash

if [ "$(id -u)" -ne 0 ]; then
    echo -e "\e[31m[-]\e[0m Error: This script must be run as root (use sudo)."
    exit 1
fi

declare -g HOST
HOST=""

#!/bin/bash

HOST=""

function help_message() {
    echo "
Bascan (https://github.com/BeerlD/bascan)
Copyright (c) 2025 BeerlD

Examples:   
    bascan [Options] <host>
    bascan [Options] -h <host>
    bascan [Options] --host <host>
    bascan [Command]

Options:
    --host, -h : The host or target to be analyzed.

Commands:
    update : Update to latest version.
    "
}

for ((argIndex=0; argIndex<$#; argIndex++)); do
    eval "arg=\${$((argIndex+1))}"

    if [ "$arg" == "update" ]; then
        sudo bash -c "$(wget -qO- https://raw.githubusercontent.com/BeerlD/bascan/refs/heads/main/install.sh)"
        exit 1
    fi

    if [ "$arg" == "--help" ]; then
        help_message
        exit 1
    fi

    if [[ ("$arg" == "--host" || "$arg" == "-h") && $((argIndex+2)) -le $# ]]; then
        eval "HOST=\${$((argIndex+2))}"
        ((argIndex++))
        continue
    fi

    if [[ -n "$HOST" || "$arg" =~ ^- ]]; then
        echo -e "\n\e[31m[-]\e[0m Invalid option: '$arg'."
        help_message
        exit 0
    fi

    HOST="$arg"
done

unset -f help_message

if [ ! -n "$HOST" ]; then
    echo -e "\e[31m[-]\e[0m No host was specified (use --help to learn more)."
    exit 0
fi

if ! command -v toilet >/dev/null 2>&1 || ! command -v figlet >/dev/null 2>&1; then 
    echo -ne "\e[33m[+]\e[0m Installing packages: \e[36mtoilet\e[0m and \e[36mfiglet\e[0m... "

    if ! sudo apt install -y toilet toilet-fonts figlet >/dev/null 2>&1; then
        echo -e "\e[31mError\e[0m."
        exit 0
    fi

    echo -e "\e[32mDone\e[0m."
    sleep 2
fi

# ======== FUNCTIONS

function enter_alt_screen() {
    tput smcup
    tput cup 0 0
}

function exit_alt_screen() {
    tput rmcup
}
  
function close() {
    stty echo icanon
    tput cnorm
    exit_alt_screen

    if [[ "$#" -ge 1 && "$1" -eq 1 ]]; then
        script_path="$(realpath "$0")"
        exec "$script_path" "$1"
    fi

    exit 1
}

# ======== VARIABLES / CONSTANTS

SOURCE="${BASH_SOURCE[0]}"

while [ -L "$SOURCE" ]; do
  DIR="$(cd -P "$(dirname "$SOURCE")" >/dev/null 2>&1 && pwd)"
  SOURCE="$(readlink "$SOURCE")"
  [[ "$SOURCE" != /* ]] && SOURCE="$DIR/$SOURCE"
done

declare -g SCRIPT_DIR
SCRIPT_DIR="$(cd -P "$(dirname "$SOURCE")" >/dev/null 2>&1 && pwd)"

source "$SCRIPT_DIR/lib/colors.sh"
source "$SCRIPT_DIR/modules/cache.sh"
source "$SCRIPT_DIR/INCLUDE.sh"
source "$SCRIPT_DIR/tools/INCLUDE.sh"

# ======== HEADER
enter_alt_screen
trap 'stty echo icanon; tput cnorm; exit' INT TERM
echo -e "${RED}$(toilet -f big BASCAN)${NC}"

while true; do
    stty echo icanon
    tput cnorm
    read -p "$(echo -e "${BLUE}>${NC} ")" userInput
    userInput=$(echo "$userInput" | tr -cd '[:alnum:] ')
    stty -echo -icanon
    tput civis

    lowerUserInput="${userInput,,}"

    if [[ "${#userInput}" -eq 0 ]]; then
        continue
    fi

    if [[ "$userInput" == "exit" ]]; then
        close
    fi

    if [[ "$lowerUserInput" == "clear" ]]; then
        tput clear
        echo -e "${RED}$(toilet -f big BASCAN)${NC}"
        continue
    fi

    echo ""

    if [[ "$lowerUserInput" == "vuln" ]]; then
        for ((index=0;index<"${#vulnerabilities[@]}";index++)); do
            if [[ "${vulnerabilities_level[$index]}" == 0 ]]; then
                echo -e "${YELLOW}Warning${NC}: ${vulnerabilities[$index]}"
            elif [[ "${vulnerabilities_level[$index]}" == 1 ]]; then
                echo -e "${ORANGE}Issue${NC}: ${vulnerabilities[$index]}"
            elif [[ "${vulnerabilities_level[$index]}" == 2 ]]; then
                echo -e "${RED}Vulnerability${NC}: ${vulnerabilities[$index]}"
            else
                echo -e "${vulnerabilities[$index]}"
            fi
        done

        echo ""
        continue
    fi

    if [[ "$lowerUserInput" == "scan" || "$lowerUserInput" =~ ^scan\  ]]; then
        if [[ "${#userInput}" -ge 5 ]]; then
            vulnerabilities=()
            vulnerabilities_level=()

            if [[ -f "./bascan_configs.sh" ]]; then
                source ./bascan_configs.sh
                cache_folder_create "$new_cache_folder"
            else
                cache_folder_create false
            fi

            if [[ "${lowerUserInput:5}" == "network" ]]; then
                start_nmap_scan
                continue
            elif [[ "${lowerUserInput:5}" == "informations" ]]; then
                start_dig_scan
                start_whois_scan
                continue
            elif [[ "${lowerUserInput:5}" == "all" ]]; then
                start_dig_scan
                start_whois_scan
                start_nmap_scan
                continue
            fi
        fi

        if [[ "$lowerUserInput" != "scan" ]]; then
           echo -e "${RED}ERROR${NC} Invalid scan operation: '${userInput:5}'."
        fi
        
        echo -e "• Usage ${BLUE}─>${NC} scan <operation>"
        echo "${BLUE}╰─>${NC} network      ${BLUE}─>${NC} Scan network vulnerabilities."
        echo "${BLUE}╰─>${NC} informations ${BLUE}─>${NC} Scan public informations."
        echo ""
        continue
    fi

    if [[ "$lowerUserInput" == "install" || "$lowerUserInput" =~ ^install\  ]]; then
        if [[ "${#userInput}" -ge 8 ]]; then
            packages_to_install=("nmap" "whois")
            package_selected="${lowerUserInput:8}"
            findedPackage=0

            if [[ $package_selected == "all" ]]; then
                for package in "${packages_to_install[@]}"; do
                    echo -ne "${YELLOW}[+]${NC} Installing package: ${CYAN}$package${NC}... "

                    if ! sudo apt install -y "$package" > /dev/null 2>&1; then
                        echo -e "${RED}Error${NC}."
                        continue
                    fi

                    echo -e "${GREEN}Done${NC}."
                done

                findedPackage=1
            fi
            
            if [[ $findedPackage -eq 0 ]]; then
                for package in "${packages_to_install[@]}"; do
                    if [[ $package == $package_selected ]]; then
                        findedPackage=1
                        echo -ne "${YELLOW}[+]${NC} Installing package: ${CYAN}$package${NC}... "

                        if ! sudo apt install -y "$package" > /dev/null 2>&1; then
                            echo -e "${RED}Error${NC}."
                            break
                        fi

                        echo -e "${GREEN}Done${NC}."
                        break
                    fi
                done
            fi

            echo ""

            if [[ $findedPackage -eq 1 ]]; then
                continue
            fi
        fi

        if [[ "$lowerUserInput" != "install" ]]; then
           echo -e "${RED}ERROR${NC} Invalid package: '${userInput:8}'."
        fi

        echo -e "• Usage ${BLUE}─>${NC} install <package>"
        echo "${BLUE}╰─>${NC} all   ${BLUE}─>${NC} Install all packages."
        echo "${BLUE}╰─>${NC} nmap  ${BLUE}─>${NC} Network scanner, identifier of active hosts, open ports, services and operating systems."
        echo "${BLUE}╰─>${NC} whois ${BLUE}─>${NC} A tool for retrieving registration information of domains and IP addresses."
        echo ""
        continue
    fi

    if [[ "$lowerUserInput" == "option" || "$lowerUserInput" =~ ^option\  ]]; then
        if [[ "${#userInput}" -ge 7 ]]; then
            if [[ "${lowerUserInput:7}" =~ ^set ]]; then
                if [[ "${#userInput}" -ge 11 ]]; then
                    option="${lowerUserInput:11}"

                    if [[ "$option" =~ ^intensity ]]; then
                        if [[ "$option" != "intensity" ]]; then
                            value="${option:10}" 
                            values=("slowly" "low" "middle" "normal" "aggressive" "insane")
                            match=false

                            for v in "${values[@]}"; do
                                if [[ "$value" == "$v" ]]; then
                                    match=true
                                    break
                                fi
                            done

                            if [[ "$match" == false ]]; then
                                echo -e "${RED}ERROR${NC} Invalid option value: '$value'."
                            else
                                cache_config_file_setValue 3 "\"$value\""
                                echo -e "${GREEN}SETTED${NC} option intensity setted to: '$value'."
                                echo ""
                                continue
                            fi
                        fi
                    elif [[ "$option" =~ ^multithread ]]; then
                        if [[ "$option" != "multithread" ]]; then
                            value="${option:12}"

                            if [[ "$value" == "true" || "$value" == "false" ]]; then
                                cache_config_file_setValue 4 "$value"
                                echo -e "${GREEN}SETTED${NC} option multithread setted to: '$value'."
                                echo ""
                                continue
                            fi
                        fi
                    elif [[ "$option" =~ ^fastmode ]]; then
                        if [[ "$option" != "fastmode" ]]; then
                            value="${option:9}"

                            if [[ "$value" == "true" || "$value" == "false" ]]; then
                                cache_config_file_setValue 5 "$value"
                                echo -e "${GREEN}SETTED${NC} option fastmode setted to: '$value'."
                                echo ""
                                continue
                            fi
                        fi
                    elif [[ "$option" =~ ^new_cache_folder ]]; then
                        if [[ "$option" != "new_cache_folder" ]]; then
                            value="${option:17}"

                            if [[ "$value" == "true" || "$value" == "false" ]]; then
                                cache_config_file_setValue 6 "$value"
                                echo -e "${GREEN}SETTED${NC} option new_cache_folder setted to: '$value'."
                                echo ""
                                continue
                            fi
                        fi
                    else
                        echo -e "${RED}ERROR${NC} Invalid option: '$option'."
                        echo ""
                        continue
                    fi
                fi

                echo -e "• Usage ${BLUE}─>${NC} option set <option> <value>"
                echo "${BLUE}╰─>${NC} • Options:"
                echo "    ${BLUE}╰─>${NC} • intensity <value>"
                echo "        ${BLUE}╰─>${NC} slowly     ${BLUE}─>${NC} Sends packets extremely slowly, useful for avoiding detection by IDS/IPS."
                echo "        ${BLUE}╰─>${NC} low        ${BLUE}─>${NC} A little faster than slowly, but still very discreet to avoid security alarms."
                echo "        ${BLUE}╰─>${NC} middle     ${BLUE}─>${NC} Reduces bandwidth and CPU usage, useful for congested networks."
                echo "        ${BLUE}╰─>${NC} normal     ${BLUE}─>${NC} Balanced speed and discretion (default, recommended)."
                echo "        ${BLUE}╰─>${NC} aggressive ${BLUE}─>${NC} Speeds up scanning, ideal for fast networks with no security restrictions."
                echo "        ${BLUE}╰─>${NC} insane     ${BLUE}─>${NC} Maximum speed, can overload the network and be easily detected by firewalls."
                echo "    ${BLUE}╰─>${NC} fastmode         ${BLUE}─>${NC} Fast mode, scan fewer vulnerabilities (true to enable, false to disable)."
                echo "    ${BLUE}╰─>${NC} multithread      ${BLUE}─>${NC} Scan asynchronously (true to enable, false to disable)."
                echo "    ${BLUE}╰─>${NC} new_cache_folder ${BLUE}─>${NC} Creates a new cache folder with each scan (true to enable, false to disable)."
                echo ""
                continue
            fi

            if [[ "${lowerUserInput:7}" == "show" ]]; then
                continue
            fi

            echo -e "${RED}ERROR${NC} Invalid option operation: '${userInput:7}'."
            echo ""
            continue
        fi

        echo -e "• Usage ${BLUE}─>${NC} option <operation> [...]"
        echo "${BLUE}╰─>${NC} • Operations:"
        echo "    ${BLUE}╰─>${NC} set <option> <value> ${BLUE}─>${NC} set an option value"
        echo "    ${BLUE}╰─>${NC} show                 ${BLUE}─>${NC} show options"
        echo ""
        continue
    fi

    if [[ "$lowerUserInput" == "help" ]]; then
        echo -e "• Commands:
${BLUE}╰─>${NC} install ${BLUE}─>${NC} Install packages and tools.
${BLUE}╰─>${NC} scan    ${BLUE}─>${NC} Run scan on host.
${BLUE}╰─>${NC} kill    ${BLUE}─>${NC} Interrupt the bascan process.
${BLUE}╰─>${NC} option  ${BLUE}─>${NC} Manage scanning and preferences options.
${BLUE}╰─>${NC} vuln    ${BLUE}─>${NC} Show vulnerabilities found after a scan.
${BLUE}╰─>${NC} lucid   ${BLUE}─>${NC} Run the Lucid DDos attack script (you are responsible for its use).
${BLUE}╰─>${NC} help    ${BLUE}─>${NC} Show this message.
        "
        continue
    fi

    if [[ "$lowerUserInput" == "lucid" ]]; then
        echo -ne "${YELLOW}[+]${NC} Installing ${CYAN}python3${NC} and ${CYAN}python3-pip${NC}... "

        if ! sudo apt install python3 python3-pip > /dev/null 2>&1; then
            echo -e "${RED}Error${NC}.\n"
            continue
        fi

        echo -e "${GREEN}Done${NC}."
        echo -ne "${YELLOW}[+]${NC} Installing packages ${CYAN}requests${NC}, ${CYAN}rich${NC}, ${CYAN}inquirer${NC} and ${CYAN}tqdm${NC}... "

        if ! pip3 install requests rich inquirer tqdm --break-system-packages > /dev/null 2>&1; then
            echo -e "${RED}Error${NC}.\n"
            continue
        fi

        echo -e "${GREEN}Done${NC}."

        sleep 3
        CURRENT_PATH="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
        cd "$SCRIPT_DIR/scripts/Lucid_DDoS/"

        function start_lucid() {
            python3 main.py
        }

        trap start_lucid SIGINT EXIT
        cd "$CURRENT_PATH"
        continue
    fi

    if [[ "$lowerUserInput" == "kill" ]]; then
        pkill -f bascan.sh
    fi

    echo -e "${RED}ERROR${NC} Invalid command: '$userInput'."
done
