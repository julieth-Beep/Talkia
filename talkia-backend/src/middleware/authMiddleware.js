const jwt = require("jsonwebtoken");

// Verifica que el token exista, esté firmado y no haya expirado
function verificarToken(req, res, next) {
  const authHeader = req.headers.authorization;

  if (!authHeader || !authHeader.startsWith("Bearer ")) {
    return res.status(401).json({ error: "Token de autenticación requerido." });
  }

  try {
    const token = authHeader.split(" ")[1];
    const payload = jwt.verify(token, process.env.JWT_SECRET);
    req.usuario = payload; // { uid, rol, iat, exp }
    next();
  } catch (error) {
    return res.status(401).json({ error: "Token inválido o expirado." });
  }
}

// Debe ir DESPUÉS de verificarToken
function soloAdmin(req, res, next) {
  if (req.usuario?.rol !== "admin") {
    return res.status(403).json({ error: "Acceso permitido solo para administradores." });
  }
  next();
}

module.exports = { verificarToken, soloAdmin };