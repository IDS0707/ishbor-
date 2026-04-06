# Job Finder App - Architecture Guide

## 📐 Overall Architecture

The app uses **Clean Architecture** with clear separation of concerns:

```
┌─────────────────────────────────────────┐
│         UI Layer (Screens)              │
│  (Features: Auth, Home, Jobs, etc)      │
└─────────────────────────────────────────┘
                    ↓
┌─────────────────────────────────────────┐
│     State Management (Riverpod)         │
│  (Providers for data & business logic)  │
└─────────────────────────────────────────┘
                    ↓
┌─────────────────────────────────────────┐
│    Services Layer (Firebase, Storage)   │
│  (FirebaseService, LocalStorageService) │
└─────────────────────────────────────────┘
                    ↓
┌─────────────────────────────────────────┐
│    External Services & Databases        │
│  (Firebase Auth, Firestore, Hive)       │
└─────────────────────────────────────────┘
```

---

## 📁 Project Structure

```
job_finder_app/
│
├── lib/                              # Main application code
│   ├── main.dart                     # App entry point & routing
│   ├── firebase_options.dart         # Firebase configuration
│   │
│   ├── core/
│   │   └── providers.dart            # All Riverpod providers
│   │
│   ├── features/                     # Feature modules
│   │   ├── auth/
│   │   │   ├── phone_auth_screen.dart
│   │   │   ├── role_selection_screen.dart
│   │   │   └── index.dart
│   │   ├── home/
│   │   │   ├── job_seeker/
│   │   │   │   ├── home_screen.dart
│   │   │   │   └── index.dart
│   │   │   └── employer/
│   │   │       ├── home_screen.dart
│   │   │       └── index.dart
│   │   ├── jobs/
│   │   │   ├── job_details_screen.dart
│   │   │   ├── applications_status_screen.dart
│   │   │   └── index.dart
│   │   ├── favorites/
│   │   │   ├── favorites_screen.dart
│   │   │   └── index.dart
│   │   └── post_job/
│   │       ├── post_job_screen.dart
│   │       └── index.dart
│   │
│   ├── models/                       # Data models
│   │   ├── user_model.dart
│   │   ├── job_model.dart
│   │   ├── application_model.dart
│   │   └── index.dart
│   │
│   ├── services/                     # Business logic & external services
│   │   ├── firebase_service.dart     # Firebase operations
│   │   ├── local_storage_service.dart # Hive operations (caching & storage)
│   │   ├── connectivity_service.dart  # Network status
│   │   └── index.dart
│   │
│   └── ui/                           # UI components
│       ├── theme/
│       │   ├── app_theme.dart        # Theme configuration
│       │   └── index.dart
│       └── widgets/
│           ├── common_widgets.dart    # Reusable UI components
│           └── index.dart
│
├── android/                          # Android-specific code
│   ├── app/
│   │   ├── build.gradle
│   │   └── google-services.json      # Firebase config (add this!)
│   └── build.gradle
│
├── web/                              # Web-specific code
│   ├── index.html
│   ├── manifest.json
│   └── favicon.ico
│
├── pubspec.yaml                      # Dependencies
├── analysis_options.yaml             # Lint rules
├── .gitignore
│
├── README.md                         # Quick overview
├── QUICK_START.md                    # 5-minute setup guide
├── SETUP_AND_BUILD_GUIDE.md         # Detailed setup & build instructions
├── DATABASE_SCHEMA.md                # Firestore schema & sample data
├── TESTING.md                        # Testing guide
├── ARCHITECTURE.md                   # This file
│
├── build_all.sh / build_all.bat      # Build APK + Web (Linux/Mac or Windows)
├── build_apk.sh / build_apk.bat      # Build APK only
└── build_web.sh / build_web.bat      # Build Web only
```

---

## 🎯 Core Concepts

### 1. Models (Data Layer)

Located in `lib/models/`, these define the data structure:

- **User** - User profile with name, phone, skills, type (Hive-persisted)
- **Job** - Job listing with title, salary, category (Hive-cached)
- **Application** - Job application with status tracking (Hive-cached)

All models are serializable (Hive & JSON):

```dart
// Models extend HiveObject for persistence
@HiveType(typeId: 0)
class User extends HiveObject {
  @HiveField(0)
  String id;
  
  // toJson() for Firebase
  Map<String, dynamic> toJson() { ... }
  
  // fromJson() for deserialization
  factory User.fromJson(Map<String, dynamic> json) { ... }
}
```

### 2. Services (Business Logic)

Located in `lib/services/`, these handle external operations:

#### FirebaseService
Handles Firebase operations:
- Phone OTP authentication
- User CRUD operations
- Job CRUD operations
- Application tracking

