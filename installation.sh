#!/bin/bash
set -e

# Function to check if Docker is installed
check_docker() {
  if ! command -v docker &> /dev/null; then
    echo "Docker is not installed. Please install Docker first."
    exit 1
  fi
}

# Function to check if Docker Compose is installed
check_docker_compose() {
  if ! command -v docker-compose &> /dev/null; then
    echo "Docker Compose is not installed. Please install Docker Compose first."
    exit 1
  fi
}

# Function to create required Docker volumes if they don't exist
create_volumes() {
  echo "Creating volumes if they don't exist..."
  docker volume inspect traefik_data > /dev/null 2>&1 || docker volume create traefik_data
  docker volume inspect n8n_data > /dev/null 2>&1 || docker volume create n8n_data
}

# Function to create required Docker network if it doesn't exist
create_network() {
  echo "Creating network if it doesn't exist..."
  docker network inspect traefik-network > /dev/null 2>&1 || docker network create traefik-network
}

# Function to start Docker Compose
start_docker_compose() {
  echo "Starting docker-compose..."
  docker-compose up -d --build
}

main() {
  echo "Starting installation..."
  check_docker
  check_docker_compose
  create_volumes
  create_network
  start_docker_compose
  echo "Installation completed successfully."
}

main