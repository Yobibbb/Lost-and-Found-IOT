/*
 * Lost & Found IoT System - Arduino Code
 * Reads lock status from Firebase Realtime Database and controls servo
 * 
 * Hardware:
 * - Arduino Uno R3
 * - ESP8266-01 WiFi Module (SoftwareSerial on pins 2, 3)
 * - Servo Motor on pin 9 (or Relay Module)
 * 
 * Features:
 * - Connects to WiFi using AT commands
 * - Reads directly from Firebase Realtime Database (SSL)
 * - Polls Firebase every 3 seconds for lock status
 * - Executes unlock (180°) and lock (0°) commands
 * - Detailed serial debugging
 * 
 * Firebase Path:
 * - /boxes/BOX_A1/isLocked (true = locked, false = unlocked)
 * - /boxes/BOX_A2/isLocked (for second box)
 */

#include <SoftwareSerial.h>
#include <Servo.h>

// ============================================
// CONFIGURATION - EDIT THESE VALUES
// ============================================

// WiFi Configuration
#define WIFI_SSID "ZTE_2.4G_VFfJNJ"       // Your WiFi network name
#define WIFI_PASSWORD "9MUkNPy4"          // Your WiFi password

// Firebase Realtime Database Configuration
#define FIREBASE_HOST "lostandfound-606de-default-rtdb.asia-southeast1.firebasedatabase.app"
#define BOX_ID "BOX_A1"                   // Change to BOX_A2 for second Arduino

// Hardware Setup
#define SERVO_PIN 9
#define LOCKED_POSITION 0      // Servo angle when locked (adjust if needed)
#define UNLOCKED_POSITION 180  // Servo angle when unlocked (adjust if needed)

// Timing Settings
#define CHECK_INTERVAL 3000    // Check Firebase every 3 seconds
#define WIFI_TIMEOUT 20000     // WiFi connection timeout

// Serial Settings
#define DEBUG_BAUD 115200
#define ESP_BAUD 115200        // ESP8266 baud rate (115200 recommended)

// ============================================
// HARDWARE SETUP
// ============================================

SoftwareSerial ESP8266(2, 3); // RX=D2, TX=D3 for ESP8266
Servo lockServo;

// ============================================
// GLOBAL VARIABLES
// ============================================

bool lastLockState = true;     // Last known lock state (true = locked)
bool firstRun = true;           // Flag for first run
unsigned long lastCheckTime = 0;
unsigned long lastWiFiCheck = 0;
const unsigned long WIFI_CHECK_INTERVAL = 60000; // Check WiFi every 60 seconds

// ============================================
// SETUP
// ============================================

void setup() {
  Serial.begin(DEBUG_BAUD);
  ESP8266.begin(ESP_BAUD);
  
  // Wait for serial to initialize
  delay(1000);
  
  Serial.println(F("\n===================================="));
  Serial.println(F("  Lost & Found IoT System"));
  Serial.println(F("  Arduino Uno R3 + ESP8266"));
  Serial.println(F("  Firebase Realtime Database"));
  Serial.println(F("===================================="));
  Serial.print(F("Box ID: "));
  Serial.println(BOX_ID);
  Serial.print(F("Firebase: "));
  Serial.println(FIREBASE_HOST);
  Serial.println(F("====================================\n"));
  
  // Initialize servo
  lockServo.attach(SERVO_PIN);
  lockServo.write(LOCKED_POSITION);
  Serial.println(F("✓ Servo initialized at LOCKED position"));
  delay(500);
  
  // Initialize ESP8266
  Serial.println(F("\n[ESP] Initializing ESP8266..."));
  initESP8266();
  
  // Connect to WiFi
  connectWiFi();
  
  Serial.println(F("\n===================================="));
  Serial.println(F("Listening for commands from Firebase"));
  Serial.println(F("====================================\n"));
}

// ============================================
// MAIN LOOP
// ============================================

