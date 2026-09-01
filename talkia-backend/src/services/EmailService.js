const nodemailer = require("nodemailer");

// Usa una cuenta de Gmail con "contraseña de aplicación" (no la contraseña normal)
// https://myaccount.google.com/apppasswords
const transporter = nodemailer.createTransport({
  service: "gmail",
  auth: {
    user: process.env.EMAIL_USER, // tu correo
    pass: process.env.EMAIL_PASS, // contraseña de aplicación de 16 dígitos
  },
});

class EmailService {
  static async enviarCorreoRecuperacion(correoDestino, token) {
    // En producción esto sería un link a tu app (deep link) o a una web
    const enlace = `talkia://reset-password?token=${token}`;

    await transporter.sendMail({
      from: `"Talkia" <${process.env.EMAIL_USER}>`,
      to: correoDestino,
      subject: "Recupera tu contraseña - Talkia",
      html: `
        <div style="font-family: Arial, sans-serif; max-width: 480px; margin: auto;">
          <h2 style="color: #006677;">Recupera tu contraseña</h2>
          <p>Recibimos una solicitud para restablecer tu contraseña en Talkia.</p>
          <p>Usa el siguiente código para continuar. Expira en 15 minutos:</p>
          <div style="background: #F8F9FF; padding: 16px; border-radius: 8px; text-align: center; font-size: 24px; font-weight: bold; letter-spacing: 4px; color: #0F172A;">
            ${token}
          </div>
          <p style="color: #64748B; font-size: 13px; margin-top: 24px;">
            Si no solicitaste esto, puedes ignorar este correo.
          </p>
        </div>
      `,
    });
  }
}

module.exports = EmailService;