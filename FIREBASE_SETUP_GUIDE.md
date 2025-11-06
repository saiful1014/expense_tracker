# Firebase Setup Guide - Step by Step

Follow these steps to configure Firebase for your Daily Expenses app.

## Prerequisites
- Google account
- Firebase project (or create a new one)
- Your app package name: `com.dailyexpenses.app`

---

## Step 1: Create/Access Firebase Project

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. If you don't have a project:
   - Click **"Add project"** or **"Create a project"**
   - Enter project name: **"Daily Expenses"** (or any name you prefer)
   - Click **Continue**
   - Disable Google Analytics (optional) or enable it if you want
   - Click **Create project**
   - Wait for project creation (30-60 seconds)
   - Click **Continue**

3. If you already have a project:
   - Select your project from the list

---

## Step 2: Add Android App to Firebase

1. In Firebase Console, click the **Android icon** (or click **"Add app"** → **Android**)

2. **Register your app:**
   - **Android package name**: `com.dailyexpenses.app`
   - **App nickname** (optional): `Daily Expenses Android`
   - **Debug signing certificate SHA-1** (optional for now, we'll add it later)
   - Click **Register app**

3. **Download `google-services.json`:**
   - Click **Download google-services.json**
   - **IMPORTANT**: Save this file to: `android/app/google-services.json`
   - Replace the existing file if prompted
   - Click **Next**

4. **Skip the next steps** (SDK setup) - Flutter handles this automatically
   - Click **Next** through the remaining steps
   - Click **Continue to console**

---

## Step 3: Enable Firestore Database

1. In Firebase Console, click **Firestore Database** in the left menu
2. Click **Create database**
3. **Choose mode:**
   - Select **Start in test mode** (for development)
   - Click **Next**
4. **Choose location:**
   - Select a location closest to your users (e.g., `us-central`, `asia-south1`)
   - Click **Enable**
   - Wait for database creation (30-60 seconds)

---

## Step 4: Enable Google Sign-In Authentication

1. In Firebase Console, click **Authentication** in the left menu
2. Click **Get started** (if first time)
3. Go to **Sign-in method** tab
4. Click on **Google** provider
5. **Enable Google:**
   - Toggle **Enable** to ON
   - **Project support email**: Select your email or enter one
   - Click **Save**

---

## Step 5: Get SHA-1 Certificate Fingerprint (Required for Google Sign-In on Android)

1. **Open terminal/command prompt** in your project directory

2. **For macOS/Linux:**
   ```bash
   cd android
   ./gradlew signingReport
   ```

3. **For Windows:**
   ```bash
   cd android
   gradlew signingReport
   ```

4. **Find SHA-1 in output:**
   - Look for a line like: `SHA1: XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX`
   - Copy the SHA-1 value (the part after `SHA1:`)

5. **Add SHA-1 to Firebase:**
   - Go back to Firebase Console
   - Click **Project Settings** (gear icon) → **Your apps**
   - Find your Android app (`com.dailyexpenses.app`)
   - Click **Add fingerprint**
   - Paste the SHA-1 value
   - Click **Save**

---

## Step 6: Update Firestore Security Rules (Important!)

1. In Firebase Console, go to **Firestore Database** → **Rules** tab

2. **For Development (Test Mode):**
   - Rules should already allow read/write (expires in 30 days)
   - This is fine for testing

3. **For Production (Recommended):**
   - Replace the rules with:
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
   - Click **Publish**

---

## Step 7: Verify Configuration

1. **Check `google-services.json`:**
   - File location: `android/app/google-services.json`
   - Open the file and verify it contains:
     - `"package_name": "com.dailyexpenses.app"`
     - Your project information

2. **Verify build.gradle files:**
   - `android/settings.gradle.kts` should have Google services plugin
   - `android/app/build.gradle.kts` should have Google services plugin applied
   - ✅ Already configured!

---

## Step 8: Test the Setup

1. **Clean and rebuild:**
   ```bash
   flutter clean
   flutter pub get
   flutter run
   ```

2. **Test Google Sign-In:**
   - Open the app
   - Tap the cloud icon in the AppBar
   - Tap "Sign in with Google"
   - You should see Google Sign-In screen
   - After signing in, you should see your profile info

---

## Troubleshooting

### Issue: "Google Sign-In failed"
- **Solution**: Make sure SHA-1 is added in Firebase Console
- **Solution**: Verify package name matches in Firebase and `build.gradle.kts`

### Issue: "Firebase not initialized"
- **Solution**: Check that `google-services.json` is in `android/app/` directory
- **Solution**: Verify Google services plugin is applied in `build.gradle.kts`

### Issue: "Permission denied" in Firestore
- **Solution**: Check Firestore security rules
- **Solution**: Make sure you're signed in with Google

### Issue: "Package name mismatch"
- **Solution**: Verify package name in Firebase Console matches `com.dailyexpenses.app`
- **Solution**: Download new `google-services.json` if package name was changed

---

## Summary Checklist

- [ ] Firebase project created
- [ ] Android app added with package name `com.dailyexpenses.app`
- [ ] `google-services.json` downloaded and placed in `android/app/`
- [ ] Firestore Database enabled
- [ ] Google Sign-In authentication enabled
- [ ] SHA-1 certificate added to Firebase
- [ ] Firestore security rules configured
- [ ] App tested and working

---

## Next Steps After Setup

1. **Test on device:** Run the app and test Google Sign-In
2. **Add data:** Create some expenses and verify they sync
3. **Test on another device:** Sign in with same Google account to see synced data
4. **Production:** Update Firestore security rules before releasing

---

## Important Notes

- **Package Name**: Always use `com.dailyexpenses.app` (don't change it after setup)
- **SHA-1**: You need to add SHA-1 for both debug and release builds if you plan to release
- **Security Rules**: Test mode expires in 30 days - update rules for production
- **Offline Support**: Firestore works offline and syncs when online automatically

---

**Need Help?** Check Firebase documentation: https://firebase.google.com/docs

