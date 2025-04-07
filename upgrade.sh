#!/bin/bash
set -e

if ! docker volume inspect traefik_data &>/dev/null; then
    docker volume create traefik_data
fi

if ! docker network inspect traefik-network &>/dev/null; then
    docker network create traefik-network
fi

#if ! sudo ufw status | grep -q "5678"; then
    #sudo ufw allow 5678
    #sudo ufw reload
#fi

docker pull n8nio/n8n:latest
docker compose build --no-cache
docker compose down
docker compose up -d