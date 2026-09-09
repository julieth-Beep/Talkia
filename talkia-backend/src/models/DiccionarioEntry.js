class DiccionarioEntry {
  constructor({
    usuarioId,
    contactoId,
    palabraOriginal,
    traduccionFija,
    fechaCreacion = new Date().toISOString(),
  }) {
    this.usuarioId = usuarioId;
    this.contactoId = contactoId;
    this.palabraOriginal = palabraOriginal.trim().toLowerCase();
    this.traduccionFija = traduccionFija.trim();
    this.fechaCreacion = fechaCreacion;
  }
}

module.exports = DiccionarioEntry;