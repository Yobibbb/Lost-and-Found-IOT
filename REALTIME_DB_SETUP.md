# Firebase Realtime Database Setup for Arduino

## ✅ What Was Done

Your Flutter app has been updated to automatically sync box lock status from Firestore to Realtime Database, allowing your Arduino/ESP8266 to read the data.

### Updated Files:
- `pubspec.yaml` - Added `firebase_database` dependency
- `lib/services/box_service.dart` - All box operations now sync to Realtime Database

## 🔧 Firebase Console Setup (Required)

### Step 1: Enable Realtime Database

1. Go to [Firebase Console](https://console.firebase.google.com)
2. Select your project: `lostandfound-606de`
3. Click **Realtime Database** in the left menu
4. Click **Create Database**
5. Choose location: **asia-southeast1** (same as your Firestore)
6. Start in **test mode** (we'll add rules later)

### Step 2: Set Database Rules

In the Realtime Database **Rules** tab, use these rules:

```json
{
  "rules": {
    "boxes": {
      "$boxId": {
        ".read": true,
        ".write": "auth != null"
      }
    }
  }
}
```

This allows:
- ✅ Arduino can READ (no auth needed)
- ✅ Only authenticated Flutter app can WRITE

## 📱 Flutter App - Initialize Boxes

Run this once to sync existing boxes to Realtime Database:

```dart
// In your app initialization or settings screen
await BoxService().initializeBoxes();
```

## 🔌 Arduino - No Changes Needed!

Your Arduino code already works! It reads from:
```
/boxes/BOX_A1/isLocked.json
```

This path is now automatically synced from Firestore by your Flutter app.

## 🧪 Testing

1. **In Flutter app**: Change lock status of BOX_A1
2. **In Firebase Console**: Go to Realtime Database → Data
3. **Verify**: You should see `boxes/BOX_A1/isLocked` update
4. **Arduino**: Should read the updated value

## 🔄 How It Works

```
Flutter App (Firestore)
       ↓
   Updates box lock status
       ↓
   Automatically syncs to RTDB
       ↓
Arduino reads from RTDB
       ↓
   Controls servo motor
```

## 📊 Database Structure

```
boxes/
  BOX_A1/
    isLocked: true
    lastUpdated: 1736534400000
  BOX_A2/
    isLocked: false
    lastUpdated: 1736534410000
```

## ⚠️ Important Notes

1. **Firestore is your source of truth** - All writes happen there first
2. **RTDB is for Arduino only** - It's automatically synced from Firestore
3. **Don't write to RTDB manually** - Always use the Flutter app
4. **The sync happens automatically** - No Cloud Functions needed!

## 🚀 Quick Start Commands

```bash
# Install dependencies (already done)
flutter pub get

# Run the app
flutter run

# Initialize boxes (run once)
# Use a button in your app to call BoxService().initializeBoxes()
```

---

**Your Arduino code is ready to use! Just enable Realtime Database in Firebase Console and initialize the boxes from your Flutter app.**
