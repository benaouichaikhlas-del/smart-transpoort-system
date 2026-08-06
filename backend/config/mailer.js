const nodemailer = require('nodemailer');

const transporter = nodemailer.createTransport({
  host: process.env.SMTP_HOST,
  port: Number(process.env.SMTP_PORT || 587),
  secure: false,
  auth: {
    user: process.env.SMTP_USER,
    pass: process.env.SMTP_PASS,
  },
});

const envoyerCodeReset = async (email, code) => {
  await transporter.sendMail({
    from: process.env.MAIL_FROM,
    to: email,
    subject: 'Réinitialisation de votre mot de passe — TransportDZ',
    html: `
      <div style="font-family:sans-serif;padding:20px;text-align:center;">
        <h2 style="color:#6aabf0;">TransportDZ</h2>
        <p>Vous avez demandé la réinitialisation de votre mot de passe.</p>
        <p>Voici votre code de vérification :</p>
        <p style="font-size:28px;font-weight:bold;letter-spacing:4px;">${code}</p>
        <p>Ce code expire dans 15 minutes.</p>
      </div>
    `,
  });
};

const envoyerCodeVerification = async (email, code) => {
  await transporter.sendMail({
    from: process.env.MAIL_FROM,
    to: email,
    subject: 'Vérification de votre email — TransportDZ',
    html: `
      <div style="font-family:sans-serif;padding:30px;text-align:center;">
        <h2 style="color:#6aabf0;">TransportDZ</h2>
        <p>Merci de vous inscrire ! Voici votre code :</p>
        <p style="font-size:36px;font-weight:bold;letter-spacing:8px;color:#333;">${code}</p>
        <p style="color:#999;">Ce code expire dans 15 minutes.</p>
      </div>
    `,
  });
};

module.exports = { envoyerCodeReset, envoyerCodeVerification };