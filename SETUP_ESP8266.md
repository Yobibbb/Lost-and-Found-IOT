# ESP8266 Setup Guide (No SSL Support)

## The Problem
ESP8266 doesn't support SSL, but Firebase requires HTTPS. 

## The Solution
Use a Cloud Function as an HTTP proxy that Arduino can access via plain HTTP.

## Setup Steps

### 1. Install Node.js
1. Download from: https://nodejs.org/ (choose LTS version)
2. Run the installer
3. Restart your PowerShell terminal
4. Verify: `node --version`

### 2. Install Firebase CLI
```bash
npm install -g firebase-tools
```

### 3. Login to Firebase
```bash
firebase login
```

### 4. Deploy the HTTP Proxy Function
```bash
cd "c:\Users\ALLAN\Desktop\LostAndFound\Lost-and-Found-IOT"
cd functions
npm install
cd ..
firebase deploy --only functions:getBoxStatus
```

### 5. Get Your Function URL
After deployment, you'll see a URL like:
```
https://us-central1-lostandfound-606de.cloudfunctions.net/getBoxStatus
```

Copy this URL!

### 6. Update Arduino Code
Replace the FIREBASE_PROXY_URL in the Arduino code with your function URL.

### 7. Upload to Arduino
Upload the updated code and it should work!

## How It Works
```
Arduino (HTTP) → Cloud Function (HTTPS) → Firebase Realtime Database
```

The Cloud Function handles the SSL connection for you!
