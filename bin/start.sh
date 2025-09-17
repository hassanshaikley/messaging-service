#!/bin/bash

set -e

echo "Starting the application..."
echo "Environment: ${ENV:-development}"

# Add your application startup commands here

iex -S mix phx.server
echo "Application started successfully!" 
