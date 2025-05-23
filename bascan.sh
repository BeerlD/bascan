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

# ======== PACKGES
packages_to_install=("toilet" "nmap" "python3-httpx" "nikto")

for package in "${packages_to_install[@]}"; do
    echo -ne "${YELLOW}[+]${NC} Installing package: ${CYAN}$package${NC}... "

    if ! sudo apt install -y "$package" > /dev/null 2>&1; then
        echo -e "${RED}Error${NC}."
        close
    else
        echo -e "${GREEN}Done${NC}."
    fi
done

sleep 3

# ======== HEADER
exit_alt_screen
enter_alt_screen

echo -e "${RED}$(toilet -f big BASCAN)${NC}"
cache_folder_create

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

    if [[ "$lowerUserInput" == "check" || "$lowerUserInput" =~ ^check\  ]]; then
        if [[ "${#userInput}" -ge 6 && "${lowerUserInput:6}" =~ ^ports ]]; then
            nmap_start_scan "$1"
            continue
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

    echo -e "${RED}ERROR${NC} Invalid command: '$userInput'."
done

close
