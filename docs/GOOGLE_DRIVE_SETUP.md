# Google Drive Sync Setup Guide

This guide will help you set up Google Drive synchronization for your WorkoutBuddy app.

## Prerequisites

- Google Account
- Google Cloud Console access
- Flutter development environment

## Step 1: Google Cloud Console Setup

### 1.1 Create a Google Cloud Project

1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Click "Select a project" → "New Project"
3. Enter project name: `WorkoutBuddy` (or your preferred name)
4. Click "Create"

### 1.2 Enable Google Drive API

1. In your project, go to "APIs & Services" → "Library"
2. Search for "Google Drive API"
3. Click "Enable"

### 1.3 Create OAuth 2.0 Credentials

1. Go to "APIs & Services" → "Credentials"
2. Click "Create Credentials" → "OAuth client ID"
3. If prompted, configure OAuth consent screen first:
   - User Type: External (for testing) or Internal (for organization only)
   - Fill in App name, User support email, Developer contact
   - Add scopes: `https://www.googleapis.com/auth/drive.file`
   - Add test users (if External)

## Step 2: Platform-Specific Setup

### Android Setup

#### 2.1 Create Android OAuth Client

1. In "Create OAuth client ID":
   - Application type: **Android**
   - Package name: `com.example.workoutbuddy` (or your package name)
   - SHA-1 certificate fingerprint: Get from your keystore

To get SHA-1 fingerprint:
```bash
# Debug keystore (for development)
keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android

# Release keystore (for production)
keytool -list -v -keystore /path/to/your/release.keystore -alias your-key-alias
```

2. Copy the SHA-1 and paste into Google Cloud Console
3. Click "Create"
4. Download the configuration file (not needed for this package)

#### 2.2 Update Android Manifest

No additional manifest changes required for `multi_cloud_storage` package.

### iOS Setup

#### 2.1 Create iOS OAuth Client

1. In "Create OAuth client ID":
   - Application type: **iOS**
   - Bundle ID: `com.example.workoutbuddy` (or your bundle ID from Xcode)

2. Download the `GoogleService-Info.plist` file

#### 2.2 Configure iOS Project

1. Open your iOS project in Xcode: `ios/Runner.xcworkspace`
2. Drag and drop `GoogleService-Info.plist` into `Runner/Runner/` folder
3. Open `Info.plist` and add:

```xml
<key>GIDClientID</key>
<string>YOUR_CLIENT_ID.apps.googleusercontent.com</string>

<key>CFBundleURLTypes</key>
<array>
  <dict>
    <key>CFBundleTypeRole</key>
    <string>Editor</string>
    <key>CFBundleURLSchemes</key>
    <array>
      <string>com.googleusercontent.apps.YOUR_REVERSED_CLIENT_ID</string>
    </array>
  </dict>
</array>
```

**Note:** Get `CLIENT_ID` and `REVERSED_CLIENT_ID` from the `GoogleService-Info.plist` file.

### Web Setup (Optional)

#### 2.1 Create Web OAuth Client

1. In "Create OAuth client ID":
   - Application type: **Web application**
   - Name: `WorkoutBuddy Web`
   - Authorized JavaScript origins: `http://localhost:8080` (for local testing)
   - Authorized redirect URIs: `http://localhost:8080` (for local testing)

2. Note down the Client ID

#### 2.2 Update Web Configuration

Add to your `web/index.html`:

```html
<meta name="google-signin-client_id" content="YOUR_WEB_CLIENT_ID.apps.googleusercontent.com">
```

## Step 3: Verify Installation

### 3.1 Check Dependencies

Ensure `pubspec.yaml` has:

```yaml
dependencies:
  multi_cloud_storage: ^0.5.1
  path_provider: ^2.0.0
```

Run:
```bash
flutter pub get
```

### 3.2 Test Connection

```dart
import 'package:workoutbuddy/services/google_drive_sync_service.dart';

// In your app
final syncService = GoogleDriveSyncService.instance;
final success = await syncService.connect();

if (success) {
  print('✅ Connected to Google Drive');
} else {
  print('❌ Connection failed: ${syncService.status.lastSyncError}');
}
```

## Step 4: Usage

### Connect to Google Drive

```dart
final syncService = GoogleDriveSyncService.instance;
await syncService.connect();
```

### Backup Data

```dart
final success = await syncService.backup();
if (success) {
  print('Backup completed!');
}
```

### Restore Data

```dart
final success = await syncService.restore(
  resolution: SyncConflictResolution.merge, // or .useRemote, .useLocal
);
```

### Sync (Smart Merge)

```dart
final success = await syncService.sync();
```

### Enable Auto-Sync

```dart
await syncService.setAutoSync(true);
```

## Troubleshooting

### Common Issues

#### 1. "Sign in failed" or "Sign in cancelled"

**Solution:**
- Verify SHA-1 fingerprint matches your keystore
- Check package name matches in Google Cloud Console
- Ensure Google Drive API is enabled
- Add test users if using External consent screen

#### 2. "Access not configured"

**Solution:**
- Enable Google Drive API in Google Cloud Console
- Wait a few minutes for changes to propagate

#### 3. "Invalid client" error

**Solution:**
- Verify Client ID in `Info.plist` (iOS)
- Ensure Bundle ID/Package name matches OAuth client configuration

#### 4. iOS: "No application found to open URL"

**Solution:**
- Check URL schemes in `Info.plist`
- Verify `REVERSED_CLIENT_ID` is correct

### Debug Mode

Enable debug logging in your app:

```dart
import 'package:flutter/foundation.dart';

// Check sync status
print('Connected: ${syncService.isConnected}');
print('Last sync: ${syncService.status.lastSyncTime}');
print('Error: ${syncService.status.lastSyncError}');
```

### Testing Checklist

- [ ] Google Drive API enabled in Cloud Console
- [ ] OAuth credentials created for your platform
- [ ] SHA-1 fingerprint correct (Android)
- [ ] `GoogleService-Info.plist` added (iOS)
- [ ] `Info.plist` updated with URL schemes (iOS)
- [ ] Test users added (if External consent screen)
- [ ] Package name/Bundle ID matches OAuth configuration
- [ ] App can connect to Google Drive
- [ ] Backup creates file in Google Drive
- [ ] Restore downloads and applies data

## Security Best Practices

1. **Never commit credentials:**
   - Add `GoogleService-Info.plist` to `.gitignore`
   - Keep OAuth secrets secure

2. **Use appropriate scopes:**
   - Current scope: `drive.file` (app-created files only)
   - This limits access to only files created by your app

3. **Production checklist:**
   - Use release keystore SHA-1 (Android)
   - Verify OAuth consent screen for production
   - Test with real users before public release
   - Monitor quota usage in Google Cloud Console

## Data Privacy

- All data is stored in the user's Google Drive
- Only the user has access to their data
- App uses `drive.file` scope (limited to app-created files)
- No data is sent to third-party servers
- Users can delete their backup anytime from Google Drive or the app

## Support

For issues related to:
- **WorkoutBuddy app**: Check GitHub issues
- **multi_cloud_storage package**: Visit [pub.dev/packages/multi_cloud_storage](https://pub.dev/packages/multi_cloud_storage)
- **Google Drive API**: Check [Google Drive API documentation](https://developers.google.com/drive)

## Resources

- [Google Cloud Console](https://console.cloud.google.com/)
- [Google Drive API Docs](https://developers.google.com/drive)
- [multi_cloud_storage Package](https://pub.dev/packages/multi_cloud_storage)
- [OAuth 2.0 Guide](https://developers.google.com/identity/protocols/oauth2)
