@echo off
REM Stop the container if running, ignore errors if not found
cd infrastructure
REM Remove the container if it is existing
docker rm -f infrastructure || true
REM Run the Docker container
docker-compose -f docker-compose.yml up -d