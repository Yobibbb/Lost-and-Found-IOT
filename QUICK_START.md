# 🚀 Flutter Lost & Found IoT App - QUICK START

## ⚡ Run in Demo Mode (No Firebase Needed!)

### Step 1: Install Flutter
If you don't have Flutter installed:

**Windows:**
1. Download Flutter SDK: https://docs.flutter.dev/get-started/install/windows
2. Extract to `C:\src\flutter`
3. Add to PATH: `C:\src\flutter\bin`
4. Run: `flutter doctor`

### Step 2: Install Dependencies
```powershell
cd "c:\Users\Glen Umadhay\OneDrive\Desktop\LostAndFoundFlutter"
flutter pub get
```

### Step 3: Run the App
```powershell
# For Android (with emulator or device connected)
flutter run

# For Windows desktop (if enabled)
flutter run -d windows

# For Chrome (web)
flutter run -d chrome
```

### Step 4: Sign In (Demo Mode)
```
Founder: founder@demo.com (any password)
Finder: finder@demo.com (any password)
```

---

## ✅ Demo Mode Features

**Current Status:** `DEMO_MODE = true` in `lib/config/demo_config.dart`

**What Works:**
- ✅ Full UI with Material Design
- ✅ Founder Flow: Create items, approve/reject requests
- ✅ Finder Flow: Search items, send requests, see status
- ✅ Real-time updates (simulated)
- ✅ Orange demo banner at top
- ✅ Mock data with 3 items and 1 request

**What's Simulated:**
- Authentication (no real accounts)
- Database (in-memory, resets on restart)
- Real-time streams (setTimeout)
- Push notifications (console logs)

---

## 🧪 Test Flows

### Founder Flow:
1. Sign in with `founder@demo.com`
2. Tap "I Found Something"
3. Enter: "Blue iPhone 13 with case"
4. Device ID: "DEVICE-001"
5. Tap "Submit Item"
6. See requests screen (1 pending request)
7. Tap "Approve"

### Finder Flow:
1. Sign in with `finder@demo.com`
2. Tap "I Lost Something"
3. Search: "iPhone"
4. Tap on iPhone 13 item
5. Enter details
6. Tap "Send Request"
7. See status: "Pending"

---

## 🔄 Switch to Real Firebase

When ready for production:

1. Edit `lib/config/demo_config.dart`:
   ```dart
   static const bool demoMode = false;
   ```

2. Set up Firebase (see `FIREBASE_SETUP.md`)

3. Restart: `flutter run`

---

## 📱 Supported Platforms

- ✅ Android
- ✅ iOS
- ✅ Windows (desktop)
- ✅ Web (Chrome)
- ✅ macOS
- ✅ Linux

---

## 🐛 Troubleshooting

**Issue: Flutter not found**
```powershell
# Add to PATH
$env:Path += ";C:\src\flutter\bin"
flutter doctor
```

**Issue: Dependencies fail**
```powershell
flutter clean
flutter pub get
```

**Issue: No devices**
```powershell
flutter emulators --launch <emulator_id>
# Or connect Android/iOS device via USB
```

---

## 📚 Documentation

- `QUICK_START.md` - This file
- `README.md` - Full documentation
- `FIREBASE_SETUP.md` - Production setup

---

**Made with Flutter ❤️**

Run `flutter run` and start testing! 🎉
