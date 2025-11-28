# 🔥 Firebase Configuration Setup

## ⚠️ IMPORTANT: Security Notice

Your Firebase API keys were previously committed to git history. While Firebase client API keys are designed for client-side use and are protected by Firebase Security Rules, it's good practice to rotate them.

## 🔄 Recommended Actions

### 1. Rotate Your API Keys (Optional but Recommended)

Since the old keys are in git history, consider rotating them:

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select your project: `calorie-counter-app-bf67e`
3. Project Settings → General
4. Under "Your apps", delete and re-create the app registrations
5. Or restrict the old API keys in [Google Cloud Console](https://console.cloud.google.com/apis/credentials)

### 2. Generate New Firebase Configuration

Run the FlutterFire CLI to generate a fresh `firebase_options.dart`:

```bash
# Install FlutterFire CLI if not already installed
dart pub global activate flutterfire_cli

# Configure Firebase for your Flutter project
flutterfire configure
```

This will:
- Create a new `lib/firebase_options.dart` file
- Configure all platforms (Web, Android, iOS, macOS, Windows)
- Use your Firebase project credentials

### 3. Alternative: Manual Setup

If you prefer manual setup:

1. Copy the example file:
   ```bash
   cp lib/firebase_options.dart.example lib/firebase_options.dart
   ```

2. Get your Firebase config from [Firebase Console](https://console.firebase.google.com/):
   - Project Settings → General → Your apps
   - Copy the configuration for each platform

3. Replace the placeholder values in `lib/firebase_options.dart`

## 🛡️ Security Best Practices

✅ **DO:**
- Keep `firebase_options.dart` in `.gitignore` (already configured)
- Use Firebase Security Rules to protect your data
- Enable Firebase App Check for additional security
- Restrict API keys in Google Cloud Console

❌ **DON'T:**
- Commit `firebase_options.dart` to version control
- Share your project's service account keys (different from client API keys)
- Use Firebase Admin SDK credentials in client code

## 📝 Note

Firebase **client API keys** (like the ones in `firebase_options.dart`) are meant to be public and included in your mobile/web apps. They are NOT secret keys. Security is enforced through:

- **Firebase Security Rules** - Control who can read/write data
- **Firebase App Check** - Verify requests come from your app
- **API Restrictions** - Limit which APIs the key can access

However, it's still best practice to keep them out of version control to prevent unnecessary exposure.
