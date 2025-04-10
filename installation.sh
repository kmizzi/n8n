#!/bin/bash
set -e

# Function to prompt the user for input interactively
prompt_for_input() {
    echo "Please provide the following values:"

    read -p "Enter the main domain (e.g., example.com): " DOMAIN_NAME
    while [[ -z "$DOMAIN_NAME" || ! "$DOMAIN_NAME" =~ ^[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$ ]]; do
        echo "Invalid domain name. Please enter a valid domain (e.g., example.com)."
        read -p "Enter the main domain (e.g., example.com): " DOMAIN_NAME
    done

    read -p "Enter the subdomain (e.g., app): " SUBDOMAIN
    while [[ -z "$SUBDOMAIN" || ! "$SUBDOMAIN" =~ ^[a-zA-Z0-9.-]+$ ]]; do
        echo "Invalid subdomain. Please enter a valid subdomain (e.g., app)."
        read -p "Enter the subdomain (e.g., app): " SUBDOMAIN
    done

    read -p "Enter the email for SSL certificate (e.g., admin@example.com): " SSL_EMAIL
    while [[ -z "$SSL_EMAIL" || ! "$SSL_EMAIL" =~ ^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$ ]]; do
        echo "Invalid email format. Please enter a valid email (e.g., admin@example.com)."
        read -p "Enter the email for SSL certificate (e.g., admin@example.com): " SSL_EMAIL
    done

    read -p "Enter the SendGrid API key: " SENDGRID_API_KEY
    while [[ -z "$SENDGRID_API_KEY" ]]; do
        echo "SendGrid API key cannot be empty. Please try again."
        read -p "Enter the SendGrid API key: " SENDGRID_API_KEY
    done
}

# Function to generate the .env file by replacing placeholders
generate_env_file() {
    if [ -f .env ]; then
        echo "Removing existing .env file..."
        rm .env
    fi

    echo "Generating .env file from .env.example..."
    cp .env.example .env

    # Replace placeholders in the .env file
    sed -i "s/{{domain}}/${DOMAIN_NAME}/g" .env
    sed -i "s/{{subdomain}}/${SUBDOMAIN}/g" .env
    sed -i "s/{{admin_email}}/${SSL_EMAIL}/g" .env
    sed -i "s/{{sendgrid_api_key}}/${SENDGRID_API_KEY}/g" .env
}

# Display usage help
usage() {
    cat <<EOF
Usage: $0 [options]

Options:
    -domain-name=<domain>       Set the top-level domain
    -subdomain=<subdomain>      Set the subdomain
    -ssl-email=<email>          Set the email for SSL certificate
    -sendgrid-api-key=<key>     Set the SendGrid API key
    -h, --help                  Display this help message

If no arguments are provided, the script will prompt for input interactively.
EOF
    exit 0
}

# Create a Docker resource if it doesn't exist
create_docker_resource() {
    local resource_type=$1
    local resource_name=$2
    local create_command=$3

    if ! docker "$resource_type" inspect "$resource_name" &> /dev/null; then
        echo "Creating Docker $resource_type: $resource_name..."
        eval "$create_command"
    fi
}

# Main function
main() {
    echo "Starting installation..."

    # prompt interactively
    prompt_for_input

    # Ensure required variables are set
    if [[ -z "$DOMAIN_NAME" || -z "$SUBDOMAIN" || -z "$SSL_EMAIL" || -z "$SENDGRID_API_KEY" ]]; then
        echo "Error: Missing required values. Please provide all required inputs."
        exit 1
    fi

    # Check if Docker is installed
    if ! command -v docker &> /dev/null; then
        echo "Docker is not installed. Installing Docker..."
        if [ "$(uname)" == "Linux" ]; then
            curl -fsSL https://get.docker.com -o get-docker.sh
            sh get-docker.sh
            rm get-docker.sh
            echo "Docker installed successfully."
        else
            echo "Unsupported OS. Please install Docker manually."
            exit 1
        fi
    fi

    generate_env_file

    create_docker_resource volume traefik_data "docker volume create traefik_data"
    create_docker_resource volume n8n_data "docker volume create n8n_data"
    create_docker_resource network traefik-network "docker network create traefik-network"

    echo "Starting Docker Compose..."
    docker compose up -d --build
    echo "Installation completed successfully."
}

main "$@"