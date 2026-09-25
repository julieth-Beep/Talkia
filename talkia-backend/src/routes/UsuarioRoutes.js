const express = require("express");
const router = express.Router();
const UsuarioController = require("../controllers/UsuarioController");
const uploadFotos = require("../config/multerFotos");

router.post("/registro", UsuarioController.registrar);
router.post("/login", UsuarioController.iniciarSesion);
router.patch("/:id/perfil", UsuarioController.completarPerfil);
router.post("/google", UsuarioController.loginConGoogle);
router.post("/recuperar", UsuarioController.solicitarRecuperacion);
router.post("/restablecer", UsuarioController.restablecerContraseña);
router.get("/", UsuarioController.listarUsuarios);
router.patch("/:id/foto", uploadFotos.single("foto"), UsuarioController.actualizarFotoPerfil);
router.patch("/:id/datos", UsuarioController.actualizarDatosPersonales);
router.patch("/:id/info", UsuarioController.actualizarInfo);

module.exports = router;