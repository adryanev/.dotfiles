#!/bin/sh

# How to Use:
# ./ssh.sh <email_address>

if [ -z "$1" ]; then
    echo "Error: Please provide an email address"
    echo "Usage: ./ssh.sh <email_address>"
    exit 1
fi

echo "Generating ssh key"

# Check if key already exists
if [ -f ~/.ssh/id_ed25519 ]; then
    echo "SSH key already exists at ~/.ssh/id_ed25519"
    read -p "Do you want to overwrite it? (y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Keeping existing key"
    else
        # Generating a new SSH key
        ssh-keygen -t ed25519 -C "$1" -f ~/.ssh/id_ed25519
    fi
else
    # Generating a new SSH key
    ssh-keygen -t ed25519 -C "$1" -f ~/.ssh/id_ed25519
fi

# Adding your SSH key to the ssh-agent
eval "$(ssh-agent -s)"

# Create or update SSH config
mkdir -p ~/.ssh
touch ~/.ssh/config
cat > ~/.ssh/config << EOL
Host *
    AddKeysToAgent yes
    IdentityFile ~/.ssh/id_ed25519
EOL

# Add key to ssh-agent using modern syntax
ssh-add ~/.ssh/id_ed25519

# Adding your SSH key to your GitHub account
echo "run 'pbcopy < ~/.ssh/id_ed25519.pub' and paste that into GitHub"
