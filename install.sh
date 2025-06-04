#!/bin/bash

YELLOW='\033[1;33m'
RED='\033[1;31m'
NC='\033[0m'

echo -e "${YELLOW}[+]${NC} Installing Bascan..."
sudo apt update && sudo apt install -y jq &> /dev/null

BIN="bascan-linux_x64"
URL=$(curl -s https://api.github.com/repos/BeerlD/Bascan/releases/latest | jq -r ".assets[] | select(.name==\"$BIN\") | .browser_download_url")

if [ -z "$URL" ]; then
    echo -e "${RED}[-]${NC} Error: Could not retrieve the file URL. Please try again later."
    exit 1
fi

echo -e "${YELLOW}[+]${NC} Downloading $BIN..."
wget -O "/usr/local/bin/$BIN" "$URL" &> /dev/null

if [ ! -f "/usr/local/bin/$BIN" ]; then
    echo -e "${RED}[-]${NC} Error: Download failed. Check your connection or try again later."
    exit 1
fi

chmod +x "/usr/local/bin/$BIN"

export PATH=$PATH:/usr/local/bin
echo 'export PATH=$PATH:/usr/local/bin' >> ~/.bashrc

echo -e "${YELLOW}[+]${NC} $BIN has been successfully installed (/usr/local/bin/)."