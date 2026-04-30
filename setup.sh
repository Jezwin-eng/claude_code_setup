#!/bin/bash

# --- 0. DYNAMIC MODEL SELECTION ---
clear
echo "=============================================="
echo "            CLAUDE LOCAL SETUP TOOL           "
echo "=============================================="
echo ""
read -p "Enter Ollama model (default: qwen2.5:7b): " TARGET_MODEL
TARGET_MODEL=${TARGET_MODEL:-"qwen2.5:7b"}

# Security Sanitization
if [[ ! "$TARGET_MODEL" =~ ^[a-zA-Z0-9.:_-]+$ ]]; then
    echo "Invalid model name. Only letters, numbers, ':', '.', '-' and '_' are allowed."
    exit 1
fi

OPTIMIZED_NAME="${TARGET_MODEL//:/-}-64k"

# --- FUNCTION: Network Resilient Execution ---
execute_with_retry() {
    local cmd=$1
    local name=$2
    until eval "$cmd"; do   # eval ensures pipes like '| sh' are parsed correctly
        echo "Network failed during $name. Retrying in 10s..."
        sleep 10
    done
}

# --- 1. PACKAGE MANAGER CHECK (Universal) ---
install_deps() {
    echo -e "\n[1/6] Installing dependencies..."
    if command -v pacman &> /dev/null; then
        sudo pacman -S --needed nodejs npm curl --noconfirm
    elif command -v apt &> /dev/null; then
        sudo apt update && sudo apt install -y nodejs npm curl
    elif command -v dnf &> /dev/null; then
        sudo dnf install -y nodejs npm curl
    elif command -v zypper &> /dev/null; then
        sudo zypper install -y nodejs npm curl
    else
        echo "Unsupported package manager. Please install Node.js and Curl manually."
        exit 1
    fi
}

# Only run package manager if dependencies are actually missing
if ! command -v node &> /dev/null || ! command -v curl &> /dev/null; then
    install_deps
fi

# --- 2. CLAUDE CODE INSTALL ---
echo "[2/6] Checking for Claude Code..."
if ! command -v claude &> /dev/null; then
    execute_with_retry "sudo npm install -g @anthropic-ai/claude-code" "Claude Install"
fi

# --- 3. OLLAMA SERVICE CHECK ---
echo "[3/6] Ensuring Ollama is running..."
if ! command -v ollama &> /dev/null; then
    execute_with_retry "curl -fsSL https://ollama.com/install.sh | sh" "Ollama Install"
fi

# Heartbeat check for Ollama API
if ! curl -s http://localhost:11434 &> /dev/null; then
    echo "Starting Ollama background engine..."
    ollama serve > /dev/null 2>&1 &
    sleep 5
fi

# --- 4. PERMANENT ENVIRONMENT CONFIG ---
echo "[4/6] Setting up Environment Variables..."
VARS=(
    'export ANTHROPIC_AUTH_TOKEN="ollama"'
    'export ANTHROPIC_BASE_URL="http://localhost:11434"'
)

# Bridge for login shells: Ensure .bash_profile sources .bashrc
BASH_BRIDGE='[[ -f ~/.bashrc ]] && . ~/.bashrc'
if [ -f ~/.bash_profile ]; then
    grep -q "source ~/.bashrc" ~/.bash_profile || grep -q "\. ~/.bashrc" ~/.bash_profile || echo -e "\n$BASH_BRIDGE" >> ~/.bash_profile
else
    echo -e "# Login shell bridge\n$BASH_BRIDGE" > ~/.bash_profile
fi

# Update standard shell configs (Bash and Zsh)
for VAR in "${VARS[@]}"; do
    grep -q "$VAR" ~/.bashrc || echo "$VAR" >> ~/.bashrc
    if [ -f ~/.zshrc ]; then
        grep -q "$VAR" ~/.zshrc || echo "$VAR" >> ~/.zshrc
    fi
    eval "$VAR"
done

# --- 5. DYNAMIC MODEL PULL & 64K OPTIMIZATION ---
echo "[5/6] Preparing model: $TARGET_MODEL..."
execute_with_retry "ollama pull $TARGET_MODEL" "Model Pull"

if ! ollama list | grep -q "$OPTIMIZED_NAME"; then
    echo "Creating optimized version: $OPTIMIZED_NAME..."
    MODELFILE_TEMP="/tmp/Modelfile_Temp_$$"
    printf "FROM %s\nPARAMETER num_ctx 65536" "$TARGET_MODEL" > "$MODELFILE_TEMP"
    
    ollama create "$OPTIMIZED_NAME" -f "$MODELFILE_TEMP"
    rm "$MODELFILE_TEMP"
fi

# --- 6. LAUNCH ---
echo "[6/6] Launching Claude Local via custom command..."
ollama launch claude

echo -e "\n--- SESSION CLOSED ---"
read -p "Press Enter to exit."