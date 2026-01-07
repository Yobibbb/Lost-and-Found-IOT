# 📱 Flutter Lost & Found IoT Application

A complete mobile application built with Flutter for managing lost and found items with IoT device integration.

## 🌟 Features

### Founder Side (Person who found an item)
- ✅ Enter item description and device ID
- ✅ Submit to database with timestamp
- ✅ Review real-time list of requests
- ✅ Approve or reject each request
- ✅ QR code scanning for device unlock
- ✅ Transaction completion

### Finder Side (Person who lost an item)
- ✅ Enter lost item description
- ✅ Search database for matching items
- ✅ View search results
- ✅ Send retrieval request
- ✅ Real-time status updates
- ✅ QR scanning after approval
- ✅ Item retrieval

### Technical Features
- ✅ **Demo Mode**: Run without Firebase for testing
- ✅ **Real-time Updates**: Firestore streams
- ✅ **State Management**: Provider pattern
- ✅ **Mock Data**: Complete demo dataset
- ✅ **Material Design**: Modern UI
- ✅ **Cross-platform**: Android, iOS, Web, Desktop

---

## 🚀 Quick Start (Demo Mode)

### Prerequisites
- Flutter SDK 3.0+
- Dart 3.0+
- Android Studio / VS Code
- (Optional) Android Emulator or iOS Simulator

### Installation

```bash
# Clone or navigate to the project
cd LostAndFoundFlutter

# Install dependencies
flutter pub get

# Run on your device/emulator
flutter run
```

### Demo Mode Login
```
Founder: founder@demo.com (any password)
Finder: finder@demo.com (any password)
```

**See `QUICK_START.md` for detailed instructions**

---

## 📂 Project Structure

```
lib/
├── main.dart                    # App entry point
├── config/
│   ├── demo_config.dart        # Demo mode toggle
│   └── mock_data.dart          # Mock dataset
├── models/
│   ├── user_model.dart         # User data model
│   ├── item_model.dart         # Item data model
│   └── request_model.dart      # Request data model
├── services/
│   ├── auth_service.dart       # Authentication
│   └── database_service.dart   # Firestore operations
├── screens/
│   ├── auth_screen.dart                  # Sign in/up
│   ├── role_selection_screen.dart        # Choose role
│   ├── founder_description_screen.dart   # Enter item
│   ├── founder_requests_screen.dart      # Review requests
│   ├── finder_description_screen.dart    # Search items
│   ├── finder_results_screen.dart        # View results
│   └── finder_status_screen.dart         # Track status
└── widgets/                    # Reusable components
```

---

## 🎯 Demo Mode

**Current Status:** Demo mode is **ENABLED**

Located in: `lib/config/demo_config.dart`
```dart
static const bool demoMode = true;  // Set to false for Firebase
```

### Demo Features:
- ✅ No Firebase configuration needed
- ✅ Mock authentication
- ✅ In-memory database
- ✅ Simulated real-time updates
- ✅ 3 sample items (iPhone, Wallet, Keys)
- ✅ 1 sample request
- ✅ Orange banner indicator

### Switching to Production:
1. Set `demoMode = false` in `demo_config.dart`
2. Configure Firebase (see Firebase Setup below)
3. Run `flutter run`

---

## 🔥 Firebase Setup (Production)

### 1. Create Firebase Project
1. Go to: https://console.firebase.google.com/
2. Click "Add project"
3. Name: `lost-and-found-flutter`
4. Follow setup wizard

### 2. Enable Services
- **Authentication**: Email/Password
- **Cloud Firestore**: Database
- **Cloud Messaging**: Notifications

### 3. Add Firebase to Flutter

**Android:**
1. Download `google-services.json`
2. Place in `android/app/`

**iOS:**
1. Download `GoogleService-Info.plist`
2. Place in `ios/Runner/`

**Install FlutterFire CLI:**
```bash
dart pub global activate flutterfire_cli
flutterfire configure
```

### 4. Update demo_config.dart
```dart
static const bool demoMode = false;
```

---

## 🧪 Testing

