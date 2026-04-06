@echo off
REM Job Finder App - Build Web Only (Windows)

echo.
echo Building Flutter Web...
echo.

flutter clean
flutter pub get

flutter pub run build_runner build --delete-conflicting-outputs

flutter build web --release

echo.
echo ✅ Web app built successfully!
echo 🌐 Location: build\web\
echo.
echo Deploy to Firebase:
echo   firebase deploy --only hosting
echo.
pause
