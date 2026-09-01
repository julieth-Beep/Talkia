const { initializeApp, cert } = require("firebase-admin/app");
const { getFirestore } = require("firebase-admin/firestore");
const path = require("path");

// Ruta al archivo de credenciales que descargaste de Firebase
const serviceAccount = require(path.join(__dirname, "../../config/serviceAccountKey.json"));

// Inicializa la conexión con Firebase (solo debe hacerse UNA vez en todo el proyecto)
initializeApp({
  credential: cert(serviceAccount),
});

// Obtenemos la referencia a Firestore para usarla en el resto del proyecto
const db = getFirestore();

module.exports = db;