@echo off
REM Job Finder App - Complete Build Script (Windows)

echo.
echo 🚀 Job Finder App - Complete Build
echo ====================================
echo.

echo [1/5] Cleaning previous builds...
flutter clean
flutter pub get

echo [2/5] Generating Hive adapters...
flutter pub run build_runner build --delete-conflicting-outputs

echo [3/5] Building Android APK...
flutter build apk --release
echo ✓ APK created: build\app\outputs\flutter-app.apk

echo [4/5] Building split APKs...
flutter build apk --release --split-per-abi
echo ✓ Split APKs created

echo [5/5] Building Flutter Web...
flutter build web --release
echo ✓ Web app created: build\web\

echo.
echo ✅ All builds completed successfully!
echo ====================================
echo.
echo 📱 Android:
echo   - Single APK: build\app\outputs\flutter-app.apk
echo   - Split APKs: build\app\outputs\app-*.apk
echo.
echo 🌐 Web:
echo   - Output: build\web\
echo   - Deploy to Firebase Hosting:
echo     firebase deploy --only hosting
echo.
pause
