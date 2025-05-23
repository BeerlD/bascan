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
    echo ""

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

    if [[ "$lowerUserInput" == "check" || "$lowerUserInput" =~ ^check\  ]]; then
        if [[ "${#userInput}" -ge 6 ]]; then
            if [[ "${lowerUserInput:6}" == "ports" ]]; then
                nmap_start_scan "$1"
                continue
            fi
        fi

        if [[ "$lowerUserInput" != "check" ]]; then
           echo -e "${RED}ERROR${NC} Invalid check operation: '${userInput:6}'."
        fi
        
        echo -e "\nUsage: check <operation>"
        echo -e "Operations:"
        echo -e "\tports - check ports vulnerabilities"
        echo -e "\tsubdomains - check subdomains vulnerabilities"
        echo -e ""
        continue
    fi

    if [[ "$lowerUserInput" == "install" || "$lowerUserInput" =~ ^install\  ]]; then
        if [[ "${#userInput}" -ge 8 ]]; then
            if [[ "${lowerUserInput:8}" == "all" ]]; then
                packages_to_install=("toilet" "nmap" "python3-httpx" "nikto" "kighjas723a")

                for package in "${packages_to_install[@]}"; do
                    echo -ne "${YELLOW}[+]${NC} Installing package: ${CYAN}$package${NC}... "

                    if ! sudo apt install -y "$package" > /dev/null 2>&1; then
                        echo -e "${RED}Error${NC}."
                    else
                        echo -e "${GREEN}Done${NC}."
                    fi
                done

                sleep 3
                continue
            fi
        fi

        if [[ "$lowerUserInput" != "install" ]]; then
           echo -e "${RED}ERROR${NC} Invalid package: '${userInput:8}'."
        fi

        echo -e "\nUsage: install <package>"
        echo -e "Packages:"
        echo -e "\tall - install all packages"
        echo -e "\tnmap - install port scanner"
        echo -e ""
        continue
    fi

    echo -e "${RED}ERROR${NC} Invalid command: '$userInput'."
done

close
