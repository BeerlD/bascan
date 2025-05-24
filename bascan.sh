#!/bin/bash

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
    
        exec "$0" "$@"
    fi

    exit 1
}

enter_alt_screen

# ======== VARIABLES / CONSTANTS
source ./lib/colors.sh
source ./modules/cache.sh
source ./tools/nmap.sh
source ./tools/scanless.sh

if [ $# -eq 0 ]; then
    echo -e "${RED}[-]${NC} No host avaliable."
    sleep 3
    close
fi

chmod +x scripts/pidstat.sh

trap 'stty echo icanon; tput cnorm; exit' INT TERM

# ======== HEADER
exit_alt_screen
enter_alt_screen

echo -e "${RED}$(toilet -f big BASCAN)${NC}"
cache_folder_create

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

    if [[ "$lowerUserInput" == "scan" || "$lowerUserInput" =~ ^scan\  ]]; then
        if [[ "${#userInput}" -ge 5 ]]; then
            if [[ "${lowerUserInput:5}" == "ports" ]]; then
                scanless_start_scan
                nmap_start_scan
                continue
            fi
        fi

        if [[ "$lowerUserInput" != "scan" ]]; then
           echo -e "${RED}ERROR${NC} Invalid scan operation: '${userInput:5}'."
        fi
        
        echo -e "\nUsage: scan <operation>"
        echo "  Operations:"
        echo "    ports - scan ports vulnerabilities"
        echo "    subdomains - scan subdomains vulnerabilities"
        echo ""
        continue
    fi

    if [[ "$lowerUserInput" == "install" || "$lowerUserInput" =~ ^install\  ]]; then
        if [[ "${#userInput}" -ge 8 ]]; then
            packages_to_install=("python3" "python3-httpx" "toilet" "nmap" "nikto")
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

            if [[ $package_selected == "scanless" || $package_selected == "all" ]]; then
                echo -ne "${YELLOW}[+]${NC} Installing package: ${CYAN}scanless${NC}... "

                if ! sudo apt install -y "python3" > /dev/null 2>&1; then
                    echo -e "${RED}Error${NC}."
                elif ! pip install scanless --user --break-system-packages > /dev/null 2>&1; then
                    echo -e "${RED}Error${NC}."
                else
                    echo -e "${GREEN}Done${NC}."
                fi

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
        echo "    scanless - Anonymous scanning via online services."
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
                                cache_config_file_setValue 2 "$value"
                                echo -e "${GRREN}SETTED${NC} option intensity setted to: '$value'."
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
                echo "    * slowly     - Sends packets extremely slowly, useful for avoiding detection by IDS/IPS." # -T0
                echo "    * low        - A little faster than slowly, but still very discreet to avoid security alarms." # -T1
                echo "    * middle     - Reduces bandwidth and CPU usage, useful for congested networks." # -T2
                echo "    * normal     - Balanced speed and discretion (default, recommended)." # -T3
                echo "    * aggressive - Speeds up scanning, ideal for fast networks with no security restrictions." # -T4
                echo "    * insane     - Maximum speed, can overload the network and be easily detected by firewalls." # -T5
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

    echo -e "${RED}ERROR${NC} Invalid command: '$userInput'."
done

close
