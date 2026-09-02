const express = require("express");
const router = express.Router();
const UsuarioController = require("../controllers/UsuarioController");

router.post("/registro", UsuarioController.registrar);
router.post("/login", UsuarioController.iniciarSesion);
router.patch("/:id/perfil", UsuarioController.completarPerfil);
router.post("/google", UsuarioController.loginConGoogle);
router.post("/recuperar", UsuarioController.solicitarRecuperacion);
router.post("/restablecer", UsuarioController.restablecerContraseña);
router.get("/", UsuarioController.listarUsuarios);

module.exports = router;