```dart
// Usage
final firebase = FirebaseService();
await firebase.verifyPhoneNumber(phoneNumber);
final jobs = await firebase.getAllJobs();
```

#### LocalStorageService
Handles local caching & persistence:
- Save/load current user
- Cache jobs locally
- Manage favorites
- Track applications offline
- Store user preferences

```dart
// Usage
await localStorage.saveUser(user);
final jobs = localStorage.getCachedJobs('simple_jobs');
localStorage.addFavorite(jobId);
```

#### ConnectivityService
Monitors network connectivity:
- Check internet status
- Listen for connectivity changes
- Enable offline mode fallback

```dart
// Usage
final hasConnection = await ConnectivityService.hasConnection();
// Or listen to changes
ConnectivityService.connectionStream.listen((isOnline) {...});
```

### 3. State Management (Riverpod)

Located in `lib/core/providers.dart`, these manage app state:

#### Service Providers
```dart
final firebaseServiceProvider = Provider<FirebaseService>((ref) {
  return FirebaseService();
});
```

#### State Providers
```dart
final currentUserProvider = StateProvider<User?>((ref) {
  return null; // Initially null
});
```

#### Future Providers (Async Data)
```dart
final jobsProvider = FutureProvider<List<Job>>((ref) async {
  final firebase = ref.watch(firebaseServiceProvider);
  return firebase.getAllJobs();
});
```

#### Stream Providers (Real-time)
```dart
final connectivityProvider = StreamProvider<bool>((ref) {
  return ConnectivityService.connectionStream;
});
```

### 4. Features (UI Layer)

Each feature is self-contained:

#### Authentication Flow
- `phone_auth_screen.dart` - Phone number input & OTP verification
- `role_selection_screen.dart` - Role selection & profile completion

#### Job Seeker
- `home/job_seeker/home_screen.dart` - Browse jobs by category
- `jobs/job_details_screen.dart` - View job details & apply
- `favorites/favorites_screen.dart` - View saved jobs
- `jobs/applications_status_screen.dart` - Track applications

#### Employer
- `home/employer/home_screen.dart` - View posted jobs & stats
- `post_job/post_job_screen.dart` - Post new job (3 fields)

### 5. UI Components

Located in `lib/ui/`:

#### Theme (`ui/theme/app_theme.dart`)
Defines colors, typography, and button styles:

```dart
class AppTheme {
  static const Color primary = Color(0xFF2563EB);    // Blue
  static const Color success = Color(0xFF10B981);    // Green
  static const Color danger = Color(0xFFEF4444);     // Red
  
  static ThemeData get lightTheme {
    // Material 3 theme
  }
}
```

#### Widgets (`ui/widgets/common_widgets.dart`)
Reusable custom widgets:

- **PrimaryButton** - Main action button
- **SecondaryButton** - Secondary action button
- **JobCard** - Job listing card
- **HiddenPhoneWidget** - Phone number with show/hide toggle
- **CategoryChip** - Category filter chip

```dart
// Usage
PrimaryButton(
  label: 'Apply',
  onPressed: () => _applyForJob(),
  isLoading: _isLoading,
)
```

---

## 🔄 Data Flow Example

### User applies for a job:

1. **UI Layer** - User taps "Apply Now" on job details screen
2. **Provider** - Call `_applyForJob(job)` method
3. **Service** - `FirebaseService.applyForJob(application)`
4. **External** - Application saved to Firestore
5. **Cache** - Application cached locally via Hive
6. **State** - Refresh `userApplicationsProvider`
7. **UI** - Screen updates with new application status

```
User Action
    ↓
[UI] JobDetailsScreen._applyForJob()
    ↓
[Service] firebase_service.applyForJob()
    ↓
[External] Firestore collection('applications').add()
    ↓
[Cache] LocalStorageService.cacheApplication()
    ↓
[Provider] ref.refresh(userApplicationsProvider)
    ↓
[State] FutureProvider rebuilds
    ↓
[UI] Screen rebuilds with new data
```

---

## 🔐 Authentication Flow

### Phone OTP Login:

1. User enters phone number
2. Firebase sends OTP via SMS
3. User enters OTP code
4. Firebase verifies OTP
5. User signed in
6. Navigate to role selection
7. User selects role (seeker or employer)
8. Profile created in Firestore
9. User cached locally
10. Navigate to home screen

```
[PhoneAuthScreen] → [Firebase].verifyPhoneNumber()
                  → [Firebase].verifyOTP()
                  → [RoleSelectionScreen]
                  → [Firebase].saveUser()
                  → [LocalStorage].saveUser()
                  → [HomeScreen]
```

---

## 🔄 Offline Mode

The app supports offline-first approach:

