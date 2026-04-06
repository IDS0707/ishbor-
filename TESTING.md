# Testing Guide for Job Finder App

## Unit Tests

```bash
flutter test
```

## Widget Tests

### Test Phone Auth Screen

`test/features/auth/phone_auth_screen_test.dart`

```dart
testWidgets('Phone auth screen renders', (WidgetTester tester) async {
  await tester.pumpWidget(const ProviderScope(child: JobFinderApp()));
  expect(find.text('🚀 Job Finder'), findsOneWidget);
  expect(find.byType(TextField), findsOneWidget);
});
```

## Integration Tests

```bash
flutter test integration_test/
```

## Manual Testing Checklist

### Authentication Flow:
- [ ] Enter phone number
- [ ] Receive OTP (mock or real)
- [ ] Enter OTP code
- [ ] Verify user logged in
- [ ] Select role (job seeker/employer)
- [ ] Fill profile (name, skills)
- [ ] Navigate to home

### Job Seeker Features:
- [ ] Browse jobs by category
- [ ] View job details
- [ ] Click "Call" button
- [ ] Save job to favorites
- [ ] Apply for job
- [ ] Check application status
- [ ] View saved jobs

### Employer Features:
- [ ] Post job (3 fields only)
- [ ] View posted jobs
- [ ] See job statistics (views, contacts)
- [ ] Navigate to post job screen

### Offline Features:
- [ ] Disconnect internet
- [ ] Browse cached jobs
- [ ] View saved favorites
- [ ] Reconnect and sync

## Test Devices

### Recommended:
- **Android:** Pixel 5 (Android 13)
- **Android:** Pixel 3a (Android 11)
- **Web:** Chrome (desktop)
- **Web:** Firefox (mobile)

## Performance Testing

```bash
# Profile mode
flutter run --profile

# Memory leaks
dart devtools
```

## Beta Testing

1. Build debug APK:
   ```bash
   flutter build apk --debug
   ```

2. Distribute via Firebase App Distribution

3. Collect feedback from 10-20 testers

## Test Accounts

Test accounts are configured in Firebase Console:
- Any phone number works in test mode
- Use real Firebase project for production testing

---

**See also:** [SETUP_AND_BUILD_GUIDE.md](SETUP_AND_BUILD_GUIDE.md)
