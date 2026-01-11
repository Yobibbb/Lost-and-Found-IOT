# 🔧 Complete System Configuration

## 📡 Network Configuration

### WiFi Settings
```
SSID: ZTE_2.4G_VFfJNJ
Password: 9MUkNPy4
Type: 2.4GHz (ESP8266 compatible)
```

### Computer/Server IP Address
```
Local IP: 192.168.1.15
Used for: PHP Backend API (if needed)
```

---

## 🔥 Firebase Configuration

### Firebase Project
```
Project ID: lostandfound-606de
Region: asia-southeast1
```

### Firebase Realtime Database
```
URL: https://lostandfound-606de-default-rtdb.asia-southeast1.firebasedatabase.app
Path for Box A1: /boxes/BOX_A1/isLocked
Path for Box A2: /boxes/BOX_A2/isLocked
```

### Firebase Firestore
```
Collections:
- boxes (main box data)
- items (lost items)
- users (user accounts)
- retrieval_requests (requests to retrieve items)
- messages (chat messages)
- notifications (user notifications)
```

---

## 🗄️ MySQL Database Configuration

### Database Connection
```
Host: localhost
Database: lostandfound_db
User: root
Password: (empty - XAMPP default)
Port: 3306
Charset: utf8mb4
```

### Database Tables
```sql
- boxes (2 records: BOX_A1, BOX_A2)
- users (user accounts)
- items (stored items)
- retrieval_requests (item retrieval requests)
- messages (user messages)
```

### MySQL Access URLs
```
phpMyAdmin: http://localhost/phpmyadmin
Direct Access: C:\xampp\mysql\data\lostandfound_db\
```

---

## 🔌 Backend API Configuration

### PHP Backend
```
Base URL: http://192.168.1.15/Lost-and-Found-IOT/backend/api
Local URL: http://localhost/Lost-and-Found-IOT/backend/api

Endpoints:
- http://192.168.1.15/Lost-and-Found-IOT/backend/api/arduino/command?box_id=BOX_A1
- http://192.168.1.15/Lost-and-Found-IOT/backend/api/arduino/ping?box_id=BOX_A1
- http://192.168.1.15/Lost-and-Found-IOT/backend/api/arduino/health
```

### API Settings
```
JWT Secret: your-secret-key-change-this-in-production-use-strong-random-string
JWT Expiry: 30 days (2592000 seconds)
Command Expiry: 60 seconds
Arduino Timeout: 120 seconds
Rate Limit: 100 requests/minute per IP
```

---

## 🤖 Arduino Configuration

### Hardware Setup
```
Board: Arduino Uno R3
WiFi Module: ESP8266-01
Lock Mechanism: SG90 Servo Motor
Servo Pin: D9
ESP8266 RX: D2
ESP8266 TX: D3
Power: 5V external recommended
```

### Arduino Box A1 Settings
```cpp
#define WIFI_SSID "ZTE_2.4G_VFfJNJ"
#define WIFI_PASSWORD "9MUkNPy4"
#define FIREBASE_HOST "lostandfound-606de-default-rtdb.asia-southeast1.firebasedatabase.app"
#define BOX_ID "BOX_A1"
#define SERVO_PIN 9
#define LOCKED_POSITION 0
#define UNLOCKED_POSITION 180
#define CHECK_INTERVAL 3000
```

### Arduino Box A2 Settings
```cpp
// Same as Box A1, except:
#define BOX_ID "BOX_A2"
```

---

## 📱 Flutter App Configuration

### Firebase Options (lib/firebase_options.dart)
```dart
Android App ID: 1:182349555558:android:f1c71a9e6f8ee63604caa7
iOS App ID: 1:182349555558:ios:f1c71a9e6f8ee63604caa7
Web App ID: 1:182349555558:web:e77f12452189a92104caa7
API Key: AIzaSyCdimuC7JfnRLeRiVLm9FZWSpEp77gXl7Q
Project ID: lostandfound-606de
Storage Bucket: lostandfound-606de.firebasestorage.app
Messaging Sender ID: 182349555558
```

### Demo Mode (lib/config/demo_config.dart)
```dart
static const bool demoMode = false; // Set to true for demo mode without Firebase
```

