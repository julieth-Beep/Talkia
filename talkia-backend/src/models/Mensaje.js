class Mensaje {
  constructor({
    conversacionId,
    remitenteId,
    textoOriginal,
    idiomaOriginal,
    textoTraducido = {},
    fecha = new Date().toISOString(),
    leido = false,
  }) {
    this.conversacionId = conversacionId;
    this.remitenteId = remitenteId;
    this.textoOriginal = textoOriginal;
    this.idiomaOriginal = idiomaOriginal;
    this.textoTraducido = textoTraducido;
    this.fecha = fecha;
    this.leido = leido;
  }
}

module.exports = Mensaje;