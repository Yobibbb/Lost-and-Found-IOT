# 🧪 Arduino & Backend Testing Guide

## 🎯 Quick Test - Get Arduino Working (30 Minutes)

### Step 1: Setup Database (5 minutes)

1. **Start XAMPP**
   ```powershell
   cd C:\xampp
   .\mysql_start.bat
   # Or use XAMPP Control Panel → Start MySQL
   ```

2. **Create Database**
   - Open: http://localhost/phpmyadmin
   - Click "New" → Database name: `lostandfound_db`
   - Collation: `utf8mb4_unicode_ci`
   - Click "Create"

3. **Import Schema**
   - Select `lostandfound_db`
   - Click "Import" tab
   - Choose file: `C:\xampp\htdocs\Lost-and-Found-IOT\backend\database\schema.sql`
   - Click "Go"
   - ✅ You should see: "Import has been successfully finished, 5 queries executed"

4. **Verify Data**
   ```sql
   SELECT * FROM boxes;
   -- Should show 5 boxes: BOX_A1, BOX_A2, BOX_B1, BOX_B2, BOX_C1
   ```

### Step 2: Test Backend API (5 minutes)

1. **Find Your Computer's IP Address**
   ```powershell
   ipconfig
   # Look for "IPv4 Address" under your active network adapter
   # Example: 192.168.1.100
   ```

2. **Test API in Browser**
   - Open: `http://localhost/Lost-and-Found-IOT/backend/api/`
   - Should see JSON response:
     ```json
     {
       "success": true,
       "message": "API is running",
       "data": {
         "name": "Lost & Found IoT",
         "version": "1.0.0"
       }
     }
     ```

3. **Test Arduino Endpoint**
   - Open: `http://localhost/Lost-and-Found-IOT/backend/api/arduino/command?box_id=BOX_A1`
   - Should see:
     ```json
     {
       "success": true,
       "data": {
         "command": null
       },
       "message": "No pending command"
     }
     ```

4. **Test Health Check**
   - Open: `http://localhost/Lost-and-Found-IOT/backend/api/arduino/health`
   - Should see system stats with 5 boxes

✅ **If all these work, your backend is ready!**

### Step 3: Issue Test Command via Database (2 minutes)

1. **Open phpMyAdmin SQL Tab**
2. **Run this command:**
   ```sql
   UPDATE boxes 
   SET command = 'unlock', 
       command_timestamp = NOW() 
   WHERE box_id = 'BOX_A1';
   ```

3. **Verify in Browser**
   - Refresh: `http://localhost/Lost-and-Found-IOT/backend/api/arduino/command?box_id=BOX_A1`
   - Should now see:
     ```json
     {
       "success": true,
       "data": {
         "command": "unlock",
         "timestamp": "2026-01-11 12:30:45",
         "age_seconds": 2
       }
     }
     ```

✅ **API is working correctly!**

### Step 4: Configure Arduino Code (5 minutes)

1. **Open Arduino IDE**
2. **Open:** `C:\xampp\htdocs\Lost-and-Found-IOT\arduino\lost_and_found_iot\lost_and_found_iot.ino`

3. **Edit Configuration (Lines 30-36):**
   ```cpp
   // WiFi Settings
   #define WIFI_SSID "Your_WiFi_Name"      // ← Your WiFi name
   #define WIFI_PASS "Your_WiFi_Password"  // ← Your WiFi password
   
   // API Settings
   #define API_HOST "192.168.1.100"  // ← Your computer's IP address
   #define API_PORT 80
   #define API_PATH "/Lost-and-Found-IOT/backend/api/arduino"
   #define BOX_ID "BOX_A1"  // ← Use BOX_A1 for first box
   ```

4. **Save the file**

### Step 5: Upload to Arduino (5 minutes)

1. **Connect Hardware:**
   - Arduino Uno R3 → USB to computer
   - ESP8266-01 → RX to pin 2, TX to pin 3, VCC to 3.3V, GND to GND
   - Servo → Signal to pin 9, VCC to 5V, GND to GND

2. **Arduino IDE Settings:**
   - Tools → Board → "Arduino Uno"
   - Tools → Port → Select your COM port
   - Sketch → Include Library → Manage Libraries
   - Install: "Servo" library (if not already installed)

3. **Upload:**
   - Click "Upload" button (→)
   - Wait for "Done uploading"

4. **Open Serial Monitor:**
   - Tools → Serial Monitor
   - Set baud rate: **115200**

### Step 6: Watch Arduino Connect (5 minutes)

**Serial Monitor Output Should Show:**

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
[ESP] Enabling multiple connections...
OK
[WIFI] Connecting to: Your_WiFi_Name
WIFI CONNECTED
WIFI GOT IP
[WIFI] ✓ Connected successfully!
192.168.1.105
[SYSTEM] Initialization complete!
[SYSTEM] Starting main loop...

