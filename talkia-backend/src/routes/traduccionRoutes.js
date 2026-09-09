const express = require("express");
const router = express.Router();
const TraduccionService = require("../services/TraduccionService");

router.post("/traducir", async (req, res) => {
  try {
    const { texto, idiomaDestino, idiomaOrigen } = req.body;

    if (!texto || !idiomaDestino) {
      return res.status(400).json({ error: "Se requiere 'texto' e 'idiomaDestino'." });
    }

    const traduccion = await TraduccionService.traducir(texto, idiomaDestino, idiomaOrigen || "Español");
    res.status(200).json({ original: texto, traduccion });
  } catch (error) {
    res.status(500).json({ error: "Error al traducir." });
  }
});

module.exports = router;