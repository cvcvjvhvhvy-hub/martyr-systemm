#!/usr/bin/env bash
set -e

IMAGE_NAME=martyr_system:latest
APK_PATH=build/app/outputs/flutter-apk/app-release.apk

# Build Docker image
docker build -t "$IMAGE_NAME" .

# Create container and copy APK out
CONTAINER_ID=$(docker create "$IMAGE_NAME")

echo "Copying APK from container..."
docker cp "$CONTAINER_ID":/app/$APK_PATH ./

docker rm "$CONTAINER_ID"

echo "APK copied to ./app-release.apk"

# Rename if exists
if [ -f "app-release.apk" ]; then
  mv app-release.apk app-release.apk || true
fi