[API] Polling for commands...
[API] Response received:
{"success":true,"data":{"command":"unlock","timestamp":"2026-01-11 12:30:45","age_seconds":5}}
[COMMAND] ⚡ UNLOCK command received!
[SERVO] Unlocking... Moving to 180°
[SERVO] ✓ Unlocked!
[API] Clearing command...
[API] ✓ Command cleared successfully

[API] Polling for commands...
[API] Response received:
{"success":true,"data":{"command":null}}
[COMMAND] No pending commands.
```

**🎉 SUCCESS! Your Arduino is working!**

---

## 🔧 Complete Testing Workflow

### Test 1: Unlock Box from Database

1. **Issue unlock command:**
   ```sql
   UPDATE boxes SET command = 'unlock', command_timestamp = NOW() WHERE box_id = 'BOX_A1';
   ```

2. **Watch Arduino Serial Monitor**
   - Should execute unlock in 3 seconds
   - Servo moves to 180°

3. **Verify command cleared:**
   ```sql
   SELECT command, command_timestamp FROM boxes WHERE box_id = 'BOX_A1';
   -- Should show: command = NULL
   ```

### Test 2: Lock Box from Database

1. **Issue lock command:**
   ```sql
   UPDATE boxes SET command = 'lock', command_timestamp = NOW() WHERE box_id = 'BOX_A1';
   ```

2. **Watch Arduino Serial Monitor**
   - Should execute lock in 3 seconds
   - Servo moves to 0°

### Test 3: Command Expiration (60 seconds)

1. **Issue command:**
   ```sql
   UPDATE boxes SET command = 'unlock', command_timestamp = DATE_SUB(NOW(), INTERVAL 65 SECOND) WHERE box_id = 'BOX_A1';
   ```

2. **Check API response:**
   - Should return: `{"command": null}`
   - Expired commands are ignored

3. **Verify auto-cleanup (event scheduler):**
   - Wait 30 seconds
   - Run: `SELECT command FROM boxes WHERE box_id = 'BOX_A1';`
   - Should be NULL (cleaned by event)

### Test 4: Heartbeat/Ping

1. **Watch Serial Monitor**
   - Every 30 seconds should see: `[PING] Sending heartbeat...`

2. **Check database:**
   ```sql
   SELECT box_id, is_online, last_ping FROM boxes WHERE box_id = 'BOX_A1';
   -- is_online should be TRUE
   -- last_ping should be recent
   ```

3. **Stop Arduino (unplug)**
   - Wait 2 minutes
   - Run query again:
     ```sql
     SELECT box_id, is_online, last_ping FROM boxes WHERE box_id = 'BOX_A1';
     -- is_online should change to FALSE (auto-updated by event)
     ```

### Test 5: Multiple Boxes

1. **Upload code to second Arduino:**
   - Change `#define BOX_ID "BOX_A2"` in code
   - Upload

2. **Test both boxes:**
   ```sql
   -- Unlock BOX_A1
   UPDATE boxes SET command = 'unlock', command_timestamp = NOW() WHERE box_id = 'BOX_A1';
   
   -- Lock BOX_A2
   UPDATE boxes SET command = 'lock', command_timestamp = NOW() WHERE box_id = 'BOX_A2';
   ```

3. **Both Arduinos should execute independently**

---

## 🐛 Troubleshooting

### Arduino Not Connecting to WiFi

**Symptoms:**
```
[WIFI] ✗ Connection failed!
[WIFI] Will retry in next cycle...
```

**Solutions:**
1. **Check WiFi credentials** in code (SSID and password)
2. **Check ESP8266 wiring:**
   - RX → Pin 2
   - TX → Pin 3
   - VCC → 3.3V (NOT 5V!)
   - GND → GND
3. **ESP8266 power issue:**
   - ESP8266 needs stable 3.3V
   - Arduino Uno's 3.3V pin might not provide enough current
   - **Solution:** Use external 3.3V power supply or level shifter
4. **Reset ESP8266:**
   - Disconnect power
   - Wait 10 seconds
   - Reconnect

### API Returns 404 Not Found

**Symptoms:**
```
[API] ✗ No response or error
```

**Solutions:**
1. **Check API_HOST is correct**
   - Must be your computer's IP (not localhost)
   - Run `ipconfig` to verify
2. **Check API_PATH matches your setup**
   - Default: `/Lost-and-Found-IOT/backend/api/arduino`
   - If XAMPP htdocs is different, adjust path
3. **Test in browser first:**
   - Open: `http://YOUR_IP/Lost-and-Found-IOT/backend/api/arduino/command?box_id=BOX_A1`
   - Should get JSON response
4. **Check Windows Firewall:**
   - Allow port 80 for XAMPP
   - Or temporarily disable firewall for testing

