require("dotenv").config();

const express = require("express");
const cors = require("cors");
const usuarioRoutes = require("./src/routes/usuarioRoutes");
const chatRoutes = require("./src/routes/chatRoutes"); 

const app = express();
app.use(cors());
app.use(express.json());

const PORT = 3000;

app.get("/", (req, res) => {
  res.send("Talkia backend funcionando correctamente");
});

app.use("/api/usuarios", usuarioRoutes);
app.use("/api/chat", chatRoutes);

app.listen(PORT, () => {
  console.log(`Servidor corriendo en http://localhost:${PORT}`);
});