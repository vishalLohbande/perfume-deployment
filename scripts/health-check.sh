#!/bin/bash

set -e

echo "======================================"
echo " Perfume Application Health Check"
echo "======================================"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

COMPOSE_FILE="$PROJECT_DIR/docker-compose.yml"
ENV_FILE="$PROJECT_DIR/.env"

CONTAINERS=(
    perfume-kafka
    perfume-service-registry
    perfume-product-service
    perfume-user-service
    perfume-order-service
    perfume-notification-service
    perfume-api-gateway
)

MAX_ATTEMPTS=60
ATTEMPT=1

# Wait for all containers to become healthy
while [ "$ATTEMPT" -le "$MAX_ATTEMPTS" ]; do

    ALL_HEALTHY=true

    echo ""
    echo "Health check attempt: $ATTEMPT/$MAX_ATTEMPTS"

    for CONTAINER in "${CONTAINERS[@]}"; do

        STATUS=$(sudo docker inspect \
            --format '{{if .State.Health}}{{.State.Health.Status}}{{else}}{{.State.Status}}{{end}}' \
            "$CONTAINER" 2>/dev/null || echo "missing")

        echo "$CONTAINER : $STATUS"

        if [ "$STATUS" != "healthy" ]; then
            ALL_HEALTHY=false
        fi

    done

    if [ "$ALL_HEALTHY" = true ]; then
        break
    fi

    sleep 5
    ATTEMPT=$((ATTEMPT + 1))

done

# Fail if containers never became healthy
if [ "$ALL_HEALTHY" != true ]; then
    echo ""
    echo "ERROR: Some containers are not healthy."

    sudo docker compose \
        --env-file "$ENV_FILE" \
        -f "$COMPOSE_FILE" \
        ps

    exit 1
fi

# Verify API Gateway endpoint
echo ""
echo "Checking API Gateway..."

if curl -fsS http://localhost:8080/actuator/health; then

    echo ""
    echo "======================================"
    echo " All containers are healthy!"
    echo " API Gateway is responding!"
    echo "======================================"

else

    echo ""
    echo "ERROR: API Gateway health endpoint failed."
    exit 1

fi