### Servo Not Moving

**Symptoms:**
- Serial shows command received but servo doesn't move

**Solutions:**
1. **Check servo wiring:**
   - Signal → Pin 9
   - VCC → 5V
   - GND → GND
2. **Power issue:**
   - Servo needs separate 5V power if driving heavy loads
   - Test with small servo first
3. **Servo library:**
   - Make sure Servo library is installed
   - Arduino IDE → Sketch → Include Library → Servo

### Commands Not Clearing

**Symptoms:**
- Arduino keeps executing same command

**Solutions:**
1. **Check clear endpoint:**
   - Test in browser: `http://YOUR_IP/Lost-and-Found-IOT/backend/api/arduino/clear?box_id=BOX_A1`
2. **Check database manually:**
   ```sql
   SELECT command FROM boxes WHERE box_id = 'BOX_A1';
   -- If still showing old command, clear it:
   UPDATE boxes SET command = NULL, command_timestamp = NULL WHERE box_id = 'BOX_A1';
   ```

### Database Connection Failed

**Symptoms:**
- API returns: "Database connection failed"

**Solutions:**
1. **Check XAMPP MySQL is running:**
   - XAMPP Control Panel → MySQL should be green
2. **Check db_config.php:**
   ```php
   define('DB_HOST', 'localhost');  // Should be localhost
   define('DB_NAME', 'lostandfound_db');  // Must match your database name
   define('DB_USER', 'root');  // Default XAMPP user
   define('DB_PASS', '');  // Empty for default XAMPP
   ```
3. **Test connection:**
   ```powershell
   cd C:\xampp\htdocs\Lost-and-Found-IOT\backend\api
   php -r "require 'config/db_config.php'; var_dump(testDBConnection());"
   # Should output: bool(true)
   ```

---

## 📊 Monitoring Commands

### View All Box Statuses

```sql
SELECT 
    box_id,
    status,
    command,
    command_timestamp,
    is_online,
    last_ping,
    TIMESTAMPDIFF(SECOND, last_ping, NOW()) as seconds_since_ping
FROM boxes
ORDER BY box_id;
```

### View Command History (Enable logging)

```sql
-- Create log table (optional)
CREATE TABLE command_logs (
    log_id INT AUTO_INCREMENT PRIMARY KEY,
    box_id VARCHAR(20),
    command ENUM('unlock', 'lock'),
    issued_by VARCHAR(50),
    issued_at TIMESTAMP,
    executed_at TIMESTAMP NULL,
    status ENUM('pending', 'executed', 'expired') DEFAULT 'pending',
    INDEX idx_box_id (box_id),
    INDEX idx_issued_at (issued_at)
);
```

### Real-Time Monitoring

```sql
-- Run this query repeatedly to see live updates
SELECT 
    box_id,
    command,
    TIMESTAMPDIFF(SECOND, command_timestamp, NOW()) as age_seconds,
    CASE 
        WHEN command IS NULL THEN 'No command'
        WHEN TIMESTAMPDIFF(SECOND, command_timestamp, NOW()) > 60 THEN 'Expired'
        ELSE 'Active'
    END as status
FROM boxes
WHERE command IS NOT NULL
ORDER BY command_timestamp DESC;
```

---

## ✅ Success Checklist

- [ ] Database created with schema imported
- [ ] 5 sample boxes exist in database
- [ ] API root endpoint returns JSON
- [ ] Arduino endpoints return correct responses
- [ ] WiFi credentials configured in Arduino code
- [ ] API_HOST set to your computer's IP
- [ ] Arduino connects to WiFi successfully
- [ ] Arduino polls API every 3 seconds
- [ ] Unlock command executes correctly
- [ ] Lock command executes correctly
- [ ] Commands clear after execution
- [ ] Heartbeat ping sends every 30 seconds
- [ ] Box shows as online in database
- [ ] Event scheduler running (commands expire)
- [ ] Multiple Arduinos work independently

---

## 🚀 Next Steps After Arduino Works

1. **Test complete founder flow** (requires remaining controllers)
2. **Integrate Flutter app** with REST API
3. **Add authentication** to box endpoints (optional)
4. **Deploy to free hosting** (000webhost)
5. **Add push notifications** for requests
6. **Implement real-time chat** (polling or SSE)

---

## 📞 Need More Help?

If you encounter issues:

1. **Check Serial Monitor** - Arduino logs every step
2. **Check browser** - Test API endpoints manually
3. **Check database** - Verify data with SQL queries
4. **Check error_log** - PHP errors logged to `C:\xampp\apache\logs\error.log`

**Most Common Issue:** WiFi credentials or API_HOST incorrect in Arduino code!

---

**Last Updated:** January 11, 2026  
**Version:** 1.0
