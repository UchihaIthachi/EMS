#!/bin/bash

# Exit on error
set -e

echo "Starting local deployment..."

# Step 1: Build Docker images for each service
echo "Building Docker images..."
docker-compose build

# Step 2: Start all services
echo "Starting services..."
docker-compose up -d

# Step 3: Show logs (optional)
echo "Showing logs for all services..."
docker-compose logs -f
