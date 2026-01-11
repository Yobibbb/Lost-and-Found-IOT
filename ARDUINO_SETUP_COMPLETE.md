# 🤖 Arduino Setup Guide - Complete Instructions

## 📋 What You Need

### Hardware Required:
1. **Arduino Uno R3** or compatible board
2. **ESP8266-01 WiFi Module** (for internet connectivity)
3. **Servo Motor SG90** or **12V Solenoid Lock** (for locking mechanism)
4. **Jumper Wires** (Male-to-Female and Male-to-Male)
5. **Breadboard** (optional, for testing)
6. **External 5V Power Supply** (for servo/solenoid - Arduino USB power may not be enough)

### Software Required:
1. **Arduino IDE** (Download from: https://www.arduino.cc/en/software)
2. **USB Cable** (Type A to Type B for Arduino Uno)
3. **CP2102 or CH340 Driver** (for USB communication)

---

## 🔧 Hardware Wiring

### ESP8266-01 to Arduino Uno

```
ESP8266-01        Arduino Uno
---------         -----------
VCC        →      3.3V (⚠️ NOT 5V!)
GND        →      GND
CH_PD      →      3.3V
TX         →      Pin 2 (RX via SoftwareSerial)
RX         →      Pin 3 (TX via SoftwareSerial) + Voltage Divider*
```

**⚠️ IMPORTANT**: ESP8266 RX pin requires **3.3V logic**, but Arduino outputs **5V**.
You MUST use a voltage divider:

```
Arduino Pin 3 → 1kΩ resistor → ESP8266 RX
                              ↓
                            2kΩ resistor → GND
```

This creates ~3.3V signal for ESP8266.

### Servo Motor to Arduino

```
Servo Wire        Arduino Uno
----------        -----------
Brown/Black →     GND
Red         →     5V (External Power Recommended)
Orange/Yellow →   Pin 9
```

**⚠️ For heavy-duty locks**, use external 5V/2A power supply:
- Connect GND of external supply to Arduino GND
- Connect 5V to servo Red wire
- Signal wire still goes to Pin 9

### Complete Wiring Diagram

```
                    Arduino Uno
                    -----------
                   |           |
ESP8266 VCC → 3.3V |           | 5V → Servo Red Wire
ESP8266 GND →  GND |    USB    | GND → Servo Black Wire
ESP8266 TX  →  D2  |           | D9 → Servo Signal Wire
ESP8266 RX  →  D3  |___________|
(via divider)
```

---

## 💻 Software Setup

### Step 1: Install Arduino IDE

1. Download: https://www.arduino.cc/en/software
2. Install for Windows
3. Connect Arduino via USB
4. Open Arduino IDE
5. Go to **Tools** → **Board** → Select **Arduino Uno**
6. Go to **Tools** → **Port** → Select your COM port (e.g., COM3)

### Step 2: Install Required Libraries

1. Open Arduino IDE
2. Go to **Sketch** → **Include Library** → **Manage Libraries**
3. Search and install:
   - ✅ **Servo** (by Arduino) - Usually pre-installed
   - ✅ **SoftwareSerial** - Usually pre-installed

No other libraries needed!

### Step 3: Get Your Computer's IP Address

**Windows:**
```powershell
ipconfig
```
Look for **IPv4 Address** under your active network adapter.
Example: `192.168.1.100` or `192.168.0.105`

**This is the IP address you'll use in the Arduino code!**

### Step 4: Configure the Arduino Code

1. Open the Arduino file:
   ```
   C:\xampp\htdocs\Lost-and-Found-IOT\arduino\lost_and_found_iot\lost_and_found_iot.ino
   ```

2. **Edit these lines** at the top of the file:

```cpp
// WiFi Settings
#define WIFI_SSID "Your_WiFi_Name"        // ⚠️ Change to YOUR WiFi name
#define WIFI_PASS "Your_WiFi_Password"    // ⚠️ Change to YOUR WiFi password

// API Settings
#define API_HOST "192.168.1.100"          // ⚠️ Change to YOUR computer's IP
#define BOX_ID "BOX_A1"                   // BOX_A1 or BOX_A2
```

**Example:**
```cpp
#define WIFI_SSID "HomeWiFi"
#define WIFI_PASS "mypassword123"
#define API_HOST "192.168.0.105"  // From ipconfig
#define BOX_ID "BOX_A1"           // First box
```

### Step 5: Upload Code to Arduino

1. **Connect Arduino** to computer via USB
2. **Select Board**: Tools → Board → Arduino Uno
3. **Select Port**: Tools → Port → COM3 (your port number)
4. **Click Upload** button (→) or press `Ctrl+U`
5. Wait for "**Done uploading**" message

---

## 🧪 Testing

### Test 1: Serial Monitor

1. Open Serial Monitor: **Tools** → **Serial Monitor**
2. Set baud rate to: **115200**
3. You should see:

```
=================================
  Lost & Found IoT System
  Arduino Uno R3 + ESP8266
=================================
Box ID: BOX_A1

[SERVO] Initialized to LOCKED position
[WIFI] Initializing ESP8266...
[ESP] Sending AT test command...
OK
[ESP] Setting station mode...
OK
[WIFI] Connecting to: HomeWiFi
...
[WIFI] ✓ Connected successfully!
[SYSTEM] Initialization complete!
[API] Polling for commands...
```

### Test 2: Manual Lock/Unlock via Database

**Method 1: Using phpMyAdmin**

1. Open: http://localhost/phpmyadmin
2. Select database: `lostandfound_db`
3. Click on table: `boxes`
4. Click "Edit" for BOX_A1
5. Change `command` to: `unlock`
6. Click "Go"

**Method 2: Using SQL Command**

```sql
-- Unlock box
UPDATE boxes SET command = 'unlock', command_timestamp = NOW() WHERE box_id = 'BOX_A1';

-- Wait 5 seconds, then lock it
UPDATE boxes SET command = 'lock', command_timestamp = NOW() WHERE box_id = 'BOX_A1';
```

**What Should Happen:**
- Arduino polls API every 3 seconds
- Detects "unlock" command
- Servo moves to 180°
- Arduino clears command
- After you set "lock", servo returns to 0°

### Test 3: Backend API Test

Open in browser:
```
http://localhost/Lost-and-Found-IOT/backend/api/arduino/command?box_id=BOX_A1
```

Should return:
```json
{
  "status": "success",
  "command": null,
  "timestamp": null
}
```

After setting unlock command in database:
```json
{
  "status": "success",
  "command": "unlock",
  "timestamp": "2026-01-11 14:30:00"
}
```

---

## 🎯 How It Works

### System Flow

```
Flutter App
    ↓
Firebase Firestore
    ↓
MySQL Database (via sync)
    ↓
PHP Backend API
    ↓
Arduino (polls every 3s)
    ↓
Servo Motor (unlocks/locks)
```

### Arduino Polling Loop

```
Every 3 seconds:
1. Arduino: "Is there a command for BOX_A1?"
2. Backend: Checks MySQL database
3. Backend: "Yes, UNLOCK command"
4. Arduino: Moves servo to 180°
5. Arduino: "Command executed, clear it"
6. Backend: Clears command from database

Every 30 seconds:
- Arduino: Sends heartbeat ping
- Backend: Updates last_ping timestamp
- Backend: Marks box as online
```

---

## 🚨 Troubleshooting

### Problem: "WiFi not connected"

**Solutions:**
1. **Check WiFi credentials**
   - SSID and password must be EXACT (case-sensitive)
   - No extra spaces

2. **Check ESP8266 wiring**
   - VCC to 3.3V (NOT 5V)
   - RX must have voltage divider
   - CH_PD connected to 3.3V

3. **Check ESP8266 baud rate**
   - Some ESP8266 modules use 9600 baud
   - Change `#define ESP_BAUD 115200` to `#define ESP_BAUD 9600`
   - Re-upload code

4. **Test ESP8266 separately**
   ```cpp
   void setup() {
     Serial.begin(115200);
     espSerial.begin(115200);
     espSerial.println("AT");
   }
   
   void loop() {
     if (espSerial.available()) {
       Serial.write(espSerial.read());
     }
     if (Serial.available()) {
       espSerial.write(Serial.read());
     }
   }
   ```
   Should respond with "OK"

### Problem: "No response from API"

**Solutions:**
1. **Check XAMPP is running**
   - Open XAMPP Control Panel
   - Start Apache and MySQL

2. **Check API_HOST IP address**
   - Run `ipconfig` again
   - IP might have changed
   - Update Arduino code and re-upload

3. **Test API in browser**
   ```
   http://YOUR_IP/Lost-and-Found-IOT/backend/api/arduino/command?box_id=BOX_A1
   ```
   Should see JSON response

4. **Check firewall**
   - Windows Firewall might block Arduino
   - Allow XAMPP/Apache through firewall

### Problem: "Servo not moving"

**Solutions:**
1. **Check power supply**
   - Arduino 5V pin might not provide enough current
   - Use external 5V/2A power supply
   - Connect GND between Arduino and power supply

2. **Check servo connection**
   - Signal wire to Pin 9
   - Red to 5V
   - Brown/Black to GND

3. **Test servo separately**
   ```cpp
   #include <Servo.h>
   Servo test;
   
   void setup() {
     test.attach(9);
   }
   
   void loop() {
     test.write(0);
     delay(2000);
     test.write(180);
     delay(2000);
   }
   ```
   Servo should sweep back and forth

4. **Adjust angles**
   - Some servos have different ranges
   - Try: `LOCK_ANGLE = 10` and `UNLOCK_ANGLE = 170`

### Problem: "ESP8266 gets hot"

**Causes:**
- Wrong voltage (5V instead of 3.3V)
- Short circuit

**Solution:**
- Immediately disconnect power
- Check wiring carefully
- ESP8266 requires 3.3V ONLY

### Problem: "Arduino resets randomly"

**Causes:**
- Insufficient power
- Servo draws too much current

**Solution:**
- Use external power supply for servo
- Add 100µF capacitor between 5V and GND
- Use powered USB hub

---

## 📊 LED Status Indicators (Optional Enhancement)

Add LEDs to show status:

```cpp
#define LED_WIFI 4      // Green LED - WiFi connected
#define LED_COMMAND 5   // Yellow LED - Command received
#define LED_ERROR 6     // Red LED - Error state

void setup() {
  pinMode(LED_WIFI, OUTPUT);
  pinMode(LED_COMMAND, OUTPUT);
  pinMode(LED_ERROR, OUTPUT);
  // ...
}

void connectWiFi() {
  // ...
  if (connected) {
    digitalWrite(LED_WIFI, HIGH);
  } else {
    digitalWrite(LED_ERROR, HIGH);
  }
}
```

---

## 🔐 Security Enhancements (Optional)

For production deployment:

1. **Add API Key Authentication**
```cpp
#define API_KEY "your-secret-key-here"

// In HTTP request:
request += "X-API-Key: " + String(API_KEY) + "\r\n";
```

2. **Encrypt WiFi Credentials**
   - Store in EEPROM
   - Use AES encryption

3. **Add Physical Button**
   - Emergency unlock button on box
   - Overrides software commands

---

## 📝 Configuration for Multiple Boxes

### For BOX_A1 (First Arduino):
```cpp
#define BOX_ID "BOX_A1"
```

### For BOX_A2 (Second Arduino):
```cpp
#define BOX_ID "BOX_A2"
```

**Each box needs:**
- Separate Arduino Uno
- Separate ESP8266
- Separate Servo
- Same WiFi credentials
- Same API_HOST
- Different BOX_ID

---

## 📦 Parts List & Shopping

### Required Components:

| Item | Quantity | Est. Price |
|------|----------|------------|
| Arduino Uno R3 | 1 per box | $25 |
| ESP8266-01 | 1 per box | $5 |
| SG90 Servo Motor | 1 per box | $3 |
| Jumper Wires | 1 pack | $5 |
| Breadboard | 1 (optional) | $5 |
| 5V Power Supply | 1 per box | $8 |
| Resistors (1kΩ, 2kΩ) | 2 per box | $1 |

**Total per box**: ~$50

### Where to Buy:
- **Amazon**
- **AliExpress** (cheaper, slower shipping)
- **Local electronics store**

---

## ✅ Final Checklist

Before deployment:

- [ ] ESP8266 wired correctly (3.3V, voltage divider on RX)
- [ ] Servo wired correctly (Pin 9, external power)
- [ ] WiFi credentials configured in code
- [ ] API_HOST IP address is correct
- [ ] BOX_ID matches database (BOX_A1 or BOX_A2)
- [ ] Code uploaded successfully
- [ ] Serial monitor shows "WiFi Connected"
- [ ] Serial monitor shows "Polling for commands"
- [ ] Test unlock/lock commands work
- [ ] Heartbeat pings successful
- [ ] Box marked as online in database

---

## 🎓 Learning Resources

- **Arduino Tutorial**: https://www.arduino.cc/en/Tutorial/HomePage
- **ESP8266 Guide**: https://randomnerdtutorials.com/esp8266-pinout-reference-gpios/
- **Servo Tutorial**: https://www.arduino.cc/en/Tutorial/LibraryExamples/Sweep

---

## 📞 Support

If you encounter issues:

1. Check Serial Monitor output
2. Test each component separately
3. Verify network connectivity
4. Check backend API logs

**Backend API Test:**
```
http://localhost/Lost-and-Found-IOT/backend/api/arduino/health
```

Should return system statistics.

---

**Last Updated**: January 11, 2026  
**Arduino IDE Version**: 2.x  
**ESP8266 Firmware**: AT v1.7+  
**Tested Hardware**: Arduino Uno R3, ESP8266-01, SG90 Servo
