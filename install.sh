#!/bin/bash
set -e

REPO_RAW="https://raw.githubusercontent.com/phtungf/mcafee-control/main"
BIN_PATH="/usr/local/bin/mcafee"
AUTOSTOP_PLIST="/Library/LaunchDaemons/com.user.mcafee-autostop.plist"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

if [ "$EUID" -ne 0 ]; then
    echo -e "${RED}Root required. Run: curl -fsSL ${REPO_RAW}/install.sh | sudo bash${NC}"
    exit 1
fi

# Detect TTY for interactive mode (works when piped from curl too)
TTY_IN="/dev/tty"
if [ ! -r "$TTY_IN" ]; then
    TTY_IN=""
fi

ask() {
    local prompt="$1" default="$2" reply
    if [ -z "$TTY_IN" ]; then
        echo "$default"
        return
    fi
    read -r -p "$prompt " reply < "$TTY_IN" || reply=""
    reply="${reply:-$default}"
    echo "$reply"
}

echo -e "${BLUE}=== mcafee-control installer ===${NC}"
echo ""

# 1. Install main script
INSTALL_BIN=$(ask "Install 'mcafee' command to ${BIN_PATH}? [Y/n]" "Y")
case "$INSTALL_BIN" in
    [Nn]*) echo "Skipping mcafee binary install." ;;
    *)
        echo -e "${YELLOW}Downloading mcafee script...${NC}"
        if [ -f "./mcafee" ]; then
            cp ./mcafee "$BIN_PATH"
        else
            curl -fsSL "${REPO_RAW}/mcafee" -o "$BIN_PATH"
        fi
        chmod 755 "$BIN_PATH"
        chown root:wheel "$BIN_PATH"
        echo -e "${GREEN}Installed: ${BIN_PATH}${NC}"
        ;;
esac

echo ""

# 2. Auto-stop on boot
INSTALL_AUTOSTOP=$(ask "Auto-stop McAfee on every macOS boot? [Y/n]" "Y")
case "$INSTALL_AUTOSTOP" in
    [Nn]*) echo "Skipping auto-stop." ;;
    *)
        echo -e "${YELLOW}Installing LaunchDaemon...${NC}"
        if [ -f "./launchd/com.user.mcafee-autostop.plist" ]; then
            cp ./launchd/com.user.mcafee-autostop.plist "$AUTOSTOP_PLIST"
        else
            curl -fsSL "${REPO_RAW}/launchd/com.user.mcafee-autostop.plist" -o "$AUTOSTOP_PLIST"
        fi
        chmod 644 "$AUTOSTOP_PLIST"
        chown root:wheel "$AUTOSTOP_PLIST"
        launchctl bootout system "$AUTOSTOP_PLIST" 2>/dev/null || true
        launchctl bootstrap system "$AUTOSTOP_PLIST"
        echo -e "${GREEN}Auto-stop enabled (${AUTOSTOP_PLIST})${NC}"
        ;;
esac

echo ""

# 3. Run stop now
RUN_NOW=$(ask "Run 'mcafee stop' now? [Y/n]" "Y")
case "$RUN_NOW" in
    [Nn]*) ;;
    *)
        if [ -x "$BIN_PATH" ]; then
            "$BIN_PATH" stop || true
        fi
        ;;
esac

echo ""
echo -e "${GREEN}Done.${NC}"
echo "Commands:"
echo "  sudo mcafee stop    - Fully stop McAfee"
echo "  sudo mcafee start   - Start McAfee back up"
echo "  mcafee status       - Show current status"
