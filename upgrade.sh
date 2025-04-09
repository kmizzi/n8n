#!/bin/bash
set -e

docker pull n8nio/n8n:latest
docker compose build --no-cache
docker compose down
docker compose up -d