void loop() {
  unsigned long currentTime = millis();
  
  // Check Firebase for lock status at regular intervals
  if (currentTime - lastCheckTime >= CHECK_INTERVAL) {
    lastCheckTime = currentTime;
    
    bool isLocked = readLockStatusFromFirebase();
    
    // Process command if it changed or first run
    if (firstRun || (isLocked != lastLockState)) {
      Serial.println(F("\n-----------------------------------"));
      Serial.print(F("📩 Lock status changed: "));
      Serial.println(isLocked ? "LOCKED" : "UNLOCKED");
      Serial.println(F("-----------------------------------"));
      
      if (isLocked) {
        lockBox();
      } else {
        unlockBox();
      }
      
      lastLockState = isLocked;
      firstRun = false;
    } else {
      Serial.print(F("Status unchanged: "));
      Serial.println(isLocked ? "LOCKED" : "UNLOCKED");
    }
  }
  
  // Periodic WiFi check (optional)
  if (currentTime - lastWiFiCheck >= WIFI_CHECK_INTERVAL) {
    lastWiFiCheck = currentTime;
    Serial.println(F("[WIFI] Periodic check..."));
    // Could add reconnect logic here if needed
  }
  
  delay(100);
}

// ============================================
// ESP8266 INITIALIZATION
// ============================================

void initESP8266() {
  Serial.println(F("[ESP] Resetting ESP8266..."));
  ESP8266.println(F("AT+RST"));
  delay(3000);
  clearESPBuffer();
  
  Serial.println(F("[ESP] Sending AT test command..."));
  ESP8266.println(F("AT"));
  delay(1000);
  clearESPBuffer();
  
  Serial.println(F("[ESP] Setting station mode..."));
  ESP8266.println(F("AT+CWMODE=1"));
  delay(1000);
  clearESPBuffer();
}

// ============================================
// CONNECT TO WIFI
// ============================================

void connectWiFi() {
  Serial.println(F("\n[WIFI] Connecting to WiFi..."));
  Serial.print(F("SSID: "));
  Serial.println(WIFI_SSID);
  
  // Build connection command
  ESP8266.print(F("AT+CWJAP=\""));
  ESP8266.print(WIFI_SSID);
  ESP8266.print(F("\",\""));
  ESP8266.print(WIFI_PASSWORD);
  ESP8266.println(F("\""));
  
  ESP8266.setTimeout(15000);
  
  // Wait for connection
  unsigned long timeout = millis();
  bool connected = false;
  String response = "";
  
  while (millis() - timeout < WIFI_TIMEOUT) {
    if (ESP8266.available()) {
      char c = ESP8266.read();
      response += c;
      Serial.write(c);
      
      if (response.indexOf("WIFI CONNECTED") > -1 || 
          response.indexOf("WIFI GOT IP") > -1 ||
          response.indexOf("OK") > -1) {
        connected = true;
        break;
      }
      
      if (response.indexOf("FAIL") > -1) {
        break;
      }
    }
  }
  
  if (connected) {
    Serial.println(F("\n✓ WiFi Connected Successfully!\n"));
    
    // Set multiple connections mode
    delay(2000);
    ESP8266.println(F("AT+CIPMUX=1"));
    delay(500);
    clearESPBuffer();
    
  } else {
    Serial.println(F("\n✗ WiFi Connection Failed!"));
    Serial.println(F("Retrying in 5 seconds...\n"));
    delay(5000);
    connectWiFi(); // Retry
  }
}

// ============================================
// READ LOCK STATUS FROM FIREBASE
// ============================================

