#!/bin/sh

# Set local app path
export PATH="$HOME/.local/bin:$PATH"

# Function to create directory with proper permissions
create_directory() {
    local dir=$1
    local perms=$2
    if [ ! -d "$dir" ]; then
        mkdir -p "$dir"
        chmod "$perms" "$dir"
        echo "Created directory $dir with permissions $perms"
    fi
}

# Create necessary directories with proper permissions
create_directory "/home/coder/.ssh" "700"
create_directory "/home/coder/.local/share/code-server/extensions" "755"
create_directory "/home/coder/.local/share/code-server/User" "755"

# Check if initial setup has been completed
SETUP_FLAG_FILE="/home/coder/.local/share/code-server/.initial_setup_complete"

# Only run extension installation if initial setup hasn't been completed
if [ ! -f "$SETUP_FLAG_FILE" ]; then
    echo "Performing initial setup..."
    
    # Install VS Code extensions
    EXTENSIONS_DIR="/home/coder/.local/share/code-server/extensions/"
    
    # Function to check if extension is installed
    is_extension_installed() {
        local extension=$1
        local extension_name
        
        # Handle .vsix files
        case "$extension" in
            *.vsix)
                extension_name=$(basename "$extension" .vsix)
                ;;
            *)
                extension_name=$extension
                ;;
        esac
        
        # Check if extension directory exists
        if [ -d "$EXTENSIONS_DIR/$extension_name" ]; then
            return 0  # Extension is installed
        fi
        
        # Check if extension is listed in code-server
        if code-server --list-extensions 2>/dev/null | grep -q "^$extension_name$"; then
            return 0  # Extension is installed
        fi
        
        return 1  # Extension is not installed
    }
    
    # Function to install extension if not already installed
    install_extension() {
        local extension=$1
        if ! is_extension_installed "$extension"; then
            echo "Installing extension $extension..."
            # Suppress all output except errors
            if ! code-server --install-extension "$extension" >/dev/null 2>&1; then
                echo "Warning: Failed to install extension $extension"
            fi
        else
            echo "Extension $extension is already installed"
        fi
    }
    
    # Install extensions from Open VSX
    echo 'Installing VS Code extensions...'
    install_extension "ms-python.python"
    install_extension "redhat.vscode-yaml"
    install_extension "sqlfluff.vscode-sqlfluff"
    install_extension "ms-toolsai.jupyter"
    install_extension "ms-toolsai.jupyter-renderers"
    install_extension "oderwat.indent-rainbow"
    install_extension "innoverio.vscode-dbt-power-user"

    # Install Claude Code extension from VS Marketplace (not available on Open VSX)
    echo 'Installing Claude Code extension...'
    CLAUDE_EXT_VSIX="/tmp/anthropic.claude-code.vsix"
    if curl -fsSL -o "$CLAUDE_EXT_VSIX" \
        "https://marketplace.visualstudio.com/_apis/public/gallery/publishers/anthropic/vsextensions/claude-code/latest/vspackage"; then
        install_extension "$CLAUDE_EXT_VSIX"
        rm -f "$CLAUDE_EXT_VSIX"
    else
        echo "Warning: Failed to download Claude Code extension"
    fi
    
    # Create flag file to indicate initial setup is complete
    touch "$SETUP_FLAG_FILE"
    echo "Initial setup completed successfully"
else
    echo "Initial setup already completed, skipping extension installation"
fi

# Install vscode Settings
echo 'Installing vscode Settings...'
VSCODE_TASKS_SETTINGS_FILE_PATH="/usr/settings/tasks.json"
VSCODE_USER_TASKS_SETTINGS_FILE_PATH="/home/coder/.local/share/code-server/User/tasks.json"
SETTINGS_FILE_PATH=/usr/settings/root_settings.json
TARGET_FILE_PATH=/home/coder/.local/share/code-server/User/root_settings.json
TARGET_FILE_PATH_UPDATED=/home/coder/.local/share/code-server/User/settings.json

# Verify settings files exist
if [ ! -e "$SETTINGS_FILE_PATH" ]; then
    echo "Error: $SETTINGS_FILE_PATH does not exist. Aborting."
    exit 1
fi

if [ ! -e "$VSCODE_TASKS_SETTINGS_FILE_PATH" ]; then
    echo "Error: $VSCODE_TASKS_SETTINGS_FILE_PATH does not exist. Aborting."
    exit 1
fi

# Copy settings files
cp "$SETTINGS_FILE_PATH" "$TARGET_FILE_PATH_UPDATED"
cp "$VSCODE_TASKS_SETTINGS_FILE_PATH" "$VSCODE_USER_TASKS_SETTINGS_FILE_PATH"
echo "VSCode settings and tasks files have been configured."

