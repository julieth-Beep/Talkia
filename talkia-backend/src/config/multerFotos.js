const multer = require("multer");
const path = require("path");
const { v4: uuidv4 } = require("uuid");

const storage = multer.diskStorage({
  destination: (req, file, cb) => {
    cb(null, path.join(__dirname, "../../uploads/fotos_perfil"));
  },
  filename: (req, file, cb) => {
    // Detectar extensión o usar .jpg por defecto
    let extension = path.extname(file.originalname).toLowerCase();
    if (!extension || extension === ".") {
      extension = ".jpg";
    }
    cb(null, `${uuidv4()}${extension}`);
  },
});

// ✅ PERMISIVO: acepta cualquier archivo que parezca imagen
const fileFilter = (req, file, cb) => {
  console.log("📷 Archivo recibido:");
  console.log("   - originalname:", file.originalname);
  console.log("   - mimetype:", file.mimetype);

  // Extensiones de imagen conocidas
  const extensionesImagen = [
    ".jpg", ".jpeg", ".png", ".gif", ".webp",
    ".bmp", ".heic", ".heif", ".svg", ".tiff", ".ico",
  ];

  const extension = path.extname(file.originalname).toLowerCase();

  // ✅ Aceptar si:
  // 1. El mimetype empieza con "image/"
  // 2. La extensión es de imagen
  // 3. El mimetype está vacío (Flutter a veces no lo envía)
  const esImagen =
    file.mimetype.startsWith("image/") ||
    extensionesImagen.includes(extension) ||
    !file.mimetype ||
    file.mimetype === "application/octet-stream";

  if (esImagen) {
    console.log("   ✅ Archivo aceptado");
    cb(null, true);
  } else {
    console.log("   ❌ Archivo rechazado");
    cb(new Error("Solo se permiten imágenes"), false);
  }
};

const upload = multer({
  storage,
  fileFilter,
  limits: { fileSize: 10 * 1024 * 1024 }, // 10 MB
});

module.exports = upload;