const functions = require('firebase-functions');
const admin = require('firebase-admin');
admin.initializeApp();

// Sync Firestore boxes collection to Realtime Database
exports.syncBoxToRealtimeDB = functions.firestore
  .document('boxes/{boxId}')
  .onWrite(async (change, context) => {
    const boxId = context.params.boxId;
    const rtdb = admin.database();
    
    if (!change.after.exists) {
      // Box deleted - remove from RTDB
      await rtdb.ref(`boxes/${boxId}`).remove();
      return null;
    }
    
    const boxData = change.after.data();
    
    // Sync only the lock status to Realtime Database
    await rtdb.ref(`boxes/${boxId}`).update({
      isLocked: boxData.isLocked || true,
      lastUpdated: admin.database.ServerValue.TIMESTAMP
    });
    
    return null;
  });

// HTTP Proxy for Arduino/ESP8266 (No SSL required)
// Arduino can access this via HTTP
exports.getBoxStatus = functions.https.onRequest(async (req, res) => {
  // Enable CORS
  res.set('Access-Control-Allow-Origin', '*');
  
  if (req.method === 'OPTIONS') {
    res.set('Access-Control-Allow-Methods', 'GET');
    res.set('Access-Control-Allow-Headers', 'Content-Type');
    res.status(204).send('');
    return;
  }
  
  try {
    const boxId = req.query.boxId || 'BOX_A1';
    const rtdb = admin.database();
    
    // Read from Realtime Database
    const snapshot = await rtdb.ref(`boxes/${boxId}/isLocked`).once('value');
    const isLocked = snapshot.val();
    
    if (isLocked === null) {
      res.status(404).json({ error: 'Box not found', boxId });
      return;
    }
    
    // Return plain boolean value for easy Arduino parsing
    res.status(200).send(isLocked.toString());
    
  } catch (error) {
    console.error('Error reading box status:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});
