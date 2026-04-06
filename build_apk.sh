#!/bin/bash

# Job Finder App - Build APK Only

set -e

echo "🚀 Building Android APK..."

# Clean
flutter clean
flutter pub get

# Generate code
flutter pub run build_runner build --delete-conflicting-outputs

# Build Release APK
flutter build apk --release

echo ""
echo "✅ APK built successfully!"
echo "📱 Location: build/app/outputs/flutter-app.apk"
echo ""
echo "Install on device:"
echo "  adb install -r build/app/outputs/flutter-app.apk"
