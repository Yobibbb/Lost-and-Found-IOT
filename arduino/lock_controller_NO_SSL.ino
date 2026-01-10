/*
 * Arduino Lock Controller - NO SSL VERSION
 * Your ESP8266 doesn't support SSL, so this uses a simpler approach
 * 
 * IMPORTANT: This won't work with Firebase directly.
 * You have 2 options:
 * 1. Install Node.js + Firebase CLI and deploy the HTTP proxy function
 * 2. Upgrade to ESP32 which has built-in SSL support
 */

#include <SoftwareSerial.h>
#include <Servo.h>

// WiFi Configuration
#define WIFI_SSID "ZTE_2.4G_VFfJNJ"
#define WIFI_PASSWORD "9MUkNPy4"

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
  Serial.println(F("⚠ WARNING: ESP8266 doesn't support SSL"));
  Serial.println(F("This code demonstrates the issue."));
  Serial.println(F(""));
  Serial.println(F("SOLUTIONS:"));
  Serial.println(F("1. Use ESP32 instead (recommended)"));
  Serial.println(F("2. Deploy HTTP proxy Cloud Function"));
  Serial.println(F("3. Update ESP8266 firmware (advanced)\n"));
  
  delay(2000);
  
  // Reset ESP8266
  ESP8266.println("AT+RST");
  delay(2000);
  
  // Set to Station Mode
  ESP8266.println("AT+CWMODE=1");
  delay(1000);
  
  // Connect to WiFi
  connectWiFi();
  
  Serial.println(F("\n=================================="));
  Serial.println(F("Your ESP8266 firmware doesn't support SSL!"));
  Serial.println(F(""));
  Serial.println(F("BEST SOLUTION: Buy ESP32"));
  Serial.println(F("ESP32 has built-in SSL and is only $3-5"));
  Serial.println(F("It's pin-compatible with most ESP8266 projects"));
  Serial.println(F("==================================\n"));
}

void loop() {
  // Simulate lock status (since we can't connect to Firebase)
  Serial.println(F("⚠ Cannot connect to Firebase without SSL"));
  Serial.println(F("Servo staying in LOCKED position"));
  Serial.println(F(""));
  Serial.println(F("To fix: Get ESP32 or deploy HTTP proxy function"));
  
  lockServo.write(LOCKED_POSITION);
  
  delay(5000);
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
