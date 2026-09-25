class Contacto {
  constructor({
    duenoId,              // ID del usuario que agrega el contacto
    contactoId,           // ID del usuario agregado
    nombrePersonalizado,  // Cómo el dueño llama a este contacto
    fechaAgregado = new Date().toISOString(),
    favorito = false,
  }) {
    this.duenoId = duenoId;
    this.contactoId = contactoId;
    this.nombrePersonalizado = nombrePersonalizado;
    this.fechaAgregado = fechaAgregado;
    this.favorito = favorito;
  }
}

module.exports = Contacto;