# Function to setup SSH keys from environment variables
setup_ssh_keys() {
    if [ -n "$SSH_PRIVATE_KEY" ]; then
        echo "Setting up SSH keys from environment variables..."
        
        # Write private key
        echo "$SSH_PRIVATE_KEY" > /home/coder/.ssh/id_ed25519
        chmod 600 /home/coder/.ssh/id_ed25519
        
        # Write public key if provided
        if [ -n "$SSH_PUBLIC_KEY" ]; then
            echo "$SSH_PUBLIC_KEY" > /home/coder/.ssh/id_ed25519.pub
            chmod 644 /home/coder/.ssh/id_ed25519.pub
        fi

        # Create known_hosts file
        touch /home/coder/.ssh/known_hosts
        chmod 644 /home/coder/.ssh/known_hosts
        
        return 0
    fi
    return 1
}

# Function to extract hostname from URL
extract_hostname() {
    url=$1
    hostname=$(echo "$url" | sed -e 's|^https\?://||' -e 's|^git@||' -e 's|:|/|' -e 's|/.*$||')
    echo "$hostname"
}

# Function to setup git provider specific configurations
setup_git_provider() {
    local provider=$1
    local host=$2
    
    echo "Setting up Git provider: $provider"
    
    # Add SSH host key with retry
    local retry_count=0
    local max_retries=3
    
    while [ $retry_count -lt $max_retries ]; do
        if ssh-keyscan -H "$host" >> /home/coder/.ssh/known_hosts 2>/dev/null; then
            echo "Successfully added SSH host key for $host"
            return 0
        fi
        retry_count=$((retry_count + 1))
        echo "Retry $retry_count/$max_retries: Failed to fetch SSH host key for $host"
        sleep 2
    done
    
    echo "Warning: Failed to fetch SSH host key for $host after $max_retries attempts"
    return 1
}

REPO_DIR="/home/coder/fast_bi_notebook/dbt-data-model"

# Check if the repository directory exists
if [ ! -d "$REPO_DIR" ]; then
    echo "Cloning Data Model repository..."
    
    # Validate required environment variables
    if [ -z "$GIT_REPO_URL" ]; then
        echo "Error: GIT_REPO_URL environment variable is not set"
        exit 1
    fi

    if [ -z "$GIT_PROVIDER" ]; then
        echo "Error: GIT_PROVIDER environment variable is not set"
        exit 1
    fi

    # Determine authentication method
    if [ -n "$SSH_PRIVATE_KEY" ]; then
        GIT_PROVIDER_AUTHENTICATION="DEPLOY_KEYS"
    elif [ -n "$GROUP_ACCESS_TOKEN" ] && [ -n "$GROUP_ACCESS_TOKEN_NAME" ]; then
        GIT_PROVIDER_AUTHENTICATION="ACCESS_TOKEN"
    else
        echo "Error: Neither SSH keys nor access token credentials provided"
        exit 1
    fi

    # Extract hostname and setup git provider
    GIT_SSH_HOST=$(extract_hostname "$GIT_REPO_URL")
    setup_git_provider "$GIT_PROVIDER" "$GIT_SSH_HOST"

    case "$GIT_PROVIDER_AUTHENTICATION" in
        "ACCESS_TOKEN")
            echo "Using access token authentication..."
            protocol="https://"
            git_repo_no_protocol=$(echo "$GIT_REPO_URL" | sed "s@$protocol@@g")
            if ! git clone "${protocol}${GROUP_ACCESS_TOKEN_NAME}:${GROUP_ACCESS_TOKEN}@${git_repo_no_protocol}" "$REPO_DIR"; then
                echo "Error: Failed to clone repository using access token"
                exit 1
            fi
            ;;
            
        "DEPLOY_KEYS")
            echo "Using SSH key authentication..."
            if ! setup_ssh_keys; then
                echo "Error: Failed to setup SSH keys"
                exit 1
            fi
            
            # Convert HTTPS URL to SSH URL if needed
            if echo "$GIT_REPO_URL" | grep -q "^https://"; then
                git_repo_ssh=$(echo "$GIT_REPO_URL" | sed -e 's|^https://||')
                repo_path=$(echo "$git_repo_ssh" | sed -e 's|^[^/]*/||')
                ssh_url="git@${GIT_SSH_HOST}:${repo_path}"
            else
                ssh_url="$GIT_REPO_URL"
            fi
            
            echo "Attempting to clone using SSH URL: $ssh_url"
            if ! git clone "$ssh_url" "$REPO_DIR"; then
                echo "Error: Failed to clone repository using SSH"
                exit 1
            fi
            ;;
    esac

    # Change directory to repository
    cd "$REPO_DIR" || exit 1

    # Configure git user if provided
    if [ -n "$GIT_USER_NAME" ] && [ -n "$GIT_USER_EMAIL" ]; then
        git config user.name "$GIT_USER_NAME"
        git config user.email "$GIT_USER_EMAIL"
    fi

    echo "Repository successfully cloned and configured."

    # Cleanup SSH keys but preserve known_hosts
    if [ "$GIT_PROVIDER_AUTHENTICATION" = "DEPLOY_KEYS" ]; then
        echo "Cleaning up SSH keys..."
        rm -f /home/coder/.ssh/id_ed25519
        rm -f /home/coder/.ssh/id_ed25519.pub
    fi
else
    echo "Directory $REPO_DIR already exists. Skipping clone."
fi