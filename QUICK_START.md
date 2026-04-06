# 🚀 Job Finder App - Quick Start (5 Minutes)

## Step 1: Prerequisites ✅

```bash
# Check Flutter
flutter --version

# Should show: Flutter 3.0+ and Dart 3.0+
```

## Step 2: Firebase Setup 🔥

1. Go to https://console.firebase.google.com
2. Create new project: `job-finder-app`
3. **Enable Phone Authentication:**
   - Authentication → Sign-in method → Phone → Enable
4. **Create Firestore Database:**
   - Firestore → Create database → Test mode → CREATE
5. **Get Config:**
   - Project Settings → Your apps → Select platform

### Android Setup:
- Download `google-services.json`
- Place in: `android/app/google-services.json`

### Web Setup:
- Copy config from Firebase console
- Update `lib/firebase_options.dart` with your credentials

## Step 3: Install & Run 🏃

```bash
# Navigate to project
cd c:\Users\secre\Desktop\ishbor

# Get dependencies
flutter pub get

# Generate Hive adapters
flutter pub run build_runner build --delete-conflicting-outputs

# Run on emulator
flutter run

# OR run on web
flutter run -d chrome

# OR run on physical Android device
adb devices  # List devices
flutter run -d <device-id>
```

## Step 4: Test Features 🧪

1. **Phone Auth:** Enter any phone number (test mode allows any)
2. **Browse Jobs:** Tap categories to filter
3. **Post Job (Employer):** Click post button with 3 fields
4. **Favorites:** Save jobs by heart icon

## Step 5: Build Release 📦

### Build APK:
```bash
flutter build apk --release
# Output: build/app/outputs/flutter-app.apk
```

### Build Web:
```bash
flutter build web --release
# Output: build/web/
# Upload to: Firebase Hosting, Netlify, Vercel, etc.
```

## 🐛 Troubleshooting

| Issue | Solution |
|-------|----------|
| "Firebase not initialized" | Update `firebase_options.dart` with real credentials |
| "Hive adapters not found" | Run: `flutter pub run build_runner build --delete-conflicting-outputs` |
| "Phone auth fails" | Check Firebase console → Authentication → Phone enabled |
| "Web won't load" | Try: `flutter run -d chrome --web-renderer html` |
| "APK won't install" | Uninstall old version first: `adb uninstall com.example.job_finder_app` |

## 📱 Default Routes

- `/auth` - Phone login
- `/role-selection` - Job seeker or employer
- `/home-seeker` - Jobs home
- `/home-employer` - Employer home  
- `/job-details` - Job detail view
- `/favorites` - Saved jobs
- `/applications` - Application status
- `/post-job` - Post new job

## 🎯 Key Files

| File | Purpose |
|------|---------|
| `lib/main.dart` | App entry point |
| `lib/firebase_options.dart` | Firebase config (UPDATE THIS!) |
| `pubspec.yaml` | Dependencies |
| `android/app/build.gradle` | Android build config |
| `web/index.html` | Web entry point |

## ✨ That's it!

Your Job Finder app is ready to go. For detailed setup, see [SETUP_AND_BUILD_GUIDE.md](SETUP_AND_BUILD_GUIDE.md)

---

**Need help?** Check [README.md](README.md) or troubleshooting section above.
