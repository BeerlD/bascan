#!/bin/bash

if [ "$(id -u)" -ne 0 ]; then
    echo -e "\e[31m[-]\e[0m Error: This script must be run as root (use sudo)."
    exit 1
fi


if [ "$#" -eq 0 ]; then
    echo -e "\e[31m[-]\e[0m No host or command was specified."
    exit 0
fi

if [ "$1" == "update" ]; then
    sudo bash -c "$(wget -qO- https://raw.githubusercontent.com/BeerlD/bascan/refs/heads/main/install.sh)"
    exit 1
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

chmod +x scripts/pidstat.sh

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
        break
    fi

    if [[ "$lowerUserInput" == "clear" ]]; then
        tput clear
        echo -e "${RED}$(toilet -f big BASCAN)${NC}"
        continue
    fi

    echo ""

    if [[ "$lowerUserInput" == "restart" ]]; then
        close "1"
    fi

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
            elif [[ "${lowerUserInput:5}" == "informations" ]]; then
                start_dig_scan
                start_whois_scan
            elif [[ "${lowerUserInput:5}" == "all" ]]; then
                start_dig_scan
                start_whois_scan
                start_nmap_scan
            fi

            continue
        fi

        if [[ "$lowerUserInput" != "scan" ]]; then
           echo -e "${RED}ERROR${NC} Invalid scan operation: '${userInput:5}'."
        fi
        
        echo -e "\nUsage: scan <operation>"
        echo "  Operations:"
        echo "    network - scan network vulnerabilities"
        echo "    informations - scan public informations"
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

        echo -e "\nUsage: install <package>"
        echo "  Packages:"
        echo "    all - Install all packages."
        echo "    nmap - Network scanner, identifier of active hosts, open ports, services and operating systems."
        echo "    whois - A tool for retrieving registration information of domains and IP addresses."
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

                echo -e "\nUsage: option set <option> <value>"
                echo "Options:"
                echo "  intensity"
                echo "    * slowly     - Sends packets extremely slowly, useful for avoiding detection by IDS/IPS."
                echo "    * low        - A little faster than slowly, but still very discreet to avoid security alarms."
                echo "    * middle     - Reduces bandwidth and CPU usage, useful for congested networks."
                echo "    * normal     - Balanced speed and discretion (default, recommended)."
                echo "    * aggressive - Speeds up scanning, ideal for fast networks with no security restrictions."
                echo "    * insane     - Maximum speed, can overload the network and be easily detected by firewalls."
                echo "  fastmode - Fast mode, scan fewer vulnerabilities (true to enable, false to disable)."
                echo "  multithread - Scan asynchronously (true to enable, false to disable)."
                echo "  new_cache_folder - Creates a new cache folder with each scan (true to enable, false to disable)."
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

        echo -e "\nUsage: option <operation> [...]"
        echo "  Operations:"
        echo "    set <option> <value> - set an option value"
        echo "    show - show options"
        echo ""
        continue
    fi

    if [[ "$lowerUserInput" == "kill" ]]; then
        pkill -f bascan.sh
    fi

    echo -e "${RED}ERROR${NC} Invalid command: '$userInput'."
done

close
