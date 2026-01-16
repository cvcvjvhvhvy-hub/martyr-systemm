# Cleans generated Flutter/Dart files so a fresh build can run on another machine.
# Run this from PowerShell in the flutter_app folder:
#   .\clean_project.ps1

$paths = @(
    "pubspec.lock",
    ".packages",
    ".dart_tool",
    "build",
    "ios/Pods",
    "ios/Runner.xcworkspace",
    "android/.gradle",
    "android/app/.gradle",
    "android/.idea",
    "**/*.iml"
)

Write-Host "Cleaning generated files (safe to run)..."
foreach ($p in $paths) {
    try {
        if (Test-Path $p) {
            Remove-Item -Recurse -Force -Path $p -ErrorAction Stop
            Write-Host "Removed: $p"
        }
    } catch {
        Write-Host "Skipped or failed to remove: $p -> $_"
    }
}

Write-Host "Cleanup complete. Run `flutter pub get` on the target machine.`"