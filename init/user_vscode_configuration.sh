#!/bin/sh

echo "🚀 Welcome ${JUPYTERHUB_USER} to your Data Modeling coder environment with dbt Labs framework! 🛠️

You are now in a specialized environment for data modeling using dbt (data build tool). This environment is powered by Visual Studio Code with special extensions tailored for efficient and streamlined data modeling workflows.

Feel free to explore the tools and features available to enhance your data modeling experience. If you have any questions or need assistance, don't hesitate to ask us on Slack.

Do not forget to login to your Data Warehouse cloud provider to start your modeling journey!

Happy coding! 🌟"

echo "\n "
echo "🚀 Checking Fast.BI Coder user configuration..."
echo "\n "

# Find if it's a dbt project folder or not
# Get the current directory path
current_path=$(pwd)
# Extract the folder name from the path using basename
folder_name=$(basename "$current_path")

# Function to check if any .pub file exists in the .ssh directory
check_ssh_key() {
    if [ -n "$(find /home/coder/.ssh -maxdepth 1 -name '*.pub' -print -quit)" ]; then
        return 0  # Key found
    else
        return 1  # No key found
    fi
}

# Check if the folder has dbt_project.yml file
if [ -f "$current_path/dbt_project.yml" ]; then
    echo "🚀 The dbt project is set to: ${folder_name}"
    echo "\n "
    # Extract username without domain
    USERNAME=${JUPYTERHUB_USER%%@*}
    GIT_BRANCH=$(git branch --show-current)

    # Extract Project name
    project_name=$(/usr/local/bin/yqs eval '.name' ./dbt_project.yml)
    # Set the dbt project configuration for vscode extensions
    # Run dbt deps inside the directory
    dbt deps 2>&1 > /dev/null

    # Create a new folder for profiles.yml file inside the .dbt folder and copy dev profile
    mkdir -p .dbt/
    cp profiles.yml .dbt/profiles.yml
    /usr/local/bin/yqs eval 'del(.[].outputs.sa, .[].outputs.test)' .dbt/profiles.yml -i
    /usr/local/bin/yqs eval '.[].target="dev"' .dbt/profiles.yml -i
    /usr/local/bin/yqs eval 'del(.config.target)' .dbt/profiles.yml -i
    type=$(/usr/local/bin/yqs eval '.[].outputs.dev.type' profiles.yml)
    if [ "$type" = "bigquery" ]; then
        /usr/local/bin/yqs eval -i '.[].outputs.dev.dataset = "dev_" + env(GIT_BRANCH)' .dbt/profiles.yml
    elif [ "$type" = "snowflake" ]; then        
        /usr/local/bin/yqs eval -i '.[].outputs.dev.schema = "dev_" + env(GIT_BRANCH)' .dbt/profiles.yml
    elif [ "$type" = "redshift" ]; then
        /usr/local/bin/yqs eval -i '.[].outputs.dev.schema = "dev_" + env(GIT_BRANCH)' .dbt/profiles.yml
    elif [ "$type" = "fabric" ]; then
        /usr/local/bin/yqs eval -i '.[].outputs.dev.schema = "dev_" + env(GIT_BRANCH)' .dbt/profiles.yml
    else
        /usr/local/bin/yqs eval -i '.[].outputs.dev.schema = "dev_" + env(GIT_BRANCH)' .dbt/profiles.yml
    fi

    # Create lightdash directory and copy profile
    mkdir -p .lightdash/
    cp profiles.yml .lightdash/profiles.yml

    # Remove SA and test outputs, set target to dev and update dataset
    /usr/local/bin/yqs eval 'del(.[].outputs.sa, .[].outputs.test)' .lightdash/profiles.yml -i
    /usr/local/bin/yqs eval '.[].target="dev"' .lightdash/profiles.yml -i
    type=$(/usr/local/bin/yqs eval '.[].outputs.dev.type' profiles.yml)
    if [ "$type" = "bigquery" ]; then
        /usr/local/bin/yqs eval -i '.[].outputs.dev.dataset = "dev_" + env(GIT_BRANCH)' .lightdash/profiles.yml
    elif [ "$type" = "snowflake" ]; then        
        /usr/local/bin/yqs eval -i '.[].outputs.dev.schema = "dev_" + env(GIT_BRANCH)' .lightdash/profiles.yml
    elif [ "$type" = "redshift" ]; then
        /usr/local/bin/yqs eval -i '.[].outputs.dev.schema = "dev_" + env(GIT_BRANCH)' .lightdash/profiles.yml
    elif [ "$type" = "fabric" ]; then
        /usr/local/bin/yqs eval -i '.[].outputs.dev.schema = "dev_" + env(GIT_BRANCH)' .lightdash/profiles.yml
    else
        /usr/local/bin/yqs eval -i '.[].outputs.dev.schema = "dev_" + env(GIT_BRANCH)' .lightdash/profiles.yml
    fi

    # Verify the changes
    echo "🔍 Verifying Lightdash and Local dbt configuration..."
    if [ -f ".lightdash/profiles.yml" ] && [ -f ".dbt/profiles.yml" ]; then
        echo "✅ Lightdash profiles.yml created successfully"
        echo "✅ vscode dbt profiles.yml created successfully"
    else
        echo "❌ Failed to create configurations"
        if [ ! -f ".lightdash/profiles.yml" ]; then
            echo "   - Lightdash profiles.yml is missing"
        fi
        if [ ! -f ".dbt/profiles.yml" ]; then
            echo "   - dbt profiles.yml is missing"
        fi
    fi

    # Create a new folder for coder user settings.json file inside the .vscode folder
    mkdir -p .vscode/
    VSCODE_SETTINGS_FILE_PATH="/usr/settings/vscode_settings.json"
    VSCODE_FILE_PATH=".vscode/vscode_settings.json"
    VSCODE_FILE_PATH_UPDATED=".vscode/settings.json"

    if [ ! -e "$VSCODE_FILE_PATH_UPDATED" ]; then
        cp "$VSCODE_SETTINGS_FILE_PATH" "$VSCODE_FILE_PATH"
        jq '.["turntable.environmentVariables"][0] = "GIT_BRANCH=\"'''dev_"${GIT_BRANCH}"'''\""' $VSCODE_FILE_PATH > $VSCODE_FILE_PATH_UPDATED
        rm -rf $VSCODE_FILE_PATH
        echo "🛠️  File vscode - settings.json was moved and updated in $TARGET_FILE_PATH_UPDATED"
    else
        echo "🛠️  File $VSCODE_FILE_PATH_UPDATED already exists. Skipping copy."
        jq '.["turntable.environmentVariables"][0] = "GIT_BRANCH=\"'''dev_"${GIT_BRANCH}"'''\""' $VSCODE_FILE_PATH_UPDATED > $VSCODE_FILE_PATH
        cp $VSCODE_FILE_PATH $VSCODE_FILE_PATH_UPDATED
        rm -rf $VSCODE_FILE_PATH
        echo "🛠️  File vscode - settings.json was updated in $VSCODE_FILE_PATH_UPDATED"
    fi
# Move back to the root of the repository
else
    echo "🛑 Attention: You are in the root folder of the projects. Please set the dbt project folder."
fi

echo "\n "
# Check if any SSH public key exists for the user; if not, prompt to create one.
if check_ssh_key; then
    echo "🛠️  SSH key found for user ${JUPYTERHUB_USER%%@*}"
else
    echo "🛠️  SSH key not found for user ${JUPYTERHUB_USER%%@*}."
    echo "✨ Please create an SSH key for user ${JUPYTERHUB_USER%%@*} and add it to your GitLab Fast.BI account."
    echo "   👉 Run: ssh-keygen -t ed25519 -C \"<EMAIL>\""
fi

# Add GIT Provider to known hosts
if [ -n "$GIT_REPO_URL" ]; then
    # Extract the base URL
    provider_url=$(echo "$GIT_REPO_URL" | awk -F[/:] '{print $4}')
    echo "Adding GIT Provider to known hosts..."
    ssh-keyscan -H "$provider_url" >> ~/.ssh/known_hosts
    echo "Git provider $provider_url added to known hosts."
else
    echo "GIT_REPO_URL is not set. Skipping addition to known hosts."
fi

echo "\n "
# Check if the user has a .gitconfig file; if not, prompt to create one.
if [ ! -f "/home/coder/.gitconfig" ]; then
    echo "🛠️  .gitconfig file not found for user ${JUPYTERHUB_USER%%@*}"
    echo "✨ Please run the following commands to set up your Git configuration:"
    echo "   👉 Run: git config --global user.email \"<EMAIL>\""
    echo "   👉 Run: git config --global user.name \"<NAME>\""
else
    echo "🛠️  .gitconfig file found for user ${JUPYTERHUB_USER%%@*}."
fi

echo "\n "
type=$(/usr/local/bin/yqs eval '.[].[].[].type' profiles.yml | head -n 1)
# Check if GOOGLE_CLOUD is set to True
# Initialize GOOGLE_CLOUD to True if not already set
if [ "$type" = "bigquery" ]; then
    : ${GOOGLE_CLOUD:=True}
else
    : ${GOOGLE_CLOUD:=False}
fi

if [ "$GOOGLE_CLOUD" = "True" ]; then
    # Check if the Google Cloud Platform account file exists
    if [ ! -f "/home/coder/.config/gcloud/application_default_credentials.json" ]; then
        echo "🛠️  Google Cloud Platform account not found for user ${JUPYTERHUB_USER%%@*}"
        echo "✨ Please run the following command to set up your Google Cloud Platform account:"
        echo "   👉 Run: gcloud auth login \n  👉 Run: gcloud auth application-default login"
    else
        # Extract the username without the domain part
        USERNAME=${JUPYTERHUB_USER%%@*}
        # Attempt to retrieve the active account matching the USERNAME
        ACTIVE_ACCOUNT=$(gcloud auth list --filter="status:ACTIVE AND account:${JUPYTERHUB_USER}" --format="value(account)")
        if [ -z "$ACTIVE_ACCOUNT" ]; then
            # If no active account is returned, the authentication is considered expired
            echo "🛑 Error: Authentication is expired with gcloud for user ${USERNAME}. Please run 'gcloud auth login'."
        else
            # If an active account is found, indicate success
            echo "🛠️  Google Cloud Platform account is ACTIVE for user ${USERNAME}"
        fi
    fi

    # Check if the Google Cloud Application-Default authentication is not expired
    # Call the Python script and capture its output
    output=$(python3 /usr/init/check_gcp_application_default_credentials.py 2>&1)

    case $? in
        1)
            echo "🛑 Error: Reauthentication required. Run 'gcloud auth application-default login'."
            ;;
        2)
            echo "🛑 Error: The application-default credentials do not have the necessary permissions for BigQuery."
            ;;
        3)
            echo "🛑 Error: No datasets accessible. This may indicate a permissions issue or that reauthentication is necessary."
            ;;
        99)
            echo "🛑 Error: An unexpected error occurred with Google Cloud authentication."
            ;;
        *)
            echo "$output"
            ;;
    esac
else
    echo "Google Cloud integration is disabled. Skipping Google Cloud authentication checks."
fi
echo "\n "
# Set env variable GIT_BRANCH for the user if not set.
if ! env | grep -q "^GIT_BRANCH="; then
    echo "⚠️  GIT_BRANCH environment variable not set for user ${JUPYTERHUB_USER%%@*}"
    echo "📝 Required only when using project's local profiles.yml (dbt run --profiles-dir .)"
    echo "✨ Set it with: export GIT_BRANCH=\$(git branch --show-current)"
else
    echo "✅ GIT_BRANCH environment variable found for user ${JUPYTERHUB_USER%%@*}"
fi

echo "\n "
cp /usr/init/data-modeling.md /home/coder/data-modeling.md
# How to start working with dbt and data modeling module follow the open the file below:
echo "\n📚 Data Modeling Instructions"
echo "To get started with data modeling, please read the instructions at:"
echo "   /home/coder/data-modeling.md"
echo "This guide will walk you through:"
echo "   - Setting up your dbt project"
echo "   - Choosing between Turntable and Lightdash workflows"
echo "   - Creating and managing your data models"
echo "   - Best practices for documentation and testing"
echo "\n"