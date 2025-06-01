#!/bin/bash

YELLOW='\033[1;33m'
RED='\033[1;31m'
NC='\033[0m'

echo -e "${YELLOW}[+]${NC} Installing bascan..."

REPO="BeerlD/Bascan"
BIN="bascan"
VERSION="latest"

URL=$(curl -s https://api.github.com/repos/$REPO/releases/$VERSION | grep "browser_download_url.*$BIN" | cut -d '"' -f 4)

if [ -z "$URL" ]; then
    echo -e "${RED}[-]${NC} Error: try again in a few minutes."
    exit 1
fi

wget -O /usr/local/bin/$BIN "$URL" &> /dev/null
chmod +x /usr/local/bin/$BIN

export PATH=$PATH:/usr/local/bin
echo 'export PATH=$PATH:/usr/local/bin' >> ~/.bashrc
source ~/.bashrc

echo -e "${YELLOW}[+]${NC} $BIN has been installed (/usr/local/bin/)."
