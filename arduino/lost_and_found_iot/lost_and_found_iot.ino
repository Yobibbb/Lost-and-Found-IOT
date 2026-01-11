/*
 * Lost & Found IoT System - Arduino Code
 * 
 * Hardware:
 * - Arduino Uno R3
 * - ESP8266-01 WiFi Module (SoftwareSerial on pins 2, 3)
 * - Servo Motor on pin 9 (or Relay Module)
 * 
 * Features:
 * - Connects to WiFi using AT commands
 * - Polls API every 3 seconds for commands
 * - Executes unlock (180°) and lock (0°) commands
 * - Sends heartbeat every 30 seconds
 * - Detailed serial debugging
 * 
 * API Endpoints:
 * - GET /api/arduino/command?box_id=BOX_A1
 * - POST /api/arduino/clear?box_id=BOX_A1
 * - POST /api/arduino/ping?box_id=BOX_A1
 */

#include <SoftwareSerial.h>
#include <Servo.h>

// ============================================
// CONFIGURATION - EDIT THESE VALUES
// ============================================

// WiFi Settings
#define WIFI_SSID "Your_WiFi_Name"
#define WIFI_PASS "Your_WiFi_Password"

// API Settings
#define API_HOST "192.168.1.100"  // Your computer IP or server IP (no http://)
#define API_PORT 80
#define API_PATH "/Lost-and-Found-IOT/backend/api/arduino"
#define BOX_ID "BOX_A1"  // Change for each box: BOX_A1, BOX_A2, etc.

// Hardware Settings
#define SERVO_PIN 9
#define LOCK_ANGLE 0      // Servo angle for locked position
#define UNLOCK_ANGLE 180  // Servo angle for unlocked position

// Timing Settings
#define POLL_INTERVAL 3000      // Poll API every 3 seconds
#define PING_INTERVAL 30000     // Send heartbeat every 30 seconds
#define WIFI_TIMEOUT 10000      // WiFi connection timeout
#define HTTP_TIMEOUT 5000       // HTTP request timeout

// Serial Settings
#define DEBUG_SERIAL Serial
#define ESP_SERIAL espSerial
#define DEBUG_BAUD 115200
#define ESP_BAUD 9600

// ============================================
// HARDWARE SETUP
// ============================================

SoftwareSerial espSerial(2, 3); // RX=2, TX=3 for ESP8266
Servo lockServo;

// ============================================
// GLOBAL VARIABLES
// ============================================

unsigned long lastPollTime = 0;
unsigned long lastPingTime = 0;
bool wifiConnected = false;
String currentCommand = "";
unsigned long commandTimestamp = 0;

// ============================================
// SETUP
// ============================================

void setup() {
  // Initialize serial communication
  DEBUG_SERIAL.begin(DEBUG_BAUD);
  ESP_SERIAL.begin(ESP_BAUD);
  
  // Wait for serial to initialize
  delay(1000);
  
  DEBUG_SERIAL.println(F("================================="));
  DEBUG_SERIAL.println(F("  Lost & Found IoT System"));
  DEBUG_SERIAL.println(F("  Arduino Uno R3 + ESP8266"));
  DEBUG_SERIAL.println(F("================================="));
  DEBUG_SERIAL.print(F("Box ID: "));
  DEBUG_SERIAL.println(BOX_ID);
  DEBUG_SERIAL.println();
  
  // Initialize servo
  lockServo.attach(SERVO_PIN);
  lockServo.write(LOCK_ANGLE); // Start in locked position
  DEBUG_SERIAL.println(F("[SERVO] Initialized to LOCKED position"));
  delay(500);
  
  // Initialize ESP8266
  DEBUG_SERIAL.println(F("[WIFI] Initializing ESP8266..."));
  initESP8266();
  
  // Connect to WiFi
  connectWiFi();
  
  DEBUG_SERIAL.println();
  DEBUG_SERIAL.println(F("[SYSTEM] Initialization complete!"));
  DEBUG_SERIAL.println(F("[SYSTEM] Starting main loop..."));
  DEBUG_SERIAL.println();
}

// ============================================
// MAIN LOOP
// ============================================

