/*
 * Arduino Lock Controller - Firestore via Realtime Database
 * Reads isLocked from Firebase Realtime Database and controls servo motor
 */

#include <SoftwareSerial.h>
#include <Servo.h>

// WiFi Configuration
#define WIFI_SSID "ZTE_2.4G_VFfJNJ"
#define WIFI_PASSWORD "9MUkNPy4"

// Firebase Realtime Database Configuration
#define FIREBASE_HOST "lostandfound-606de-default-rtdb.asia-southeast1.firebasedatabase.app"
#define BOX_ID "BOX_A1"

// Hardware Setup
SoftwareSerial ESP8266(2, 3); // RX, TX
Servo lockServo;
const int SERVO_PIN = 9;

// Lock States
const int LOCKED_POSITION = 0;
const int UNLOCKED_POSITION = 180;

// Track previous state
bool previousLockState = true; // Start with locked
bool firstRun = true; // Flag for first execution

void setup() {
  Serial.begin(115200);
  ESP8266.begin(115200);
  
  // Initialize servo
  lockServo.attach(SERVO_PIN);
  lockServo.write(LOCKED_POSITION);
  
  Serial.println(F("\n=== Arduino Lock Controller ==="));
  Serial.println(F("Connected to Realtime Database"));
  Serial.println(F("Servo will ONLY move when status changes!\n"));
  
  delay(2000);
  
  // Reset ESP8266
  ESP8266.println("AT+RST");
  delay(2000);
  
  // Set to Station Mode
  ESP8266.println("AT+CWMODE=1");
  delay(1000);
  
  // Connect to WiFi
  connectWiFi();
}

void loop() {
  // Read isLocked status from Firebase
  bool isLocked = readLockStatus();
  
  // Only move servo when state changes
  if (firstRun || isLocked != previousLockState) {
    if (isLocked) {
      Serial.println(F("🔒 STATUS CHANGED: LOCKED - Moving servo to 0°"));
      lockServo.write(LOCKED_POSITION);
    } else {
      Serial.println(F("🔓 STATUS CHANGED: UNLOCKED - Moving servo to 180°"));
      lockServo.write(UNLOCKED_POSITION);
    }
    
    previousLockState = isLocked;
    firstRun = false;
  } else {
    // No change - just report current state
    Serial.print(F("Status unchanged: "));
    Serial.println(isLocked ? F("LOCKED") : F("UNLOCKED"));
  }
  
  // Wait 3 seconds before checking again
  delay(3000);
}

// Connect to WiFi
void connectWiFi() {
  Serial.println(F("Connecting to WiFi..."));
  
  ESP8266.print("AT+CWJAP=\"");
  ESP8266.print(WIFI_SSID);
  ESP8266.print("\",\"");
  ESP8266.print(WIFI_PASSWORD);
  ESP8266.println("\"");
  
  ESP8266.setTimeout(10000);
  
  if (ESP8266.find("WIFI CONNECTED") || ESP8266.find("OK")) {
    Serial.println(F("✓ WiFi Connected!\n"));
    
    delay(2000);
    ESP8266.println("AT+CIPMUX=1");
    delay(500);
  } else {
    Serial.println(F("✗ WiFi Failed - Retrying in 5 seconds...\n"));
    delay(5000);
    connectWiFi(); // Retry
  }
}

// Read lock status from Firebase Realtime Database
bool readLockStatus() {
  // Close any existing connection
  ESP8266.println("AT+CIPCLOSE=0");
  delay(500);
  
  // Connect to Firebase
  Serial.print(F("Connecting to Firebase... "));
  Serial.println();
  Serial.print(F("Host: "));
  Serial.println(FIREBASE_HOST);
  
  ESP8266.print("AT+CIPSTART=0,\"SSL\",\"");
  ESP8266.print(FIREBASE_HOST);
  ESP8266.println("\",443");
  
  // Show ESP8266 response
  Serial.println(F("ESP8266 Response:"));
  String connResponse = "";
  unsigned long timeout = millis();
  bool connected = false;
  
  while (millis() - timeout < 10000) {
    while (ESP8266.available()) {
      char c = ESP8266.read();
      Serial.print(c);
      connResponse += c;
    }
    if (connResponse.indexOf("CONNECT") > -1) {
      Serial.println(F("\n✓ SSL Connected!"));
      connected = true;
      break;
    }
    if (connResponse.indexOf("ERROR") > -1) {
      Serial.println(F("\n✗ SSL Connection Failed!"));
      Serial.println(F("Your ESP8266 firmware may not support SSL."));
      return previousLockState; // Return last known state
    }
  }
  
  if (!connected) {
    Serial.println(F("\n✗ Connection Timeout"));
    return previousLockState; // Return last known state
  }
  
  delay(1000);
  
  // Prepare HTTP GET request
  String path = "/boxes/" + String(BOX_ID) + "/isLocked.json";
  String request = "GET " + path + " HTTP/1.1\r\n";
  request += "Host: " + String(FIREBASE_HOST) + "\r\n";
  request += "Connection: close\r\n\r\n";
  
  // Send request
  ESP8266.print("AT+CIPSEND=0,");
  ESP8266.println(request.length());
  delay(1000);
  
  if (ESP8266.find(">")) {
    ESP8266.print(request);
    delay(2000);
    
    // Read response
    String response = "";
    unsigned long timeout = millis();
    
    while (millis() - timeout < 5000) {
      while (ESP8266.available()) {
        response += (char)ESP8266.read();
      }
    }
    
    // Close connection
    ESP8266.println("AT+CIPCLOSE=0");
    delay(500);
    
    // Debug: Print response
    Serial.println(F("\n--- Response ---"));
    Serial.println(response);
    Serial.println(F("--- End ---\n"));
    
    // Parse response (look for true or false)
    if (response.indexOf("true") > -1) {
      Serial.println(F("✓ Read from Firebase: LOCKED"));
      return true;
    } else if (response.indexOf("false") > -1) {
      Serial.println(F("✓ Read from Firebase: UNLOCKED"));
      return false;
    }
  }
  
  // If cannot read, return last known state
  Serial.println(F("⚠ Cannot read Firebase - Using last known state"));
  return previousLockState;
}
