#!/bin/bash
set -e

BIN_PATH="/usr/local/bin/mcafee"
AUTOSTOP_PLIST="/Library/LaunchDaemons/com.user.mcafee-autostop.plist"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

if [ "$EUID" -ne 0 ]; then
    echo -e "${RED}Root required. Run with sudo.${NC}"
    exit 1
fi

echo -e "${YELLOW}Removing auto-stop LaunchDaemon...${NC}"
if [ -f "$AUTOSTOP_PLIST" ]; then
    launchctl bootout system "$AUTOSTOP_PLIST" 2>/dev/null || true
    rm -f "$AUTOSTOP_PLIST"
    echo -e "${GREEN}Removed: ${AUTOSTOP_PLIST}${NC}"
else
    echo "Auto-stop not installed."
fi

echo -e "${YELLOW}Removing mcafee binary...${NC}"
if [ -f "$BIN_PATH" ]; then
    rm -f "$BIN_PATH"
    echo -e "${GREEN}Removed: ${BIN_PATH}${NC}"
else
    echo "Binary not installed."
fi

echo -e "${GREEN}Uninstall complete.${NC}"
