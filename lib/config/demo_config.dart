/// Demo Mode Configuration
/// 
/// TO CONNECT TO FIREBASE:
/// 1. Run: flutter pub get
/// 2. Run: flutterfire configure
/// 3. Enable Authentication & Firestore in Firebase Console
/// 4. Change 'demoMode' below to FALSE
/// 5. Restart the app
/// 
/// Set DEMO_MODE to true to run the app without Firebase
/// This allows you to test the UI and flow without backend configuration
library;

class DemoConfig {
  /// Change this to FALSE after Firebase setup
  static const bool demoMode = false;
  
  static const bool autoSignIn = true;
  static const bool showDemoBanner = true;
  static const int mockNetworkDelay = 500; // milliseconds
}
