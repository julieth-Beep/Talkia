const express = require("express");
const router = express.Router();
const AdminController = require("../controllers/AdminController");
const { verificarToken, soloAdmin } = require("../middleware/authMiddleware");

// TODAS las rutas de admin exigen: token válido + rol admin
// El orden importa: verificarToken primero (llena req.usuario), soloAdmin después (revisa el rol)
router.post("/crear-admin", verificarToken, soloAdmin, AdminController.crearAdmin);
router.get("/usuarios", verificarToken, soloAdmin, AdminController.listarUsuarios);
router.patch("/usuarios/:id/estado", verificarToken, soloAdmin, AdminController.cambiarEstado);
router.patch("/usuarios/:id/rol", verificarToken, soloAdmin, AdminController.cambiarRol);

module.exports = router;