#!/bin/bash

# Stop the containers
docker stop bnc-client-container
docker stop bncapi-container

# Remove the containers
docker rm bnc-client-container
docker rm bncapi-container

# Remove the images
docker rmi bnc-client
docker rmi bncapi