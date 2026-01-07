# Firebase Setup Guide for Lost & Found Flutter App

## Prerequisites Completed ✅
- Firebase packages added to pubspec.yaml
- Ready for Firebase integration

## Step-by-Step Instructions

### 1. Install Firebase CLI
```powershell
npm install -g firebase-tools
```
If you don't have npm, install Node.js from: https://nodejs.org/

### 2. Login to Firebase
```powershell
firebase login
```

### 3. Install FlutterFire CLI
```powershell
dart pub global activate flutterfire_cli
```

### 4. Install Dependencies
```powershell
cd "C:\Users\Glen Umadhay\OneDrive\Desktop\LostAndFoundFlutter"
flutter pub get
```

### 5. Configure Firebase
```powershell
flutterfire configure
```
- Select your Firebase project (or create new one)
- Choose platforms: Android, iOS, Web
- This creates `lib/firebase_options.dart` automatically

### 6. Enable Firebase Services in Console

Go to https://console.firebase.google.com/ and enable:

#### A. **Authentication**
1. Click "Authentication" → "Get Started"
2. Enable "Email/Password" sign-in method
3. (Optional) Enable "Google" sign-in

#### B. **Firestore Database**
1. Click "Firestore Database" → "Create database"
2. Start in **Test Mode** (for development)
3. Choose location closest to you

**Collections to create:**
- `users` - Store user profiles
- `items` - Store found items
- `requests` - Store retrieval requests
- `notifications` - Store notifications
- `chatRooms` - Store chat rooms
- `messages` - Store chat messages

**Security Rules (For Testing - Update for Production!):**
```
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /{document=**} {
      allow read, write: if request.auth != null;
    }
  }
}
```

#### C. **Storage** (For item images)
1. Click "Storage" → "Get Started"
2. Start in **Test Mode**

**Storage Rules:**
```
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    match /{allPaths=**} {
      allow read: if true;
      allow write: if request.auth != null;
    }
  }
}
```

### 7. Update main.dart

Replace the current main.dart initialization with:

```dart
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:provider/provider.dart';
// ... other imports

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}
```

### 8. Switch from Demo Mode to Firebase

In `lib/config/demo_config.dart`, change:
```dart
static const bool demoMode = false; // Change to false
```

### 9. Test the App
```powershell
flutter run -d chrome
```

## Firebase Database Structure

### users/
```
{userId}
  - uid: string
  - email: string
  - displayName: string
  - createdAt: timestamp
}
```

### items/
```
{itemId}
  - id: string
  - title: string
  - description: string
  - founderId: string
  - founderName: string
  - founderEmail: string
  - deviceId: string (optional)
  - location: string (optional)
  - status: string (waiting/claimed)
  - imageUrl: string (optional)
  - timestamp: timestamp
  - createdAt: timestamp
}
```

### requests/
```
{requestId}
  - id: string
  - itemId: string
  - finderId: string
  - finderName: string
  - finderEmail: string
  - finderDescription: string
  - status: string (pending/approved/rejected)
  - timestamp: timestamp
  - createdAt: timestamp
  - approvedAt: timestamp (optional)
  - rejectedAt: timestamp (optional)
}
```

### notifications/
```
{notificationId}
  - id: string
  - userId: string
  - title: string
  - message: string
  - type: string
  - relatedId: string (optional)
  - isRead: boolean
  - createdAt: timestamp
}
```

### chatRooms/
```
{chatRoomId}
  - id: string
  - itemId: string
  - founderId: string
  - founderName: string
  - finderId: string
  - finderName: string
  - itemTitle: string
  - createdAt: timestamp
  - lastMessageAt: timestamp
  - lastMessage: string
}
```

### messages/
```
{messageId}
  - id: string
  - chatRoomId: string
  - senderId: string
  - senderName: string
  - message: string
  - timestamp: timestamp
  - isRead: boolean
}
```

## Common Issues & Solutions

### Issue: "Firebase not initialized"
**Solution:** Make sure `Firebase.initializeApp()` is called in `main()` before `runApp()`

### Issue: "Permission denied" in Firestore
**Solution:** Check your Firestore Security Rules allow authenticated users

### Issue: "No Firebase App"
**Solution:** Run `flutterfire configure` again

### Issue: Build errors on Android
**Solution:** Update `android/build.gradle`:
```gradle
buildscript {
    dependencies {
        classpath 'com.google.gms:google-services:4.4.0'
    }
}
```

And in `android/app/build.gradle`, add at the bottom:
```gradle
apply plugin: 'com.google.gms.google-services'
```

## Next Steps After Firebase Setup

1. ✅ Test authentication (sign up/login)
2. ✅ Test creating items
3. ✅ Test search functionality
4. ✅ Test notifications
5. ✅ Test chat messages
6. 📸 Add image upload feature
7. 🔐 Update security rules for production
8. 🚀 Deploy to production

## Need Help?

If you encounter issues:
1. Check Firebase Console for errors
2. Check browser/device console logs
3. Verify all Firebase services are enabled
4. Check internet connection