1. **Jobs** cached locally after each fetch
2. **Favorites** stored in Hive
3. **User data** persisted locally
4. **When offline:**
   - Display cached jobs
   - Allow browsing favorites
   - Queue applications for sync
5. **When online:**
   - Sync queued applications
   - Refresh job list
   - Push new favorites

---

## 📊 State Management Patterns

### Pattern 1: Simple State
```dart
final counterProvider = StateProvider<int>((ref) => 0);

// Usage
final count = ref.watch(counterProvider);
ref.read(counterProvider.notifier).state++;
```

### Pattern 2: Async Data (Future)
```dart
final jobsProvider = FutureProvider<List<Job>>((ref) async {
  return await firebaseService.getAllJobs();
});

// Usage
final jobsAsync = ref.watch(jobsProvider);
jobsAsync.when(
  loading: () => CircularProgressIndicator(),
  error: (err, stack) => Text('Error'),
  data: (jobs) => ListView(...)
);
```

### Pattern 3: Computed State
```dart
final selectedJobProvider = StateProvider<Job?>((ref) => null);

final jobDetailsProvider = FutureProvider.family<Job?, String>((ref, jobId) {
  return firebaseService.getJob(jobId);
});

// Always use FutureProvider.family for parameterized async data
```

### Pattern 4: Watch Dependencies
```dart
final myProvider = FutureProvider<List<Job>>((ref) {
  final firebase = ref.watch(firebaseServiceProvider);
  final user = ref.watch(currentUserProvider);
  
  if (user == null) return [];
  return firebase.getEmployerJobs(user.id);
});
```

---

## 🎯 Best Practices Used

1. **Clean Separation of Concerns**
   - UI only talks to providers
   - Providers talk to services
   - Services handle external ops

2. **Immutability**
   - All models are immutable
   - Use `final` keyword
   - No mutable state within widgets

3. **Type Safety**
   - Strong typing throughout
   - Null safety enabled
   - No `dynamic` types

4. **Error Handling**
   - Try-catch in services
   - Error states in async providers
   - User-friendly error messages

5. **Performance**
   - Lazy loading
   - Local caching
   - Pagination (50 jobs limit)
   - Const widgets where possible

6. **Code Organization**
   - Each feature in separate folder
   - Shared code in `services` & `ui`
   - Index files for easy imports
   - Clear naming conventions

---

## 🚀 Extending the App

### Adding a New Feature

1. Create feature folder: `lib/features/my_feature/`
2. Create screens: `my_feature_screen.dart`
3. Create index: `index.dart`
4. Add providers in `lib/core/providers.dart`
5. Add routes in `main.dart`
6. Create service methods in appropriate service file

### Adding a New Model

1. Create `lib/models/my_model.dart`
2. Add `@HiveType` and `@HiveField` if storing locally
3. Implement `toJson()` and `fromJson()`
4. Execute: `flutter pub run build_runner build`
5. Export from `lib/models/index.dart`

### Adding New State

1. Add provider in `lib/core/providers.dart`
2. Use in widgets via `ref.watch()`
3. Update state via `ref.read().notifier.state`

---

## 🧪 Testing Architecture

- **Unit tests** - Test services & models
- **Widget tests** - Test screens & widgets
- **Integration tests** - Test complete flows
- **Manual tests** - Test real Firebase & devices

---

## 📊 Performance Considerations

| Aspect | Optimization |
|--------|--------------|
| Load Time | Lazy loading, local cache |
| Network | Pagination (50 jobs), compression |
| Memory | Dispose providers, limit list items |
| Battery | Background tasks only when needed |
| Storage | Hive with automatic cleanup |

---

## 🔐 Security Architecture

1. **Authentication:** Firebase Phone OTP (no passwords)
2. **Authorization:** Firestore rules enforce access control
3. **Data Validation:** Input validation on all forms
4. **Encryption:** Hive handles local data encryption
5. **API Security:** Only use official Firebase SDK
6. **Rate Limiting:** Firebase Auth handles abuse prevention

---

## 📞 Troubleshooting Architecture Issues

| Issue | Cause | Solution |
|-------|-------|----------|
| Stale data | Provider not refreshing | Use `ref.refresh(provider)` |
| Memory leak | Provider not disposed | Use `select()` to watch specific fields |
| Offline failure | No cache | Ensure `LocalStorageService` is caching |
| Slow loading | Too many rebuilds | Use `select()` or `.family` |

---

## 🎓 Learning Resources

- [Riverpod Docs](https://riverpod.dev)
- [Firebase Flutter Guide](https://firebase.flutter.dev)
- [Clean Architecture in Flutter](https://resocoder.com/flutter-clean-architecture)
- [Hive Storage](https://docs.hivedb.dev)

---

**Version:** 1.0.0  
**Last Updated:** April 2026  
**Maintainer:** Job Finder Team