void loop() {
  unsigned long currentTime = millis();
  
  // Poll for commands every POLL_INTERVAL
  if (currentTime - lastPollTime >= POLL_INTERVAL) {
    lastPollTime = currentTime;
    
    if (wifiConnected) {
      pollForCommand();
    } else {
      DEBUG_SERIAL.println(F("[ERROR] WiFi not connected. Reconnecting..."));
      connectWiFi();
    }
  }
  
  // Send heartbeat ping every PING_INTERVAL
  if (currentTime - lastPingTime >= PING_INTERVAL) {
    lastPingTime = currentTime;
    
    if (wifiConnected) {
      sendHeartbeat();
    }
  }
  
  // Small delay to prevent overwhelming the loop
  delay(100);
}

// ============================================
// ESP8266 INITIALIZATION
// ============================================

void initESP8266() {
  DEBUG_SERIAL.println(F("[ESP] Sending AT test command..."));
  sendATCommand(F("AT"), 1000);
  
  DEBUG_SERIAL.println(F("[ESP] Setting station mode..."));
  sendATCommand(F("AT+CWMODE=1"), 2000);
  
  DEBUG_SERIAL.println(F("[ESP] Enabling multiple connections..."));
  sendATCommand(F("AT+CIPMUX=1"), 2000);
}

// ============================================
// WIFI CONNECTION
// ============================================

void connectWiFi() {
  DEBUG_SERIAL.print(F("[WIFI] Connecting to: "));
  DEBUG_SERIAL.println(WIFI_SSID);
  
  // Build connection command
  String cmd = F("AT+CWJAP=\"");
  cmd += WIFI_SSID;
  cmd += F("\",\"");
  cmd += WIFI_PASS;
  cmd += F("\"");
  
  // Send command and wait for OK
  ESP_SERIAL.println(cmd);
  
  unsigned long startTime = millis();
  String response = "";
  bool connected = false;
  
  while (millis() - startTime < WIFI_TIMEOUT) {
    if (ESP_SERIAL.available()) {
      char c = ESP_SERIAL.read();
      response += c;
      DEBUG_SERIAL.write(c);
      
      if (response.indexOf("OK") != -1) {
        connected = true;
        break;
      }
      
      if (response.indexOf("FAIL") != -1) {
        break;
      }
    }
  }
  
  wifiConnected = connected;
  
  if (connected) {
    DEBUG_SERIAL.println();
    DEBUG_SERIAL.println(F("[WIFI] ✓ Connected successfully!"));
    
    // Get IP address
    sendATCommand(F("AT+CIFSR"), 2000);
  } else {
    DEBUG_SERIAL.println();
    DEBUG_SERIAL.println(F("[WIFI] ✗ Connection failed!"));
    DEBUG_SERIAL.println(F("[WIFI] Will retry in next cycle..."));
  }
}

// ============================================
// POLL FOR COMMAND
// ============================================

void pollForCommand() {
  DEBUG_SERIAL.println(F("[API] Polling for commands..."));
  
  // Build HTTP GET request
  String url = String(API_PATH) + "/command?box_id=" + BOX_ID;
  String response = httpGet(API_HOST, API_PORT, url);
  
  if (response.length() > 0) {
    DEBUG_SERIAL.println(F("[API] Response received:"));
    DEBUG_SERIAL.println(response);
    
    // Parse command from JSON (simple string search, no JSON library)
    int commandPos = response.indexOf("\"command\":");
    if (commandPos != -1) {
      int startQuote = response.indexOf("\"", commandPos + 10);
      int endQuote = response.indexOf("\"", startQuote + 1);
      
      if (startQuote != -1 && endQuote != -1) {
        String command = response.substring(startQuote + 1, endQuote);
        
        if (command == "unlock") {
          DEBUG_SERIAL.println(F("[COMMAND] ⚡ UNLOCK command received!"));
          executeUnlock();
          clearCommand();
        } 
        else if (command == "lock") {
          DEBUG_SERIAL.println(F("[COMMAND] ⚡ LOCK command received!"));
          executeLock();
          clearCommand();
        }
        else if (command == "null") {
          DEBUG_SERIAL.println(F("[COMMAND] No pending commands."));
        }
        else {
          DEBUG_SERIAL.print(F("[COMMAND] Unknown command: "));
          DEBUG_SERIAL.println(command);
        }
      }
    }
  } else {
    DEBUG_SERIAL.println(F("[API] ✗ No response or error"));
  }
  
  DEBUG_SERIAL.println();
}

// ============================================
// EXECUTE COMMANDS
// ============================================

