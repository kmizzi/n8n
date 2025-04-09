#!/bin/bash
set -e

# Default values for environment variables
DEFAULT_DOMAIN_NAME="sku.io"
DEFAULT_SUBDOMAIN="dev2"
DEFAULT_SSL_EMAIL="kalvin@mizzi.com"
DEFAULT_SENDGRID_API_KEY="your_sendgrid_api_key"

# Function to generate the .env file by replacing placeholders
generate_env_file() {
    if [[ -n "$DOMAIN_NAME" || -n "$SUBDOMAIN" || -n "$SSL_EMAIL" || -n "$SENDGRID_API_KEY" ]]; then
        echo "Arguments provided. Regenerating .env file..."
        if [ -f .env ]; then
            echo "Removing existing .env file..."
            if [ -w .env ]; then
                rm .env
            else
                echo "Error: Insufficient permissions to remove .env file."
                exit 1
            fi
        fi
        echo "Generating .env file from .env.example..."
        cp .env.example .env

        # Replace placeholders in the .env file
        sed -i "s/{{domain}}/${DOMAIN_NAME:-$DEFAULT_DOMAIN_NAME}/g" .env
        sed -i "s/{{subdomain}}/${SUBDOMAIN:-$DEFAULT_SUBDOMAIN}/g" .env
        sed -i "s/{{admin_email}}/${SSL_EMAIL:-$DEFAULT_SSL_EMAIL}/g" .env
        sed -i "s/{{sendgrid_api_key}}/${SENDGRID_API_KEY:-$DEFAULT_SENDGRID_API_KEY}/g" .env
    else
        if [ -f .env ]; then
            echo "No arguments provided. Using existing .env file."
        else
            echo "Error: .env file does not exist and no arguments provided to generate it."
            exit 1
        fi
    fi
}

# Display usage help
usage() {
    cat <<EOF
Usage: $0 [options]

Options:
    -domain-name=<domain>       Set the top-level domain (default: $DEFAULT_DOMAIN_NAME)
    -subdomain=<subdomain>      Set the subdomain (default: $DEFAULT_SUBDOMAIN)
    -ssl-email=<email>          Set the email for SSL certificate (default: $DEFAULT_SSL_EMAIL)
    -sendgrid-api-key=<key>     Set the SendGrid API key (default: $DEFAULT_SENDGRID_API_KEY)
    -h, --help                  Display this help message

If no arguments are provided, the script will use the existing .env file.
EOF
    exit 0
}

# Parse command-line arguments
parse_arguments() {
    while [[ "$#" -gt 0 ]]; do
        case $1 in
            -domain-name=*) DOMAIN_NAME="${1#*=}" ;;
            -subdomain=*) SUBDOMAIN="${1#*=}" ;;
            -ssl-email=*) SSL_EMAIL="${1#*=}" ;;
            -sendgrid-api-key=*) SENDGRID_API_KEY="${1#*=}" ;;
            -h|--help) usage ;;
            *) echo "Unknown parameter: $1"; usage ;;
        esac
        shift
    done
}

# Check if a command exists
check_command() {
    if ! command -v "$1" &> /dev/null; then
        echo "$1 is not installed. Please install $1 first."
        exit 1
    fi
}

# Pull the latest n8n Docker image
pull_latest_image() {
    echo "Pulling the latest n8n Docker image..."
    docker pull n8nio/n8n:latest
}

# Rebuild Docker Compose services
rebuild_services() {
    echo "Rebuilding Docker Compose services..."
    docker-compose build --no-cache
}

# Restart Docker Compose services
restart_services() {
    echo "Restarting Docker Compose services..."
    docker-compose down
    docker-compose up -d
}

# Main function
main() {
    echo "Starting upgrade process..."
    parse_arguments "$@"

    check_command docker
    check_command docker-compose

    generate_env_file

    pull_latest_image
    rebuild_services
    restart_services

    echo "Upgrade completed successfully."
}

main "$@"