const admin = require('firebase-admin');
const serviceAccount = require('./medigo-8fbb2-firebase-adminsdk-fbsvc-aa957931f9.json'); // <-- YOUR FILE NAME

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

const db = admin.firestore();
const tests = require('./tests_100.json'); // make sure this file exists

async function upload() {
  let batch = db.batch();
  let count = 0;
  for (const test of tests) {
    const docRef = db.collection('tests').doc(); // auto ID
    batch.set(docRef, test);
    count++;
    if (count % 500 === 0) {
      await batch.commit();
      batch = db.batch();
    }
  }
  if (count % 500 !== 0) await batch.commit();
  console.log(`✅ Uploaded ${count} tests`);
}

upload().catch(console.error);