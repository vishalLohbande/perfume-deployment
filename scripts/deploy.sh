#!/bin/bash

# Stop execution if any command fails
set -e

echo "======================================"
echo " Starting Perfume Microservices Deploy"
echo "======================================"

# Find deployment project directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

# Define configuration files
COMPOSE_FILE="$PROJECT_DIR/docker-compose.yml"
ENV_FILE="$PROJECT_DIR/.env"

# Check required files
if [ ! -f "$COMPOSE_FILE" ]; then
    echo "ERROR: docker-compose.yml not found"
    exit 1
fi

if [ ! -f "$ENV_FILE" ]; then
    echo "ERROR: .env file not found"
    exit 1
fi

# Validate Docker Compose configuration
echo "Validating Docker Compose configuration..."

sudo docker compose \
    --env-file "$ENV_FILE" \
    -f "$COMPOSE_FILE" \
    config --quiet

# Pull latest images
echo "Pulling Docker images..."

sudo docker compose \
    --env-file "$ENV_FILE" \
    -f "$COMPOSE_FILE" \
    pull

# Start all containers
echo "Starting all containers..."

sudo docker compose \
    --env-file "$ENV_FILE" \
    -f "$COMPOSE_FILE" \
    up -d --remove-orphans

echo "======================================"
echo " Deployment command completed"
echo "======================================"

# Display container status
sudo docker compose \
    --env-file "$ENV_FILE" \
    -f "$COMPOSE_FILE" \
    ps

# Run health check
"$SCRIPT_DIR/health-check.sh"