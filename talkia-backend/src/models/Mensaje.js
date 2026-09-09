class Mensaje {
  constructor({
    conversacionId,
    remitenteId,
    tipo = "texto", // "texto" o "audio"
    textoOriginal = null,
    idiomaOriginal = null,
    textoTraducido = {},
    audioUrl = null,
    fecha = new Date().toISOString(),
    leido = false,
  }) {
    this.conversacionId = conversacionId;
    this.remitenteId = remitenteId;
    this.tipo = tipo;
    this.textoOriginal = textoOriginal;
    this.idiomaOriginal = idiomaOriginal;
    this.textoTraducido = textoTraducido;
    this.audioUrl = audioUrl;
    this.fecha = fecha;
    this.leido = leido;
  }
}

module.exports = Mensaje;