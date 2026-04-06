#!/bin/bash

# Job Finder App - Complete Build Script
# This script builds both APK and Web versions

set -e  # Exit on error

echo "🚀 Job Finder App - Complete Build"
echo "===================================="

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Step 1: Clean
echo -e "${BLUE}[1/5] Cleaning previous builds...${NC}"
flutter clean
flutter pub get

# Step 2: Generate code
echo -e "${BLUE}[2/5] Generating Hive adapters...${NC}"
flutter pub run build_runner build --delete-conflicting-outputs

# Step 3: Build APK
echo -e "${BLUE}[3/5] Building Android APK...${NC}"
flutter build apk --release
echo -e "${GREEN}✓ APK created: build/app/outputs/flutter-app.apk${NC}"

# Step 4: Build split APKs (optional)
echo -e "${BLUE}[4/5] Building split APKs...${NC}"
flutter build apk --release --split-per-abi
echo -e "${GREEN}✓ Split APKs created in build/app/outputs/${NC}"

# Step 5: Build Web
echo -e "${BLUE}[5/5] Building Flutter Web...${NC}"
flutter build web --release
echo -e "${GREEN}✓ Web app created: build/web/${NC}"

echo ""
echo -e "${GREEN}===================================="
echo "✅ All builds completed successfully!"
echo "====================================${NC}"
echo ""
echo "📱 Android:"
echo "  - Single APK: build/app/outputs/flutter-app.apk"
echo "  - Split APKs: build/app/outputs/app-*.apk"
echo ""
echo "🌐 Web:"
echo "  - Output: build/web/"
echo "  - Deploy to Firebase Hosting:"
echo "    firebase deploy --only hosting"
echo ""
