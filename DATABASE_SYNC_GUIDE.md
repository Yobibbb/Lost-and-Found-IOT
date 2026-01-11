# 🔄 Database Synchronization Guide

## Overview

This app uses **two databases** that stay synchronized:

### 1. **Firebase (Primary - Mobile App)**
- **Firestore**: Main database for items, requests, messages, users, boxes
- **Realtime Database**: Syncs box lock status for Arduino/ESP8266
- **Location**: Cloud (Google Firebase)
- **Used by**: Flutter mobile app

### 2. **MySQL (Secondary - Arduino Backend)**
- **Location**: Local XAMPP (`C:\xampp\mysql\data\lostandfound_db`)
- **Used by**: Arduino/IoT hardware via PHP API
- **Tables**: boxes, users, items, retrieval_requests, messages

---

## 📦 Current Box Configuration

Both databases contain **exactly 2 boxes**:

| Box ID  | Name   | Location                                |
|---------|--------|-----------------------------------------|
| BOX_A1  | Box A1 | Building A, Floor 1, Near Main Entrance|
| BOX_A2  | Box A2 | Building A, Floor 2, Near Cafeteria    |

---

## 🔄 How Synchronization Works

### Automatic Sync (Firebase → MySQL)

The app automatically syncs changes from Firebase to MySQL:

```dart
// In lib/services/box_service.dart
// Every time a box is updated in Firebase:
1. Update Firestore (primary database)
2. Sync to Realtime Database (for Arduino)
3. Sync to MySQL (via DatabaseSyncService)
```

### Data Flow

```
Flutter App
    ↓
Firebase Firestore (Primary)
    ↓
├─→ Firebase Realtime DB (Arduino reads this)
└─→ MySQL Database (Arduino writes commands here)
```

### When Sync Happens

Automatic sync triggers on:
- ✅ Box lock/unlock
- ✅ Item storage in box
- ✅ Item retrieval from box
- ✅ Box status changes
- ✅ App initialization

---

## 🚀 Setup Instructions

### 1. Verify Firebase Configuration

Check that Firebase has the correct boxes:

```bash
# Run the Flutter app
flutter run

# Check console output for:
# ✅ Boxes initialization complete (Firestore + RTDB)
```

### 2. Verify MySQL Configuration

```bash
# Check MySQL boxes
C:\xampp\mysql\bin\mysql.exe -u root lostandfound_db -e "SELECT * FROM boxes;"

# Should show exactly 2 boxes matching Firebase
```

### 3. Import Clean Database

If you need to reset MySQL:

```bash
# Drop and recreate
C:\xampp\mysql\bin\mysql.exe -u root -e "DROP DATABASE IF EXISTS lostandfound_db; CREATE DATABASE lostandfound_db;"

# Import clean schema
C:\xampp\mysql\bin\mysql.exe -u root lostandfound_db < "C:\xampp\htdocs\Lost-and-Found-IOT\lostandfound_db_clean.sql"
```

Or use phpMyAdmin:
1. Open http://localhost/phpmyadmin
2. Drop `lostandfound_db` database
3. Create new database `lostandfound_db`
4. Import `lostandfound_db_clean.sql`

---

## 🔧 Adding New Boxes

To add a new box to **both databases**:

### Step 1: Update Flutter Code

Edit `lib/services/box_service.dart`:

```dart
Future<void> initializeBoxes() async {
  // ...
  final boxes = [
    {
      'id': 'BOX_A1',
      'name': 'Box A1',
      'location': 'Building A, Floor 1, Near Main Entrance'
    },
    {
      'id': 'BOX_A2',
      'name': 'Box A2',
      'location': 'Building A, Floor 2, Near Cafeteria'
    },
    // Add new box here:
    {
      'id': 'BOX_B1',
      'name': 'Box B1',
      'location': 'Building B, Floor 1, Near Library'
    },
  ];
  // ...
}
```

### Step 2: Run Initialization

```dart
// In your app, call:
await BoxService().initializeBoxes();

// This will:
// 1. Create box in Firebase
// 2. Sync to Realtime Database
// 3. Sync to MySQL automatically
```