### Founder Flow Test:
```
1. Sign in: founder@demo.com
2. Tap: "I Found Something"
3. Enter: "Blue iPhone 13 with black case"
4. Device ID: "DEVICE-001"
5. Submit → See Requests screen
6. Approve pending request
7. Success!
```

### Finder Flow Test:
```
1. Sign in: finder@demo.com
2. Tap: "I Lost Something"
3. Search: "iPhone"
4. Select: Blue iPhone 13
5. Enter details about your item
6. Send Request
7. See status: Pending → Approved
8. Scan QR (simulated)
```

---

## 📦 Dependencies

Main packages in `pubspec.yaml`:

```yaml
dependencies:
  flutter:
    sdk: flutter
  
  # Firebase
  firebase_core: ^2.24.2
  firebase_auth: ^4.15.3
  cloud_firestore: ^4.13.6
  firebase_messaging: ^14.7.9
  
  # State Management
  provider: ^6.1.1
  
  # QR Code
  qr_code_scanner: ^1.0.1
  qr_flutter: ^4.1.0
  
  # Bluetooth
  flutter_blue_plus: ^1.14.0
  
  # Utilities
  shared_preferences: ^2.2.2
  intl: ^0.18.1
  uuid: ^4.2.2
```

---

## 🔧 Development

### Run on different platforms:
```bash
# Android
flutter run

# iOS (Mac only)
flutter run -d ios

# Windows Desktop
flutter run -d windows

# Web
flutter run -d chrome

# List all devices
flutter devices
```

### Build for release:
```bash
# Android APK
flutter build apk

# Android App Bundle
flutter build appbundle

# iOS (Mac only)
flutter build ios

# Windows
flutter build windows
```

---

## 🛠️ Troubleshooting

### Flutter Doctor Issues
```bash
flutter doctor
flutter doctor --android-licenses
```

### Clean Build
```bash
flutter clean
flutter pub get
flutter run
```

### Hot Reload Not Working
- Press `r` in terminal for hot reload
- Press `R` for hot restart

---

## 📱 Platform-Specific Setup

### Android Permissions
Already configured in `android/app/src/main/AndroidManifest.xml`:
- Camera
- Internet
- Bluetooth
- Location

### iOS Permissions
Configure in `ios/Runner/Info.plist`:
- Camera usage description
- Bluetooth usage description
- Location usage description

---

## 🎨 UI/UX Features

- Material Design 3
- Responsive layouts
- Loading states
- Error handling
- Form validation
- Real-time updates
- Status indicators
- Demo mode banner

---

## 🔐 Security Features

- Firebase Authentication
- Firestore Security Rules
- User-specific data access
- Request validation
- Timeout mechanisms

---

## 📊 Database Schema

### Items Collection
```dart
{
  id: String,
  description: String,
  founderId: String,
  founderName: String,
  founderEmail: String,
  deviceId: String?,
  location: String?,
  status: 'waiting' | 'matched' | 'retrieved',
  timestamp: DateTime,
  createdAt: DateTime
}
```

### Requests Collection
```dart
{
  id: String,
  itemId: String,
  finderId: String,
  finderName: String,
  finderEmail: String,
  finderDescription: String,
  status: 'pending' | 'approved' | 'rejected',
  timestamp: DateTime,
  createdAt: DateTime,
  approvedAt: DateTime?,
  rejectedAt: DateTime?
}
```

---

## 🚀 Next Steps

1. **Test Demo Mode**
   - Run `flutter run`
   - Test both flows
   - Explore the UI

2. **Set Up Firebase** (Optional)
   - Create Firebase project
   - Configure authentication
   - Enable Firestore
   - Switch `demoMode = false`

3. **Customize**
   - Add your branding
   - Modify colors/theme
   - Add new features

4. **Deploy**
   - Build release APK
   - Publish to Play Store
   - Deploy to App Store

---

## 📞 Support

- Flutter Docs: https://docs.flutter.dev/
- Firebase Docs: https://firebase.google.com/docs
- Flutter Community: https://flutter.dev/community

---

## 📄 License

MIT License - Feel free to use for your projects

---

**Built with Flutter ❤️**

Happy coding! 🎉
