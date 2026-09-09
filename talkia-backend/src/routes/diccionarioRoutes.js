const express = require("express");
const router = express.Router();
const DiccionarioController = require("../controllers/DiccionarioController");

router.post("/", DiccionarioController.agregarPalabra);
router.get("/:usuarioId/:contactoId", DiccionarioController.obtenerDiccionario);
router.delete("/:id", DiccionarioController.eliminarPalabra);

module.exports = router;