### Step 3: Verify Both Databases

```bash
# Check Firebase via Flutter app logs

# Check MySQL
C:\xampp\mysql\bin\mysql.exe -u root lostandfound_db -e "SELECT * FROM boxes;"
```

---

## 🧪 Testing Synchronization

### Test 1: Lock/Unlock Box

```dart
// In Flutter app
await BoxService().updateBoxLockStatus('BOX_A1', false); // Unlock

// Check sync happened:
// ✅ Firebase Firestore updated
// ✅ Firebase RTDB updated  
// ✅ MySQL updated
```

### Test 2: Store Item in Box

```dart
// Store item
await BoxService().occupyBox('BOX_A1', 'item_123');

// Verify in MySQL:
// box_id | status   | current_item_id
// BOX_A1 | occupied | item_123
```

### Test 3: Verify Sync Status

```dart
// Check sync status
final syncService = DatabaseSyncService();
final status = await syncService.verifySyncStatus();

print(status);
// {
//   'status': 'synced',
//   'firebase_boxes': 2,
//   'mysql_boxes': 2,
//   'in_sync': true
// }
```

---

## 🐛 Troubleshooting

### Issue: Databases Out of Sync

**Symptom**: Different number of boxes in Firebase vs MySQL

**Solution**:
```bash
# 1. Check Firebase (run Flutter app)
flutter run
# Look for initialization logs

# 2. Check MySQL
C:\xampp\mysql\bin\mysql.exe -u root lostandfound_db -e "SELECT COUNT(*) FROM boxes;"

# 3. Force sync
# In Flutter app, run:
await DatabaseSyncService().syncAllBoxesToMySQL();
```

### Issue: MySQL Not Updating

**Causes**:
- XAMPP MySQL not running
- Backend API not accessible
- Network/localhost issues

**Solution**:
```bash
# 1. Start XAMPP
# Open XAMPP Control Panel
# Start Apache & MySQL

# 2. Test backend API
# Visit: http://localhost/Lost-and-Found-IOT/backend/api/

# 3. Check PHP error logs
# C:\xampp\apache\logs\error.log
```

### Issue: Firebase Not Updating

**Causes**:
- Not authenticated
- Firebase rules
- Network issues

**Solution**:
```dart
// Check authentication
final user = FirebaseAuth.instance.currentUser;
if (user == null) {
  // Sign in first
  await AuthService().signIn(email, password);
}

// Check Firebase rules in console
// https://console.firebase.google.com/
```

---

## 📊 Database Locations

### Firebase
- **Console**: https://console.firebase.google.com/
- **Project**: lostandfound-606de
- **Firestore**: `/boxes`, `/items`, `/users`
- **Realtime DB**: `/boxes/{boxId}/isLocked`

### MySQL
- **Location**: `C:\xampp\mysql\data\lostandfound_db\`
- **Access**: http://localhost/phpmyadmin
- **Database**: `lostandfound_db`
- **Tables**: `boxes`, `items`, `users`, etc.

---

## 🔐 Security Notes

1. **MySQL** is local only (localhost) - not exposed to internet
2. **Firebase** uses authentication and security rules
3. **Arduino** connects via PHP API (API key protected)
4. **Never commit** Firebase credentials to git

---

## 📝 File References

- **Sync Service**: `lib/services/database_sync_service.dart`
- **Box Service**: `lib/services/box_service.dart`
- **SQL Schema**: `backend/database/schema.sql`
- **SQL Dump**: `lostandfound_db_clean.sql`
- **PHP API**: `backend/api/`

---

## ✅ Verification Checklist

Before deployment, verify:

- [ ] Both databases have same number of boxes
- [ ] Box IDs match exactly
- [ ] Box locations match exactly
- [ ] XAMPP MySQL is running
- [ ] Firebase project is configured
- [ ] Backend API is accessible
- [ ] Auto-sync is enabled in app
- [ ] Arduino can read Realtime DB
- [ ] Arduino can write to MySQL

---

**Last Updated**: January 11, 2026
**Database Version**: 1.0
**Boxes Count**: 2 (BOX_A1, BOX_A2)
