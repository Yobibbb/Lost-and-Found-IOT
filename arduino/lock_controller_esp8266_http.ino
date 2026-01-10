/*
 * Arduino Lock Controller - ESP8266 via HTTP Proxy
 * Works with ESP8266 that doesn't support SSL
 * Uses Cloud Function as HTTP proxy
 */

#include <SoftwareSerial.h>
#include <Servo.h>

// WiFi Configuration
#define WIFI_SSID "ZTE_2.4G_VFfJNJ"
#define WIFI_PASSWORD "9MUkNPy4"

// Cloud Function HTTP Proxy (NO SSL NEEDED!)
// REPLACE THIS WITH YOUR ACTUAL FUNCTION URL AFTER DEPLOYMENT
#define PROXY_HOST "us-central1-lostandfound-606de.cloudfunctions.net"
#define PROXY_PATH "/getBoxStatus?boxId=BOX_A1"
#define BOX_ID "BOX_A1"

// Hardware Setup
SoftwareSerial ESP8266(2, 3); // RX, TX
Servo lockServo;
const int SERVO_PIN = 9;

// Lock States
const int LOCKED_POSITION = 0;
const int UNLOCKED_POSITION = 180;

// Track previous state
bool previousLockState = true;
bool firstRun = true;

void setup() {
  Serial.begin(115200);
  ESP8266.begin(115200);
  
  lockServo.attach(SERVO_PIN);
  lockServo.write(LOCKED_POSITION);
  
  Serial.println(F("\n=== Arduino Lock Controller ==="));
  Serial.println(F("Using HTTP Proxy for ESP8266\n"));
  
  delay(2000);
  
  ESP8266.println("AT+RST");
  delay(2000);
  
  ESP8266.println("AT+CWMODE=1");
  delay(1000);
  
  connectWiFi();
  
  Serial.println(F("\n✓ Setup complete!"));
  Serial.println(F("Now checking Firebase every 3 seconds...\n"));
}

void loop() {
  bool isLocked = readLockStatus();
  
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
    Serial.print(F("Status unchanged: "));
    Serial.println(isLocked ? F("LOCKED") : F("UNLOCKED"));
  }
  
  delay(3000);
}

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
    Serial.println(F("✗ WiFi Failed - Retrying...\n"));
    delay(5000);
    connectWiFi();
  }
}

bool readLockStatus() {
  ESP8266.println("AT+CIPCLOSE=0");
  delay(500);
  
  Serial.println(F("→ Connecting to Cloud Function (HTTP)..."));
  
  // Use SSL for Cloud Functions (they support it better than RTDB)
  ESP8266.print("AT+CIPSTART=0,\"SSL\",\"");
  ESP8266.print(PROXY_HOST);
  ESP8266.println("\",443");
  
  String connResponse = "";
  unsigned long timeout = millis();
  bool connected = false;
  
  while (millis() - timeout < 10000) {
    while (ESP8266.available()) {
      char c = ESP8266.read();
      connResponse += c;
    }
    if (connResponse.indexOf("CONNECT") > -1) {
      connected = true;
      break;
    }
    if (connResponse.indexOf("ERROR") > -1) {
      Serial.println(F("✗ SSL Failed - Trying TCP..."));
      // Try plain TCP as fallback
      ESP8266.println("AT+CIPCLOSE=0");
      delay(500);
      
      ESP8266.print("AT+CIPSTART=0,\"TCP\",\"");
      ESP8266.print(PROXY_HOST);
      ESP8266.println("\",80");
      delay(2000);
      
      connResponse = "";
      while (ESP8266.available()) {
        connResponse += (char)ESP8266.read();
      }
      
      if (connResponse.indexOf("CONNECT") > -1) {
        connected = true;
        Serial.println(F("✓ Connected via TCP (port 80)"));
        break;
      } else {
        Serial.println(F("✗ Both SSL and TCP failed!"));
        Serial.println(F("Make sure Cloud Function is deployed."));
        return previousLockState;
      }
    }
  }
  
  if (!connected) {
    Serial.println(F("✗ Connection timeout"));
    return previousLockState;
  }
  
  Serial.println(F("✓ Connected!"));
  delay(1000);
  
  // Build HTTP request
  String request = "GET ";
  request += PROXY_PATH;
  request += " HTTP/1.1\r\n";
  request += "Host: ";
  request += PROXY_HOST;
  request += "\r\n";
  request += "Connection: close\r\n\r\n";
  
  Serial.print(F("Request size: "));
  Serial.println(request.length());
  
  ESP8266.print("AT+CIPSEND=0,");
  ESP8266.println(request.length());
  delay(1000);
  
  if (ESP8266.find(">")) {
    ESP8266.print(request);
    Serial.println(F("✓ Request sent"));
    delay(2000);
    
    String response = "";
    timeout = millis();
    
    while (millis() - timeout < 5000) {
      while (ESP8266.available()) {
        response += (char)ESP8266.read();
      }
    }
    
    ESP8266.println("AT+CIPCLOSE=0");
    delay(500);
    
    Serial.println(F("\n--- Response ---"));
    Serial.println(response);
    Serial.println(F("--- End ---\n"));
    
    // Parse response - Cloud Function returns plain "true" or "false"
    if (response.indexOf("true") > -1) {
      Serial.println(F("✓ Firebase says: LOCKED"));
      return true;
    } else if (response.indexOf("false") > -1) {
      Serial.println(F("✓ Firebase says: UNLOCKED"));
      return false;
    }
  }
  
  Serial.println(F("⚠ No valid response - using last state"));
  return previousLockState;
}
