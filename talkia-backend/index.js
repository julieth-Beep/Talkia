require("dotenv").config();

const express = require("express");
const cors = require("cors");
const path = require("path");
const usuarioRoutes = require("./src/routes/usuarioRoutes");
const chatRoutes = require("./src/routes/chatRoutes");
const traduccionRoutes = require("./src/routes/traduccionRoutes");
const diccionarioRoutes = require("./src/routes/diccionarioRoutes");
const adminRoutes = require("./src/routes/adminRoutes");
const contactoRoutes = require("./src/routes/contactoRoutes");

const app = express();
app.use(cors());
app.use(express.json());

// SIRVE ARCHIVOS ESTÁTICOS - IMPORTANTE que esté ANTES de las rutas
app.use("/uploads", express.static(path.resolve(__dirname, "uploads")));

const PORT = 3000;

app.get("/", (req, res) => {
  res.send("Talkia backend funcionando correctamente");
});

app.use("/api/usuarios", usuarioRoutes);
app.use("/api/chat", chatRoutes);
app.use("/api/diccionario", diccionarioRoutes);
app.use("/api/admin", adminRoutes);
app.use("/api/contactos", contactoRoutes);

// Escucha en todas las interfaces (0.0.0.0)
app.listen(PORT, '0.0.0.0', () => {
  console.log(`Servidor corriendo en:`);
  console.log(`  - Local: http://localhost:${PORT}`);
  console.log(`  - Emulador Android: http://10.0.2.2:${PORT}`);
  console.log(`  - Red local: http://${getLocalIp()}:${PORT}`);
});

app.use("/api/traduccion", traduccionRoutes);

function getLocalIp() {
  const { networkInterfaces } = require('os');
  const nets = networkInterfaces();
  for (const name of Object.keys(nets)) {
    for (const net of nets[name]) {
      if (net.family === 'IPv4' && !net.internal) {
        return net.address;
      }
    }
  }
  return '127.0.0.1';
}