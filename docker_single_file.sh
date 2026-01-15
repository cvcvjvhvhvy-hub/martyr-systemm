#!/usr/bin/env bash
set -euo pipefail

# Single-file Docker builder for the Flutter app.
# Usage:
#   chmod +x docker_single_file.sh
#   ./docker_single_file.sh
# This script creates a temporary Dockerfile, builds the image and extracts app-release.apk

PROJECT_DIR=$(cd "$(dirname "$0")" && pwd)
IMAGE_NAME=martyr_system_singlefile:latest
DOCKERFILE_PATH=$(mktemp /tmp/Dockerfile.XXXX)
trap 'rm -f "$DOCKERFILE_PATH"' EXIT

cat > "$DOCKERFILE_PATH" <<'DOCKERFILE'
FROM ghcr.io/cirrusci/flutter:stable

WORKDIR /app

# Copy project into image
COPY . /app

# Accept Android SDK licenses (may fail harmlessly if sdkmanager not present)
RUN yes | sdkmanager --licenses || true

# Get packages and build release APK
RUN flutter pub get
RUN flutter build apk --release

# Keep shell for debugging
CMD ["/bin/bash"]
DOCKERFILE

echo "Building Docker image ($IMAGE_NAME) using temporary Dockerfile: $DOCKERFILE_PATH"

# Build the image
docker build -f "$DOCKERFILE_PATH" -t "$IMAGE_NAME" "$PROJECT_DIR"

# Create a container from the image and copy out the APK
APK_PATH=build/app/outputs/flutter-apk/app-release.apk
CONTAINER_ID=$(docker create --rm "$IMAGE_NAME")

echo "Copying APK from container..."
if docker cp "$CONTAINER_ID":/app/$APK_PATH "$PROJECT_DIR"/app-release.apk; then
  echo "APK extracted to $PROJECT_DIR/app-release.apk"
else
  echo "APK not found in container. Build may have failed. Inspect container logs with: docker start -ai $CONTAINER_ID"
  docker rm "$CONTAINER_ID" || true
  exit 1
fi

docker rm "$CONTAINER_ID" || true

echo "Done."