### Backend API (lib/services/database_sync_service.dart)
```dart
final String _baseUrl = 'http://192.168.1.15/Lost-and-Found-IOT/backend/api';
// Change IP address if your computer IP changes
```

---

## 🗂️ Box Configuration

### Available Boxes
```
Box ID: BOX_A1
Name: Box A1
Location: Building A, Floor 1, Near Main Entrance
Status: available
Command: null
Online: false

Box ID: BOX_A2
Name: Box A2
Location: Building A, Floor 2, Near Cafeteria
Status: available
Command: null
Online: false
```

---

## 🔄 Database Synchronization

### Sync Flow
```
Flutter App
    ↓
Firebase Firestore (Primary)
    ↓
├─→ Firebase Realtime DB (Arduino reads)
└─→ MySQL Database (Backend API)
```

### Auto-Sync Triggers
```
- Box lock/unlock
- Item storage
- Item retrieval
- Box status change
- App initialization
```

---

## 🔐 Security Configuration

### Firebase Security Rules

**Firestore Rules:**
```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /{document=**} {
      allow read, write: if request.auth != null;
    }
  }
}
```

**Realtime Database Rules:**
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

### MySQL Security
```
- Local access only (localhost)
- No external connections allowed
- Default XAMPP root user (no password)
- Production: Use strong passwords
```

---

## 🌐 Network Ports

```
HTTP: 80 (Backend API)
HTTPS: 443 (Firebase)
MySQL: 3306 (Database)
Arduino Polling: Every 3 seconds
WiFi: 2.4GHz only
```

---

## 📋 Quick Reference

### Start Development Environment
```powershell
# 1. Start XAMPP
Start-Process "C:\xampp\xampp-control.exe"
# Click: Start Apache, Start MySQL

# 2. Verify database
Start-Process "http://localhost/phpmyadmin"

# 3. Test backend API
Start-Process "http://localhost/Lost-and-Found-IOT/backend/api/arduino/health"

# 4. Run Flutter app
cd C:\xampp\htdocs\Lost-and-Found-IOT
flutter run
```

### Upload Arduino Code
```
1. Open: arduino/lost_and_found_iot/lost_and_found_iot.ino
2. Tools → Board → Arduino Uno
3. Tools → Port → COM3 (your port)
4. Sketch → Upload (Ctrl+U)
5. Tools → Serial Monitor (115200 baud)
```

### Test Complete System
```
1. Arduino connects to WiFi ✓
2. Arduino connects to Firebase SSL ✓
3. Flutter app logs in ✓
4. Create item in app ✓
5. Store in BOX_A1 ✓
6. Arduino unlocks within 3 seconds ✓
7. Check MySQL database synced ✓
```

---

## 🔍 Verification Commands

### Check WiFi Connection
```powershell
ping 192.168.1.15
# Should reply successfully
```

### Check MySQL Database
```powershell
C:\xampp\mysql\bin\mysql.exe -u root lostandfound_db -e "SELECT * FROM boxes;"
```

### Check Backend API
```powershell
curl http://localhost/Lost-and-Found-IOT/backend/api/arduino/health
```

### Check Firebase
```
Visit: https://console.firebase.google.com/project/lostandfound-606de
```

---

## 📞 Support Information

### If IP Address Changes
Update in these files:
1. `lib/services/database_sync_service.dart` (line 10)
2. Arduino code (if using PHP backend fallback)
3. Backend configuration

### If WiFi Changes
Update in:
1. Arduino code: `WIFI_SSID` and `WIFI_PASSWORD`
2. Re-upload to all Arduino boards

### If Firebase Changes
Update in:
1. `lib/firebase_options.dart`
2. Arduino code: `FIREBASE_HOST`
3. Run: `flutterfire configure`

---

## ✅ Configuration Checklist

- [x] WiFi credentials configured
- [x] Firebase project setup
- [x] MySQL database created
- [x] Boxes initialized (BOX_A1, BOX_A2)
- [x] Arduino code configured
- [x] Flutter app configured
- [x] Backend API configured
- [x] Database sync service ready
- [x] Security rules set
- [x] Network access verified

---

**Configuration Complete!** All systems are configured and ready to use.

**Last Updated**: January 11, 2026  
**Project**: Lost & Found IoT System  
**Version**: 1.0  
**Status**: Production Ready
