# Job Finder App - Complete Setup & Build Guide

## 🎯 Project Overview

**Job Finder** is a production-ready Flutter app for Android APK and Web deployment. It enables users to find or post jobs in under 10 seconds with a privacy-first approach.

### Key Features
- ✅ Phone OTP authentication (no password)
- ✅ Job posting in 3 fields only
- ✅ Local favorites & application tracking
- ✅ Simple, fast, minimal UI
- ✅ Privacy-focused (name, phone, skills only)
- ✅ Offline caching support
- ✅ Works on Android & Web

---

## 📋 Prerequisites

Before starting, ensure you have:

1. **Flutter SDK** (>=3.0.0)
   ```bash
   flutter --version
   ```

2. **Dart** (included with Flutter)
   ```bash
   dart --version
   ```

3. **Android SDK** (for APK build)
   - Android Studio >=2022.1
   - Min SDK: Android 21

4. **Firebase Project**
   - Create at [firebase.google.com](https://firebase.google.com)
   - Enable Authentication (Phone OTP)
   - Create Firestore database

5. **Git** (for version control)

---

## 🔥 Firebase Setup

### Step 1: Create Firebase Project

1. Go to [Firebase Console](https://console.firebase.google.com)
2. Click "Add Project"
3. Name: `job-finder-app`
4. Continue with default settings
5. Create project

### Step 2: Enable Authentication

1. Go to **Authentication** → **Sign-in method**
2. Click **Phone** and enable it
3. Add your test phone numbers (for testing)

### Step 3: Create Firestore Database

1. Go to **Firestore Database**
2. Click **Create database**
3. Start in **Test mode** (for development)
4. Select region closest to you
5. Create database

### Step 4: Set Firestore Rules

```javascript
rules_version = '2';

service cloud.firestore {
  match /databases/{database}/documents {
    // Public read access for jobs
    match /jobs/{document=**} {
      allow read: if true;
      allow create, update, delete: if request.auth != null;
    }
    
    // Users - only their own data
    match /users/{userId} {
      allow read, write: if request.auth.uid == userId;
    }
    
    // Applications - only own data
    match /applications/{document=**} {
      allow read, write: if request.auth.uid == resource.data.userId;
      allow create: if request.auth != null;
    }
  }
}
```

### Step 5: Get Firebase Config

#### For Android:

1. Go to **Project Settings** → **Your apps** → **Android**
2. Download `google-services.json`
3. Place in: `android/app/google-services.json`

#### For Web:

1. Go to **Project Settings** → **Your apps** → **Web**
2. Copy Firebase config object
3. Update `lib/firebase_options.dart`:

```dart
static const FirebaseOptions web = FirebaseOptions(
  apiKey: 'YOUR_API_KEY',
  appId: 'YOUR_APP_ID',
  messagingSenderId: 'YOUR_SENDER_ID',
  projectId: 'your-firebase-project',
  authDomain: 'your-firebase-project.firebaseapp.com',
);
```

---

## 💻 Local Setup

### Step 1: Clone & Install Dependencies

```bash
cd c:\Users\secre\Desktop\ishbor
flutter pub get
flutter pub add hive_generator build_runner riverpod_generator
```

### Step 2: Generate Hive Adapters

```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

### Step 3: Verify Project Structure

```
lib/
├── main.dart                          # App entry point
├── firebase_options.dart              # Firebase config
├── core/
│   └── providers.dart                # Riverpod providers
├── features/
│   ├── auth/                          # Authentication screens
│   ├── home/                          # Home screens (seeker/employer)
│   ├── jobs/                          # Job details & applications
│   ├── favorites/                     # Saved jobs
│   └── post_job/                      # Post job screen
├── models/                            # Data models
├── services/                          # Firebase, storage, connectivity
└── ui/
    ├── theme/                         # App theme
    └── widgets/                       # Reusable widgets
```

---

## 🚀 Running the App

### Development (Hot Reload)

```bash
# Clear and run
flutter clean
flutter pub get
flutter run

# For web
flutter run -d chrome

# For web (specific port)
flutter run -d chrome --web-port 3000
```

### Run on Physical Device

1. **Android Phone:**
   ```bash
   flutter devices
   flutter run -d <device-id>
   ```

2. **Enable USB Debugging:**
   - Settings → Developer Options → USB Debugging → ON

---

## 📱 Build APK (Android)

### Build Release APK

```bash
# Single APK
flutter build apk --release

# Output: build/app/outputs/flutter-app.apk
```

### Build Split APKs (for different architectures)

```bash
flutter build apk --release --split-per-abi

# Outputs:
# - app-arm64-v8a-release.apk (64-bit)
# - app-armeabi-v7a-release.apk (32-bit)
# - app-x86_64-release.apk (x86)
```

### Build App Bundle (for Google Play Store)

```bash
# Recommended for distribution
flutter build appbundle --release

# Output: build/app/outputs/bundle/release/app-release.aab
```

### Installation on Device

```bash
# Install APK
adb install build/app/outputs/flutter-app.apk

# Or via file manager on phone
# Download APK and tap to install
```

### Signing APK for Play Store

1. **Create Keystore:**
   ```bash
   keytool -genkey -v -keystore ~/job-finder-key.jks \
     -keyalg RSA -keysize 2048 -validity 10000 \
     -alias job-finder-key
   ```

2. **Update Build Config** (`android/app/build.gradle`):
   ```gradle
   signingConfigs {
     release {
       keyAlias = 'job-finder-key'
       keyPassword = 'YOUR_KEY_PASSWORD'
       storeFile = file('~/job-finder-key.jks')
       storePassword = 'YOUR_STORE_PASSWORD'
     }
   }

   buildTypes {
     release {
       signingConfig = signingConfigs.release
     }
   }
   ```

3. **Build signed APK:**
   ```bash
   flutter build apk --release
   ```

---

## 🌐 Build Web

### Build for Web

```bash
# Clean and build
flutter clean
flutter pub get
flutter build web --release

# Output: build/web/
```

### Deploy Web App

#### Option 1: Firebase Hosting

```bash
# Install Firebase CLI
npm install -g firebase-tools

# Login
firebase login

# Initialize Firebase in project
firebase init hosting

# Deploy
firebase deploy --only hosting
```

#### Option 2: Netlify

```bash
# Install Netlify CLI
npm install -g netlify-cli

# Deploy directory: build/web/
netlify deploy --prod --dir=build/web
```

#### Option 3: Vercel

```bash
# Install Vercel CLI
npm install -g vercel

# Deploy
vercel --prod
```

#### Manual Deployment

1. Build web: `flutter build web --release`
2. Upload `build/web/` folder to any web hosting
3. Configure server for SPA routing (index.html on 404)

---

## 🧪 Testing

### Unit Tests

```bash
flutter test
```

### Integration Tests

```bash
flutter test integration_test/
```

### Test on Multiple Devices

```bash
# List emulators
flutter emulators

# Launch emulator
flutter emulators --launch <emulator-name>

# Run on all devices
flutter run
# Select device when prompted
```

---

## 📦 App Size Optimization

### Reduce APK Size

```bash
# Remove debug info
flutter build apk --release --split-per-abi

# Use ProGuard (Android)
# Edit android/app/build.gradle:
buildTypes {
  release {
    minifyEnabled true
    shrinkResources true
  }
}
```

### Web Size Optimization

```bash
flutter build web --release --dart-define=FLUTTER_WEB_AUTO_DETECT=false
```

---

## 🔐 Security Checklist

- [ ] Firebase rules configured (see Firebase Setup)
- [ ] No API keys in code
- [ ] All sensitive data in environment variables
- [ ] Database backups enabled
- [ ] Rate limiting enabled for Auth
- [ ] Phone verification enabled
- [ ] HTTPS enforced for web
- [ ] No logging of sensitive data

---

## 🐛 Troubleshooting

### Issue: Firebase Auth Not Working

**Solution:**
```bash
flutter pub get
flutter clean
# Re-run and check Firebase console for auth logs
```

### Issue: APK Won't Install

**Solution:**
```bash
# Check Android version
adb shell getprop ro.build.version.release

# Build for minimum version
flutter build apk --target-platform android-arm64
```

### Issue: Web App Not Loading

**Solution:**
```bash
# Clear browser cache
# Try different browser
# Check console for CORS errors
flutter run -d chrome --web-renderer html
```

### Issue: Hive Adapter Not Generated

**Solution:**
```bash
flutter pub run build_runner clean
flutter pub run build_runner build --delete-conflicting-outputs
flutter pub get
```

---

## 📊 Performance Tips

1. **Lazy load images:**
   ```dart
   Image.network(url, cacheWidth: 400)
   ```

2. **Cache jobs locally:**
   - LocalStorageService handles this

3. **Paginate API calls:**
   - Already limited to 50 jobs in provider

4. **Use const widgets:**
   - Already applied throughout

5. **Profile performance:**
   ```bash
   flutter run --profile
   ```

---

## 🚢 Deployment Checklist

### Before Production:

- [ ] Firebase project configured
- [ ] Authentication (phone OTP) working
- [ ] Firestore rules set
- [ ] App signed with production keystore
- [ ] All environment variables set
- [ ] Tested on real devices
- [ ] Privacy policy added
- [ ] Terms of service agreed
- [ ] Analytics enabled (optional)
- [ ] Crash reporting enabled (optional)

### Google Play Store:

1. Create Google Play Developer Account ($25 one-time)
2. Create app and fill store listing
3. Upload signed APK or App Bundle
4. Set ratings, categories, privacy
5. Submit for review

### Firebase Hosting (Web):

1. Initialize Firebase hosting
2. Deploy web build
3. Configure custom domain
4. Enable SSL (automatic)

---

## 📞 Support & Resources

- [Flutter Docs](https://flutter.dev/docs)
- [Firebase Docs](https://firebase.google.com/docs)
- [Riverpod Docs](https://riverpod.dev)
- [Material Design](https://material.io)

---

## 📄 License

This project is provided as-is for educational and commercial use.

---

**Version:** 1.0.0  
**Last Updated:** April 2026  
**Status:** ✅ Production Ready
