const multer = require("multer");
const path = require("path");
const { v4: uuidv4 } = require("uuid");

const storage = multer.diskStorage({
  destination: (req, file, cb) => {
    cb(null, path.join(__dirname, "../../uploads/audios"));
  },
  filename: (req, file, cb) => {
    const extension = path.extname(file.originalname) || ".m4a";
    cb(null, `${uuidv4()}${extension}`);
  },
});

const extensionesPermitidas = [".mp3", ".wav", ".m4a", ".aac", ".ogg", ".opus", ".webm"];

const fileFilter = (req, file, cb) => {
  const extension = path.extname(file.originalname).toLowerCase();
  const esMimetypeAudio = file.mimetype.startsWith("audio/") || file.mimetype.startsWith("video/ogg");
  const esExtensionValida = extensionesPermitidas.includes(extension);

  if (esMimetypeAudio || esExtensionValida) {
    cb(null, true);
  } else {
    cb(new Error(`Solo se permiten archivos de audio. Recibido: ${file.mimetype} (${extension})`), false);
  }
};

const upload = multer({
  storage,
  fileFilter,
  limits: { fileSize: 15 * 1024 * 1024 },
});

module.exports = upload;