# Watch Connectivity Setup Guide

Quick guide to enable phone↔smartwatch synchronization in your WorkoutBuddy app.

---

## Prerequisites

- ✅ `watch_connectivity: ^0.2.3` added to `pubspec.yaml`
- ✅ Phone and watch apps installed
- ✅ Watch paired with phone

---

## Platform Setup

### Android (Wear OS)

#### 1. Create Wear OS App

Follow: [Android Wear App Tutorial](https://developer.android.com/training/wearables/apps/creating)

#### 2. Match Package Names

**CRITICAL:** Both apps must have the **same package name**

**Phone app** (`android/app/build.gradle`):
```gradle
android {
    defaultConfig {
        applicationId "com.example.workoutbuddy"  // Your package name
    }
}
```

**Wear OS app** (`wear/build.gradle`):
```gradle
android {
    defaultConfig {
        applicationId "com.example.workoutbuddy"  // MUST MATCH phone app
    }
}
```

#### 3. Sign with Same Key

Both apps must be signed with the same keystore:

```gradle
android {
    signingConfigs {
        release {
            keyAlias keystoreProperties['keyAlias']
            keyPassword keystoreProperties['keyPassword']
            storeFile keystoreProperties['storeFile'] ? file(keystoreProperties['storeFile']) : null
            storePassword keystoreProperties['storePassword']
        }
    }
}
```

#### 4. Permissions

**Phone app** (`AndroidManifest.xml`):
```xml
<uses-permission android:name="android.permission.BLUETOOTH" />
<uses-permission android:name="android.permission.BLUETOOTH_ADMIN" />
```

**Wear OS app** (`AndroidManifest.xml`):
```xml
<uses-permission android:name="android.permission.BLUETOOTH" />
<uses-permission android:name="android.permission.WAKE_LOCK" />
```

---

### iOS (watchOS)

#### 1. Create watchOS App

Follow: [Apple Watch App Tutorial](https://developer.apple.com/documentation/watchos-apps/creating-a-watchos-app)

#### 2. Configure Bundle IDs

**iPhone app**: `com.example.workoutbuddy`

**Watch app**: `com.example.workoutbuddy.watchkitapp` (must add `.watchkitapp`)

#### 3. Add WatchConnectivity Capability

In Xcode, for both iPhone and Watch apps:
1. Select target
2. Go to "Signing & Capabilities"
3. Add "Background Modes"
4. Enable "Remote notifications"

#### 4. Info.plist Configuration

**iPhone app** (`Info.plist`):
```xml
<key>UIBackgroundModes</key>
<array>
    <string>remote-notification</string>
</array>
```

**Watch app** (`Info.plist`):
```xml
<key>WKBackgroundModes</key>
<array>
    <string>remote-notification</string>
</array>
```

---

## Testing the Connection

### 1. Check Watch Status

```dart
import 'package:workoutbuddy/services/watch_sync_service.dart';

final watchService = WatchSyncService.instance;
await watchService.initialize();

print('Supported: ${watchService.status.isSupported}');
print('Paired: ${watchService.status.isPaired}');
print('Reachable: ${watchService.status.isReachable}');
print('Can Sync: ${watchService.canSync}');
```

### 2. Test Sync

```dart
if (watchService.canSync) {
  final success = await watchService.syncToWatch();
  print('Sync successful: $success');
} else {
  print('Cannot sync: ${watchService.status.statusMessage}');
}
```

### 3. UI Testing

1. Open Food Diary screen
2. Look for watch icon in AppBar
3. Icon color indicates status:
   - 🟢 **Green**: Connected and ready
   - 🟠 **Orange**: Paired but not reachable
   - ⚪ **Grey**: Not paired or not supported

---

## Troubleshooting

### "Watch not supported on this device"

**Cause:** Running on platform without watch support (e.g., desktop)

**Solution:** Test on physical Android/iOS device

---

### "No watch paired"

**Android:**
- Install Wear OS app on phone
- Pair watch in Wear OS app
- Wait for apps to sync

**iOS:**
- Open Watch app on iPhone
- Pair Apple Watch
- Wait for sync to complete

---

### "Watch not connected"

**Cause:** Watch out of Bluetooth range or powered off

**Solution:**
- Bring watch closer to phone
- Ensure watch is powered on
- Check Bluetooth is enabled on both devices
- Restart both devices if needed

---

### Apps Not Communicating

**Android:**
1. Verify package names match exactly
2. Check both apps signed with same key
3. Reinstall both apps
4. Check logcat for errors:
   ```bash
   adb logcat | grep WatchConnectivity
   ```

**iOS:**
1. Verify bundle IDs (`app.id` and `app.id.watchkitapp`)
2. Check WatchConnectivity capability enabled
3. Rebuild both apps
4. Check Xcode console for errors

---

### Sync Seems Slow

**Expected:** 50-200ms  
**If > 1 second:**

1. Check Bluetooth interference
2. Reduce data size (limit meals to 5)
3. Check watch battery level
4. Restart Bluetooth on both devices

---

## Debugging

### Enable Debug Logging

Add to `main.dart`:

```dart
import 'package:flutter/foundation.dart';

void main() {
  if (kDebugMode) {
    // Watch connectivity logging
    debugPrint('🔍 Debug mode: Watch logging enabled');
  }
  
  runApp(const WorkoutBuddyApp());
}
```

### Check Sync Status

```dart
// Add listener for status changes
WatchSyncService.instance.addListener(() {
  final status = WatchSyncService.instance.status;
  debugPrint('Watch Status: $status');
  debugPrint('Can Sync: ${WatchSyncService.instance.canSync}');
  debugPrint('Last Sync: ${status.lastSync}');
});
```

### Monitor Sync Activity

```dart
// Before sync
debugPrint('📤 Starting sync to watch...');
final startTime = DateTime.now();

final success = await watchService.syncToWatch();

final duration = DateTime.now().difference(startTime);
debugPrint('✅ Sync completed in ${duration.inMilliseconds}ms');
```

---

## Production Checklist

Before releasing to production:

### Android
- [ ] Package names match
- [ ] Apps signed with release key
- [ ] Tested on physical Wear OS device
- [ ] Permissions declared in manifest
- [ ] Google Play Console configured for wearable

### iOS
- [ ] Bundle IDs correctly configured
- [ ] Watch app included in iPhone app
- [ ] Tested on physical Apple Watch
- [ ] WatchConnectivity capability enabled
- [ ] App Store Connect configured for watchOS

### Both Platforms
- [ ] Sync works reliably
- [ ] Status indicator shows correctly
- [ ] Error messages are user-friendly
- [ ] Battery impact is minimal
- [ ] Data size is < 5KB
- [ ] Sync latency is < 200ms

---

## Quick Reference

### Key Files

```
lib/
├── models/watch_data.dart           # Data models
├── services/watch_sync_service.dart # Sync logic
├── widgets/watch_status_indicator.dart # UI components
└── screens/
    ├── food_diary_screen.dart       # Shows status
    └── food_entry_screen.dart       # Syncs on add

test/
└── watch_sync_test.dart             # Unit tests (27)

docs/
├── WATCH_SYNC.md                    # Technical docs
└── WATCH_SETUP.md                   # This file
```

### Common Commands

```bash
# Run watch sync tests
flutter test test/watch_sync_test.dart

# Run all tests
flutter test

# Check dependencies
flutter pub get

# Build Android
flutter build apk

# Build iOS
flutter build ios
```

### Important Constants

```dart
// lib/services/watch_sync_service.dart
static const Duration _autoSyncInterval = Duration(minutes: 15);

// lib/models/watch_data.dart
const int maxMealNameLength = 20;
const int maxRecentMeals = 5;
```

---

## Support

### Documentation
- **Technical Details**: [WATCH_SYNC.md](./WATCH_SYNC.md)
- **Google Drive Sync**: [GOOGLE_DRIVE_SETUP.md](./GOOGLE_DRIVE_SETUP.md)
- **Testing Guide**: [TESTING.md](./TESTING.md)

### Resources
- [watch_connectivity Package](https://pub.dev/packages/watch_connectivity)
- [Android Wear Documentation](https://developer.android.com/training/wearables)
- [watchOS Development](https://developer.apple.com/watchos/)

### Common Issues
- **Package name mismatch** (Android): Most common issue
- **Bundle ID format** (iOS): Must end with `.watchkitapp`
- **Signing mismatch** (Android): Apps won't communicate
- **Bluetooth disabled**: Check settings on both devices

---

## Next Steps

After setup is complete:

1. **Test basic sync**: Add food on phone → check watch
2. **Test bidirectional**: Log meal on watch → check phone
3. **Test offline**: Disable WiFi → sync should still work
4. **Monitor battery**: Check battery drain over 24 hours
5. **Gather feedback**: Test with real users

---

**Setup Time**: ~30 minutes (first time)  
**Complexity**: Moderate (platform-specific configs)  
**Maintenance**: Low (stable APIs)

---

**Need help?** Check [WATCH_SYNC.md](./WATCH_SYNC.md) for detailed troubleshooting.
