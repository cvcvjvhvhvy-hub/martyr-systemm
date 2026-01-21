Preparation and build instructions

1) Required Flutter/Dart
- Use Flutter stable with Dart 3 (Flutter 3.10+ recommended).

2) Clean generated files (optional if you want a fresh fetch)
Open PowerShell in this folder and run:

```powershell
.\clean_project.ps1
```

3) Fetch dependencies and build

```powershell
cd "C:\Users\Hamid\Desktop\نظام-الشهداء-(martyr-system) (4)\flutter_app"
flutter pub get
flutter build apk  # or flutter run
```

4) If you see a version conflict error mentioning `cloud_firestore_platform_interface`:
- Paste the full `flutter pub get` error here so we can pin the exact override.
- As a general step: delete `pubspec.lock` and run `flutter pub get` again.

Notes
- This repo does not modify source UI code; the above only removes generated files and helps the target machine resolve dependencies cleanly.
- If you want, I can add a temporary `dependency_overrides` entry, but I prefer to pick the exact version after seeing the real `pub get` error output.