void executeUnlock() {
  DEBUG_SERIAL.println(F("[SERVO] Unlocking... Moving to 180°"));
  lockServo.write(UNLOCK_ANGLE);
  delay(1000); // Wait for servo to reach position
  DEBUG_SERIAL.println(F("[SERVO] ✓ Unlocked!"));
}

void executeLock() {
  DEBUG_SERIAL.println(F("[SERVO] Locking... Moving to 0°"));
  lockServo.write(LOCK_ANGLE);
  delay(1000); // Wait for servo to reach position
  DEBUG_SERIAL.println(F("[SERVO] ✓ Locked!"));
}

// ============================================
// CLEAR COMMAND (AFTER EXECUTION)
// ============================================

void clearCommand() {
  DEBUG_SERIAL.println(F("[API] Clearing command..."));
  
  String url = String(API_PATH) + "/clear?box_id=" + BOX_ID;
  String response = httpPost(API_HOST, API_PORT, url, "");
  
  if (response.indexOf("success") != -1) {
    DEBUG_SERIAL.println(F("[API] ✓ Command cleared successfully"));
  } else {
    DEBUG_SERIAL.println(F("[API] ✗ Failed to clear command"));
  }
}

// ============================================
// SEND HEARTBEAT
// ============================================

void sendHeartbeat() {
  DEBUG_SERIAL.println(F("[PING] Sending heartbeat..."));
  
  String url = String(API_PATH) + "/ping?box_id=" + BOX_ID;
  String response = httpPost(API_HOST, API_PORT, url, "");
  
  if (response.indexOf("success") != -1) {
    DEBUG_SERIAL.println(F("[PING] ✓ Heartbeat sent"));
  } else {
    DEBUG_SERIAL.println(F("[PING] ✗ Heartbeat failed"));
    wifiConnected = false; // Mark as disconnected to trigger reconnect
  }
}

// ============================================
// HTTP GET REQUEST
// ============================================

String httpGet(String host, int port, String url) {
  return httpRequest(host, port, url, "GET", "");
}

// ============================================
// HTTP POST REQUEST
// ============================================

String httpPost(String host, int port, String url, String body) {
  return httpRequest(host, port, url, "POST", body);
}

// ============================================
// HTTP REQUEST (USING AT COMMANDS)
// ============================================

String httpRequest(String host, int port, String url, String method, String body) {
  // Start TCP connection
  String cmd = "AT+CIPSTART=0,\"TCP\",\"" + host + "\"," + String(port);
  ESP_SERIAL.println(cmd);
  delay(2000);
  
  // Build HTTP request
  String request = method + " " + url + " HTTP/1.1\r\n";
  request += "Host: " + host + "\r\n";
  request += "Connection: close\r\n";
  
  if (body.length() > 0) {
    request += "Content-Type: application/json\r\n";
    request += "Content-Length: " + String(body.length()) + "\r\n";
  }
  
  request += "\r\n";
  request += body;
  
  // Send request length
  cmd = "AT+CIPSEND=0," + String(request.length());
  ESP_SERIAL.println(cmd);
  delay(500);
  
  // Send actual request
  ESP_SERIAL.print(request);
  
  // Wait for response
  unsigned long startTime = millis();
  String response = "";
  
  while (millis() - startTime < HTTP_TIMEOUT) {
    if (ESP_SERIAL.available()) {
      char c = ESP_SERIAL.read();
      response += c;
    }
    
    if (response.indexOf("+IPD") != -1 && response.indexOf("}") != -1) {
      break; // Got complete JSON response
    }
  }
  
  // Close connection
  ESP_SERIAL.println(F("AT+CIPCLOSE=0"));
  delay(500);
  
  // Extract JSON from response
  int jsonStart = response.indexOf("{");
  if (jsonStart != -1) {
    return response.substring(jsonStart);
  }
  
  return "";
}

// ============================================
// SEND AT COMMAND
// ============================================

void sendATCommand(const __FlashStringHelper* cmd, int timeout) {
  ESP_SERIAL.println(cmd);
  
  unsigned long startTime = millis();
  while (millis() - startTime < timeout) {
    if (ESP_SERIAL.available()) {
      DEBUG_SERIAL.write(ESP_SERIAL.read());
    }
  }
  DEBUG_SERIAL.println();
}

// ============================================
// END OF CODE
// ============================================
