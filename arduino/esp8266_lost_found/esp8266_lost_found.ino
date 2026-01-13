#include <ESP8266WiFi.h>
#include <FirebaseESP8266.h>
#include <ArduinoJson.h>

// WiFi credentials
#define WIFI_SSID "YOUR_WIFI_SSID"
#define WIFI_PASSWORD "YOUR_WIFI_PASSWORD"

// Firebase credentials
#define FIREBASE_HOST "YOUR_PROJECT_ID.firebaseio.com"
#define FIREBASE_AUTH "YOUR_DATABASE_SECRET"

// Define Firebase objects
FirebaseData firebaseData;ab
FirebaseAuth auth;
FirebaseConfig config;

// Box/Device ID
String boxId = "box_001";

void setup() {
  Serial.begin(115200);
  
  // Connect to WiFi
  Serial.println();
  Serial.print("Connecting to WiFi");
  WiFi.begin(WIFI_SSID, WIFI_PASSWORD);
  
  while (WiFi.status() != WL_CONNECTED) {
    Serial.print(".");
    delay(500);
  }
  
  Serial.println();
  Serial.println("WiFi Connected!");
  Serial.print("IP Address: ");
  Serial.println(WiFi.localIP());
  
  // Configure Firebase
  config.host = FIREBASE_HOST;
  config.signer.tokens.legacy_token = FIREBASE_AUTH;
  
  // Initialize Firebase
  Firebase.begin(&config, &auth);
  Firebase.reconnectWiFi(true);
  
  Serial.println("Firebase initialized!");
}

void loop() {
  // Your main logic here
  
  // Example: Read data from Firebase
  if (Firebase.getString(firebaseData, "/boxes/" + boxId + "/status")) {
    Serial.println("Box Status: " + firebaseData.stringData());
  } else {
    Serial.println("Error: " + firebaseData.errorReason());
  }
  
  delay(5000); // Wait 5 seconds
}
