#!/bin/bash

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}Installing Tmux Plugin Manager (TPM)...${NC}"

# Create tmux plugins directory if it doesn't exist
TMUX_PLUGINS_DIR="$HOME/.tmux/plugins"
if [ ! -d "$TMUX_PLUGINS_DIR" ]; then
    echo -e "${GREEN}Creating tmux plugins directory...${NC}"
    mkdir -p "$TMUX_PLUGINS_DIR"
fi

# Clone TPM if it doesn't exist
TPM_DIR="$TMUX_PLUGINS_DIR/tpm"
if [ ! -d "$TPM_DIR" ]; then
    echo -e "${GREEN}Cloning TPM repository...${NC}"
    git clone https://github.com/tmux-plugins/tpm "$TPM_DIR"
else
    echo -e "${GREEN}TPM already exists, updating...${NC}"
    cd "$TPM_DIR" && git pull
fi

echo -e "${BLUE}TPM installation complete!${NC}"
echo -e "${GREEN}To install plugins, start tmux and press:${NC}"
echo -e "  ${BLUE}prefix + I${NC} (capital i)"
echo -e "${GREEN}To update plugins, press:${NC}"
echo -e "  ${BLUE}prefix + U${NC}"

# Install Zsh plugins for Oh My Zsh
echo -e "\n${BLUE}Installing Zsh plugins for Oh My Zsh...${NC}"

# Create Oh My Zsh custom plugins directory if it doesn't exist
OHMYZSH_PLUGINS_DIR="$HOME/.oh-my-zsh/custom/plugins"
if [ ! -d "$OHMYZSH_PLUGINS_DIR" ]; then
    echo -e "${GREEN}Creating Oh My Zsh custom plugins directory...${NC}"
    mkdir -p "$OHMYZSH_PLUGINS_DIR"
fi

# Install zsh-autosuggestions
AUTOSUGGESTIONS_DIR="$OHMYZSH_PLUGINS_DIR/zsh-autosuggestions"
if [ ! -d "$AUTOSUGGESTIONS_DIR" ]; then
    echo -e "${GREEN}Installing zsh-autosuggestions...${NC}"
    git clone https://github.com/zsh-users/zsh-autosuggestions "$AUTOSUGGESTIONS_DIR"
else
    echo -e "${GREEN}zsh-autosuggestions already exists, updating...${NC}"
    cd "$AUTOSUGGESTIONS_DIR" && git pull
fi

# Install zsh-syntax-highlighting
SYNTAX_HIGHLIGHTING_DIR="$OHMYZSH_PLUGINS_DIR/zsh-syntax-highlighting"
if [ ! -d "$SYNTAX_HIGHLIGHTING_DIR" ]; then
    echo -e "${GREEN}Installing zsh-syntax-highlighting...${NC}"
    git clone https://github.com/zsh-users/zsh-syntax-highlighting "$SYNTAX_HIGHLIGHTING_DIR"
else
    echo -e "${GREEN}zsh-syntax-highlighting already exists, updating...${NC}"
    cd "$SYNTAX_HIGHLIGHTING_DIR" && git pull
fi

# Install fast-syntax-highlighting
FAST_SYNTAX_DIR="$OHMYZSH_PLUGINS_DIR/fast-syntax-highlighting"
if [ ! -d "$FAST_SYNTAX_DIR" ]; then
    echo -e "${GREEN}Installing fast-syntax-highlighting...${NC}"
    git clone https://github.com/zdharma-continuum/fast-syntax-highlighting "$FAST_SYNTAX_DIR"
else
    echo -e "${GREEN}fast-syntax-highlighting already exists, updating...${NC}"
    cd "$FAST_SYNTAX_DIR" && git pull
fi

# Install zsh-autocomplete
AUTOCOMPLETE_DIR="$OHMYZSH_PLUGINS_DIR/zsh-autocomplete"
if [ ! -d "$AUTOCOMPLETE_DIR" ]; then
    echo -e "${GREEN}Installing zsh-autocomplete...${NC}"
    git clone https://github.com/marlonrichert/zsh-autocomplete "$AUTOCOMPLETE_DIR"
else
    echo -e "${GREEN}zsh-autocomplete already exists, updating...${NC}"
    cd "$AUTOCOMPLETE_DIR" && git pull
fi

echo -e "\n${BLUE}Zsh plugins installation complete!${NC}"
echo -e "${GREEN}To use these plugins, add them to your plugins list in .zshrc:${NC}"
echo -e "  ${BLUE}plugins=(... zsh-autosuggestions fast-syntax-highlighting zsh-autocomplete)${NC}"