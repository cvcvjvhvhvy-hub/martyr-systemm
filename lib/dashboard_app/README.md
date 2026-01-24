# Admin Dashboard (Flutter)

This is a standalone Flutter admin dashboard (mock). It is not integrated with the main app — it's a separate Flutter project placed under `flutter_app/admin/dashboard_app` so you can connect it later.

Quick start:

```bash
cd flutter_app/admin/dashboard_app
flutter pub get
flutter run
```

Notes:
- The data layer is a simple in-memory `MockService` (no backend).
- Pages: Users, Content, Notifications.
- Use Material design; localize/RTL as needed.

Build for web (recommended for easy deployment):

```bash
cd flutter_app/admin/dashboard_app
flutter pub get
flutter build web --release
# The built files are in build/web
```

Run locally (serve the `build/web` folder) or build a Docker image as below.

Docker build & run (serves production web build via nginx):

```bash
# from project root flutter_app/admin/dashboard_app
docker build -t admin-dashboard:latest .
docker run -p 8080:80 admin-dashboard:latest
# open http://localhost:8080
```

Notes on Dockerfile:
- Multi-stage: uses a Flutter SDK image to build web, then copies to `nginx:alpine` for serving.
- If you're building on CI, ensure Docker has enough disk/CPU and network to fetch Flutter SDK.