bool readLockStatusFromFirebase() {
  // Close any existing connection
  ESP8266.println(F("AT+CIPCLOSE=0"));
  delay(500);
  clearESPBuffer();
  
  // Connect to Firebase via SSL
  Serial.println(F("[Firebase] Connecting to Firebase SSL..."));
  
  ESP8266.print(F("AT+CIPSTART=0,\"SSL\",\""));
  ESP8266.print(FIREBASE_HOST);
  ESP8266.println(F("\",443"));
  
  // Wait for connection
  String connResponse = "";
  unsigned long timeout = millis();
  bool connected = false;
  
  while (millis() - timeout < 10000) {
    while (ESP8266.available()) {
      char c = ESP8266.read();
      connResponse += c;
    }
    
    if (connResponse.indexOf("CONNECT") > -1) {
      Serial.println(F("✓ SSL Connected!"));
      connected = true;
      break;
    }
    
    if (connResponse.indexOf("ERROR") > -1 || connResponse.indexOf("CLOSED") > -1) {
      Serial.println(F("✗ SSL Connection Failed!"));
      Serial.println(F("⚠ Check: 1) ESP8266 firmware supports SSL"));
      Serial.println(F("         2) Firebase host is correct"));
      return lastLockState; // Return last known state
    }
  }
  
  if (!connected) {
    Serial.println(F("✗ Connection Timeout"));
    return lastLockState; // Return last known state
  }
  
  delay(1000);
  
  // Prepare HTTP GET request for isLocked field
  String path = "/boxes/" + String(BOX_ID) + "/isLocked.json";
  String request = "GET " + path + " HTTP/1.1\r\n";
  request += "Host: " + String(FIREBASE_HOST) + "\r\n";
  request += "Connection: close\r\n\r\n";
  
  // Send request
  Serial.println(F("[Firebase] Sending HTTP request..."));
  ESP8266.print(F("AT+CIPSEND=0,"));
  ESP8266.println(request.length());
  delay(1000);
  
  if (ESP8266.find(">")) {
    ESP8266.print(request);
    Serial.println(F("✓ Request sent"));
    delay(2000);
    
    // Read response
    String response = "";
    timeout = millis();
    
    while (millis() - timeout < 5000) {
      while (ESP8266.available()) {
        response += (char)ESP8266.read();
      }
    }
    
    // Close connection
    ESP8266.println(F("AT+CIPCLOSE=0"));
    delay(500);
    
    // Debug: Print response
    Serial.println(F("\n--- Firebase Response ---"));
    Serial.println(response);
    Serial.println(F("--- End Response ---\n"));
    
    // Parse isLocked from JSON response
    bool isLocked = parseLockStatus(response);
    return isLocked;
    
  } else {
    Serial.println(F("✗ Failed to send request"));
    ESP8266.println(F("AT+CIPCLOSE=0"));
    delay(500);
    return lastLockState; // Return last known state
  }
}

// ============================================
// PARSE LOCK STATUS FROM JSON RESPONSE
// ============================================

bool parseLockStatus(String response) {
  // Look for "true" or "false" in response
  
  if (response.indexOf("true") > -1) {
    return true;  // Locked
  } 
  else if (response.indexOf("false") > -1) {
    return false; // Unlocked
  }
  else if (response.indexOf("null") > -1) {
    return true;  // Default to locked if null
  }
  
  return lastLockState; // Return last known state if parsing fails
}

// ============================================
// UNLOCK BOX
// ============================================

void unlockBox() {
  Serial.println(F("\n🔓 UNLOCKING BOX..."));
  
  lockServo.write(UNLOCKED_POSITION);
  Serial.print(F("✓ Servo moved to "));
  Serial.print(UNLOCKED_POSITION);
  Serial.println(F("°"));
  
  Serial.println(F("✓ Box UNLOCKED!\n"));
}

// ============================================
// LOCK BOX
// ============================================

void lockBox() {
  Serial.println(F("\n🔒 LOCKING BOX..."));
  
  lockServo.write(LOCKED_POSITION);
  Serial.print(F("✓ Servo moved to "));
  Serial.print(LOCKED_POSITION);
  Serial.println(F("°"));
  
  Serial.println(F("✓ Box LOCKED!\n"));
}

// ============================================
// CLEAR ESP8266 BUFFER
// ============================================

void clearESPBuffer() {
  while (ESP8266.available()) {
    ESP8266.read();
  }
}

// ============================================
// END OF CODE
// ============================================
