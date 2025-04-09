#!/bin/bash
set -e

# Default values for environment variables
DEFAULT_DOMAIN_NAME="sku.io"
DEFAULT_SUBDOMAIN="dev2"
DEFAULT_SSL_EMAIL="kalvin@mizzi.com"
DEFAULT_SENDGRID_API_KEY="your_sendgrid_api_key"

# Function to generate the .env file by replacing placeholders
generate_env_file() {
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

    # Ensure required arguments are provided
    if [[ -z "$DOMAIN_NAME" || -z "$SUBDOMAIN" || -z "$SSL_EMAIL" || -z "$SENDGRID_API_KEY" ]]; then
        echo "Error: Missing required arguments."
        usage
    fi
}

# Check if a command exists
check_command() {
    if ! command -v "$1" &> /dev/null; then
        echo "$1 is not installed. Please install $1 first."
        exit 1
    fi
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
    parse_arguments "$@"

    check_command docker
    check_command docker-compose

    generate_env_file

    create_docker_resource volume traefik_data "docker volume create traefik_data"
    create_docker_resource volume n8n_data "docker volume create n8n_data"
    create_docker_resource network traefik-network "docker network create traefik-network"

    echo "Starting Docker Compose..."
    sudo docker-compose up -d --build

    echo "Installation completed successfully."
}

main "$@"