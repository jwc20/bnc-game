#!/bin/bash

# Set the names of the Docker images and containers
BNC_CLIENT_IMAGE_NAME="bnc-client"
BNC_CLIENT_CONTAINER_NAME="bnc-client-container"
BNC_API_IMAGE_NAME="bncapi"
BNC_API_CONTAINER_NAME="bncapi-container"
API_DB_CONTAINER_NAME="api-db"
REDIS_CONTAINER_NAME="redis"

# Set the ports to map for each container
BNC_CLIENT_PORT=3000
BNC_API_PORT=8000
API_DB_PORT=5432
REDIS_PORT=6379

# Build the Docker images using the Dockerfiles
echo "Building bnc-client image..."
docker build -t $BNC_CLIENT_IMAGE_NAME ./bnc-client

echo "Building bncapi image..."
docker build -t $BNC_API_IMAGE_NAME ./bncapi

# Create the Postgres container
echo "Creating Postgres container..."
docker run -d --name $API_DB_CONTAINER_NAME \
  -e POSTGRES_DB=bncapi_dev \
  -e POSTGRES_USER=postgres \
  -e POSTGRES_PASSWORD=postgres \
  -p $API_DB_PORT:$API_DB_PORT \
  -v postgres_data:/var/lib/postgresql/data \
  postgres:17-alpine

# Create the Redis container
echo "Creating Redis container..."
docker run -d --name $REDIS_CONTAINER_NAME \
  -p $REDIS_PORT:$REDIS_PORT \
  redis:7-alpine

# Run the bnc-client container
echo "Running bnc-client container..."
docker run -d --name $BNC_CLIENT_CONTAINER_NAME \
  -p $BNC_CLIENT_PORT:$BNC_CLIENT_PORT \
  -e VITE_API_URL=http://localhost:$BNC_API_PORT \
  $BNC_CLIENT_IMAGE_NAME

# Run the bncapi container
echo "Running bncapi container..."
docker run -d --name $BNC_API_CONTAINER_NAME \
  -p $BNC_API_PORT:$BNC_API_PORT \
  -e DEBUG=False \
  -e DJANGO_SETTINGS_MODULE=bncapi.settings \
  -e POSTGRES_DATABASE_URL=postgres://postgres:postgres@$API_DB_CONTAINER_NAME:$API_DB_PORT/bncapi_dev \
  -e POSTGRES_DB=bncapi_dev \
  -e POSTGRES_USER=postgres \
  -e POSTGRES_PASSWORD=postgres \
  -e POSTGRES_HOST=$API_DB_CONTAINER_NAME \
  -e POSTGRES_PORT=$API_DB_PORT \
  -e REDIS_HOST=$REDIS_CONTAINER_NAME \
  -e REDIS_PORT=$REDIS_PORT \
  -e REDIS_CHANNEL_LAYER_URL=redis://$REDIS_CONTAINER_NAME:$REDIS_PORT \
  -e PUBLIC_API_URL=http://localhost:$BNC_API_PORT/api \
  -e SECRET_KEY=my_precious_secret_key_for_local_prod \
  --link $API_DB_CONTAINER_NAME \
  --link $REDIS_CONTAINER_NAME \
  $BNC_API_IMAGE_NAME

# Run any additional scripts to configure the containers
echo "Configuring bnc-client container..."
./configure-bnc-client.sh

echo "Configuring bncapi container..."
./configure-bncapi.sh

# Start the containers
echo "Starting bnc-client container..."
docker start $BNC_CLIENT_CONTAINER_NAME

echo "Starting bncapi container..."
docker start $BNC_API_CONTAINER_NAME

echo "Starting Postgres container..."
docker start $API_DB_CONTAINER_NAME

echo "Starting Redis container..."
docker start $REDIS_CONTAINER_NAME

# Verify that the containers are running
echo "Verifying container status..."
docker ps -a