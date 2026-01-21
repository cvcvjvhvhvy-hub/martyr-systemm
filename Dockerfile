# Dockerfile to build Android APK for the Flutter app
# Uses cirrusci Flutter image which includes Flutter + Android SDK
FROM ghcr.io/cirrusci/flutter:stable

WORKDIR /app

# Copy project files
COPY . /app

# Ensure licenses accepted and Flutter dependencies
RUN yes | sdkmanager --licenses || true
RUN flutter pub get

# Build release APK
RUN flutter build apk --release

# Keep container interactive by default
CMD ["/bin/bash"]
