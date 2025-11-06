# Firebase Setup Instructions

To enable cloud sync across devices, you need to set up Firebase:

## Step 1: Create Firebase Project

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Click "Add project"
3. Enter project name (e.g., "Daily Expenses")
4. Follow the setup wizard

## Step 2: Add Android App

1. In Firebase Console, click "Add app" → Android
2. Register app:
   - Package name: Check `android/app/build.gradle` for `applicationId`
   - App nickname: "Daily Expenses Android"
3. Download `google-services.json`
4. Place it in `android/app/` directory

## Step 3: Add iOS App (if needed)

1. In Firebase Console, click "Add app" → iOS
2. Register app:
   - Bundle ID: Check `ios/Runner.xcodeproj` for bundle identifier
   - App nickname: "Daily Expenses iOS"
3. Download `GoogleService-Info.plist`
4. Place it in `ios/Runner/` directory

## Step 4: Enable Firestore

1. In Firebase Console, go to "Firestore Database"
2. Click "Create database"
3. Start in **test mode** (for development)
4. Choose a location (closest to your users)

## Step 5: Enable Google Sign-In Authentication

1. In Firebase Console, go to "Authentication"
2. Click "Get started"
3. Go to "Sign-in method" tab
4. Click on "Google" provider
5. Enable it and set a support email
6. Click "Save"

**Important for Android:**
- You need to add SHA-1 certificate fingerprint
- Get SHA-1: `cd android && ./gradlew signingReport`
- Copy SHA-1 from output and add it in Firebase Console → Project Settings → Your Android App

**Important for iOS:**
- Add your iOS bundle ID in Firebase Console
- Download updated `GoogleService-Info.plist` if needed

## Step 6: Install FlutterFire CLI

```bash
dart pub global activate flutterfire_cli
```

## Step 7: Configure Flutter App

```bash
flutterfire configure
```

This will automatically configure your Flutter app for Firebase.

## Step 8: Run the App

```bash
flutter pub get
flutter run
```

## Important Notes

- **Test Mode**: Firestore in test mode allows read/write for 30 days. For production, set up proper security rules.
- **Google Sign-In**: Users sign in with their Google account. Same account = same data across devices.
- **Offline Support**: The app works offline and syncs when online.
- **SHA-1 Certificate**: Required for Android Google Sign-In. Make sure to add it in Firebase Console.

## Security Rules (for Production)

Update Firestore security rules:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /users/{userId}/{document=**} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
  }
}
```

## Troubleshooting

- If Firebase initialization fails, the app will work in local-only mode
- Check that `google-services.json` (Android) and `GoogleService-Info.plist` (iOS) are in correct locations
- Ensure internet connection for first-time sync

