# 🚀 Arduino Quick Setup - 5 Minutes

## ⚡ Fast Track Setup

### 1. Wire Hardware (2 minutes)

```
ESP8266-01 → Arduino Uno
------------------------
VCC     → 3.3V
GND     → GND
CH_PD   → 3.3V
TX      → Pin 2
RX      → Pin 3 (with voltage divider: 1kΩ + 2kΩ)

Servo → Arduino Uno
-------------------
Signal  → Pin 9
Red     → 5V (external power recommended)
Black   → GND
```

### 2. Get Your IP Address (30 seconds)

```powershell
ipconfig
```
Look for **IPv4 Address** (e.g., 192.168.1.100)

### 3. Edit Arduino Code (1 minute)

Open: `arduino/lost_and_found_iot/lost_and_found_iot.ino`

Change these 4 lines:

```cpp
#define WIFI_SSID "Your_WiFi_Name"      // Your WiFi name
#define WIFI_PASS "Your_WiFi_Password"  // Your WiFi password
#define API_HOST "192.168.1.100"        // Your IP from step 2
#define BOX_ID "BOX_A1"                 // BOX_A1 or BOX_A2
```

### 4. Upload to Arduino (1 minute)

1. Connect Arduino via USB
2. Tools → Board → Arduino Uno
3. Tools → Port → COM3 (your port)
4. Click Upload (→) button

### 5. Test (30 seconds)

1. Open Serial Monitor (Tools → Serial Monitor)
2. Set baud rate: 115200
3. Look for: `[WIFI] ✓ Connected successfully!`

### 6. Test Lock/Unlock

**Via phpMyAdmin:**
```
1. http://localhost/phpmyadmin
2. Database: lostandfound_db
3. Table: boxes
4. Edit BOX_A1 → set command = 'unlock'
5. Wait 3 seconds → servo moves!
```

**Via SQL:**
```sql
UPDATE boxes SET command = 'unlock' WHERE box_id = 'BOX_A1';
```

---

## 🎯 What Should Happen

**Serial Monitor Output:**
```
=================================
  Lost & Found IoT System
=================================
Box ID: BOX_A1

[SERVO] Initialized to LOCKED position
[WIFI] ✓ Connected successfully!
[SYSTEM] Starting main loop...

[API] Polling for commands...
[COMMAND] No pending commands.

[PING] Sending heartbeat...
[PING] ✓ Heartbeat sent

[API] Polling for commands...
[COMMAND] ⚡ UNLOCK command received!
[SERVO] Unlocking... Moving to 180°
[SERVO] ✓ Unlocked!
[API] ✓ Command cleared successfully
```

---

## 🚨 Common Issues & Quick Fixes

| Problem | Quick Fix |
|---------|-----------|
| "WiFi not connected" | Check SSID/password, use 3.3V for ESP8266 |
| "No response from API" | Check IP address, restart XAMPP |
| "Servo not moving" | Use external 5V power supply |
| "ESP8266 hot" | Unplug immediately! Check it's on 3.3V NOT 5V |

---

## 📱 Test via Flutter App

1. Run Flutter app
2. Login as founder
3. Create an item
4. Store in BOX_A1
5. Arduino should unlock automatically!

---

## 🔧 Quick Commands

**Reset Arduino:**
- Press reset button on board

**Re-upload code:**
- `Ctrl+U` in Arduino IDE

**Check connection:**
```
http://localhost/Lost-and-Found-IOT/backend/api/arduino/command?box_id=BOX_A1
```

**Force unlock from MySQL:**
```sql
UPDATE boxes SET command = 'unlock', command_timestamp = NOW() WHERE box_id = 'BOX_A1';
```

**Check box status:**
```sql
SELECT box_id, status, command, is_online, last_ping FROM boxes;
```

---

## ✅ Success Checklist

- [ ] ESP8266 on 3.3V (NOT 5V!)
- [ ] Voltage divider on ESP RX
- [ ] WiFi SSID/password correct
- [ ] API_HOST = your computer IP
- [ ] BOX_ID = BOX_A1 or BOX_A2
- [ ] Serial monitor shows "Connected"
- [ ] Servo moves on command
- [ ] Heartbeat every 30 seconds

---

**Need more help?** See `ARDUINO_SETUP_COMPLETE.md` for detailed guide.
