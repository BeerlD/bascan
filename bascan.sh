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
    sleep 3
    exit_alt_screen
    exit 1
}

enter_alt_screen

# ======== VARIABLES / CONSTANTS
if [ $# -eq 0 ]; then
    echo -e "${RED}[-]${NC} No host avaliable."
    close
fi

source ./lib/colors.sh
source ./modules/cache.sh
source ./tools/nmap.sh

# ======== HEADER
exit_alt_screen
enter_alt_screen

echo -e "${RED}$(toilet -f big BASCAN)${NC}"
cache_folder_create
history -r

while true; do
    read -e -p "$(echo -e "${BLUE}>${NC} ")" userInput
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

    if [[ "$lowerUserInput" == "scan" || "$lowerUserInput" =~ ^scan\  ]]; then
        if [[ "${#userInput}" -ge 5 ]]; then
            if [[ "${lowerUserInput:5}" == "ports" ]]; then
                nmap_start_scan "$1"
                continue
            fi
        fi

        if [[ "$lowerUserInput" != "scan" ]]; then
           echo -e "${RED}ERROR${NC} Invalid scan operation: '${userInput:5}'."
        fi
        
        echo -e "\nUsage: scan <operation>"
        echo -e "  Operations:"
        echo -e "    ports - scan ports vulnerabilities"
        echo -e "    subdomains - scan subdomains vulnerabilities"
        echo -e ""
        continue
    fi

    if [[ "$lowerUserInput" == "install" || "$lowerUserInput" =~ ^install\  ]]; then
        if [[ "${#userInput}" -ge 8 ]]; then
            if [[ "${lowerUserInput:8}" == "all" ]]; then
                packages_to_install=("toilet" "nmap" "python3-httpx" "nikto")

                for package in "${packages_to_install[@]}"; do
                    echo -ne "${YELLOW}[+]${NC} Installing package: ${CYAN}$package${NC}... "

                    if ! sudo apt install -y "$package" > /dev/null 2>&1; then
                        echo -e "${RED}Error${NC}."
                    else
                        echo -e "${GREEN}Done${NC}."
                    fi
                done
                
                echo ""
                sleep 3
                continue
            fi
        fi

        if [[ "$lowerUserInput" != "install" ]]; then
           echo -e "${RED}ERROR${NC} Invalid package: '${userInput:8}'."
        fi

        echo "\nUsage: install <package>"
        echo "  Packages:"
        echo "    all - install all packages"
        echo "    nmap - install port scanner"
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

                echo "\nUsage: option set <option> <value>"
                echo "Options:"
                echo "  intensity"
                echo "    * slowly - Sends packets extremely slowly, useful for avoiding detection by IDS/IPS." # -T0
                echo "    * low - A little faster than slowly, but still very discreet to avoid security alarms." # -T1
                echo "    * middle - Reduces bandwidth and CPU usage, useful for congested networks." # -T2
                echo "    * normal - Balanced speed and discretion (default, recommended)." # -T3
                echo "    * aggressive - Speeds up scanning, ideal for fast networks with no security restrictions." # -T4
                echo "    * insane - Maximum speed, can overload the network and be easily detected by firewalls." # -T5
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

        echo "\nUsage: option <operation> [...]"
        echo "  Operations:"
        echo "    set <option> <value> - set an option value"
        echo "    show - show options value"
        echo ""
        continue
    fi

    echo -e "${RED}ERROR${NC} Invalid command: '$userInput'."
done

close
