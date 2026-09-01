const fetch = require("node-fetch");

class TraduccionService {
  constructor() {
    this.idiomas = {
      "Español": "es",
      "Inglés": "en",
      "Francés": "fr",
      "Italiano": "it",
      "Mandarín": "zh",
      "Alemán": "de",
      "Portugués": "pt",
      "Ruso": "ru",
      "Japonés": "ja",
      "Coreano": "ko"
    };

    this.apiUrl = "https://api.mymemory.translated.net";
    console.log("✅ TraduccionService inicializado con MyMemory");
  }

  async traducir(texto, idiomaDestino, idiomaOrigen = "es") {
    if (!texto || texto.trim() === "") return texto;

    try {
      const target = this.idiomas[idiomaDestino] || idiomaDestino;
      const source = this.idiomas[idiomaOrigen] || idiomaOrigen;

      if (source === target) return texto;

      console.log(`📝 Traduciendo "${texto}" de ${source} a ${target}`);

      const langpair = `${source}|${target}`;
      const url = `${this.apiUrl}/get?q=${encodeURIComponent(texto)}&langpair=${langpair}`;

      const response = await fetch(url);
      if (!response.ok) throw new Error(`HTTP error! status: ${response.status}`);

      const data = await response.json();

      if (data.responseData && data.responseData.translatedText) {
        console.log(`✅ Traducción exitosa: "${data.responseData.translatedText}"`);
        return data.responseData.translatedText;
      }

      return texto;
    } catch (error) {
      console.error("❌ Error en traducción:", error.message);
      return texto;
    }
  }

  // MyMemory no detecta idioma por separado.
  // Usamos el idioma predeterminado del REMITENTE (guardado en su perfil)
  // en vez de intentar adivinarlo con reglas poco confiables.
  async detectarIdioma(texto, idiomaRemitente = "Español") {
    return this.idiomas[idiomaRemitente] || "es";
  }
}

module.exports = new TraduccionService();