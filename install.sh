#!/bin/bash

YELLOW='\033[1;33m'
RED='\033[1;31m'
NC='\033[0m'

echo -e "${YELLOW}[+]${NC} Installing Bascan..."

if [ "$(id -u)" -ne 0 ]; then
    echo -e "${RED}[-]${NC} Error: This script must be run as root (use sudo)."
    exit 1
fi

if ! command -v jq &> /dev/null; then
    echo -e "${YELLOW}[+]${NC} Installing jq..."
    apt update -y
    apt install -y jq
fi

echo -e "${YELLOW}[+]${NC} Fetching latest release info..."
API_URL="https://api.github.com/repos/BeerlD/bascan/releases/latest"
TARBALL_URL=$(curl -s "$API_URL" | jq -r '.tarball_url')

if [ -z "$TARBALL_URL" ] || [ "$TARBALL_URL" == "null" ]; then
    echo -e "${RED}[-]${NC} Error: Could not retrieve the tarball URL from GitHub."
    exit 1
fi

TMP_DIR=$(mktemp -d)
cd "$TMP_DIR" || exit 1

echo -e "${YELLOW}[+]${NC} Downloading latest release tarball..."
curl -sL "$TARBALL_URL" -o source.tar.gz

if [ ! -f source.tar.gz ]; then
    echo -e "${RED}[-]${NC} Error: Failed to download the tarball."
    exit 1
fi

INSTALL_DIR="/usr/local/bin/bascan"
rm -rf "$INSTALL_DIR"

echo -e "${YELLOW}[+]${NC} Extracting source to $INSTALL_DIR..."
mkdir -p "$INSTALL_DIR"
tar -xzf source.tar.gz --strip-components=1 -C "$INSTALL_DIR"

if [[ ":$PATH:" != *":/usr/local/bin:"* ]]; then
    echo 'export PATH=$PATH:/usr/local/bin' >> ~/.bashrc
    export PATH=$PATH:/usr/local/bin
fi

echo -e "${YELLOW}[+]${NC} Bascan has been successfully installed to $INSTALL_DIR."
rm -rf "$TMP_DIR"
