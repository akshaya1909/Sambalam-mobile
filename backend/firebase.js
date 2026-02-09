import admin from 'firebase-admin';
// Change 'assert' to 'with'
import serviceAccount from './firebase-service-account.json' with { type: 'json' }; 

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
});

export default admin;