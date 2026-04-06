#!/bin/bash

# Job Finder App - Build Web Only

set -e

echo "🌐 Building Flutter Web..."

# Clean
flutter clean
flutter pub get

# Generate code
flutter pub run build_runner build --delete-conflicting-outputs

# Build Web
flutter build web --release

echo ""
echo "✅ Web app built successfully!"
echo "🌐 Location: build/web/"
echo ""
echo "Deploy to Firebase:"
echo "  firebase deploy --only hosting"
