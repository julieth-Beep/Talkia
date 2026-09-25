const express = require("express");
const router = express.Router();
const ContactoController = require("../controllers/ContactoController");

router.post("/", ContactoController.agregar);
router.get("/personas-disponibles/:duenoId", ContactoController.personasDisponibles);
router.get("/buscar-usuario/:duenoId", ContactoController.buscarUsuario);
router.get("/mis-contactos/:duenoId", ContactoController.buscarEnMisContactos);
router.get("/nombre-amostrar/:duenoId/:contactoId", ContactoController.obtenerNombreAMostrar);
router.get("/:duenoId", ContactoController.listar);
router.patch("/:contactoId", ContactoController.actualizar);
router.delete("/:contactoId", ContactoController.eliminar);

module.exports = router;