@echo off
REM Job Finder App - Build APK Only (Windows)

echo.
echo Building Android APK...
echo.

flutter clean
flutter pub get

flutter pub run build_runner build --delete-conflicting-outputs

flutter build apk --release

echo.
echo ✅ APK built successfully!
echo 📱 Location: build\app\outputs\flutter-app.apk
echo.
echo Install on device:
echo   adb install -r build\app\outputs\flutter-app.apk
echo.
pause
